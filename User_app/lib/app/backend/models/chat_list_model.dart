class ChatListModel {
  int? id;
  int? senderId;
  //int? reciverId;
  int? roomId;
  String? message;
  int? messageType;
  int? reported;
  String? extraFields;
  int? status;
  String? updatedAt;

  ChatListModel(
      {this.id,
      this.senderId,
      this.roomId,
      this.message,
      this.messageType,
      this.reported,
      this.extraFields,
      this.status,
      this.updatedAt,
      //this.reciverId
      });

  ChatListModel.fromJson(Map<String, dynamic> json) {
    id = int.parse(json['id'].toString());
    senderId = int.parse(json['sender_id'].toString());
    //reciverId = int.parse(json['receiver_id'].toString());
    roomId = int.parse(json['room_id'].toString());
    message = json['message'];
    messageType = int.parse(json['message_type'].toString());
    reported = int.parse(json['reported'].toString());
    extraFields = json['extra_fields'];
    status = int.parse(json['status'].toString());
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['sender_id'] = senderId;
    //data['receiver_id'] = reciverId;
    data['room_id'] = roomId;
    data['message'] = message;
    data['message_type'] = messageType;
    data['reported'] = reported;
    data['extra_fields'] = extraFields;
    data['status'] = status;
    data['updated_at'] = updatedAt;
    return data;
  }
}
