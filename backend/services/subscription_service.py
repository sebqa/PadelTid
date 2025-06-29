import stripe
from config.database import get_db_padeltid, is_stripe_ready, get_stripe_error
from config.settings import get_settings
import logging

logger = logging.getLogger(__name__)

class SubscriptionService:
    def __init__(self):
        self.db = get_db_padeltid
        self.settings = get_settings()
    
    def _check_stripe_availability(self):
        """Check if Stripe is available and return error if not"""
        if not is_stripe_ready():
            stripe_error = get_stripe_error()
            return {
                "error": "Stripe not configured",
                "message": "Subscription features are not available. Stripe configuration required.",
                "details": stripe_error,
                "required_env_vars": [
                    "STRIPE_SECRET_KEY",
                    "STRIPE_MONTHLY_PRICE_ID", 
                    "STRIPE_YEARLY_PRICE_ID"
                ]
            }
        return None
    
    async def check_subscription(self, user_id: str):
        """Check subscription status for a user"""
        try:
            # Check if Stripe is available
            stripe_check = self._check_stripe_availability()
            if stripe_check:
                return stripe_check
                
            logger.info(f"Checking subscription for user: {user_id}")
            
            # Find user in MongoDB
            user = self.db()['users'].find_one({'_id': user_id})
            
            if not user:
                logger.error(f"User not found: {user_id}")
                raise ValueError("User not found")

            subscription_data = {
                'hasSubscription': False,
                'status': None,
                'currentPeriodEnd': None,
                'cancelAtPeriodEnd': False,
                'plan': None,
                'invoices': []
            }

            # Check if user has Stripe customer ID
            if 'stripeCustomerId' in user:
                try:
                    # Get customer's subscriptions
                    subscriptions = stripe.Subscription.list(
                        customer=user['stripeCustomerId'],
                        status='all',
                        limit=1
                    )

                    if subscriptions.data:
                        subscription = subscriptions.data[0]
                        subscription_data.update({
                            'hasSubscription': True,
                            'status': subscription.status,
                            'currentPeriodEnd': subscription.current_period_end,
                            'cancelAtPeriodEnd': subscription.cancel_at_period_end,
                            'plan': subscription.plan.nickname or subscription.plan.id
                        })

                    # Get recent invoices
                    invoices = stripe.Invoice.list(
                        customer=user['stripeCustomerId'],
                        limit=10
                    )

                    subscription_data['invoices'] = [{
                        'id': invoice.id,
                        'amount_paid': invoice.amount_paid / 100,
                        'currency': invoice.currency,
                        'status': invoice.status,
                        'created': invoice.created,
                        'hosted_invoice_url': invoice.hosted_invoice_url,
                        'pdf_url': invoice.invoice_pdf
                    } for invoice in invoices.data]

                except stripe.error.InvalidRequestError as e:
                    logger.warning(f"Stripe error: {str(e)}")
                    if "No such customer" in str(e):
                        # Clear invalid customer ID
                        self.db()['users'].update_one(
                            {'_id': user_id},
                            {'$unset': {'stripeCustomerId': ''}}
                        )

            return subscription_data

        except Exception as e:
            logger.error(f"Error in check_subscription: {str(e)}")
            raise e
    
    async def create_subscription(self, data: dict):
        """Create a new subscription"""
        try:
            # Check if Stripe is available
            stripe_check = self._check_stripe_availability()
            if stripe_check:
                return stripe_check
                
            # TODO: Implement logic from createSubscription Lambda
            return {
                "message": "Subscription creation endpoint - implement from createSubscription Lambda",
                "data": data
            }
        except Exception as e:
            logger.error(f"Error in create_subscription: {str(e)}")
            raise e
    
    async def cancel_subscription(self, data: dict):
        """Cancel a subscription"""
        try:
            # Check if Stripe is available
            stripe_check = self._check_stripe_availability()
            if stripe_check:
                return stripe_check
                
            # TODO: Implement logic from cancelSubscription Lambda
            return {
                "message": "Subscription cancellation endpoint - implement from cancelSubscription Lambda",
                "data": data
            }
        except Exception as e:
            logger.error(f"Error in cancel_subscription: {str(e)}")
            raise e
    
    async def get_invoices(self, user_id: str):
        """Get user invoices"""
        try:
            # Check if Stripe is available
            stripe_check = self._check_stripe_availability()
            if stripe_check:
                return stripe_check
                
            # TODO: Implement logic from getInvoices Lambda
            return {
                "message": "Get invoices endpoint - implement from getInvoices Lambda",
                "userId": user_id
            }
        except Exception as e:
            logger.error(f"Error in get_invoices: {str(e)}")
            raise e 