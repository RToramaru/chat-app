import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

class ChatUser extends Equatable {
  final String id;
  final String fotoUrl;
  final String nome;
  final String telefone;
  final String sobre;

  const ChatUser(
      {required this.id,
      required this.fotoUrl,
      required this.nome,
      required this.telefone,
      required this.sobre});

  ChatUser copyWith({
    String? id,
    String? fotoUrl,
    String? apelido,
    String? telefone,
    String? email,
  }) =>
      ChatUser(
          id: id ?? this.id,
          fotoUrl: fotoUrl ?? this.fotoUrl,
          nome: apelido ?? nome,
          telefone: telefone ?? this.telefone,
          sobre: email ?? sobre);

  Map<String, dynamic> toJson() => {
        FirestoreConstants.nome: nome,
        FirestoreConstants.fotoUrl: fotoUrl,
        FirestoreConstants.telefone: telefone,
        FirestoreConstants.sobre: sobre,
      };
  factory ChatUser.fromDocument(DocumentSnapshot snapshot) {
    String fotoUrl = "";
    String apelido = "";
    String telefone = "";
    String sobre = "";

    try {
      fotoUrl = snapshot.get(FirestoreConstants.fotoUrl);
      apelido = snapshot.get(FirestoreConstants.nome);
      telefone = snapshot.get(FirestoreConstants.telefone);
      sobre = snapshot.get(FirestoreConstants.sobre);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return ChatUser(
        id: snapshot.id,
        fotoUrl: fotoUrl,
        nome: apelido,
        telefone: telefone,
        sobre: sobre);
  }

  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();
}
