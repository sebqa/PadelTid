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
                onPressed: () {
                  Navigator.of(context).pop();
                  startSubscription(
                      context, 'premium', refreshSubscriptionData);
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

  static Future<void> startSubscription(BuildContext context, String plan,
      Function refreshSubscriptionData) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale.languageCode;

    await SubscriptionService.startSubscription(
      userId: FirebaseAuth.instance.currentUser!.uid,
      plan: plan,
      context: context,
      onSuccess: () async {
        await refreshSubscriptionData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translate(
                'subscription_created', languageCode)),
            backgroundColor: Colors.green,
          ),
        );
      },
      onError: (String error) {
        print('Error creating subscription: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${TranslationHelper.translate('error_prefix', languageCode)} $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
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
}
