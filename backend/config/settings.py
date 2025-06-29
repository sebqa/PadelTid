import os
from typing import Optional

class Settings:
    def __init__(self):
        self.atlas_uri = os.environ.get("ATLAS_URI")
        self.stripe_secret_key = os.environ.get("STRIPE_SECRET_KEY")
        self.stripe_monthly_price_id = os.environ.get("STRIPE_MONTHLY_PRICE_ID")
        self.stripe_yearly_price_id = os.environ.get("STRIPE_YEARLY_PRICE_ID")
        self.port = int(os.environ.get("PORT", 8000))
        
    @property
    def stripe_price_ids(self):
        return {
            'monthly': self.stripe_monthly_price_id,
            'yearly': self.stripe_yearly_price_id
        }

# Singleton pattern
_settings: Optional[Settings] = None

def get_settings() -> Settings:
    global _settings
    if _settings is None:
        _settings = Settings()
    return _settings 