part of janus_client;

class SipSubscriptionEventResult {
  String? event;
  int? code;
  String? reason;
  int? expires;

  SipSubscriptionEventResult(
      {this.event, this.code, this.reason, this.expires});

  factory SipSubscriptionEventResult.fromJson(Map<String, dynamic> json) {
    return SipSubscriptionEventResult(
      event: json["event"] as String?,
      code: json["code"] is int
          ? json["code"] as int
          : int.tryParse(json["code"]?.toString() ?? ''),
      reason: json["reason"] as String?,
      expires: json["expires"] is int
          ? json["expires"] as int
          : int.tryParse(json["expires"]?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "event": event,
      "code": code,
      "reason": reason,
      "expires": expires,
    }..removeWhere((key, value) => value == null);
  }
}

abstract class SipSubscriptionLifecycleEvent {
  String? sip;
  String? callId;
  SipSubscriptionEventResult? result;

  SipSubscriptionLifecycleEvent({this.sip, this.callId, this.result});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "sip": sip,
      "call_id": callId,
    };
    if (result != null) {
      data["result"] = result!.toJson();
    }
    return data;
  }
}

class SipSubscribingEvent extends SipSubscriptionLifecycleEvent {
  SipSubscribingEvent(
      {String? sip, String? callId, SipSubscriptionEventResult? result})
      : super(sip: sip, callId: callId, result: result);

  factory SipSubscribingEvent.fromJson(Map<String, dynamic> json) {
    return SipSubscribingEvent(
      sip: json["sip"] as String?,
      callId: json["call_id"] as String?,
      result: json["result"] == null
          ? null
          : SipSubscriptionEventResult.fromJson(
              Map<String, dynamic>.from(json["result"])),
    );
  }
}

class SipSubscribeSucceededEvent extends SipSubscriptionLifecycleEvent {
  SipSubscribeSucceededEvent(
      {String? sip, String? callId, SipSubscriptionEventResult? result})
      : super(sip: sip, callId: callId, result: result);

  factory SipSubscribeSucceededEvent.fromJson(Map<String, dynamic> json) {
    return SipSubscribeSucceededEvent(
      sip: json["sip"] as String?,
      callId: json["call_id"] as String?,
      result: json["result"] == null
          ? null
          : SipSubscriptionEventResult.fromJson(
              Map<String, dynamic>.from(json["result"])),
    );
  }
}

class SipSubscribeFailedEvent extends SipSubscriptionLifecycleEvent {
  SipSubscribeFailedEvent(
      {String? sip, String? callId, SipSubscriptionEventResult? result})
      : super(sip: sip, callId: callId, result: result);

  factory SipSubscribeFailedEvent.fromJson(Map<String, dynamic> json) {
    return SipSubscribeFailedEvent(
      sip: json["sip"] as String?,
      callId: json["call_id"] as String?,
      result: json["result"] == null
          ? null
          : SipSubscriptionEventResult.fromJson(
              Map<String, dynamic>.from(json["result"])),
    );
  }
}

class SipUnsubscribingEvent extends SipSubscriptionLifecycleEvent {
  SipUnsubscribingEvent(
      {String? sip, String? callId, SipSubscriptionEventResult? result})
      : super(sip: sip, callId: callId, result: result);

  factory SipUnsubscribingEvent.fromJson(Map<String, dynamic> json) {
    return SipUnsubscribingEvent(
      sip: json["sip"] as String?,
      callId: json["call_id"] as String?,
      result: json["result"] == null
          ? null
          : SipSubscriptionEventResult.fromJson(
              Map<String, dynamic>.from(json["result"])),
    );
  }
}
