# PadelTid Backend API

This directory contains the FastAPI backend that replaces the AWS Lambda functions.

## Quick Start

```bash
# Navigate to backend directory
cd backend

# Install dependencies
pip3 install -r requirements.txt

# Set environment variables
export ATLAS_URI="your_mongodb_connection_string"
export STRIPE_SECRET_KEY="your_stripe_secret_key"
export STRIPE_MONTHLY_PRICE_ID="your_monthly_price_id"
export STRIPE_YEARLY_PRICE_ID="your_yearly_price_id"

# Run the development server
python3 -m uvicorn main:app --reload --port 8000
```

## Project Structure

```
backend/
├── main.py                     # FastAPI app entry point
├── requirements.txt            # Python dependencies
├── railway.toml               # Railway deployment config
├── config/                    # Configuration layer
│   ├── settings.py           # Environment variables & settings
│   └── database.py           # Database connections
├── routes/                    # API routes layer
│   ├── clubs.py              # Club and court endpoints
│   ├── subscriptions.py      # Stripe subscription endpoints
│   ├── padel.py              # Padel recommendations
│   ├── weather.py            # Weather endpoints
│   ├── auth.py               # Authentication endpoints
│   └── notifications.py      # Notification endpoints
├── services/                  # Business logic layer
│   ├── clubs_service.py      # Club business logic
│   ├── subscription_service.py # Stripe integration
│   ├── padel_service.py      # Recommendation algorithms
│   ├── weather_service.py    # Weather data processing
│   ├── auth_service.py       # Authentication logic
│   └── notification_service.py # Notification logic
└── models/                    # Data models (empty for now)
```

## API Endpoints

Base URL: `http://localhost:8000` (development) or `https://your-app.up.railway.app` (production)

All API endpoints are prefixed with `/api`:

- `GET /` - Health check
- `GET /api/clubs` - Get all clubs ✅
- `GET /api/check-subscription?userId=<id>` - Check subscription status ✅
- `GET /api/padel-recommendations?userId=<id>&locations=<clubs>` - Get recommendations ✅
- `POST /api/update-weather` - Update weather data ✅

## Deployment

See `RAILWAY_DEPLOYMENT.md` for deployment instructions to Railway.

## Migration Status

✅ **Completed**: Clubs, subscription checking, padel recommendations, weather updates
🔄 **To Be Implemented**: Subscription management, authentication, notifications

## Development

The backend runs independently from the Flutter app. You can develop and test the API separately at `http://localhost:8000`. 