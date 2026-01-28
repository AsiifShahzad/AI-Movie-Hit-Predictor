"""
FastAPI Application for Movie Revenue Prediction and Classification
Provides /predict endpoint that returns revenue prediction and movie category
"""

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import List, Optional
import pickle
import numpy as np
import pandas as pd
from pathlib import Path
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Movie Revenue Predictor API",
    description="Predict movie revenue and classify as Flop/Average/Hit/Blockbuster",
    version="1.0.0"
)

# Project paths
PROJECT_ROOT = Path(__file__).parent.parent.parent  # Go up to: code -> project_components -> AI-Movie-Hit-Predictor
DATA_DIR = PROJECT_ROOT / "project_components" / "data"
MODEL_DIR = DATA_DIR / "models"

# Global model cache
_models_cache = {}


def load_models():
    """Load all models and scalers from disk"""
    global _models_cache
    
    if _models_cache:
        return _models_cache
    
    try:
        logger.info("Loading regression model...")
        with open(MODEL_DIR / "best_regression_model.pkl", 'rb') as f:
            _models_cache['reg_model'] = pickle.load(f)
        
        logger.info("Loading classification model...")
        with open(MODEL_DIR / "best_classification_model.pkl", 'rb') as f:
            _models_cache['clf_model'] = pickle.load(f)
        
        logger.info("Loading regression scaler...")
        with open(MODEL_DIR / "regression_scaler.pkl", 'rb') as f:
            _models_cache['reg_scaler'] = pickle.load(f)
        
        logger.info("Loading classification scaler...")
        with open(MODEL_DIR / "classification_scaler.pkl", 'rb') as f:
            _models_cache['clf_scaler'] = pickle.load(f)
        
        logger.info("Loading feature columns...")
        with open(MODEL_DIR / "regression_feature_columns.pkl", 'rb') as f:
            _models_cache['reg_features'] = pickle.load(f)
        
        with open(MODEL_DIR / "classification_feature_columns.pkl", 'rb') as f:
            _models_cache['clf_features'] = pickle.load(f)
        
        logger.info("Loading category definitions...")
        with open(MODEL_DIR / "category_definitions.pkl", 'rb') as f:
            _models_cache['category_defs'] = pickle.load(f)
        
        logger.info("Models loaded successfully")
        return _models_cache
        
    except FileNotFoundError as e:
        logger.error(f"Model file not found: {e}")
        raise RuntimeError(f"Failed to load models: {e}")


# Input model for predictions
class MovieFeatures(BaseModel):
    """Movie features for prediction"""
    budget: Optional[float] = None
    runtime: Optional[float] = None
    genres: Optional[List[str]] = None
    cast_count: Optional[float] = None
    director_popularity: Optional[float] = None
    release_month: Optional[int] = None
    release_day: Optional[int] = None
    original_language: Optional[str] = None
    vote_average: Optional[float] = None
    vote_count: Optional[float] = None
    
    class Config:
        schema_extra = {
            "example": {
                "budget": 100000000,
                "runtime": 120,
                "genres": ["Action", "Adventure"],
                "cast_count": 15,
                "release_month": 6
            }
        }


# Output model for predictions
class PredictionResponse(BaseModel):
    """Prediction response model"""
    predicted_revenue: float
    predicted_revenue_formatted: str
    category: str
    confidence: float
    explanation: str
    model_info: dict


@app.on_event("startup")
async def startup_event():
    """Load models on startup"""
    try:
        load_models()
        logger.info("Application startup complete - models loaded")
    except Exception as e:
        logger.error(f"Failed to load models on startup: {e}")


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "Movie Revenue Predictor API",
        "version": "1.0.0"
    }


