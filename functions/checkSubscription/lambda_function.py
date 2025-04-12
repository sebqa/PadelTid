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
    
    # Set up CORS headers
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,Accept',
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET',
        'Access-Control-Expose-Headers': '*',
        'Content-Type': 'application/json'
    }

    # Handle CORS preflight request
    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        logger.info("Handling OPTIONS request")
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({'message': 'OK'})
        }

    try:
        # Get the user ID from the request
        user_id = event['queryStringParameters']['userId']
        logger.info(f"Processing request for user: {user_id}")
        
        if not user_id:
            logger.error("User ID is missing from request")
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'error': 'User ID is required'})
            }

        # Get the user from MongoDB
        logger.info(f"Fetching user from MongoDB: {user_id}")
        user = db['users'].find_one({"_id": user_id})
        
        if not user:
            logger.error(f"User not found in MongoDB: {user_id}")
            return {
                'statusCode': 404,
                'headers': headers,
                'body': json.dumps({'error': 'User not found'})
            }

        # Check if user has a Stripe customer ID
        if 'stripeCustomerId' not in user:
            logger.info(f"User {user_id} has no Stripe customer ID")
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({
                    'hasSubscription': False,
                    'subscriptionId': None,
                    'status': None,
                    'plan': None
                })
            }

        # Get the customer's subscriptions from Stripe
        logger.info(f"Fetching subscriptions for customer: {user['stripeCustomerId']}")
        subscriptions = stripe.Subscription.list(
            customer=user['stripeCustomerId'],
            status='all',
            expand=['data.default_payment_method']
        )

        if not subscriptions.data:
            logger.info(f"No subscriptions found for customer: {user['stripeCustomerId']}")
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({
                    'hasSubscription': False,
                    'subscriptionId': None,
                    'status': None,
                    'plan': None
                })
            }

        # Get the most recent subscription
        subscription = subscriptions.data[0]
        logger.info(f"Found subscription: {subscription.id} with status: {subscription.status}")

        # Determine the plan type
        plan = None
        for price_id in subscription.items.data:
            for plan_type, price in PRICE_IDS.items():
                if price_id.price.id == price:
                    plan = plan_type
                    break
            if plan:
                break

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'hasSubscription': True,
                'subscriptionId': subscription.id,
                'status': subscription.status,
                'plan': plan,
                'currentPeriodEnd': subscription.current_period_end,
                'cancelAtPeriodEnd': subscription.cancel_at_period_end
            })
        }

    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }
        
    try:
        # Try to get the customer from Stripe
        logger.info(f"Fetching Stripe customer: {user['stripeCustomerId']}")
        customer = stripe.Customer.retrieve(user['stripeCustomerId'])
        
            # Get the customer's subscriptions from Stripe
            logger.info(f"Fetching subscriptions for customer: {customer.id}")
            subscriptions = stripe.Subscription.list(
                customer=customer.id,
                status='all',
                expand=['data.default_payment_method']
            )

            # Get the customer's payment methods
            logger.info(f"Fetching payment methods for customer: {customer.id}")
            payment_methods = stripe.PaymentMethod.list(
                customer=customer.id,
                type='card'
            )

            # Get the customer's invoices
            logger.info(f"Fetching invoices for customer: {customer.id}")
            invoices = stripe.Invoice.list(
                customer=customer.id,
                limit=5
            )

            # Check if there's an active subscription
            active_subscription = next(
                (sub for sub in subscriptions.data if sub.status == 'active'),
                None
            )

            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({
                    'isActive': active_subscription is not None,
                    'subscriptions': subscriptions.data,
                    'payment_methods': payment_methods.data,
                    'invoices': invoices.data
                })
            }

        except stripe.error.InvalidRequestError as e:
            if 'No such customer' in str(e):
                logger.warning(f"Stripe customer not found: {user['stripeCustomerId']}")
                # Clear the Stripe customer ID from MongoDB
                db['users'].update_one(
                    {"_id": user_id},
                    {"$unset": {"stripeCustomerId": ""}}
                )
                return {
                    'statusCode': 200,
                    'headers': headers,
                    'body': json.dumps({
                        'isActive': False,
                        'message': 'No subscription found'
                    })
                }
            else:
                raise

    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }
