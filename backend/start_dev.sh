#!/bin/bash

echo "🚀 Starting PadelTid Backend API..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install/update dependencies
echo "📚 Installing dependencies..."
pip install -r requirements.txt

# Check for environment variables
if [ -z "$ATLAS_URI" ]; then
    echo "⚠️  Warning: ATLAS_URI environment variable not set"
    echo "   Set it with: export ATLAS_URI='your_mongodb_connection_string'"
fi

if [ -z "$STRIPE_SECRET_KEY" ]; then
    echo "⚠️  Warning: STRIPE_SECRET_KEY environment variable not set"
    echo "   Set it with: export STRIPE_SECRET_KEY='your_stripe_secret_key'"
fi

echo ""
echo "✅ Backend API starting at: http://localhost:8000"
echo "📖 API Documentation: http://localhost:8000/docs"
echo "❤️  Health Check: http://localhost:8000/"
echo ""

# Start the server
python3 -m uvicorn main:app --reload --port 8000 