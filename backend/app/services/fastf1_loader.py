from __future__ import annotations

import sys
import traceback
from typing import Any, Dict, List, Optional, Tuple
from pathlib import Path
import math
import threading
import warnings

# Suppress deprecation warnings for google.generativeai
warnings.filterwarnings("ignore", category=FutureWarning)

import fastf1
import pandas as pd


class TimeoutError(Exception):
    pass


def log_error(prefix: str, e: Exception):
    print(f"[ERROR] {prefix}: {e}", file=sys.stderr)
    traceback.print_exc(file=sys.stderr)


class FastF1Loader:
    """
    Loads FastF1 sessions and produces a JSON-serializable payload used by the frontend.
    """

    def __init__(self, store, fastf1_cache_dir: str = "./fastf1_cache"):
        self.store = store
        self.fastf1_cache_dir = fastf1_cache_dir
        Path(self.fastf1_cache_dir).mkdir(parents=True, exist_ok=True)
        fastf1.Cache.enable_cache(self.fastf1_cache_dir)

    def get_event_schedule(self, season: int) -> Dict[str, Any]:
        """
        Returns JSON-serializable schedule:
        {
          "season": 2025,
          "events": [
            {
              "round": 1,
              "event_name": "...",            # FastF1 EventName (best for internal access)
              "official_event_name": "...",   # OfficialEventName
              "country": "...",
              "location": "...",
              "event_format": "...",
              "event_date_utc": "...",
              "f1_api_support": true/false,
              "sessions": [
                 {"name":"Practice 1","date_utc":"..."},
                 ...
              ]
            },
            ...
          ]
        }
        """
        # Threading-based timeout (works on HuggingFace)
        result = {"df": None, "error": None}

        def fetch_schedule():
            try:
                result["df"] = fastf1.get_event_schedule(season)
            except Exception as e:
                result["error"] = e

        thread = threading.Thread(target=fetch_schedule)
        thread.daemon = True
        thread.start()
        thread.join(timeout=15)

        if thread.is_alive() or result["error"] is not None:
            return {"season": int(season), "events": []}

        df = result["df"]

        # Some FastF1 versions return an EventSchedule object that behaves like a DataFrame;
        # to be safe, coerce to DataFrame.
        if not isinstance(df, pd.DataFrame):
            try:
                df = pd.DataFrame(df)
            except Exception:
                df = pd.DataFrame()

        events: List[Dict[str, Any]] = []
        if df is None or len(df) == 0:
            return {"season": int(season), "events": []}

        # Normalize column names that can vary (rare, but happens across versions/backends)
        col_round = self._pick_col(df, ["RoundNumber", "Round", "round"])
        col_country = self._pick_col(df, ["Country"])
        col_location = self._pick_col(df, ["Location"])
        col_event_name = self._pick_col(df, ["EventName", "Name"])
        col_official = self._pick_col(df, ["OfficialEventName"])
        col_event_date = self._pick_col(df, ["EventDate", "EventDateUtc"])
        col_format = self._pick_col(df, ["EventFormat", "Format"])
        col_api_support = self._pick_col(df, ["F1ApiSupport"])

        # Session columns: Session1..Session5 + Session1DateUtc..Session5DateUtc
        session_name_cols = []
        session_date_cols = []
        for i in range(1, 6):
            sn = f"Session{i}"
            sd = f"Session{i}DateUtc"
            if sn in df.columns:
                session_name_cols.append(sn)
            if sd in df.columns:
                session_date_cols.append(sd)

        # Build list ordered by RoundNumber
        df2 = df.copy()

        if col_round and col_round in df2.columns:
            df2[col_round] = pd.to_numeric(df2[col_round], errors="coerce")
            df2 = df2.dropna(subset=[col_round]).sort_values(col_round)

        for _, r in df2.iterrows():
            round_no = None
            if col_round:
                try:
                    rv = r.get(col_round)
                    if pd.notna(rv):
                        round_no = int(rv)
                except Exception:
                    round_no = None

            sessions: List[Dict[str, Any]] = []
            # Prefer Session1..5 + Session1DateUtc..5 pairing when possible
            for i in range(1, 6):
                sn = f"Session{i}"
                sd = f"Session{i}DateUtc"
                if sn in df2.columns:
                    sname = r.get(sn)
                    if sname is None or (isinstance(sname, float) and pd.isna(sname)):
                        continue
                    obj = {"name": str(sname)}
                    if sd in df2.columns:
                        obj["date_utc"] = self._safe_jsonable(r.get(sd))
                    sessions.append(obj)

            ev = {
                "round": round_no,
                "country": str(r.get(col_country) or "") if col_country else "",
                "location": str(r.get(col_location) or "") if col_location else "",
                "event_name": str(r.get(col_event_name) or "") if col_event_name else "",
                "official_event_name": str(r.get(col_official) or "") if col_official else "",
                "event_format": str(r.get(col_format) or "") if col_format else "",
                "event_date_utc": self._safe_jsonable(r.get(col_event_date)) if col_event_date else None,
                "f1_api_support": bool(r.get(col_api_support)) if col_api_support else None,
                "sessions": sessions,
            }

            events.append(self._safe_jsonable(ev))

        return self._safe_jsonable({"season": int(season), "events": events})

    def _pick_col(self, df: pd.DataFrame, candidates: List[str]) -> Optional[str]:
        for c in candidates:
            if c in df.columns:
                return c
        return None

    def load_and_cache_full(self, season: int, round_no: int, session_name: str) -> str:
        existing = self.store.find_full(season, round_no, session_name)
        if existing:
            return existing

        payload = self._build_full_payload(season, round_no, session_name)
        return self.store.write_full(season, round_no, session_name, payload)

    def _build_full_payload(self, season: int, round_no: int, session_name: str) -> Dict[str, Any]:
        ses = fastf1.get_session(season, round_no, session_name)
        ses.load()
        

        event = ses.event

        meta = {
            "season": int(season),
            "round": int(round_no),
            "session_name": str(session_name),
            "event_name": str(getattr(event, "EventName", "") or getattr(event, "OfficialEventName", "") or ""),
            "country": str(getattr(event, "Country", "") or ""),
        }

        telemetry_charts = self._build_telemetry_charts(ses)
        drivers = self._build_drivers(ses)
        overview = self._build_overview(ses)
        lap_charts = self._build_lap_charts(ses)
        tyre_strategy = self._build_tyre_strategy(ses)
        replay = self._build_replay(ses)

        raw = {"event": self._safe_jsonable(self._event_to_dict(event))}

        return {
            "meta": meta,
            "drivers": drivers,
            "overview": overview,
            "lap_charts": lap_charts,
            "telemetry_charts": telemetry_charts,
            "tyre_strategy": tyre_strategy,
            "replay": replay,
            "raw": raw,
        }

    # -----------------------------
    # Drivers (for colors in UI)
    # -----------------------------
    def _build_drivers(self, ses) -> List[Dict[str, Any]]:
        out: List[Dict[str, Any]] = []
        try:
            res = getattr(ses, "results", None)
            if res is not None and len(res) > 0:
                for _, r in res.iterrows():
                    code = str(r.get("Abbreviation") or r.get("Driver") or "").strip()
                    team_color = r.get("TeamColor")
                    color = "#90A4AE"
                    if isinstance(team_color, str) and team_color.strip():
                        c = team_color.strip()
                        if not c.startswith("#"):
                            c = "#" + c
                        if len(c) >= 7:
                            color = c[:7]
                    out.append({"code": code, "color": color})
        except Exception:
            pass

        if not out:
            laps = getattr(ses, "laps", None)
            if laps is not None and len(laps) > 0 and "Driver" in laps.columns:
                codes = sorted({str(x) for x in laps["Driver"].dropna().unique()})
                out = [{"code": c, "color": "#90A4AE"} for c in codes]

        return self._safe_jsonable(out)

    # -----------------------------
    # Overview
    # -----------------------------
    # -----------------------------
