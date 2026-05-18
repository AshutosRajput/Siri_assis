import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class SiriIntentHandler {
  static const MethodChannel _channel = MethodChannel('com.example.demo/siri_intents');
  
  // Callback when an intent arrives
  final Function(String action, Map<String, dynamic> data) onIntentReceived;

  SiriIntentHandler({required this.onIntentReceived}) {
    _channel.setMethodCallHandler(_handleMethod);
    // Tell Swift that Flutter is booted and ready to receive queued intents
    _channel.invokeMethod('flutterIsReady');
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    if (call.method == 'onSiriIntent') {
      try {
        final Map<dynamic, dynamic> args = call.arguments;
        final action = args['action'] as String;
        final data = Map<String, dynamic>.from(args['data'] as Map);
        
        developer.log('Siri Intent Received: $action data: $data');
        onIntentReceived(action, data);
      } catch (e) {
        developer.log('Error parsing Siri intent: $e');
      }
    }
  }
}
