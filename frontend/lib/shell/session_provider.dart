import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/models.dart';
import '../auth/auth_provider.dart';
import '../providers/loading_provider.dart';
import '../widgets/f1_snackbar.dart';

final sessionProvider = StateNotifierProvider<SessionController, SessionState>((
  ref,
) {
  final api = ref.read(apiProvider);
  return SessionController(api: api, ref: ref);
});

class SessionState {
  final bool loading;
  final String? cacheId;
  final FullPayload? full;
  final String? error;
  final bool justLoaded;

  const SessionState({
    this.loading = false,
    this.cacheId,
    this.full,
    this.error,
    this.justLoaded = false,
  });

  SessionState copyWith({
    bool? loading,
    String? cacheId,
    FullPayload? full,
    String? error,
    bool? justLoaded,
  }) {
    return SessionState(
      loading: loading ?? this.loading,
      cacheId: cacheId ?? this.cacheId,
      full: full ?? this.full,
      error: error,
      justLoaded: justLoaded ?? this.justLoaded,
    );
  }
}

class SessionController extends StateNotifier<SessionState> {
  final ApiClient api;
  final Ref ref;

  SessionController({required this.api, required this.ref})
    : super(const SessionState());

  Future<void> load({
    required int season,
    required int round,
    required String sessionName,
  }) async {
    state = state.copyWith(loading: true, error: null, justLoaded: false);
    ref.read(loadingProvider.notifier).show();

    try {
      final resp = await api.loadSession(
        season: season,
        round: round,
        sessionName: sessionName,
      );

      final respMap = Map<String, dynamic>.from(resp as Map);
      final cacheId = (respMap['cache_id'] ?? '').toString();

      if (cacheId.isEmpty) {
        throw Exception("load-session did not return cache_id");
      }

      final fullJson = await api.getFull(cacheId: cacheId);
      final full = FullPayload(Map<String, dynamic>.from(fullJson as Map));

      state = state.copyWith(
        loading: false,
        cacheId: cacheId,
        full: full,
        error: null,
        justLoaded: true,
      );
      ref.read(loadingProvider.notifier).hide();
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
        justLoaded: false,
      );
      ref.read(loadingProvider.notifier).hide();
    }
  }
}
