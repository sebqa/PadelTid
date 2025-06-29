# Railway Deployment Guide

## Prerequisites
- Railway account (railway.app)
- GitHub account
- MongoDB Atlas connection string
- Stripe API keys

## Step 1: Railway Setup

1. **Connect GitHub Repository**
   - Go to Railway dashboard
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose this repository

2. **Set Environment Variables**
   Add these variables in Railway dashboard:
   ```
   ATLAS_URI=mongodb+srv://username:password@cluster.mongodb.net/
   STRIPE_SECRET_KEY=sk_test_your_secret_key_here
   STRIPE_MONTHLY_PRICE_ID=price_your_monthly_price_id
   STRIPE_YEARLY_PRICE_ID=price_your_yearly_price_id
   ```

## Step 2: Deploy

Railway will automatically:
- Detect Python application
- Install dependencies from requirements.txt
- Use the start command from railway.toml
- Deploy your API

## Step 3: Test Your API

Your API will be available at: `https://your-app-name.up.railway.app`

### Test endpoints:
- `GET /` - Health check
- `GET /api/clubs` - Get all clubs
- `GET /api/check-subscription?userId=your_user_id` - Check subscription
- `GET /api/padel-recommendations?userId=your_user_id&locations=club1,club2` - Get recommendations
- `POST /api/update-weather` - Update weather data

### Local Development:
```bash
cd backend
pip3 install -r requirements.txt
python3 -m uvicorn main:app --reload --port 8000
```

## Step 4: Complete Migration

The following endpoints are stubbed and need implementation:
- `POST /create-subscription` - Migrate from createSubscription Lambda
- `POST /cancel-subscription` - Migrate from cancelSubscription Lambda  
- `GET /courts` - Migrate from getCourts Lambda
- `GET /document/{doc_id}` - Migrate from getDocumentById Lambda
- `POST /send-notification` - Migrate from sendNotification Lambda
- `POST /manage-tokens` - Migrate from manageTokens Lambda
- `POST /auth` - Migrate from auth Lambda

## Step 5: Set Up Cron Jobs (Optional)

For weather updates, you can:
1. Use Railway's cron jobs feature
2. Or use an external service like cron-job.org to call `POST /update-weather`

## Benefits After Migration

✅ **No cold starts** - Your API is always running
✅ **Better performance** - Dedicated resources
✅ **Easier debugging** - Centralized logs
✅ **Cost predictable** - $5/month vs Lambda pricing
✅ **Simpler deployment** - Git push to deploy

## Troubleshooting

- Check Railway logs for deployment issues
- Ensure all environment variables are set
- Verify MongoDB Atlas allows Railway's IP ranges
- Test locally first: `cd backend && python3 -m uvicorn main:app --reload`
- Make sure Railway build command includes the backend directory path 