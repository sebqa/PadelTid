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

              // Monthly Plan Card
              _buildPlanCard(
                context,
                'Monthly Plan',
                '19,00 kr/month',
                'monthly',
                refreshSubscriptionData,
              ),
              SizedBox(height: 16),

              // Yearly Plan Card
              _buildPlanCard(
                context,
                'Yearly Plan',
                '99,00 kr/year',
                'yearly',
                refreshSubscriptionData,
                isPopular: true,
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

  static Widget _buildPlanCard(
    BuildContext context,
    String title,
    String price,
    String plan,
    Function refreshSubscriptionData, {
    bool isPopular = false,
  }) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale.languageCode;

    return Card(
      elevation: isPopular ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPopular
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  TranslationHelper.translate('most_popular', languageCode),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await SubscriptionService.startSubscription(
                  userId: FirebaseAuth.instance.currentUser!.uid,
                  context: context,
                  plan: plan,
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
                    .replaceAll('{price}', price),
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
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
