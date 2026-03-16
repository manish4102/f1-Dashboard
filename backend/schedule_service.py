# backend/schedule_service.py
import pandas as pd
from typing import Any, Dict, List, Optional

# small mapping from country full name to ISO2 code (extend as needed)
_COUNTRY_TO_ISO2 = {
    "Bahrain": "BH",
    "Australia": "AU",
    "China": "CN",
    "Japan": "JP",
    "Saudi Arabia": "SA",
    "United States": "US",
    "Italy": "IT",
    "Monaco": "MC",
    "Spain": "ES",
    "Canada": "CA",
    "Austria": "AT",
    "United Kingdom": "GB",
    "Belgium": "BE",
    "Hungary": "HU",
    "Netherlands": "NL",
    "Azerbaijan": "AZ",
    "Singapore": "SG",
    "Mexico": "MX",
    "Brazil": "BR",
    "Qatar": "QA",
    "United Arab Emirates": "AE",
    # add more as needed
}

def _pick_col(df: pd.DataFrame, candidates: List[str]) -> Optional[str]:
    for c in candidates:
        if c in df.columns:
            return c
    return None

def _safe_to_str(v: Any) -> str:
    try:
        if v is None:
            return ""
        if isinstance(v, float) and pd.isna(v):
            return ""
        return str(v).strip()
    except Exception:
        return ""

class ScheduleService:
    # assume this is part of your service/class where self._safe_jsonable exists;
    # if _safe_jsonable is not available put `import json` and use json-serializable friendly types.
    def __init__(self):
        pass

    def _safe_jsonable(self, v):
        # minimal passthrough; adapt to your project's safe-serialization if needed
        return v

    def get_event_schedule(self, season: int) -> Dict[str, Any]:
        # get raw schedule from fastf1
        import fastf1  # local import so file is safe if fastf1 isn't installed elsewhere
        df = fastf1.get_event_schedule(season)

        # coerce to DataFrame if needed
        if not isinstance(df, pd.DataFrame):
            try:
                df = pd.DataFrame(df)
            except Exception:
                df = pd.DataFrame()

        if df is None or len(df) == 0:
            return {"season": int(season), "events": []}

        # normalize column names (expand candidate lists)
        col_round = _pick_col(df, ["RoundNumber", "Round", "round", "Round No", "Round_No"])
        col_country = _pick_col(df, ["Country", "CountryName", "Country_Code", "CountryCode"])
        col_location = _pick_col(df, ["Location", "Track", "Circuit", "Venue"])
        col_event_name = _pick_col(df, ["EventName", "Name", "Event", "Event_Name"])
        col_official = _pick_col(df, ["OfficialEventName", "Official Name", "Official_Name"])
        col_event_date = _pick_col(df, ["EventDate", "EventDateUtc", "Date", "DateUtc"])
        col_format = _pick_col(df, ["EventFormat", "Format"])
        col_api_support = _pick_col(df, ["F1ApiSupport", "F1_Api_Support"])

        # session columns detection (Session1..5)
        session_name_cols = []
        session_date_cols = []
        for i in range(1, 6):
            sn = f"Session{i}"
            sd = f"Session{i}DateUtc"
            if sn in df.columns:
                session_name_cols.append(sn)
            if sd in df.columns:
                session_date_cols.append(sd)

        # order rows by round when possible
        df2 = df.copy()
        if col_round and col_round in df2.columns:
            df2[col_round] = pd.to_numeric(df2[col_round], errors="coerce")
            df2 = df2.dropna(subset=[col_round]).sort_values(col_round)

        events: List[Dict[str, Any]] = []
        for _, r in df2.iterrows():
            # round
            round_no = None
            if col_round:
                try:
                    rv = r.get(col_round)
                    if pd.notna(rv):
                        round_no = int(rv)
                except Exception:
                    round_no = None

            # sessions
            sessions: List[Dict[str, Any]] = []
            for i in range(1, 6):
                sn = f"Session{i}"
                sd = f"Session{i}DateUtc"
                if sn in df2.columns:
                    sname = r.get(sn)
                    if sname is None or (isinstance(sname, float) and pd.isna(sname)):
                        continue
                    obj = {"name": _safe_to_str(sname)}
                    if sd in df2.columns:
                        obj["date_utc"] = self._safe_jsonable(r.get(sd))
                    sessions.append(obj)

            # extract event name fields robustly
            raw_event_name = _safe_to_str(r.get(col_event_name)) if col_event_name else ""
            raw_official_name = _safe_to_str(r.get(col_official)) if col_official else ""

            event_name = raw_event_name
            official_name = raw_official_name

            # prefer short non-sponsored name
            display_name = event_name or official_name

            # try location/country fallback if both empty
            if not display_name:
                loc = _safe_to_str(r.get(col_location)) if col_location else ""
                country_raw = _safe_to_str(r.get(col_country)) if col_country else ""
                display_name = f"Round {round_no or '?'} — {loc or country_raw or 'Unnamed Event'}"

            # country string (primary human readable)
            country_str = _safe_to_str(r.get(col_country)) if col_country else ""

            # attempt to produce an ISO2 country code (countryCode)
            country_code = ""
            # if there's already a two-letter code in some column, prefer it
            if col_country:
                maybe = _safe_to_str(r.get(col_country))
                if len(maybe) == 2:
                    country_code = maybe.upper()
            # map from full country name using our small lookup
            if not country_code and country_str in _COUNTRY_TO_ISO2:
                country_code = _COUNTRY_TO_ISO2[country_str]
            # final fallback: empty string (frontend will handle)
            country_code = country_code or ""

            ev = {
                "round": round_no,
                "name": display_name,
                "event_name": event_name,
                "official_event_name": official_name,
                "country": country_str,
                "countryCode": country_code,
                "location": _safe_to_str(r.get(col_location)) if col_location else "",
                "event_format": _safe_to_str(r.get(col_format)) if col_format else "",
                "event_date_utc": self._safe_jsonable(r.get(col_event_date)) if col_event_date else None,
                "f1_api_support": bool(r.get(col_api_support)) if col_api_support else None,
                "sessions": sessions,
            }

            events.append(self._safe_jsonable(ev))

        return self._safe_jsonable({"season": int(season), "events": events})