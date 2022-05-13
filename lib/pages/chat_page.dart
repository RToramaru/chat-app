// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:chat_app/allConstants/all_constants.dart';
import 'package:chat_app/allWidgets/common_widgets.dart';
import 'package:chat_app/models/chat_mensagens.dart';
import 'package:chat_app/pages/login_page.dart';
import 'package:chat_app/providers/autor_provider.dart';
import 'package:chat_app/providers/chat_provider.dart';
import 'package:chat_app/providers/perfil_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends StatefulWidget {
  final String parId;
  final String parAvatar;
  final String parApelido;
  final String userAvatar;

  const ChatPage(
      {Key? key,
      required this.parApelido,
      required this.parAvatar,
      required this.parId,
      required this.userAvatar})
      : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late String currentUserId;

  List<QueryDocumentSnapshot> listMessages = [];

  int _limit = 20;
  final int _limitIncrement = 20;
  String groupChatId = '';

  File? imageFile;
  bool isLoading = false;
  bool isShowSticker = false;
  String imageUrl = '';

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  late ChatProvider chatProvider;
  late AutorProvider autorProvider;

  @override
  void initState() {
    super.initState();
    chatProvider = context.read<ChatProvider>();
    autorProvider = context.read<AutorProvider>();

    focusNode.addListener(onFocusChanged);
    scrollController.addListener(_scrollListener);
    readLocal();
  }

  _scrollListener() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void onFocusChanged() {
    if (focusNode.hasFocus) {
      setState(() {
        isShowSticker = false;
      });
    }
  }

  void readLocal() {
    if (autorProvider.getFirebaseUserId()?.isNotEmpty == true) {
      currentUserId = autorProvider.getFirebaseUserId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false);
    }
    if (currentUserId.compareTo(widget.parId) > 0) {
      groupChatId = '$currentUserId - ${widget.parId}';
    } else {
      groupChatId = '${widget.parId} - $currentUserId';
    }
    chatProvider.updateFirestoreData(FirestoreConstants.pathUsuariosCollection,
        currentUserId, {FirestoreConstants.conversando: widget.parId});
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile;
    pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      if (imageFile != null) {
        setState(() {
          isLoading = true;
        });
        uploadImageFile();
      }
    }
  }

  void getSticker() {
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  Future<bool> onBackPressed() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      chatProvider.updateFirestoreData(FirestoreConstants.pathUsuariosCollection,
          currentUserId, {FirestoreConstants.conversando: null});
    }
    return Future.value(false);
  }

  void _telefone(String phoneNumber) async {
    var url = 'telefone://$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Ocorreu um erro';
    }
  }

  void uploadImageFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadTask = chatProvider.uploadImageFile(imageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        enviarMensagem(imageUrl, MessageType.image);
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void enviarMensagem(String content, int type) {
    if (content.trim().isNotEmpty) {
      textEditingController.clear();
      chatProvider.sendChatMessage(
          content, type, groupChatId, currentUserId, widget.parId);
      scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(
          msg: 'Campo vazio', backgroundColor: Colors.grey);
    }
  }

  bool mensagemRecebida(int index) {
    if ((index > 0 &&
            listMessages[index - 1].get(FirestoreConstants.idFrom) ==
                currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool mensagemEnviada(int index) {
    if ((index > 0 &&
            listMessages[index - 1].get(FirestoreConstants.idFrom) !=
                currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Conversando com ${widget.parApelido}'.trim()),
        actions: [
          IconButton(
            onPressed: () {
              PerfilProvider profileProvider;
              profileProvider = context.read<PerfilProvider>();
              String callPhoneNumber =
                  profileProvider.getPrefs(FirestoreConstants.telefone) ??
                      "";
              _telefone(callPhoneNumber);
            },
            icon: const Icon(Icons.phone),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sizes.dimen_8),
          child: Column(
            children: [
              buildListMessage(),
              buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMessageInput() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: Sizes.dimen_4),
            decoration: BoxDecoration(
              color: AppColors.burgundy,
              borderRadius: BorderRadius.circular(Sizes.dimen_30),
            ),
            child: IconButton(
              onPressed: getImage,
              icon: const Icon(
                Icons.camera_alt,
                size: Sizes.dimen_28,
              ),
              color: AppColors.white,
            ),
          ),
          Flexible(
              child: TextField(
            focusNode: focusNode,
            textInputAction: TextInputAction.send,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
            controller: textEditingController,
            decoration:
                kTextInputDecoration.copyWith(hintText: 'Escreva'),
            onSubmitted: (value) {
              enviarMensagem(textEditingController.text, MessageType.text);
            },
          )),
          Container(
            margin: const EdgeInsets.only(left: Sizes.dimen_4),
            decoration: BoxDecoration(
              color: AppColors.burgundy,
              borderRadius: BorderRadius.circular(Sizes.dimen_30),
            ),
            child: IconButton(
              onPressed: () {
                enviarMensagem(textEditingController.text, MessageType.text);
              },
              icon: const Icon(Icons.send_rounded),
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(int index, DocumentSnapshot? documentSnapshot) {
    if (documentSnapshot != null) {
      ChatMensagens chatMessages = ChatMensagens.fromDocument(documentSnapshot);
      if (chatMessages.idFrom == currentUserId) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                chatMessages.type == MessageType.text
                    ? messageBubble(
                        chatContent: chatMessages.content,
                        color: AppColors.spaceLight,
                        textColor: AppColors.white,
                        margin: const EdgeInsets.only(right: Sizes.dimen_10),
                      )
                    : chatMessages.type == MessageType.image
                        ? Container(
                            margin: const EdgeInsets.only(
                                right: Sizes.dimen_10, top: Sizes.dimen_10),
                            child: chatImage(
                                imageSrc: chatMessages.content, onTap: () {}),
                          )
                        : const SizedBox.shrink(),
                mensagemEnviada(index)
                    ? Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Sizes.dimen_20),
                        ),
                        child: Image.network(
                          widget.userAvatar,
                          width: Sizes.dimen_40,
                          height: Sizes.dimen_40,
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext ctx, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: AppColors.burgundy,
                                value: loadingProgress.expectedTotalBytes !=
                                            null &&
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, object, stackTrace) {
                            return const Icon(
                              Icons.account_circle,
                              size: 35,
                              color: AppColors.greyColor,
                            );
                          },
                        ),
                      )
                    : Container(
                        width: 35,
                      ),
              ],
            ),
            mensagemEnviada(index)
                ? Container(
                    margin: const EdgeInsets.only(
                        right: Sizes.dimen_50,
                        top: Sizes.dimen_6,
                        bottom: Sizes.dimen_8),
                    child: Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(
                        DateTime.fromMillisecondsSinceEpoch(
                          int.parse(chatMessages.data),
                        ),
                      ),
                      style: const TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: Sizes.dimen_12,
                          fontStyle: FontStyle.italic),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                mensagemRecebida(index)
                    ? Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Sizes.dimen_20),
                        ),
                        child: Image.network(
                          widget.parAvatar,
                          width: Sizes.dimen_40,
                          height: Sizes.dimen_40,
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext ctx, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: AppColors.burgundy,
                                value: loadingProgress.expectedTotalBytes !=
                                            null &&
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, object, stackTrace) {
                            return const Icon(
                              Icons.account_circle,
                              size: 35,
                              color: AppColors.greyColor,
                            );
                          },
                        ),
                      )
                    : Container(
                        width: 35,
                      ),
                chatMessages.type == MessageType.text
                    ? messageBubble(
                        color: AppColors.burgundy,
                        textColor: AppColors.white,
                        chatContent: chatMessages.content,
                        margin: const EdgeInsets.only(left: Sizes.dimen_10),
                      )
                    : chatMessages.type == MessageType.image
                        ? Container(
                            margin: const EdgeInsets.only(
                                left: Sizes.dimen_10, top: Sizes.dimen_10),
                            child: chatImage(
                                imageSrc: chatMessages.content, onTap: () {}),
                          )
                        : const SizedBox.shrink(),
              ],
            ),
            mensagemRecebida(index)
                ? Container(
                    margin: const EdgeInsets.only(
                        left: Sizes.dimen_50,
                        top: Sizes.dimen_6,
                        bottom: Sizes.dimen_8),
                    child: Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(
                        DateTime.fromMillisecondsSinceEpoch(
                          int.parse(chatMessages.data),
                        ),
                      ),
                      style: const TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: Sizes.dimen_12,
                          fontStyle: FontStyle.italic),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
              stream: chatProvider.getChatMessage(groupChatId, _limit),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  listMessages = snapshot.data!.docs;
                  if (listMessages.isNotEmpty) {
                    return ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: snapshot.data?.docs.length,
                        reverse: true,
                        controller: scrollController,
                        itemBuilder: (context, index) =>
                            buildItem(index, snapshot.data?.docs[index]));
                  } else {
                    return const Center(
                      child: Text('Sem mensagens'),
                    );
                  }
                } else {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.burgundy,
                    ),
                  );
                }
              })
          : const Center(
              child: CircularProgressIndicator(
                color: AppColors.burgundy,
              ),
            ),
    );
  }
}