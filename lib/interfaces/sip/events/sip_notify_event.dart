part of janus_client;

class SipNotifyEvent {
  String? sip;
  String? callId;
  SipNotifyEventResult? result;

  SipNotifyEvent({this.sip, this.callId, this.result});

  factory SipNotifyEvent.fromJson(Map<String, dynamic> json) {
    return SipNotifyEvent(
      sip: json["sip"] as String?,
      callId: json["call_id"] as String?,
      result: json["result"] == null
          ? null
          : SipNotifyEventResult.fromJson(
              Map<String, dynamic>.from(json["result"])),
    );
  }

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

class SipNotifyEventResult {
  String? event;
  String? notify;
  String? substate;
  String? contentType;
  String? content;
  Map<String, dynamic>? headers;

  SipNotifyEventResult(
      {this.event,
      this.notify,
      this.substate,
      this.contentType,
      this.content,
      this.headers});

  factory SipNotifyEventResult.fromJson(Map<String, dynamic> json) {
    return SipNotifyEventResult(
      event: json["event"] as String?,
      notify: json["notify"] as String?,
      substate: json["substate"] as String?,
      contentType: json["content-type"] as String?,
      content: json["content"]?.toString(),
      headers: json["headers"] is Map
          ? Map<String, dynamic>.from(json["headers"])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "event": event,
      "notify": notify,
      "substate": substate,
      "content-type": contentType,
      "content": content,
      "headers": headers,
    }..removeWhere((key, value) => value == null);
    return data;
  }
}
