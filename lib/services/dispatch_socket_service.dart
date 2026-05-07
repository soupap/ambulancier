import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:incident_reporter/core/config/app_config.dart';
import 'package:incident_reporter/core/models/dispatch_assignment_model.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class DispatchSocketService {
  StompClient? _client;
  String? _subscribedAmbulanceId;

  bool get isConnected => _client?.connected ?? false;

  void connect({
    required String token,
    required String ambulanceId,
    required void Function(DispatchAssignmentModel assignment) onAssignment,
    required void Function(String message) onError,
  }) {
    if (_subscribedAmbulanceId == ambulanceId && isConnected) {
      return;
    }

    disconnect();
    _subscribedAmbulanceId = ambulanceId;

    debugPrint('Connecting to WebSocket: ${AppConfig.websocketUrl}');
    _client = StompClient(
      config: StompConfig(
        url: AppConfig.websocketUrl,
        reconnectDelay: const Duration(seconds: 5),
        beforeConnect: () async {
          await Future<void>.delayed(const Duration(milliseconds: 150));
        },
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onWebSocketError: (dynamic error) {
          debugPrint('WebSocket Error: $error');
          onError(error.toString());
        },
        onStompError: (frame) {
          debugPrint('STOMP Error Command: ${frame.command}');
          debugPrint('STOMP Error Headers: ${frame.headers}');
          debugPrint('STOMP Error Body: ${frame.body}');
          onError(frame.body ?? 'WebSocket STOMP error');
        },
        onDisconnect: (frame) {
          debugPrint('Disconnected from STOMP server');
        },
        onConnect: (frame) {
          debugPrint('Connected to STOMP server. Frame: ${frame.command}');
          debugPrint('Subscribing to: /topic/drivers/$ambulanceId/dispatches');
          _client?.subscribe(
            destination: '/topic/drivers/$ambulanceId/dispatches',
            callback: (event) {
              Get.snackbar('Dispatch', 'New dispatch received');
              final body = event.body;
              if (body == null || body.isEmpty) {
                return;
              }

              try {
                final decoded = jsonDecode(body) as Map<String, dynamic>;
                onAssignment(DispatchAssignmentModel.fromJson(decoded));
              } catch (error) {
                onError('Invalid dispatch payload: $error');
              }
            },
          );
        },
      ),
    )..activate();
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    _subscribedAmbulanceId = null;
  }
}
