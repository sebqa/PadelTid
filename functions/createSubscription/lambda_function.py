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
    try:
        # Parse the request body
        body = json.loads(event['body'])
        user_id = body.get('userId')
        payment_method_id = body.get('paymentMethodId')
        
        if not user_id or not payment_method_id:
            return {
                'statusCode': 400,
                'headers': {
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
                'body': json.dumps({'error': 'User ID and payment method ID are required'})
            }

        # Get the user from MongoDB
        user = db['users'].find_one({"_id": user_id})
        
        if not user:
            return {
                'statusCode': 404,
                'headers': {
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
                'body': json.dumps({'error': 'User not found'})
            }

        # If user doesn't have a Stripe customer ID, create one
        if 'stripeCustomerId' not in user:
            customer = stripe.Customer.create(
                payment_method=payment_method_id,
                email=user.get('email'),
                metadata={'user_id': user_id}
            )
            # Update user in MongoDB with Stripe customer ID
            db['users'].update_one(
                {"_id": user_id},
                {"$set": {"stripeCustomerId": customer.id}}
            )
        else:
            # Attach the payment method to the existing customer
            stripe.PaymentMethod.attach(
                payment_method_id,
                customer=user['stripeCustomerId']
            )
            # Set as default payment method
            stripe.Customer.modify(
                user['stripeCustomerId'],
                invoice_settings={'default_payment_method': payment_method_id}
            )

        # Create the subscription
        subscription = stripe.Subscription.create(
            customer=user['stripeCustomerId'],
            items=[{'price': os.environ['STRIPE_PRICE_ID']}],  # Your Stripe price ID for 19,00 kr/month
            payment_behavior='default_incomplete',
            payment_settings={'save_default_payment_method': 'on_subscription'},
            expand=['latest_invoice.payment_intent']
        )

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({
                'subscriptionId': subscription.id,
                'clientSecret': subscription.latest_invoice.payment_intent.client_secret
            })
        }
    except Exception as e:
        print(f'Error: {str(e)}')
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'error': str(e)})
        } 