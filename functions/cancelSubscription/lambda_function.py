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

        # Get the Stripe customer ID from the user document
        stripe_customer_id = user.get('stripeCustomerId')
        if not stripe_customer_id:
            logger.error(f"No Stripe customer ID found for user: {user_id}")
            return {
                'statusCode': 404,
                'headers': headers,
                'body': json.dumps({'error': 'No Stripe customer found for this user'})
            }

        # Get the active subscription for this customer
        try:
            logger.info(f"Fetching active subscription for customer: {stripe_customer_id}")
            subscriptions = stripe.Subscription.list(
                customer=stripe_customer_id,
                status='active',
                limit=1
            )
            
            if not subscriptions.data:
                logger.error(f"No active subscription found for customer: {stripe_customer_id}")
                return {
                    'statusCode': 404,
                    'headers': headers,
                    'body': json.dumps({'error': 'No active subscription found'})
                }
            
            subscription = subscriptions.data[0]
            logger.info(f"Found active subscription: {subscription.id}")

            # Cancel the subscription
            logger.info(f"Cancelling subscription: {subscription.id}")
            cancelled_subscription = stripe.Subscription.cancel(subscription.id)
            logger.info(f"Successfully cancelled subscription: {subscription.id}")

            # Update the subscription status in MongoDB
            logger.info(f"Updating subscription status in MongoDB for user: {user_id}")
            db['subscriptions'].update_one(
                {'userId': user_id},
                {
                    '$set': {
                        'subscriptionStatus': 'cancelled',
                        'subscriptionId': '',
                        'updatedAt': cancelled_subscription.canceled_at
                    }
                }
            )
            logger.info(f"Successfully updated subscription status for user: {user_id}")

            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({
                    'success': True,
                    'message': 'Subscription cancelled successfully',
                    'cancelledAt': cancelled_subscription.canceled_at
                })
            }

        except stripe.error.StripeError as e:
            logger.error(f"Stripe error while cancelling subscription: {str(e)}")
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'error': f'Failed to cancel subscription: {str(e)}'})
            }

    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        } 