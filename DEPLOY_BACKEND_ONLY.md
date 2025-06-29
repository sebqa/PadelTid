# Deploy Backend Only to Railway

Since your backend is in a subdirectory, here are the best methods to deploy just the backend to Railway:

## **Method 1: Railway Root Path Configuration (Recommended)**

### Step 1: Set Root Path in Railway Dashboard
1. Go to your Railway project dashboard
2. Click on your service
3. Go to **Settings** → **General**
4. Set **Root Directory** to: `backend`
5. Click **Save**

### Step 2: Deploy
Railway will now automatically:
- Build from the `backend/` directory
- Use `backend/requirements.txt`
- Execute commands relative to the backend folder

## **Method 2: Using Railway CLI with Root Path**

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login to Railway
railway login

# Navigate to your project root (PadelTid/)
cd /path/to/PadelRecommender/PadelTid

# Deploy with root path specified
railway up --service your-service-name --rootPath backend
```

## **Method 3: Separate Repository (Alternative)**

If you prefer a completely separate deployment:

```bash
# Create a new repo just for backend
cd backend
git init
git add .
git commit -m "Initial backend commit"

# Push to new GitHub repo
git remote add origin https://github.com/yourusername/padeltid-backend.git
git push -u origin main

# Connect this new repo to Railway
```

## **Method 4: Manual Railway Configuration**

In Railway dashboard:

### Build Settings:
- **Build Command**: `pip install --no-cache-dir -r requirements.txt`
- **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`
- **Root Directory**: `backend`

### Environment Variables:

**Required:**
```
ATLAS_URI=your_mongodb_connection_string
```

**Optional (for subscription features):**
```
STRIPE_SECRET_KEY=your_stripe_secret_key
STRIPE_MONTHLY_PRICE_ID=your_monthly_price_id
STRIPE_YEARLY_PRICE_ID=your_yearly_price_id
```

> **Note**: The app will start successfully with just MongoDB configured. Stripe is optional and only needed for subscription features.

## **Verification Steps**

After deployment:

1. **Check logs** in Railway dashboard
2. **Test health endpoint**: `https://your-app.up.railway.app/`
3. **Test detailed health**: `https://your-app.up.railway.app/health`
4. **Test API endpoint**: `https://your-app.up.railway.app/api/clubs`

## **Available Features by Configuration**

### With MongoDB Only:
✅ **Health checks**  
✅ **Clubs data** (`/api/clubs`)  
✅ **Padel recommendations** (`/api/padel-recommendations`)  
✅ **Weather updates** (`/api/update-weather`)  
❌ **Subscriptions** (returns helpful error message)

### With MongoDB + Stripe:
✅ **All MongoDB features**  
✅ **Subscription checking** (`/api/check-subscription`)  
✅ **Subscription management** (create/cancel)  
✅ **Invoice management**

## **Troubleshooting**

### If Railway can't find files:
- Ensure **Root Directory** is set to `backend`
- Check that `requirements.txt` exists in `backend/`
- Verify `railway.toml` is in the `backend/` folder

### If imports fail:
- Make sure all Python modules are relative to the backend directory
- Check that `__init__.py` files exist in config, routes, and services

### Build fails:
- Check Railway build logs
- Ensure all dependencies are in `requirements.txt`
- Verify Python version compatibility

### Subscription endpoints return errors:
- This is expected if Stripe is not configured
- Check `/health` endpoint to see which features are available
- Add Stripe environment variables when ready

## **Recommended Approach**

**Use Method 1** (Root Path Configuration) because:
- ✅ Keeps your monorepo structure
- ✅ Automatic deployments on backend changes
- ✅ Easy to manage from Railway dashboard
- ✅ No need for separate repositories

## **Quick Start (Minimal Configuration)**

For testing without Stripe:

1. Set **Root Directory** to `backend` in Railway
2. Add only: `ATLAS_URI=your_mongodb_connection_string`
3. Deploy and test: `https://your-app-name.up.railway.app/health`

Your backend will be available at: `https://your-app-name.up.railway.app` 