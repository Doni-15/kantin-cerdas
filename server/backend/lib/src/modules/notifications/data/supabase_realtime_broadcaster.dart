import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kantin_cerdas_backend/src/core/config/supabase_config.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_models.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/realtime_broadcaster.dart';

export 'package:kantin_cerdas_backend/src/modules/notifications/domain/realtime_broadcaster.dart';

/// Publishes minimal order signals to Supabase Realtime HTTP Broadcast API
/// (`POST /realtime/v1/api/broadcast`) using server-side credentials (RT-TECH-001, RT-TECH-003).
class SupabaseHttpRealtimeBroadcaster implements RealtimeBroadcaster {
  SupabaseHttpRealtimeBroadcaster({
    required this._supabaseConfig,
    required this._enabled,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 5),
  }) : _httpClient = httpClient ?? http.Client();

  final SupabaseConfig _supabaseConfig;
  final bool _enabled;
  final http.Client _httpClient;
  final Duration timeout;

  @override
  bool get isEnabled => _enabled;

  @override
  void close() {
    _httpClient.close();
  }

  @override
  Future<void> publish(List<UnbroadcastedRealtimeSignal> signals) async {
    if (!_enabled || signals.isEmpty) return;

    final messages = <Map<String, Object?>>[];
    for (final signal in signals) {
      final payload = signal.toBroadcastPayload();
      messages.add({
        'topic': signal.customerTopic,
        'event': 'order_status_changed',
        'payload': {...payload, 'audience_scope': 'customer'},
        'private': true,
      });
      messages.add({
        'topic': signal.stallTopic,
        'event': 'order_status_changed',
        'payload': {...payload, 'audience_scope': 'owner'},
        'private': true,
      });
    }

    final endpoint = _supabaseConfig.url.resolve('/realtime/v1/api/broadcast');
    try {
      final response = await _httpClient
          .post(
            endpoint,
            headers: {
              'apikey': _supabaseConfig.secretKey,
              'authorization': 'Bearer ${_supabaseConfig.secretKey}',
              'content-type': 'application/json',
            },
            body: jsonEncode({'messages': messages}),
          )
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        // Best-effort: clients still recover via Shelf SSE / REST polling (ORDER-017).
        return;
      }
    } on TimeoutException {
      return;
    } on IOException {
      return;
    } on http.ClientException {
      return;
    }
  }
}
