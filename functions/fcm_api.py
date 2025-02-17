import firebase_admin
from firebase_admin import credentials
from firebase_admin import messaging


cred = credentials.Certificate("credentials/serviceAccountKey.json")
firebase_admin.initialize_app(cred)

# This registration token comes from the client FCM SDKs.
registration_token = 'dwG-z7kf1oos8EprUnTtmi:APA91bE_xwYnHgW2FgkBaiHTT3tDl8AGjqw5EV094S8J_eVklKXy6RStnFFadHkzTu-Y2_ER23YJ-0f2hGcIS9l-kaINCLAAp1v6Pe9Yvq-PdsM1_h95ZV12e5fO1Ohb3mgnaeX2ozeA'

# See documentation on defining a message payload.
message = messaging.Message(
      notification=messaging.WebpushNotification(
          title='Test Notification',
          body='This is a test notification.'
      ),
      token=registration_token
)

# Send the message
response = messaging.send(message)
# Response is a message ID string.
print('Successfully sent message:', response)