# Overview
# -----------------------------
    def _build_overview(self, ses) -> Dict[str, Any]:
        """
        Builds:
        - leaderboard: position, driver_code, status, gap_s (seconds from winner; winner = 0.0),
                        team_name, team_key, team_color
        - podium: top 3 from leaderboard
        - fastest_lap: unchanged (as before)

        NOTE:
        FastF1 ses.results 'Time' is commonly the total race time for each classified driver.
        We compute winner gap as (driver_time - winner_time) in seconds.
        """
        leaderboard: List[Dict[str, Any]] = []
        podium: List[Dict[str, Any]] = []

        def team_key(team_name) -> Optional[str]:
            if team_name is None:
                return None
            s = str(team_name).strip().lower()
            if not s:
                return None

            if "red bull" in s:
                return "redbull"
            if "mclaren" in s:
                return "mclaren"
            if "ferrari" in s:
                return "ferrari"
            if "mercedes" in s:
                return "mercedes"
            if "aston" in s:
                return "astonmartin"
            if "alpine" in s:
                return "alpine"
            if "williams" in s:
                return "williams"
            if "haas" in s:
                return "haas"
            if "sauber" in s or "stake" in s or "kick" in s:
                return "stake"
            if s == "rb" or "visa" in s or "vcarb" in s or "alphatauri" in s:
                return "rb"

            return (
                s.replace("&", "and")
                .replace("-", " ")
                .replace("_", " ")
                .replace(".", "")
                .strip()
                .replace(" ", "")
            )

        def to_seconds(x) -> Optional[float]:
            """
            Convert FastF1/pandas timedelta-like or string duration to seconds.
            """
            try:
                if x is None or pd.isna(x):
                    return None
            except Exception:
                if x is None:
                    return None

            # pandas Timedelta
            if isinstance(x, pd.Timedelta):
                return float(x.total_seconds())

            # already numeric
            if isinstance(x, (int, float)):
                return float(x)

            # try parse string like "0 days 01:26:07.469000"
            s = str(x).strip()
            if not s:
                return None

            # pd.to_timedelta handles many formats
            try:
                td = pd.to_timedelta(s)
                return float(td.total_seconds())
            except Exception:
                return None

        # ---- Build leaderboard with gaps in seconds ----
        try:
            res = getattr(ses, "results", None)
            if res is not None and len(res) > 0:
                # Keep only classified positions; sort by Position if present
                df = res.copy()
                if "Position" in df.columns:
                    df["Position"] = pd.to_numeric(df["Position"], errors="coerce")
                    df = df.dropna(subset=["Position"]).sort_values("Position")

                # Winner time in seconds (Position == 1)
                winner_time_s: Optional[float] = None
                if "Time" in df.columns and len(df) > 0:
                    first_row = df.iloc[0]
                    winner_time_s = to_seconds(first_row.get("Time"))

                for _, r in df.iterrows():
                    pos = int(r.get("Position")) if pd.notna(r.get("Position")) else None
                    code = str(r.get("Abbreviation") or r.get("Driver") or "").strip()
                    status = str(r.get("Status") or "").strip()

                    # team info
                    tname = str(r.get("TeamName") or r.get("Team") or "").strip() or None
                    tkey = team_key(tname)
                    tcol = r.get("TeamColor")
                    team_color = None
                    if isinstance(tcol, str) and tcol.strip():
                        c = tcol.strip()
                        if not c.startswith("#"):
                            c = "#" + c
                        if len(c) >= 7:
                            team_color = c[:7]

                    # gap in seconds from winner (winner=0.0)
                    time_s = to_seconds(r.get("Time"))
                    gap_s: Optional[float] = None
                    if time_s is not None and winner_time_s is not None:
                        gap_s = max(0.0, float(time_s - winner_time_s))

                    leaderboard.append(
                        {
                            "position": pos,
                            "driver_code": code,
                            "status": status,
                            # ✅ gap in seconds (float). Winner is 0.0.
                            "gap_s": gap_s,
                            # (optional) keep original time string if you want
                            "time": self._safe_jsonable(r.get("Time")),
                            # ✅ team fields for frontend assets/themes
                            "team_name": tname,
                            "team_key": tkey,
                            "team_color": team_color,
                        }
                    )

                podium = leaderboard[:3]
        except Exception:
            pass

        # ---- Fastest lap (unchanged except key name consistency) ----
        fastest_lap = None
        try:
            laps = getattr(ses, "laps", None)
            if laps is not None and len(laps) > 0 and "LapTime" in laps.columns and "Driver" in laps.columns:
                fl = laps.pick_fastest()
                if fl is not None and len(fl) > 0:
                    drv = str(fl["Driver"].iloc[0])
                    lt = fl["LapTime"].iloc[0]
                    lapnum = fl["LapNumber"].iloc[0] if "LapNumber" in fl.columns else None
                    compound = fl["Compound"].iloc[0] if "Compound" in fl.columns else None
                    tyre_age = fl["TyreLife"].iloc[0] if "TyreLife" in fl.columns else None

                    # Lap time seconds too (nice for UI)
                    lt_s = None
                    try:
                        if isinstance(lt, pd.Timedelta):
                            lt_s = float(lt.total_seconds())
                        else:
                            lt_s = to_seconds(lt)
                    except Exception:
                        lt_s = None

                    fastest_lap = {
                        "driver_code": drv,
                        "time": str(lt) if lt is not None else None,
                        "time_s": lt_s,
                        "lap": int(lapnum) if pd.notna(lapnum) else None,
                        "compound": str(compound) if compound is not None else None,
                        "tyre_age": int(tyre_age) if pd.notna(tyre_age) else None,
                    }
        except Exception:
            pass

        return {
            "leaderboard": self._safe_jsonable(leaderboard),
            "podium": self._safe_jsonable(podium),
            "fastest_lap": self._safe_jsonable(fastest_lap),
        }

    # -----------------------------
    # Lap Charts
    # -----------------------------
    def _build_lap_charts(self, ses) -> Dict[str, Any]:
        laps_df = getattr(ses, "laps", None)
        if laps_df is None or len(laps_df) == 0:
            return {"laps": [], "series": {}, "laps_count": 0}

        if "LapNumber" not in laps_df.columns:
            return {"laps": [], "series": {}, "laps_count": 0}

        max_lap = int(pd.to_numeric(laps_df["LapNumber"], errors="coerce").max() or 0)
        if max_lap <= 0:
            return {"laps": [], "series": {}, "laps_count": 0}

        laps_list = list(range(1, max_lap + 1))

        if "LapTime" not in laps_df.columns or "Driver" not in laps_df.columns:
            return {"laps": laps_list, "series": {}, "laps_count": max_lap}

        df = laps_df[["Driver", "LapNumber", "LapTime"]].copy()
        df["LapNumber"] = pd.to_numeric(df["LapNumber"], errors="coerce")
        df = df.dropna(subset=["Driver", "LapNumber"])

        def to_seconds(x):
            try:
                if isinstance(x, pd.Timedelta):
                    return float(x.total_seconds())
                if isinstance(x, (int, float)):
                    return float(x)
            except Exception:
                pass
            return None

        df["lap_s"] = df["LapTime"].apply(to_seconds)

        series: Dict[str, Dict[str, Any]] = {}

        for code, g in df.groupby("Driver"):
            arr: List[Any] = [None] * max_lap
            for _, row in g.iterrows():
                ln = row["LapNumber"]
                s = row["lap_s"]
                if pd.isna(ln) or s is None:
                    continue
                li = int(ln) - 1
                if 0 <= li < max_lap:
                    arr[li] = float(s)

            series[str(code)] = {
                "visible_default": True,
                "lap_times_s": arr,
            }

        return self._safe_jsonable(
            {
                "laps": laps_list,
                "series": series,
                "laps_count": max_lap,
            }
        )

    # -----------------------------
    # Tyre Strategy
    # -----------------------------
    def _build_tyre_strategy(self, ses) -> Dict[str, Any]:
        laps = getattr(ses, "laps", None)
        if laps is None or len(laps) == 0:
            return {"drivers": []}

        needed = {"Stint", "Compound", "LapNumber"}
        if not needed.issubset(set(laps.columns)):
            return {"drivers": []}

        df = laps.copy()

        driver_col = "Driver" if "Driver" in df.columns else None
        if driver_col is None:
            return {"drivers": []}

        df["LapNumber"] = pd.to_numeric(df["LapNumber"], errors="coerce")
        df["Stint"] = pd.to_numeric(df["Stint"], errors="coerce")
        df["Compound"] = df["Compound"].astype(str)

        df = df.dropna(subset=["LapNumber", "Stint"])
        if len(df) == 0:
            return {"drivers": []}

        df["_driver"] = df[driver_col].astype(str)

        by_driver: Dict[str, List[Dict[str, Any]]] = {}
        grouped = df.groupby(["_driver", "Stint"], dropna=True)

        for (drv, _stint), g in grouped:
            if g is None or len(g) == 0:
                continue

            lap_start = int(g["LapNumber"].min())
            lap_end = int(g["LapNumber"].max())

            comp = g["Compound"].mode()
            compound = str(comp.iloc[0]) if len(comp) else str(g["Compound"].iloc[0])

            by_driver.setdefault(drv, []).append(
                {"compound": compound, "lap_start": lap_start, "lap_end": lap_end}
            )

        drivers_out: List[Dict[str, Any]] = []
        for drv, stints in by_driver.items():
            drivers_out.append(
                {"driver_code": drv, "stints": sorted(stints, key=lambda x: x["lap_start"])}
            )

        drivers_out.sort(key=lambda x: x["driver_code"])
        return {"drivers": self._safe_jsonable(drivers_out)}

    # -----------------------------
    # ✅ Replay (track polyline + frames + weather)
    # -----------------------------
    def _build_replay(self, ses) -> dict:
        """
        Per-driver replay builder (NOT per-frame).

        Returns JSON:
        {
        "meta": {...},
        "track": {"polyline": [[x,y], ...]},
        "drivers": {
            "VER": {"t":[...], "x":[...], "y":[...], "speed":[...], "gear":[...], "drs":[...]},
            ...
        },
        "duration_s": 1234.5,
        "weather": {...}
        }

        Notes:
        - speed is km/h (FastF1 telemetry Speed)
        - gear is int (nGear)
        - drs is int (DRS; often 0/1 but can be other encodings depending on source)
        - time is normalized so first sample across all drivers starts at t=0
        """
        import math
        import numpy as np
        import pandas as pd

        # ---------------- helpers ----------------
        def _finite_float(v):
            try:
                f = float(v)
                return f if math.isfinite(f) else None
            except Exception:
                return None

        def _clean(obj):
            """Recursively remove NaN/inf and keep JSON-safe primitives."""
            if obj is None:
                return None
            if isinstance(obj, float):
                return obj if math.isfinite(obj) else None
            if isinstance(obj, (int, str, bool)):
                return obj
            if isinstance(obj, dict):
                return {str(k): _clean(v) for k, v in obj.items()}
            if isinstance(obj, list):
                return [_clean(v) for v in obj]
            return obj

        def _downsample_by_count(arrs, max_n: int):
            """
            Downsample multiple aligned numpy arrays to <= max_n points by stride.
            """
            n = len(arrs[0])
            if n <= max_n:
                return arrs
            step = max(1, n // max_n)
            idx = np.arange(0, n, step)
            return [a[idx] for a in arrs]

        def _pick_fast_lap_for_polyline(driver_laps):
            """Pick a best lap for polyline; fall back to first lap."""
            try:
                lap0 = driver_laps.pick_fastest()
                if lap0 is not None:
                    return lap0
            except Exception:
                pass
            try:
                return driver_laps.iloc[0] if len(driver_laps) else None
            except Exception:
                return None

        # ---------------- meta ----------------
        try:
            meta = {
                "session_name": str(getattr(ses, "name", "") or getattr(ses, "session", "") or ""),
                "source": "per_driver_telemetry",
            }
            ev = getattr(ses, "event", None)
            try:
                meta["season"] = int(getattr(ev, "EventDate", pd.Timestamp.now()).year)
            except Exception:
                meta["season"] = None
            try:
                meta["round"] = int(getattr(ev, "RoundNumber", 0) or 0)
            except Exception:
                meta["round"] = 0
            try:
                meta["event_name"] = str(getattr(ev, "EventName", "") or getattr(ev, "OfficialEventName", "") or "")
            except Exception:
                meta["event_name"] = ""
            try:
                meta["country"] = str(getattr(ev, "Country", "") or "")
            except Exception:
                meta["country"] = ""
        except Exception:
            meta = {"source": "per_driver_telemetry"}

        out = {
            "meta": meta,
            "track": {"polyline": []},
            "drivers": {},
            "duration_s": None,
            "weather": {},
        }

        laps = getattr(ses, "laps", None)
        if laps is None or len(laps) == 0 or "Driver" not in getattr(laps, "columns", []):
            return self._safe_jsonable(_clean(out))

        drivers = list(laps["Driver"].dropna().unique())
        if not drivers:
            return self._safe_jsonable(_clean(out))

        # ---------------- track polyline (first usable driver's lap X/Y) ----------------
        try:
            for drv in drivers:
                try:
                    dlaps = laps.pick_drivers(str(drv))
                    if dlaps is None or len(dlaps) == 0:
                        continue

                    lap0 = _pick_fast_lap_for_polyline(dlaps)
                    if lap0 is None:
                        continue

                    tel = lap0.get_telemetry()
                    if tel is None or len(tel) == 0 or not {"X", "Y"}.issubset(tel.columns):
                        continue

                    xy = tel[["X", "Y"]].copy()
                    xy["X"] = pd.to_numeric(xy["X"], errors="coerce")
                    xy["Y"] = pd.to_numeric(xy["Y"], errors="coerce")
                    xy = xy.dropna()
                    if len(xy) < 10:
                        continue

                    pts = xy.to_numpy(dtype=float)

                    # cap polyline points (keeps UI fast)
                    MAX_POLYLINE = 1400
                    if len(pts) > MAX_POLYLINE:
                        step = max(1, len(pts) // MAX_POLYLINE)
                        pts = pts[::step]

                    out["track"]["polyline"] = [[float(x), float(y)] for x, y in pts]
                    break
                except Exception:
                    continue
        except Exception:
            pass

        # ---------------- per-driver trajectory ----------------
        global_t_min = None
        global_t_max = None

        # payload size knobs
        MAX_POINTS_PER_DRIVER = 1500
        MIN_POINTS_PER_DRIVER = 30

        for drv in drivers:
            code = str(drv)
            try:
                dlaps = laps.pick_drivers(code)
                if dlaps is None or len(dlaps) == 0:
                    continue

                t_all = []
                x_all = []
                y_all = []
                speed_all = []
                gear_all = []
                drs_all = []

                # iterate laps
                for _, lap in dlaps.iterlaps():
                    try:
                        tel = lap.get_telemetry()
                        if tel is None or len(tel) == 0:
                            continue

                        if not {"SessionTime", "X", "Y"}.issubset(tel.columns):
                            continue

                        t = tel["SessionTime"].dt.total_seconds().to_numpy()
                        x = pd.to_numeric(tel["X"], errors="coerce").to_numpy()
                        y = pd.to_numeric(tel["Y"], errors="coerce").to_numpy()

                        speed = pd.to_numeric(tel["Speed"], errors="coerce").to_numpy() if "Speed" in tel.columns else None
                        gear = pd.to_numeric(tel["nGear"], errors="coerce").to_numpy() if "nGear" in tel.columns else None
                        drs = pd.to_numeric(tel["DRS"], errors="coerce").to_numpy() if "DRS" in tel.columns else None

                        m = np.isfinite(t) & np.isfinite(x) & np.isfinite(y)
                        if speed is not None:
                            m = m & np.isfinite(speed)
                        if gear is not None:
                            m = m & np.isfinite(gear)
                        if drs is not None:
                            m = m & np.isfinite(drs)

                        if int(m.sum()) < 5:
                            continue

                        t_all.append(t[m])
                        x_all.append(x[m])
                        y_all.append(y[m])
                        if speed is not None:
                            speed_all.append(speed[m])
                        if gear is not None:
                            gear_all.append(gear[m])
                        if drs is not None:
                            drs_all.append(drs[m])

                    except Exception:
                        continue

                if not t_all:
                    continue

                # concat
                t = np.concatenate(t_all)
                x = np.concatenate(x_all)
                y = np.concatenate(y_all)
                speed = np.concatenate(speed_all) if speed_all else None
                gear = np.concatenate(gear_all) if gear_all else None
                drs = np.concatenate(drs_all) if drs_all else None

                # sort by time
                order = np.argsort(t)
                t = t[order]
                x = x[order]
                y = y[order]
                if speed is not None:
                    speed = speed[order]
                if gear is not None:
                    gear = gear[order]
                if drs is not None:
                    drs = drs[order]

                # de-dup times (critical for interpolation)
                t_u, idx = np.unique(t, return_index=True)
                x_u = x[idx]
                y_u = y[idx]
                speed_u = speed[idx] if speed is not None else None
                gear_u = gear[idx] if gear is not None else None
                drs_u = drs[idx] if drs is not None else None

                if len(t_u) < MIN_POINTS_PER_DRIVER:
                    continue

                # downsample while keeping alignment
                arrs = [t_u, x_u, y_u]
                has_speed = speed_u is not None and len(speed_u) == len(t_u)
                has_gear = gear_u is not None and len(gear_u) == len(t_u)
                has_drs = drs_u is not None and len(drs_u) == len(t_u)

                if has_speed:
                    arrs.append(speed_u)
                if has_gear:
                    arrs.append(gear_u)
                if has_drs:
                    arrs.append(drs_u)

                arrs = _downsample_by_count(arrs, MAX_POINTS_PER_DRIVER)

                # unpack
                t_u = arrs[0]
                x_u = arrs[1]
                y_u = arrs[2]
                k = 3
                if has_speed:
                    speed_u = arrs[k]; k += 1
                else:
                    speed_u = None
                if has_gear:
                    gear_u = arrs[k]; k += 1
                else:
                    gear_u = None
                if has_drs:
                    drs_u = arrs[k]; k += 1
                else:
                    drs_u = None

                # global min/max
                tmin = float(t_u[0])
                tmax = float(t_u[-1])
                global_t_min = tmin if global_t_min is None else min(global_t_min, tmin)
                global_t_max = tmax if global_t_max is None else max(global_t_max, tmax)

                obj = {
                    "t": [float(v) for v in t_u.tolist()],
                    "x": [float(v) for v in x_u.tolist()],
                    "y": [float(v) for v in y_u.tolist()],
                }
                if speed_u is not None:
                    obj["speed"] = [float(v) for v in speed_u.tolist()]
                if gear_u is not None:
                    obj["gear"] = [int(v) for v in gear_u.tolist()]
                if drs_u is not None:
                    obj["drs"] = [int(v) for v in drs_u.tolist()]

                out["drivers"][code] = obj

            except Exception:
                continue

        if global_t_min is None or global_t_max is None or not out["drivers"]:
            return self._safe_jsonable(_clean(out))

        # normalize time so frontend can start at 0
        t0 = float(global_t_min)
        out["duration_s"] = float(global_t_max - global_t_min)

        for code, d in out["drivers"].items():
            try:
                d["t"] = [float(v - t0) for v in d["t"]]
            except Exception:
                pass

        # ---------------- weather aggregates ----------------
        try:
            w = getattr(ses, "weather_data", None)
            if w is not None and len(w) > 0:
                def safe_mean(col):
                    try:
                        s = pd.to_numeric(w.get(col), errors="coerce")
                        return _finite_float(s.mean())
                    except Exception:
                        return None

                out["weather"] = {
                    "air_temp_c_avg": safe_mean("AirTemp"),
                    "track_temp_c_avg": safe_mean("TrackTemp"),
                    "humidity_avg": safe_mean("Humidity"),
                }
        except Exception:
            pass

        return self._safe_jsonable(_clean(out))

    def _driver_number_to_code(self, ses) -> Dict[str, str]:
        """
        Map driver number string -> abbreviation code (e.g. "1" -> "VER")
        """
        out: Dict[str, str] = {}
        try:
            res = getattr(ses, "results", None)
            if res is not None and len(res) > 0:
                for _, r in res.iterrows():
                    num = r.get("DriverNumber")
                    code = r.get("Abbreviation")
                    if pd.notna(num) and pd.notna(code):
                        out[str(int(num))] = str(code)
        except Exception:
            pass
        return out

    def _downsample_xy(self, xy: pd.DataFrame, target: int = 600) -> List[Dict[str, float]]:
        """
        Downsample DataFrame with X/Y columns to ~target points.
        """
        if xy is None or len(xy) == 0:
            return []
        n = len(xy)
        if n <= target:
            return [{"x": float(r["X"]), "y": float(r["Y"])} for _, r in xy.iterrows()]

        step = max(1, n // target)
        sampled = xy.iloc[::step]
        return [{"x": float(r["X"]), "y": float(r["Y"])} for _, r in sampled.iterrows()]

    def _downsample_list(self, xs: List[Any], target: int = 400) -> List[Any]:
        if not xs:
            return []
        n = len(xs)
        if n <= target:
            return xs
        step = max(1, n // target)
        return xs[::step]

    def _safe_float(self, v: Any) -> Optional[float]:
        """
        Convert to JSON-safe float (no NaN/inf).
        """
        try:
            if v is None or pd.isna(v):
                return None
            fv = float(v)
            if math.isfinite(fv):
                return fv
            return None
        except Exception:
            return None

    # -----------------------------
    # Helpers
    # -----------------------------
    def _event_to_dict(self, event) -> Dict[str, Any]:
        try:
            return dict(event)
        except Exception:
            return {}

    def _safe_jsonable(self, obj: Any) -> Any:
        """
        Convert pandas/numpy types to JSON-safe Python types.
        Also removes NaN/inf which crash json.dumps when allow_nan=False (Starlette does this).
        """
        if obj is None:
            return None

        # pandas Timestamp / Timedelta
        if isinstance(obj, (pd.Timestamp, pd.Timedelta)):
            return str(obj)

        # float: clean NaN/inf
        if isinstance(obj, float):
            if not math.isfinite(obj):
                return None
            return obj

        # int/bool/str
        if isinstance(obj, (str, int, bool)):
            return obj

        # dict
        if isinstance(obj, dict):
            return {str(k): self._safe_jsonable(v) for k, v in obj.items()}

        # list/tuple
        if isinstance(obj, (list, tuple)):
            return [self._safe_jsonable(v) for v in obj]

        # pandas Series
        if isinstance(obj, pd.Series):
            return self._safe_jsonable(obj.to_dict())

        # pandas DataFrame
        if isinstance(obj, pd.DataFrame):
            return self._safe_jsonable(obj.to_dict(orient="records"))

        # fallback: try numeric then stringify
        try:
            if isinstance(obj, (int,)):
                return int(obj)
            if isinstance(obj, (float,)):
                return self._safe_jsonable(float(obj))
        except Exception:
            pass

        return str(obj)

    def _build_telemetry_charts(self, ses) -> Dict[str, Any]:
        import pandas as pd

        out = {
            "x_type": "distance_m",
            "x": [],
            "series": {},
        }

        laps = getattr(ses, "laps", None)
        if laps is None or len(laps) == 0:
            return out

        if "Driver" not in laps.columns:
            return out

        drivers = list(laps["Driver"].dropna().unique())
        if not drivers:
            return out

        ref_x = None

        for drv in drivers:
            try:
                dlaps = laps.pick_drivers(str(drv))
                if dlaps is None or len(dlaps) == 0:
                    continue

                fastest = dlaps.pick_fastest()
                if fastest is None:
                    continue

                tel = fastest.get_telemetry()
                if tel is None or len(tel) == 0:
                    continue

                if "Distance" not in tel.columns:
                    continue

                tel = tel.copy()
                tel["Distance"] = pd.to_numeric(tel["Distance"], errors="coerce")
                tel = tel.dropna(subset=["Distance"]).sort_values("Distance").reset_index(drop=True)

                # Downsample to keep payload small
                if len(tel) > 600:
                    step = max(1, len(tel) // 600)
                    tel = tel.iloc[::step].reset_index(drop=True)

                if ref_x is None:
                    ref_x = tel["Distance"].astype(float).tolist()
                    out["x"] = ref_x

                series_obj = {"visible_default": True}

                channel_map = {
                    "Speed": "speed",
                    "Throttle": "throttle",
                    "Brake": "brake",
                    "RPM": "engine_rpm",
                    "DRS": "drs",
                    "nGear": "gear",
                }

                for col, key in channel_map.items():
                    if col not in tel.columns:
                        continue

                    y = pd.to_numeric(tel[col], errors="coerce")
                    if y.isna().all():
                        continue

                    # align to ref_x
                    yy = pd.Series(y.values, index=tel["Distance"].values)
                    yy = yy.reindex(ref_x, method="nearest")

                    series_obj[key] = [
                        None if pd.isna(v) else float(v)
                        for v in yy.values
                    ]

                if len(series_obj.keys()) > 1:
                    out["series"][str(drv)] = series_obj

            except Exception:
                continue

        return self._safe_jsonable(out)