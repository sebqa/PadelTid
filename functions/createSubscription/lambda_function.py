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
        # Parse the request body
        logger.info("Parsing request body")
        body = json.loads(event['body'])
        user_id = body.get('userId')
        logger.info(f"Request body: {json.dumps(body)}")
        
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

        # Handle create intent request
        if body.get('createIntent'):
            logger.info("Processing createIntent request")
            # If user doesn't have a Stripe customer ID, create one
            if 'stripeCustomerId' not in user:
                logger.info("Creating new Stripe customer")
                customer = stripe.Customer.create(
                    email=user.get('email'),
                    metadata={'user_id': user_id}
                )
                logger.info(f"Created Stripe customer: {customer.id}")
                # Update user in MongoDB with Stripe customer ID
                db['users'].update_one(
                    {"_id": user_id},
                    {"$set": {"stripeCustomerId": customer.id}}
                )
                customer_id = customer.id
            else:
                customer_id = user['stripeCustomerId']
                logger.info(f"Using existing Stripe customer: {customer_id}")

            # Create a SetupIntent
            logger.info("Creating SetupIntent")
            setup_intent = stripe.SetupIntent.create(
                customer=customer_id,
                payment_method_types=['card'],
                usage='off_session',
            )
            logger.info(f"Created SetupIntent: {setup_intent.id}")

            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({
                    'clientSecret': setup_intent.client_secret
                })
            }

        # Handle complete subscription request
        elif body.get('completeSubscription'):
            logger.info("Processing completeSubscription request")
            client_secret = body.get('clientSecret')
            payment_method_id = body.get('paymentMethodId')  # For web platform
            
            if not client_secret:
                logger.error("Client secret is missing from request")
                return {
                    'statusCode': 400,
                    'headers': headers,
                    'body': json.dumps({'error': 'Client secret is required'})
                }

            if payment_method_id:
                logger.info("Processing web flow with payment method")
                # Web flow - use the provided payment method directly
                subscription = stripe.Subscription.create(
                    customer=user['stripeCustomerId'],
                    items=[{'price': os.environ['STRIPE_PRICE_ID']}],
                    default_payment_method=payment_method_id,
                    payment_settings={'save_default_payment_method': 'on_subscription'},
                    expand=['latest_invoice.payment_intent']
                )
            else:
                logger.info("Processing mobile flow with setup intent")
                # Mobile flow - get payment method from setup intent
                setup_intent = stripe.SetupIntent.retrieve(client_secret.split('_secret_')[0])
                subscription = stripe.Subscription.create(
                    customer=user['stripeCustomerId'],
                    items=[{'price': os.environ['STRIPE_PRICE_ID']}],
                    default_payment_method=setup_intent.payment_method,
                    payment_settings={'save_default_payment_method': 'on_subscription'},
                    expand=['latest_invoice.payment_intent']
                )

            logger.info(f"Created subscription: {subscription.id} with status: {subscription.status}")
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({
                    'subscriptionId': subscription.id,
                    'status': subscription.status
                })
            }
        else:
            logger.error(f"Invalid request type. Body: {json.dumps(body)}")
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'error': 'Invalid request type'})
            }

    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        } 