import json
import os
import stripe
from pymongo import MongoClient
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize Stripe
stripe.api_key = os.environ['STRIPE_SECRET_KEY']

# Set up MongoDB connection
client = MongoClient(host=os.environ.get("ATLAS_URI"))
db = client['padeltid']

# Define price IDs for different plans
PRICE_IDS = {
    'monthly': os.environ['STRIPE_MONTHLY_PRICE_ID'],
    'yearly': os.environ['STRIPE_YEARLY_PRICE_ID']
}

def lambda_handler(event, context):
    logger.info("Lambda function invoked")
    logger.info(f"Event: {json.dumps(event)}")
    
    # Enable CORS
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'GET,OPTIONS'
    }

    if event['httpMethod'] == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({})
        }

    try:
        # Get user ID from query parameters
        user_id = event.get('queryStringParameters', {}).get('userId')
        if not user_id:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'error': 'User ID is required'})
            }

        # Find user in MongoDB
        logger.info(f"Fetching user from MongoDB: {user_id}")
        user = db['users'].find_one({'userId': user_id})
        
        if not user:
            logger.error(f"User not found in MongoDB: {user_id}")
            return {
                'statusCode': 404,
                'headers': headers,
                'body': json.dumps({'error': 'User not found'})
            }

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
                logger.info(f"Fetching Stripe customer: {user['stripeCustomerId']}")
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
                    'amount_paid': invoice.amount_paid / 100,  # Convert from cents
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
                    db['users'].update_one(
                        {'userId': user_id},
                        {'$unset': {'stripeCustomerId': ''}}
                    )

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(subscription_data)
        }

    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }
    finally:
        if 'client' in locals():
            client.close()
