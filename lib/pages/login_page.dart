import 'package:chat_app/allConstants/all_constants.dart';
import 'package:chat_app/pages/home_page.dart';
import 'package:chat_app/providers/autor_provider.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final autorProvider = Provider.of<AutorProvider>(context);

    switch (autorProvider.status) {
      case Status.erroAutenticacao:
        Fluttertoast.showToast(msg: 'Falha no login');
        break;
      case Status.autenticacaoCancelada:
        Fluttertoast.showToast(msg: 'Login cancelado');
        break;
      case Status.autenticado:
        Fluttertoast.showToast(msg: 'Logado com sucesso');
        break;
      default:
        break;
    }

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(
              vertical: Sizes.dimen_30,
              horizontal: Sizes.dimen_20,
            ),
            children: [
              vertical50,
              const Text(
                'Bem Vindo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Sizes.dimen_26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              vertical30,
              const Text(
                'Faça login para continuar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Sizes.dimen_22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              vertical50,
              Center(child: Image.asset('assets/images/papel_de_parede.png')),
              vertical50,
              SizedBox(
                height: Sizes.dimen_50,
                child: SignInButton(
                  Buttons.Google,
                  text: "Acessar com o Google",
                  onPressed: () async {
                    bool isSuccess = await autorProvider.handleGoogleSignIn();
                    if (isSuccess) {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HomePage()));
                    }
                  },
                ),
              ),
              
            ],
          ),
          Center(
            child: autorProvider.status == Status.autenticando
                ? const CircularProgressIndicator(
                    color: AppColors.lightGrey,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
