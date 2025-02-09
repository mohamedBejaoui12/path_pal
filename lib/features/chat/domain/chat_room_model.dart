import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'chat_room_model.freezed.dart';
part 'chat_room_model.g.dart';

@freezed
class ChatRoom with _$ChatRoom {
  const factory ChatRoom({
    String? id,
    required String user1Email,
    required String user2Email,
    String? lastMessage,
    DateTime? lastMessageTimestamp,
  }) = _ChatRoom;

  factory ChatRoom.fromJson(Map<String, dynamic> json) => _$ChatRoomFromJson(json);
}