@app.get("/models-info")
async def models_info():
    """Get information about loaded models"""
    try:
        models = load_models()
        return {
            "regression_model": str(models['reg_model'].__class__.__name__),
            "classification_model": str(models['clf_model'].__class__.__name__),
            "regression_features_count": len(models['reg_features']),
            "classification_features_count": len(models['clf_features']),
            "categories": models.get('category_defs', {}).get('categories', [])
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/predict", response_model=PredictionResponse)
async def predict(features: MovieFeatures):
    """
    Predict movie revenue and category
    
    Takes movie features as input and returns:
    - Predicted revenue (in dollars)
    - Movie category (Flop/Average/Hit/Blockbuster)
    - Confidence score (0-1)
    - Explanation of prediction
    """
    try:
        models = load_models()
        
        # Load sample data for feature consistency
        df_engineered = pd.read_csv(DATA_DIR / "04_engineered_features.csv")
        
        # Prepare input features
        input_dict = features.dict()
        
        # Create feature vector for regression
        feature_vector = {}
        for feat in models['reg_features']:
            if feat in input_dict and input_dict[feat] is not None:
                feature_vector[feat] = input_dict[feat]
            else:
                # Use median from training data as default
                if feat in df_engineered.select_dtypes(include=[np.number]).columns:
                    feature_vector[feat] = df_engineered[feat].median()
                else:
                    feature_vector[feat] = 0
        
        # Create DataFrame with correct column order
        X_reg = pd.DataFrame([feature_vector])[models['reg_features']]
        
        # Scale and predict revenue
        X_reg_scaled = models['reg_scaler'].transform(X_reg)
        log_revenue_pred = models['reg_model'].predict(X_reg_scaled)[0]
        predicted_revenue = np.expm1(log_revenue_pred)
        
        # Prepare input for classification
        feature_vector_clf = {}
        for feat in models['clf_features']:
            if feat in input_dict and input_dict[feat] is not None:
                feature_vector_clf[feat] = input_dict[feat]
            else:
                if feat in df_engineered.select_dtypes(include=[np.number]).columns:
                    feature_vector_clf[feat] = df_engineered[feat].median()
                else:
                    feature_vector_clf[feat] = 0
        
        # Create DataFrame with correct column order
        X_clf = pd.DataFrame([feature_vector_clf])[models['clf_features']]
        
        # Scale and predict category
        X_clf_scaled = models['clf_scaler'].transform(X_clf)
        category_pred_numeric = models['clf_model'].predict(X_clf_scaled)[0]
        
        # Decode numeric prediction to category name
        category_map = {0: 'Flop', 1: 'Average', 2: 'Hit', 3: 'Blockbuster'}
        category_pred = category_map.get(int(category_pred_numeric), 'Average')
        
        # Get confidence (use prediction probabilities if available)
        try:
            proba = models['clf_model'].predict_proba(X_clf_scaled)[0]
            confidence = float(np.max(proba))
        except:
            confidence = 0.85  # Default confidence if probabilities not available
        
        # Format currency
        revenue_formatted = f"${predicted_revenue:,.2f}"
        
        # Create explanation
        category_defs = models.get('category_defs', {})
        thresholds = category_defs.get('thresholds', {})
        
        if category_pred == 'Blockbuster':
            explanation = f"Strong performer with predicted revenue {revenue_formatted}. Excellent box office potential."
        elif category_pred == 'Hit':
            explanation = f"Solid performer with predicted revenue {revenue_formatted}. Good commercial potential."
        elif category_pred == 'Average':
            explanation = f"Moderate performer with predicted revenue {revenue_formatted}. Meeting market expectations."
        else:  # Flop
            explanation = f"Predicted revenue {revenue_formatted}. Below average commercial performance expected."
        
        logger.info(f"Prediction: {category_pred} with revenue ${predicted_revenue:,.2f}")
        
        return PredictionResponse(
            predicted_revenue=float(predicted_revenue),
            predicted_revenue_formatted=revenue_formatted,
            category=category_pred,
            confidence=min(confidence, 1.0),
            explanation=explanation,
            model_info={
                "regression_model": str(models['reg_model'].__class__.__name__),
                "classification_model": str(models['clf_model'].__class__.__name__),
                "features_used_regression": len(models['reg_features']),
                "features_used_classification": len(models['clf_features'])
            }
        )
        
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")


@app.post("/batch-predict")
async def batch_predict(movies: List[MovieFeatures]):
    """
    Batch predict for multiple movies
    
    Args:
        movies: List of MovieFeatures objects
        
    Returns:
        List of prediction responses
    """
    try:
        predictions = []
        for movie in movies:
            # Reuse the predict function for each movie
            prediction = await predict(movie)
            predictions.append(prediction)
        
        return {"predictions": predictions, "count": len(predictions)}
        
    except Exception as e:
        logger.error(f"Batch prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Batch prediction failed: {str(e)}")


@app.get("/docs-custom")
async def custom_docs():
    """Custom documentation"""
    return {
        "api_name": "Movie Revenue Predictor",
        "version": "1.0.0",
        "endpoints": {
            "/health": "Check API health status",
            "/models-info": "Get information about loaded models",
            "/predict": "Predict revenue and category for a single movie",
            "/batch-predict": "Predict for multiple movies",
            "/docs": "Interactive API documentation (Swagger UI)"
        },
        "input_features": [
            "budget", "runtime", "genres", "cast_count", "director_popularity",
            "release_month", "release_day", "original_language", "vote_average", "vote_count"
        ],
        "output_categories": ["Flop", "Average", "Hit", "Blockbuster"],
        "notes": "All features are optional; missing values use median from training data"
    }


@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "message": "Movie Revenue Prediction API",
        "documentation": "/docs",
        "health_check": "/health",
        "models_info": "/models-info"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
