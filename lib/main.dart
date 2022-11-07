import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

final logger = Logger();

void main() async {
  await dotenv.load(fileName: '.env');
  logger.d('BACK4APP_APPLICATION_ID: ${dotenv.env['BACK4APP_APPLICATION_ID']}');

  final applicationId = dotenv.env['BACK4APP_APPLICATION_ID'];
  final clientKey = dotenv.env['BACK4APP_CLIENT_KEY'];
  const parseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(applicationId!, parseServerUrl, clientKey: clientKey, autoSendSessionId: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const appTitle = 'Google OAuth Test';

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp(
        title: appTitle,
        home: Scaffold(
          appBar: AppBar(
            title: const Text(appTitle),
          ),
          body: const Center(
            child: SignInOutWidget(),
          ),
        ),
      ),
    );
  }
}

class SignInOutWidget extends StatefulWidget {
  const SignInOutWidget({super.key});

  @override
  SignInOutWidgetState createState() {
    return SignInOutWidgetState();
  }
}

class SignInOutWidgetState extends State<SignInOutWidget> {
  ParseUser? currentUser;

  Widget currentStateText() {
    late final String message;
    if (currentUser == null) {
      message = '非ログイン状態です';
    } else {
      message = '${currentUser!.get('username')}さんがログイン中です';
    }

    return Text(message, style: const TextStyle(fontSize: 20));
  }

  void fetchCurrentUser() async {
    currentUser = await ParseUser.currentUser() as ParseUser?;
  }

  @override
  void initState() {
    super.initState();
    fetchCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        currentStateText(),
        const Padding(padding: EdgeInsets.only(top: 18)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () async {
                final user = await googleLogin();
                setState(() {
                  currentUser = user;
                });
              },
              child: const Text('SIGN IN'),
            ),
            ElevatedButton(
              onPressed: () async {
                final succeededLogout = await logout();
                if (succeededLogout) {
                  setState(() {
                    currentUser = null;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('LOGOUT'),
            ),
          ],
        ),
      ],
    );
  }
}

Future<ParseUser> googleLogin() async {
  final GoogleSignIn googleSignIn = GoogleSignIn(scopes: [
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
  ]);
  GoogleSignInAccount? account = await googleSignIn.signIn();
  logger.i(googleSignIn);
  logger.i(account);

  GoogleSignInAuthentication authentication = await account!.authentication;
  final parseResponse = await ParseUser.loginWith(
    'google',
    google(authentication.accessToken!, googleSignIn.currentUser!.id, authentication.idToken!),
    username: account.displayName,
    email: account.email,
  );

  logger.i(parseResponse.result);
  return parseResponse.result as ParseUser;
}

Future<bool> logout() async {
  final user = await ParseUser.currentUser() as ParseUser?;
  if (user == null) {
    return false;
  }

  final parseResponse = await user.logout();
  return parseResponse.success;
}
