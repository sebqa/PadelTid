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
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:flutter_application_1/services/subscription_service.dart';
import 'package:flutter_application_1/widgets/subscription_dialogs.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

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
                          GoogleProvider(
                            clientId: kIsWeb
                                ? "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com" // Web client ID
                                : Secrets.clientId, // Android/iOS client ID
                          ),
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
            return AccountScreen(
              user: FirebaseAuth.instance.currentUser!,
              onSignOut: () => _signOut(context),
              onDeleteAccount: () => _showDeleteAccountDialog(context),
            );
          },
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      // Navigate back to login screen after sign out
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale.languageCode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationHelper.translate(
            'delete_account_confirm', languageCode)),
        content: Text(TranslationHelper.translate(
            'delete_account_warning', languageCode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationHelper.translate('cancel', languageCode)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => _deleteAccount(context),
            child: Text(TranslationHelper.translate('delete', languageCode)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale.languageCode;

    try {
      await FirebaseAuth.instance.currentUser?.delete();

      // Navigate back to login screen after account deletion
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
        (route) => false, // Remove all previous routes
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                TranslationHelper.translate('account_deleted', languageCode))),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close the dialog

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${TranslationHelper.translate('delete_error', languageCode)}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class AccountScreen extends StatefulWidget {
  final User user;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;

  const AccountScreen({
    Key? key,
    required this.user,
    required this.onSignOut,
    required this.onDeleteAccount,
  }) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _subscriptionData;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final data = await SubscriptionService.checkSubscription(userId);
        if (mounted) {
          setState(() {
            _subscriptionData = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void _showInvoices(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invoices',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              if (_subscriptionData?['invoices']?.isEmpty ?? true)
                Text('No invoices available')
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount:
                      min((_subscriptionData?['invoices']?.length ?? 0), 5),
                  itemBuilder: (context, index) {
                    final invoice = _subscriptionData!['invoices'][index];
                    return ListTile(
                      title: Text('Invoice ${_formatDate(invoice['created'])}'),
                      subtitle: Text(
                        '${invoice['amount_paid']} ${invoice['currency'].toUpperCase()}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.visibility),
                            onPressed: () => launchUrl(
                                Uri.parse(invoice['hosted_invoice_url'])),
                          ),
                          IconButton(
                            icon: Icon(Icons.download),
                            onPressed: () =>
                                launchUrl(Uri.parse(invoice['pdf_url'])),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final languageCode = localeProvider.locale.languageCode;
    final userName = widget.user.displayName ?? widget.user.email ?? '';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Theme.of(context).shadowColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: Text(
                              userInitial,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          if (widget.user.email != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.user.email!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Subscription Status
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Theme.of(context).shadowColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _subscriptionData?['hasSubscription'] == true
                                    ? Icons.star
                                    : Icons.star_border,
                                color: _subscriptionData?['hasSubscription'] ==
                                        true
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                TranslationHelper.translate(
                                    'subscription_status', languageCode),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_subscriptionData?['hasSubscription'] ==
                              true) ...[
                            Text(
                              TranslationHelper.translate(
                                  'subscription_active', languageCode),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            // Add Invoices Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showInvoices(context),
                                icon: const Icon(Icons.receipt),
                                label: Text(TranslationHelper.translate(
                                    'view_invoices', languageCode)),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _handleUnsubscribe,
                                icon: const Icon(Icons.cancel),
                                label: Text(TranslationHelper.translate(
                                    'unsubscribe', languageCode)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            Text(
                              TranslationHelper.translate(
                                  'subscription_inactive', languageCode),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                            ),
                            const SizedBox(height: 16),
                            // Premium Features
                            Text(
                              TranslationHelper.translate(
                                  'premium_features', languageCode),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            _buildFeatureItem(context, Icons.notifications,
                                'feature_notifications'),
                            _buildFeatureItem(
                                context, Icons.cloud, 'feature_weather'),
                            _buildFeatureItem(context, Icons.recommend,
                                'feature_recommendations'),
                            _buildFeatureItem(context, Icons.all_inclusive,
                                'feature_unlimited'),
                            const SizedBox(height: 16),
                            // Single Subscription Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    SubscriptionDialogs.showSubscriptionDialog(
                                  context,
                                  _loadSubscriptionData,
                                ),
                                icon: const Icon(Icons.star),
                                label: Text(TranslationHelper.translate(
                                    'subscribe_to_premium', languageCode)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              TranslationHelper.translate(
                                  'subscription_cancel_anytime', languageCode),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Account Settings
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Theme.of(context).shadowColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.settings,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                TranslationHelper.translate(
                                    'account_settings', languageCode),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Language Selector
                          const SimpleLanguageSelector(),
                          const SizedBox(height: 16),
                          // Sign Out Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: widget.onSignOut,
                              icon: const Icon(Icons.logout),
                              label: Text(TranslationHelper.translate(
                                  'sign_out', languageCode)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceVariant,
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Delete Account Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: widget.onDeleteAccount,
                              icon: const Icon(Icons.delete_forever),
                              label: Text(TranslationHelper.translate(
                                  'delete_account', languageCode)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.1),
                                foregroundColor: Colors.red,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Support Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Theme.of(context).shadowColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.support_agent,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                TranslationHelper.translate(
                                    'support', languageCode),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: Icon(Icons.email_outlined),
                            title: Text(TranslationHelper.translate(
                                'contact_email', languageCode)),
                            subtitle: Text('support@padeltid.com'),
                            onTap: () => launchUrl(
                                Uri.parse('mailto:support@padeltid.com')),
                          ),
                          ListTile(
                            leading: Icon(Icons.help_outline),
                            title: Text(TranslationHelper.translate(
                                'faq', languageCode)),
                            subtitle: Text(TranslationHelper.translate(
                                'view_faq', languageCode)),
                            onTap: () => launchUrl(
                                Uri.parse('https://padeltid.com/faq')),
                          ),
                          if (_subscriptionData?['hasSubscription'] == true)
                            ListTile(
                              leading: Icon(Icons.support),
                              title: Text(TranslationHelper.translate(
                                  'premium_support', languageCode)),
                              subtitle: Text(TranslationHelper.translate(
                                  'priority_support', languageCode)),
                              onTap: () => launchUrl(Uri.parse(
                                  'mailto:premium-support@padeltid.com')),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _handleUnsubscribe() async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale.languageCode;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationHelper.translate(
            'unsubscribe_confirmation_title', languageCode)),
        content: Text(TranslationHelper.translate(
            'unsubscribe_confirmation_message', languageCode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(TranslationHelper.translate('cancel', languageCode)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(TranslationHelper.translate('confirm', languageCode)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SubscriptionService.cancelSubscription(
          userId: widget.user.uid,
          onSuccess: () async {
            await _loadSubscriptionData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(TranslationHelper.translate(
                      'unsubscribe_success', languageCode)),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          onError: (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(TranslationHelper.translate(
                      'unsubscribe_error', languageCode)),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      } catch (e) {
        debugPrint('Error unsubscribing: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationHelper.translate(
                  'unsubscribe_error', languageCode)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildFeatureItem(
      BuildContext context, IconData icon, String translationKey) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale.languageCode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              TranslationHelper.translate(translationKey, languageCode),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
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
