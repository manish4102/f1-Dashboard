class AuthResponse {
  final String token;

  AuthResponse({required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token']?.toString() ?? '',
    );
  }
}

class LoadSessionResponse {
  final String cacheId;

  LoadSessionResponse({required this.cacheId});

  factory LoadSessionResponse.fromJson(Map<String, dynamic> json) {
    return LoadSessionResponse(
      cacheId: json['cache_id']?.toString() ?? '',
    );
  }
}

class FullPayload {
  final Map<String, dynamic> json;

  FullPayload(this.json);

  Map<String, dynamic> get meta =>
      Map<String, dynamic>.from(json['meta'] ?? {});

  List<dynamic> get drivers =>
      List<dynamic>.from(json['drivers'] ?? []);

  Map<String, dynamic> get overview =>
      Map<String, dynamic>.from(json['overview'] ?? {});

  Map<String, dynamic> get lapCharts =>
      Map<String, dynamic>.from(json['lap_charts'] ?? {});

  // ✅ already added by you
  Map<String, dynamic> get telemetryCharts =>
      Map<String, dynamic>.from(json['telemetry_charts'] ?? {});

  Map<String, dynamic> get tyreStrategy =>
      Map<String, dynamic>.from(json['tyre_strategy'] ?? {});

  Map<String, dynamic> get replay =>
      Map<String, dynamic>.from(json['replay'] ?? {});
}