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

        # Get the subscription from MongoDB
        logger.info(f"Fetching subscription for user: {user_id}")
        subscription = db['subscriptions'].find_one({'userId': user_id})
        
        if not subscription:
            logger.error(f"No subscription found for user: {user_id}")
            return {
                'statusCode': 404,
                'headers': headers,
                'body': json.dumps({'error': 'No subscription found for this user'})
            }
            
        subscription_id = subscription.get('subscriptionId')
        if not subscription_id:
            logger.error(f"No subscription ID found for user: {user_id}")
            return {
                'statusCode': 404,
                'headers': headers,
                'body': json.dumps({'error': 'No subscription ID found for this user'})
            }

        # Cancel the subscription in Stripe
        try:
            logger.info(f"Cancelling Stripe subscription: {subscription_id}")
            stripe.Subscription.cancel(subscription_id)
            logger.info(f"Successfully cancelled Stripe subscription: {subscription_id}")
        except stripe.error.StripeError as e:
            logger.error(f"Stripe error while cancelling subscription: {str(e)}")
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'error': f'Failed to cancel subscription: {str(e)}'})
            }

        # Update the subscription status in MongoDB
        logger.info(f"Updating subscription status in MongoDB for user: {user_id}")
        db['subscriptions'].update_one(
            {'userId': user_id},
            {
                '$set': {
                    'subscriptionStatus': 'cancelled',
                    'subscriptionId': '',
                    'updatedAt': subscription.get('updatedAt', None)
                }
            }
        )
        logger.info(f"Successfully updated subscription status for user: {user_id}")

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'success': True,
                'message': 'Subscription cancelled successfully'
            })
        }

    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        } 