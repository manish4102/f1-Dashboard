// lib/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Lightweight session model used by the client
class GpSessionLite {
  final String name;
  final String? dateUtc;

  GpSessionLite({required this.name, this.dateUtc});

  factory GpSessionLite.fromJson(Map<String, dynamic> json) {
    return GpSessionLite(
      name: (json['name'] ?? '').toString(),
      dateUtc: json['date_utc']?.toString(),
    );
  }

  @override
  String toString() => 'GpSessionLite(name:$name, dateUtc:$dateUtc)';
}

/// Simple lightweight event model used by the client
class GpEventLite {
  final int round;
  final String name;
  final String countryCode; // ISO2, may be empty if unknown
  final List<GpSessionLite> sessions;

  GpEventLite({
    required this.round,
    required this.name,
    required this.countryCode,
    required this.sessions,
  });

  @override
  String toString() =>
      'GpEventLite(round:$round, name:$name, countryCode:$countryCode, sessions:${sessions.length})';
}

class ApiClient {
  final String baseUrl;
  final http.Client client = http.Client();

  ApiClient({this.baseUrl = "http://localhost:8001"});

  // -----------------------------
  // AUTH (keep your existing implementations)
  // -----------------------------
  Future<dynamic> devLogin() async {
    final res = await http.post(Uri.parse("$baseUrl/auth/dev-login"));
    if (res.statusCode >= 400) {
      throw Exception("Dev login failed: ${res.body}");
    }
    final normalized = _deepConvert(jsonDecode(res.body));
    return normalized;
  }

  Future<dynamic> signup(String email, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (res.statusCode >= 400) {
      throw Exception("Signup failed: ${res.body}");
    }

    final normalized = _deepConvert(jsonDecode(res.body));
    return normalized;
  }

  Future<dynamic> login(String email, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (res.statusCode >= 400) {
      throw Exception("Login failed: ${res.body}");
    }

    final normalized = _deepConvert(jsonDecode(res.body));
    return normalized;
  }

  // -----------------------------
  // LOAD SESSION
  // -----------------------------
  Future<dynamic> loadSession({
    required int season,
    required int round,
    required String sessionName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/load-session'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'season': season,
        'round': round,
        'session_name': sessionName,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final normalized = _deepConvert(jsonDecode(response.body));
    return normalized;
  }

  // -----------------------------
  // GET FULL SESSION
  // -----------------------------
  Future<dynamic> getFull({required String cacheId}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/session/$cacheId/full'),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final normalized = _deepConvert(jsonDecode(response.body));
    return normalized;
  }

  // -----------------------------
  // REPLAY FRAMES
  // -----------------------------
  Future<Map<String, dynamic>> getReplayFrames({
    required String token,
    required String cacheId,
  }) async {
    final res = await http.get(
      Uri.parse("$baseUrl/session/$cacheId/replay/frames"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode >= 400) {
      throw Exception("Fetch replay failed: ${res.body}");
    }

    final normalized = _deepConvert(jsonDecode(res.body));
    return (normalized['replay'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  // -----------------------------
  // GET SCHEDULE (updated: includes sessions)
  // -----------------------------
  Future<List<GpEventLite>> getSchedule({required int season}) async {
    final uri = Uri.parse('$baseUrl/schedule?season=$season');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception(
        'Failed to fetch schedule (${res.statusCode}): ${res.body}',
      );
    }

    final normalized = _deepConvert(jsonDecode(res.body));
    final events = (normalized['events'] as List<dynamic>?) ?? [];

    // mapping of common full country names to ISO2 codes
    const countryMap = {
      'Bahrain': 'BH',
      'Australia': 'AU',
      'China': 'CN',
      'Japan': 'JP',
      'Saudi Arabia': 'SA',
      'United States': 'US',
      'Italy': 'IT',
      'Monaco': 'MC',
      'Spain': 'ES',
      'Canada': 'CA',
      'Austria': 'AT',
      'United Kingdom': 'GB',
      'Belgium': 'BE',
      'Hungary': 'HU',
      'Netherlands': 'NL',
      'Azerbaijan': 'AZ',
      'Singapore': 'SG',
      'Mexico': 'MX',
      'Brazil': 'BR',
      'Qatar': 'QA',
      'United Arab Emirates': 'AE',
    };

    List<GpEventLite> out = [];

    for (final e in events) {
      try {
        final round = (e['round'] is int)
            ? e['round'] as int
            : int.tryParse('${e['round']}') ?? 0;

        // Your backend uses event_name / official_event_name
        final name =
            (e['event_name'] ?? e['official_event_name'] ?? e['name'] ?? '')
                .toString();

        final countryRaw = (e['country'] ?? '').toString();

        String countryCode = '';

        // prefer backend-provided countryCode
        if (e is Map &&
            e.containsKey('countryCode') &&
            e['countryCode'] != null) {
          final cc = e['countryCode']?.toString() ?? '';
          if (cc.length == 2) countryCode = cc.toUpperCase();
        }

        // fallback: map from full country name
        if (countryCode.isEmpty && countryMap.containsKey(countryRaw)) {
          countryCode = countryMap[countryRaw]!;
        }

        // fallback: if backend returned two-letter country in 'country'
        if (countryCode.isEmpty && countryRaw.length == 2) {
          countryCode = countryRaw.toUpperCase();
        }

        // sessions
        final sessionsRaw = (e['sessions'] as List<dynamic>?) ?? const [];
        final sessions = sessionsRaw
            .whereType<Map>()
            .map((s) => GpSessionLite.fromJson(s.cast<String, dynamic>()))
            .toList();

        out.add(
          GpEventLite(
            round: round,
            name: name,
            countryCode: countryCode,
            sessions: sessions,
          ),
        );
      } catch (_) {
        // continue on parse errors
      }
    }

    return out;
  }

  // -----------------------------
  // Convenience helper (optional): load -> full in one go
  // -----------------------------
  Future<Map<String, dynamic>> loadAndGetFull({
    required int season,
    required int round,
    required String sessionName,
  }) async {
    final load = await loadSession(
      season: season,
      round: round,
      sessionName: sessionName,
    );
    final cacheId = (load['cache_id'] ?? '').toString();
    if (cacheId.isEmpty) {
      throw Exception("load-session did not return cache_id");
    }
    return await getFull(cacheId: cacheId);
  }

  // -----------------------------
  // DEEP MAP NORMALIZER
  // -----------------------------
  dynamic _deepConvert(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), _deepConvert(val)),
      );
    } else if (value is List) {
      return value.map(_deepConvert).toList();
    } else {
      return value;
    }
  }

  // -----------------------------
  // CHAT
  // -----------------------------
  Future<String> chat(String message) async {
    final res = await http.post(
      Uri.parse("$baseUrl/chat"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"message": message}),
    );

    if (res.statusCode >= 400) {
      throw Exception("Chat failed: ${res.body}");
    }

    final normalized = _deepConvert(jsonDecode(res.body));
    return (normalized['response'] ?? '').toString();
  }
}
