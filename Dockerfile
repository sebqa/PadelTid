FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy backend requirements first (for better caching)
COPY backend/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend application code
COPY backend/ .

# Make startup script executable
RUN chmod +x start.sh

# Expose default port (Railway will override with PORT env var)
EXPOSE 8000

# Use startup script for better debugging
CMD ["./start.sh"] 