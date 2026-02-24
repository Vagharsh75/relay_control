import 'package:flutter/services.dart';
import '../models/sim_card_info.dart';

class SmsService {
  static const _channel = MethodChannel('com.example.lift_restart/sms');
  static const _eventChannel = EventChannel('com.example.lift_restart/sms_receive');

  Stream<Map<String, String>>? _smsStream;

  Stream<Map<String, String>> get onSmsReceived {
    _smsStream ??= _eventChannel.receiveBroadcastStream().map((event) {
      final map = Map<String, dynamic>.from(event as Map);
      return {
        'sender': map['sender'] as String? ?? '',
        'body': map['body'] as String? ?? '',
      };
    }).asBroadcastStream();
    return _smsStream!;
  }

  Future<bool> sendSms({
    required String phoneNumber,
    required String message,
    int subscriptionId = -1,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('sendSms', {
        'phoneNumber': phoneNumber,
        'message': message,
        'subscriptionId': subscriptionId,
      });
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<List<SimCardInfo>> getAvailableSims() async {
    try {
      final result = await _channel.invokeListMethod<Map>('getAvailableSims');
      if (result == null) return [];
      return result
          .map((e) => SimCardInfo.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } on PlatformException catch (_) {
      return [];
    }
  }
}
