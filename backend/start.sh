#!/bin/bash

echo "🚀 Starting PadelTid Backend..."
echo "📊 Environment Check:"
echo "  - PORT: ${PORT:-8000}"
echo "  - ATLAS_URI: ${ATLAS_URI:+SET}"
echo "  - STRIPE_SECRET_KEY: ${STRIPE_SECRET_KEY:+SET}"
echo "  - Working Directory: $(pwd)"
echo "  - Python Version: $(python3 --version)"

echo ""
echo "📁 Files in current directory:"
ls -la

echo ""
echo "🧪 Testing Python imports..."
python3 -c "
try:
    from main import app
    print('✅ Main app imports successfully')
except Exception as e:
    print(f'❌ Import error: {e}')
    import traceback
    traceback.print_exc()
"

echo ""
echo "🌐 Starting server on port ${PORT:-8000}..."

# Start uvicorn with more robust settings for Railway
exec uvicorn main:app \
    --host 0.0.0.0 \
    --port ${PORT:-8000} \
    --log-level info \
    --access-log \
    --timeout-keep-alive 30 