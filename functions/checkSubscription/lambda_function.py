import json
import os
import stripe
from pymongo import MongoClient

# Initialize Stripe
stripe.api_key = os.environ['STRIPE_SECRET_KEY']

# Set up MongoDB connection
client = MongoClient(host=os.environ.get("ATLAS_URI"))
db = client['padeltid']

def lambda_handler(event, context):
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
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({'message': 'OK'})
        }

    try:
        # Get the user ID from the request
        user_id = event['queryStringParameters']['userId']
        
        if not user_id:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'error': 'User ID is required'})
            }

        # Get the user's Stripe customer ID from MongoDB
        user = db['users'].find_one({"_id": user_id})
        
        if not user or 'stripeCustomerId' not in user:
            return {
                'statusCode': 404,
                'headers': headers,
                'body': json.dumps({'error': 'User not found or no Stripe customer ID'})
            }

        # Get the customer's subscriptions from Stripe
        subscriptions = stripe.Subscription.list(
            customer=user['stripeCustomerId'],
            status='all',
            expand=['data.default_payment_method']
        )

        # Get the customer's payment methods
        payment_methods = stripe.PaymentMethod.list(
            customer=user['stripeCustomerId'],
            type='card'
        )

        # Get the customer's invoices
        invoices = stripe.Invoice.list(
            customer=user['stripeCustomerId'],
            limit=5
        )

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'subscriptions': subscriptions.data,
                'payment_methods': payment_methods.data,
                'invoices': invoices.data
            })
        }
    except Exception as e:
        print(f'Error: {str(e)}')
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)})
        }