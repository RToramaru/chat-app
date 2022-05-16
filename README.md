# Chat App


Chat App é um aplicativo de bate papo simples, desenvolvido em Flutter com integração ao FireBase.

O aplicativo contém as seguintes funcionalidades:

- Autenticação de login pelo Google via Firebase
- Bate papo com todos os usuários conectados no aplicativo

## Instalação

Para instalação primeiramente clone o repositório local, em seguida abra o diretório salvo e instale as dependências.

```sh
git clone https://github.com/RToramaru/chat-app
cd chat-app
flutter pub get
```

Após feito isso será necessário integração do projeto no firebase e ativar a opção de login via Google.
Para facilitar utilize o firebase cli com os seguintes comandos:

```sh
npm install -g firebase-tools  
dart pub global activate flutterfire_cli
cd chat-app
flutterfire configure
```
E selecione o projeto firebase para se usar.


## Demonstração

![](/screen/demonstracao.gif)
