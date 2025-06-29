# Railway Deployment Troubleshooting

## ❌ **Your Issue: Healthcheck Failed**

The error you're seeing indicates the app isn't responding to health checks. Here's how to fix it:

## 🔧 **Immediate Fixes**

### 1. **Check Environment Variables in Railway**
Go to your Railway project → **Variables** and ensure these are set:

```
ATLAS_URI=mongodb+srv://username:password@cluster.mongodb.net/
STRIPE_SECRET_KEY=sk_test_your_stripe_key_here
STRIPE_MONTHLY_PRICE_ID=price_your_monthly_id
STRIPE_YEARLY_PRICE_ID=price_your_yearly_id
```

### 2. **Verify Root Directory Setting**
In Railway Dashboard:
- Go to **Settings** → **General**
- Set **Root Directory** to: `backend`
- Click **Save** and redeploy

### 3. **Check Build/Deploy Settings**
In Railway Dashboard → **Settings** → **Deploy**:
- **Build Command**: `pip install --no-cache-dir -r requirements.txt`
- **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`

## 🔍 **Debug Your Deployment**

### Step 1: Check Railway Logs
1. Go to Railway Dashboard
2. Click on your service
3. Go to **Deployments** tab
4. Click on the failed deployment
5. Check **Build Logs** and **Deploy Logs**

### Step 2: Test Health Endpoints
Once deployed, test these URLs:
- `https://your-app.up.railway.app/` - Basic health check
- `https://your-app.up.railway.app/health` - Detailed health with database status
- `https://your-app.up.railway.app/readiness` - Readiness check

### Step 3: Common Log Errors and Solutions

**"ModuleNotFoundError"**
```
Solution: Ensure requirements.txt includes all dependencies
Check: Root directory is set to 'backend'
```

**"Database connection failed"**  
```
Solution: Verify ATLAS_URI environment variable
Check: MongoDB Atlas allows Railway IP addresses
Test: Connection string works from your local machine
```

**"Stripe initialization failed"**
```
Solution: Verify STRIPE_SECRET_KEY environment variable
Check: Key starts with 'sk_test_' or 'sk_live_'
```

**"Port binding failed"**
```
Solution: Ensure uvicorn uses --port $PORT (not hardcoded port)
Check: App binds to 0.0.0.0, not localhost
```

## 🚀 **Quick Deploy Test**

### Local Test First:
```bash
cd backend

# Set environment variables
export ATLAS_URI="your_mongodb_uri"
export STRIPE_SECRET_KEY="your_stripe_key"

# Test locally
python3 -m uvicorn main:app --host 0.0.0.0 --port 8000

# Test health endpoint
curl http://localhost:8000/
curl http://localhost:8000/health
```

### If Local Works But Railway Fails:
1. **Double-check environment variables** in Railway
2. **Verify Root Directory** is set to `backend`
3. **Check MongoDB Atlas** allows Railway's IP ranges
4. **Review Railway logs** for specific error messages

## 🔧 **Updated Configuration**

I've updated your configuration to be more robust:

### Railway Configuration (`railway.toml`):
- ✅ Increased healthcheck timeout to 30 seconds
- ✅ Reduced max retries to prevent endless loops
- ✅ Proper build command configuration

### Application Updates:
- ✅ Database initialization won't crash the app
- ✅ Health check always responds (even if DB is down)
- ✅ Detailed health endpoint shows database status
- ✅ Better error logging and handling

## 🆘 **Still Having Issues?**

### Enable Debug Mode:
Add to Railway environment variables:
```
DEBUG=true
LOG_LEVEL=DEBUG
```

### Check These Common Issues:
1. **Wrong Python version** - Railway uses Python 3.11 by default
2. **Missing dependencies** - Check if all imports are in requirements.txt
3. **MongoDB timeout** - Atlas may have connection limits
4. **Stripe API limits** - Check if your Stripe key is valid

### Railway-Specific Checks:
1. **Service region** - Ensure it's close to your MongoDB region
2. **Resource limits** - Check if you're hitting memory/CPU limits
3. **Network policies** - Verify outbound connections are allowed

Your app should now start successfully even if the database connection fails initially! 