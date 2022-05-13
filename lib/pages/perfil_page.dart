import 'dart:io';

import 'package:chat_app/allConstants/all_constants.dart';
import 'package:chat_app/allConstants/app_constants.dart';
import 'package:chat_app/allWidgets/loading_view.dart';
import 'package:chat_app/models/chat_usuario.dart';
import 'package:chat_app/providers/perfil_provider.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController? nomeController;
  TextEditingController? sobreController;
  final TextEditingController _phoneController = TextEditingController();

  late String currentUserId;
  String dialCodeDigits = '+00';
  String id = '';
  String nome = '';
  String fotoUrl = '';
  String telefone = '';
  String sobre = '';

  bool isLoading = false;
  File? avatarImageFile;
  late PerfilProvider profileProvider;

  final FocusNode focusNodeNickname = FocusNode();

  @override
  void initState() {
    super.initState();
    profileProvider = context.read<PerfilProvider>();
    readLocal();
  }

  void readLocal() {
    setState(() {
      id = profileProvider.getPrefs(FirestoreConstants.id) ?? "";
      nome = profileProvider.getPrefs(FirestoreConstants.nome) ?? "";

      fotoUrl = profileProvider.getPrefs(FirestoreConstants.fotoUrl) ?? "";
      telefone =
          profileProvider.getPrefs(FirestoreConstants.telefone) ?? "";
      sobre = profileProvider.getPrefs(FirestoreConstants.sobre) ?? "";
    });
    nomeController = TextEditingController(text: nome);
    sobreController = TextEditingController(text: sobre);
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    // PickedFile is not supported
    // Now use XFile?
    XFile? pickedFile = await imagePicker
        .pickImage(source: ImageSource.gallery)
        .catchError((onError) {
      Fluttertoast.showToast(msg: onError.toString())
    });
    File? image;
    if (pickedFile != null) {
      image = File(pickedFile.path);
    }
    if (image != null) {
      setState(() {
        avatarImageFile = image;
        isLoading = true;
      });
      uploadFile();
    }
  }

  Future uploadFile() async {
    String fileName = id;
    UploadTask uploadTask = profileProvider.uploadImageFile(
        avatarImageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      fotoUrl = await snapshot.ref.getDownloadURL();
      ChatUsuario updateInfo = ChatUsuario(id: id,
          fotoUrl: fotoUrl,
          nome: nome,
          telefone: telefone,
          sobre: sobre);
      profileProvider.updateFirestoreData(
          FirestoreConstants.pathUsuariosCollection, id, updateInfo.toJson())
          .then((value) async {
        await profileProvider.setPrefs(FirestoreConstants.fotoUrl, fotoUrl);
        setState(() {
          isLoading = false;
        });
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  void updateFirestoreData() {
    focusNodeNickname.unfocus();
    setState(() {
      isLoading = true;
      if (dialCodeDigits != "+00" && _phoneController.text != "") {
        telefone = dialCodeDigits + _phoneController.text.toString();
      }
    });
    ChatUsuario updateInfo = ChatUsuario(id: id,
        fotoUrl: fotoUrl,
        nome: nome,
        telefone: telefone,
        sobre: sobre);
    profileProvider.updateFirestoreData(
        FirestoreConstants.pathUsuariosCollection, id, updateInfo.toJson())
        .then((value) async {
      await profileProvider.setPrefs(
          FirestoreConstants.nome, nome);
      await profileProvider.setPrefs(
          FirestoreConstants.telefone, telefone);
      await profileProvider.setPrefs(
        FirestoreConstants.fotoUrl, fotoUrl,);
      await profileProvider.setPrefs(
          FirestoreConstants.sobre,sobre );

      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'Sucesso');
    }).catchError((onError) {
      Fluttertoast.showToast(msg: onError.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return
        Scaffold(
          appBar: AppBar(
            title: const Text(
              AppConstants.perfilTitle,
            ),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        onTap: getImage,
                        child: Container(
                          alignment: Alignment.center,
                          child: avatarImageFile == null ? fotoUrl.isNotEmpty ?
                          ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.network(fotoUrl,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              errorBuilder: (context, object, stackTrace) {
                                return const Icon(Icons.account_circle, size: 90,
                                  color: AppColors.greyColor,);
                              },
                              loadingBuilder: (BuildContext context, Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.grey,
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes! : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ) : const Icon(Icons.account_circle,
                            size: 90,
                            color: AppColors.greyColor,)
                              : ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.file(avatarImageFile!, width: 120,
                              height: 120,
                              fit: BoxFit.cover,),),
                          margin: const EdgeInsets.all(20),
                        ),),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Nome', style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: AppColors.spaceCadet,
                          ),),
                          TextField(
                            decoration: kTextInputDecoration.copyWith(
                                hintText: 'Escreva seu nome'),
                            controller: nomeController,
                            onChanged: (value) {
                              nome = value;
                            },
                            focusNode: focusNodeNickname,
                          ),
                          vertical15,
                          const Text('Sobre', style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: AppColors.spaceCadet
                          ),),
                          TextField(
                            decoration: kTextInputDecoration.copyWith(
                                hintText: 'Escreva Sobre você'),
                            onChanged: (value) {
                              sobre = value;
                            },
                          ),
                          vertical15,
                          const Text('Selecione o código do país', style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: AppColors.spaceCadet,
                          ),),
                          Container(
                            width: double.infinity,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 1.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: CountryCodePicker(
                              onChanged: (country) {
                                setState(() {
                                  dialCodeDigits = country.dialCode!;
                                });
                              },
                              initialSelection: 'BR',
                              showCountryOnly: false,
                              showOnlyCountryWhenClosed: false,
                              favorite: const ["+1", "US", "+55", "BR"],
                            ),
                          ),
                          vertical15,
                          const Text('Telefone', style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: AppColors.spaceCadet,
                          ),),
                          TextField(
                            decoration: kTextInputDecoration.copyWith(
                              hintText: 'Telefone',
                              prefix: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(dialCodeDigits,
                                  style: const TextStyle(color: Colors.grey),),
                              ),
                            ),
                            controller: _phoneController,
                            maxLength: 12,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                      ElevatedButton(onPressed: updateFirestoreData, child:const Padding(
                        padding:  EdgeInsets.all(8.0),
                        child:  Text('Inserir informações'),
                      )),

                    ],
                  ),
                ),
              Positioned(child: isLoading ? const LoadingView() : const SizedBox.shrink()),
            ],
          ),

        );

  }
}