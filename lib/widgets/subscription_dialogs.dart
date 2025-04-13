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
              // Premium Features Section
              Text(
                TranslationHelper.translate('premium_features', languageCode),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildFeatureItem(
                  context, Icons.notifications, 'feature_notifications'),
              _buildFeatureItem(context, Icons.cloud, 'feature_weather'),
              _buildFeatureItem(
                  context, Icons.recommend, 'feature_recommendations'),
              _buildFeatureItem(
                  context, Icons.all_inclusive, 'feature_unlimited'),
              SizedBox(height: 24),

              // Monthly Plan Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await SubscriptionService.startSubscription(
                      userId: FirebaseAuth.instance.currentUser!.uid,
                      context: context,
                      plan: 'monthly',
                    );
                    await refreshSubscriptionData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                    foregroundColor:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Monthly Plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '19,00 kr/month',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Yearly Plan Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await SubscriptionService.startSubscription(
                      userId: FirebaseAuth.instance.currentUser!.uid,
                      context: context,
                      plan: 'yearly',
                    );
                    await refreshSubscriptionData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              TranslationHelper.translate(
                                  'most_popular', languageCode),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Yearly Plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '99,00 kr/year',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),
              Text(
                TranslationHelper.translate(
                    'subscription_cancel_anytime', languageCode),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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

  static Widget _buildFeatureItem(
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
          SizedBox(width: 8),
          Expanded(
            child: Text(
              TranslationHelper.translate(translationKey, languageCode),
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> showSubscriptionDialogWithLoading(
      BuildContext context, String userId,
      {String plan = 'monthly'}) async {
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
        plan: plan,
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
