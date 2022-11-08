import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

final logger = Logger();
final GoogleSignIn googleSignIn = GoogleSignIn(scopes: [
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/userinfo.profile',
]);

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
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [
          Locale("ja", "JP"),
        ],
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

  // Check whether sign-in already, and set currentUser
  void initCurrentUser() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user != null) {
      setState(() {
        currentUser = user;
      });
    }
  }

void showFailedSignInToast() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Oh, failed to sign-in...'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    initCurrentUser();
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
                if (currentUser != null) return;

                final user = await googleLogin();
                if (user != null) {
                  setState(() {
                    currentUser = user;
                  });
                } else {
                  showFailedSignInToast();
                }
              },
              child: const Text('SIGN IN'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (currentUser == null) return;

                final succeededLogout = await logoutCompletely();
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

Future<ParseUser?> googleLogin({ bool silent = false }) async {
  GoogleSignInAccount? account = googleSignIn.currentUser;
  account ??= await googleSignIn.signInSilently(); // アカウント選択の必要がないなら暗転を挟まない
  if (!silent) {
    account ??= await googleSignIn.signIn();
  }

  logger.i('account: $account');

  // アカウント選択画面でどれも選ばれずに戻った場合
  if (account == null) {
    return null;
  }

  GoogleSignInAuthentication authentication = await account.authentication;
  final parseResponse = await ParseUser.loginWith(
    'google',
    google(authentication.accessToken!, googleSignIn.currentUser!.id, authentication.idToken!),
    username: account.displayName,
    email: account.email,
  );

  logger.i('parseResponse.result: ${parseResponse.result}');
  return parseResponse.result as ParseUser;
}

// Logout only as ParseUser
Future<bool> logout() async {
  final user = await ParseUser.currentUser() as ParseUser?;
  logger.d('user: $user');
  if (user == null) {
    return false;
  }

  final parseResponse = await user.logout();
  logger.d('parseResponse.success: ${parseResponse.success}');
  return parseResponse.success;
}

// Logout ParseUser and GoogleSignInAccount
Future<bool> logoutCompletely() async {
  final succeededLogout = await logout();
  if (!succeededLogout) return false;

  GoogleSignInAccount? account = await googleSignIn.signOut();
  logger.i('account: $account');

  return true;
}
