# PadelTid API - Modular Project Structure

## Overview
This project has been refactored from AWS Lambda functions into a modular FastAPI application suitable for Railway deployment.

## Project Structure

```
PadelTid/
├── main.py                     # FastAPI app entry point
├── requirements.txt            # Dependencies
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
└── services/                  # Business logic layer
    ├── clubs_service.py      # Club business logic
    ├── subscription_service.py # Stripe integration
    ├── padel_service.py      # Recommendation algorithms
    ├── weather_service.py    # Weather data processing
    ├── auth_service.py       # Authentication logic
    └── notification_service.py # Notification logic
```

## API Endpoints (prefixed with /api)

### Completed Migrations
- `GET /api/clubs` - Get all clubs ✅
- `GET /api/check-subscription` - Check subscription status ✅  
- `GET /api/padel-recommendations` - Get recommendations ✅
- `POST /api/update-weather` - Update weather data ✅

### To Be Implemented
- `POST /api/create-subscription` - Create subscription 🔄
- `POST /api/cancel-subscription` - Cancel subscription 🔄
- `GET /api/courts` - Get courts information 🔄
- `GET /api/document/{doc_id}` - Get document by ID 🔄
- `POST /api/auth` - Authenticate user 🔄
- `POST /api/send-notification` - Send notification 🔄

## Deployment
See `RAILWAY_DEPLOYMENT.md` for deployment instructions. 