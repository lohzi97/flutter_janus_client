// {
//     "event": "hangup",
//     "code": 200,
//     "reason": "Session Terminated",
//     "reason_header_protocol": "Q.850",
//     "reason_header_cause": "16"
// }
part of janus_client;

class SipHangupEvent {
  String? sip;
  String? callId;
  SipHangupEventResult? result;

  SipHangupEvent({this.sip, this.callId, this.result});

  SipHangupEvent.fromJson(Map<String, dynamic> json) {
    this.sip = json["sip"];
    this.callId = json["call_id"];
    this.result = json["result"] != null ? SipHangupEventResult.fromJson(json["result"]) : null;
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["sip"] = this.sip;
    data["call_id"] = this.callId;
    if (this.result != null) {
      data["result"] = this.result!.toJson();
    }
    return data;
  }
  
}

class SipHangupEventResult {
  String? event;
  int? code;
  String? reason;
  String? reasonHeaderProtocol;
  String? reasonHeaderCause;

  SipHangupEventResult({this.event, this.code, this.reason, this.reasonHeaderProtocol, this.reasonHeaderCause});

  SipHangupEventResult.fromJson(Map<String, dynamic> json) {
    this.event = json["event"];
    this.code = json["code"];
    this.reason = json["reason"];
    this.reasonHeaderProtocol = json["reason_header_protocol"];
    this.reasonHeaderCause = json["reason_header_cause"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["event"] = this.event;
    data["code"] = this.code;
    data["reason"] = this.reason;
    data["reason_header_protocol"] = this.reasonHeaderProtocol;
    data["reason_header_cause"] = this.reasonHeaderCause;
    return data;
  }
}
