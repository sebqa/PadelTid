import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/home_page.dart';
import 'package:flutter_application_1/secrets/secrets.dart';
import 'package:flutter_application_1/widgets/simple_language_selector.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () =>
                Navigator.of(context).maybePop(context).then((value) {
              if (value == false) {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomePage(),
                    ));
              }
            }),
          ),
          title: Text(AppLocalizations.of(context).translate('account')),
        ),
        body: SafeArea(
          child: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Column(
                  children: [
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: const SimpleLanguageSelector(),
                    ),
                    Expanded(
                      child: SignInScreen(
                        providers: [
                          EmailAuthProvider(),
                          GoogleProvider(clientId: Secrets.clientId),
                        ],
                        headerBuilder: (context, constraints, shrinkOffset) {
                          return Padding(
                            padding: const EdgeInsets.all(20),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Icon(
                                Icons.account_circle,
                                color: Colors.black,
                                size: 100,
                              ),
                            ),
                          );
                        },
                        subtitleBuilder: (context, action) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: action == AuthAction.signIn
                                ? Text(AppLocalizations.of(context)
                                    .translate('welcome_sign_in'))
                                : Text(AppLocalizations.of(context)
                                    .translate('welcome_sign_up')),
                          );
                        },
                        footerBuilder: (context, action) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              AppLocalizations.of(context)
                                  .translate('terms_agreement'),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
              print(FirebaseAuth.instance.currentUser!.uid);

              final userId = FirebaseAuth.instance.currentUser!.uid;

              return AccountScreen(userId);
            },
          ),
        ));
  }
}

class AccountScreen extends StatefulWidget {
  final String userId;
  AccountScreen(this.userId, {super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: const SimpleLanguageSelector(),
        ),
        Expanded(
          child: ProfileScreen(
            actions: [
              SignedOutAction(
                (context) {
                  // Sign out and clear FCM token
                  // Navigate back to AuthGate after sign out
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthGate()),
                    (route) =>
                        false, // This removes all previous routes from the stack
                  );
                },
              ),
            ],
            providers: const [],
            children: [],
          ),
        ),
      ],
    );
  }
}
