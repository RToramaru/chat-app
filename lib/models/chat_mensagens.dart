import 'package:chat_app/allConstants/firestore_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMensagens {
  String idFrom;
  String idTo;
  String data;
  String content;
  int type;

  ChatMensagens(
      {required this.idFrom,
      required this.idTo,
      required this.data,
      required this.content,
      required this.type});

  Map<String, dynamic> toJson() {
    return {
      FirestoreConstants.idFrom: idFrom,
      FirestoreConstants.idTo: idTo,
      FirestoreConstants.data: data,
      FirestoreConstants.content: content,
      FirestoreConstants.type: type,
    };
  }

  factory ChatMensagens.fromDocument(DocumentSnapshot documentSnapshot) {
    String idFrom = documentSnapshot.get(FirestoreConstants.idFrom);
    String idTo = documentSnapshot.get(FirestoreConstants.idTo);
    String data = documentSnapshot.get(FirestoreConstants.data);
    String content = documentSnapshot.get(FirestoreConstants.content);
    int type = documentSnapshot.get(FirestoreConstants.type);

    return ChatMensagens(
        idFrom: idFrom,
        idTo: idTo,
        data: data,
        content: content,
        type: type);
  }
}