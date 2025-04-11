import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/locale_provider.dart';
import 'package:flutter_application_1/utils/translations.dart';
import 'package:flutter_application_1/services/subscription_service.dart';

class SubscriptionDialogs {
  static void showSubscriptionDialog(
      BuildContext context, Function refreshSubscriptionData) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale.languageCode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          TranslationHelper.translate('subscription_title', languageCode),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Plan Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationHelper.translate(
                            'subscription_monthly', languageCode),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '19,00 kr/month',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        TranslationHelper.translate(
                            'subscription_features', languageCode),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(TranslationHelper.translate(
                          'feature_notifications', languageCode)),
                      SizedBox(height: 4),
                      Text(TranslationHelper.translate(
                          'feature_weather', languageCode)),
                      SizedBox(height: 4),
                      Text(TranslationHelper.translate(
                          'feature_recommendations', languageCode)),
                      SizedBox(height: 4),
                      Text(TranslationHelper.translate(
                          'feature_unlimited', languageCode)),
                      SizedBox(height: 16),
                      Text(
                        TranslationHelper.translate(
                            'subscription_cancel_anytime', languageCode),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await SubscriptionService.startSubscription(
                    userId: FirebaseAuth.instance.currentUser!.uid,
                    context: context,
                    plan: 'premium',
                  );
                  await refreshSubscriptionData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  TranslationHelper.translate('subscribe_button', languageCode)
                      .replaceAll('{price}', '19,00 kr'),
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationHelper.translate('cancel', languageCode)),
          ),
        ],
      ),
    );
  }

  static Future<void> showSubscriptionDialogWithLoading(
      BuildContext context, String userId) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale.languageCode;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );

      // Start subscription process
      await SubscriptionService.startSubscription(
        userId: userId,
        context: context,
        plan: 'premium',
      );
    } catch (e) {
      print('Error in subscription dialog: $e');
      // Only show error if the context is still valid
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translate(
                'subscription_error', languageCode)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static void showBillingInfo(
      BuildContext context, Map<String, dynamic>? subscriptionData) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale.languageCode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationHelper.translate('billing_info', languageCode)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TranslationHelper.translate('payment_methods', languageCode),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ...(subscriptionData?['paymentMethods'] ?? [])
                  .map<Widget>((method) => ListTile(
                        leading: Icon(Icons.credit_card),
                        title: Text('•••• ${method['card']['last4']}'),
                        subtitle: Text(
                            'Expires ${method['card']['exp_month']}/${method['card']['exp_year']}'),
                      ))
                  .toList(),
              SizedBox(height: 16),
              Text(
                TranslationHelper.translate('recent_invoices', languageCode),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ...(subscriptionData?['invoices'] ?? [])
                  .map<Widget>((invoice) => ListTile(
                        title: Text(
                            '\$${(invoice['amount_paid'] / 100).toStringAsFixed(2)}'),
                        subtitle: Text(DateTime.fromMillisecondsSinceEpoch(
                                invoice['created'] * 1000)
                            .toString()
                            .split(' ')[0]),
                        trailing: Text(invoice['status']),
                      ))
                  .toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationHelper.translate('close', languageCode)),
          ),
        ],
      ),
    );
  }

  static Future<void> showSubscriptionFeatures(BuildContext context) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale.languageCode;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            TranslationHelper.translate('subscription_title', languageCode)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(TranslationHelper.translate(
                'subscription_features', languageCode)),
            const SizedBox(height: 16),
            Text(TranslationHelper.translate(
                'feature_notifications', languageCode)),
            Text(TranslationHelper.translate('feature_weather', languageCode)),
            Text(TranslationHelper.translate(
                'feature_recommendations', languageCode)),
            Text(
                TranslationHelper.translate('feature_unlimited', languageCode)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(TranslationHelper.translate('cancel', languageCode)),
          ),
        ],
      ),
    );
  }
}
