import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/home_page.dart';
import 'package:flutter_application_1/secrets/secrets.dart';
import 'package:flutter_application_1/widgets/simple_language_selector.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/locale_provider.dart';
import 'package:flutter_application_1/utils/translations.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final languageCode = localeProvider.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () =>
              Navigator.of(context).maybePop(context).then((value) {
            if (value == false) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(),
                ),
              );
            }
          }),
        ),
        title: Text(
          TranslationHelper.translate('account', languageCode),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Column(
                children: [
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: InputDecorationTheme(
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        elevatedButtonTheme: ElevatedButtonThemeData(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      child: SignInScreen(
                        providers: [
                          EmailAuthProvider(),
                          GoogleProvider(clientId: Secrets.clientId),
                        ],
                        headerBuilder: (context, constraints, shrinkOffset) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Container(),
                          );
                        },
                        styles: const {
                          EmailFormStyle(
                            signInButtonVariant: ButtonVariant.filled,
                          ),
                        },
                        subtitleBuilder: (context, action) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              action == AuthAction.signIn
                                  ? TranslationHelper.translate(
                                      'welcome_sign_in', languageCode)
                                  : TranslationHelper.translate(
                                      'welcome_sign_up', languageCode),
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                      ),
                    ),
                    child: const SimpleLanguageSelector(),
                  ),
                ],
              );
            }

            final userId = FirebaseAuth.instance.currentUser!.uid;
            return AccountScreen(userId);
          },
        ),
      ),
    );
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
    final localeProvider = Provider.of<LocaleProvider>(context);
    final languageCode = localeProvider.locale.languageCode;

    return Column(
      children: [
        Expanded(
          child: ProfileScreen(
            appBar: AppBar(
              title: Text(
                TranslationHelper.translate('profile', languageCode),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
            ),
            actions: [
              SignedOutAction(
                (context) {
                  // Sign out and navigate back to AuthGate
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthGate()),
                    (route) => false, // Remove all previous routes
                  );
                },
              ),
            ],
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  TranslationHelper.translate('account_settings', languageCode),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ),
            ],
            providers: const [],
          ),
        ),
        Card(
          elevation: 0,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: const SimpleLanguageSelector(),
        ),
      ],
    );
  }
}

class LoginPage extends StatefulWidget {
  final bool isLogin;

  const LoginPage({Key? key, this.isLogin = true}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final languageCode = localeProvider.locale.languageCode;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App title
                  Text(
                    TranslationHelper.translate('app_title', languageCode),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Welcome message
                  Text(
                    widget.isLogin
                        ? TranslationHelper.translate(
                            'welcome_sign_in', languageCode)
                        : TranslationHelper.translate(
                            'welcome_sign_up', languageCode),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Email field
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),

                  // Password field
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText:
                          TranslationHelper.translate('password', languageCode),
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    obscureText: true,
                  ),

                  const SizedBox(height: 24),

                  // Sign in button
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        if (widget.isLogin) {
                          // Sign in
                          await FirebaseAuth.instance
                              .signInWithEmailAndPassword(
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                          );
                        } else {
                          // Sign up
                          await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                          );
                        }
                        // Navigate to home on success
                        Navigator.of(context).pushReplacementNamed('/home');
                      } catch (e) {
                        // Show error
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${TranslationHelper.translate('error_prefix', languageCode)} $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.isLogin
                          ? TranslationHelper.translate('sign_in', languageCode)
                          : TranslationHelper.translate(
                              'sign_up', languageCode),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Toggle login/signup
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) =>
                              LoginPage(isLogin: !widget.isLogin),
                        ),
                      );
                    },
                    child: Text(
                      widget.isLogin
                          ? TranslationHelper.translate(
                              'create_account', languageCode)
                          : TranslationHelper.translate(
                              'already_have_account', languageCode),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
