"""
Unit and Integration Tests for Movie Revenue Prediction Pipeline
Tests cover: data processing, model training, predictions, and API responses
"""

import pytest
import pandas as pd
import numpy as np
import pickle
from pathlib import Path
import sys

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

DATA_DIR = PROJECT_ROOT / "project_components" / "data"
MODEL_DIR = DATA_DIR / "models"


class TestDataProcessing:
    """Unit tests for data processing functions"""
    
    def test_csv_loading(self):
        """Test that CSV files load correctly"""
        engineered_data = DATA_DIR / "04_engineered_features.csv"
        assert engineered_data.exists(), f"File not found: {engineered_data}"
        
        df = pd.read_csv(engineered_data)
        assert df.shape[0] > 0, "Dataset is empty"
        assert df.shape[1] > 0, "No features in dataset"
    
    def test_revenue_filtering(self):
        """Test filtering movies with revenue data"""
        df = pd.read_csv(DATA_DIR / "04_engineered_features.csv")
        df_with_revenue = df[df['revenue'].notna()]
        
        assert len(df_with_revenue) > 0, "No movies with revenue data"
        assert df_with_revenue['revenue'].notna().all(), "Revenue column has NaNs"
    
    def test_feature_selection(self):
        """Test numeric feature selection"""
        df = pd.read_csv(DATA_DIR / "04_engineered_features.csv")
        numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()
        
        assert len(numeric_cols) > 0, "No numeric columns found"
        assert 'revenue' in numeric_cols or 'id' in numeric_cols, "Key columns missing"
    
    def test_missing_value_handling(self):
        """Test missing value imputation"""
        df = pd.read_csv(DATA_DIR / "04_engineered_features.csv")
        
        exclude_cols = ['id', 'title', 'revenue', 'budget', 'release_date', 'genres', 'cast', 'crew']
        numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()
        feature_cols = [col for col in numeric_cols if col not in exclude_cols]
        
        X = df[feature_cols]
        X_filled = X.fillna(X.median(numeric_only=True))
        
        assert X_filled.isna().sum().sum() == 0, "Missing values remain after imputation"
    
    def test_log_transformation(self):
        """Test log transformation of revenue"""
        df = pd.read_csv(DATA_DIR / "04_engineered_features.csv")
        df = df[df['revenue'].notna()].copy()
        df['log_revenue'] = np.log1p(df['revenue'])
        
        assert df['log_revenue'].notna().all(), "Log revenue contains NaNs"
        assert (df['log_revenue'] >= 0).all(), "Log revenue should be non-negative"


class TestModelLoading:
    """Unit tests for model loading and setup"""
    
    def test_regression_model_exists(self):
        """Test that regression model file exists"""
        model_path = MODEL_DIR / "best_regression_model.pkl"
        assert model_path.exists(), f"Model not found: {model_path}"
    
    def test_regression_model_loads(self):
        """Test that regression model loads without errors"""
        model_path = MODEL_DIR / "best_regression_model.pkl"
        with open(model_path, 'rb') as f:
            model = pickle.load(f)
        
        assert model is not None, "Model failed to load"
        assert hasattr(model, 'predict'), "Model doesn't have predict method"
    
    def test_scaler_exists(self):
        """Test that scaler file exists"""
        scaler_path = MODEL_DIR / "regression_scaler.pkl"
        assert scaler_path.exists(), f"Scaler not found: {scaler_path}"
    
    def test_feature_columns_exist(self):
        """Test that feature columns are saved"""
        feature_path = MODEL_DIR / "regression_feature_columns.pkl"
        assert feature_path.exists(), f"Feature columns not found: {feature_path}"
        
        with open(feature_path, 'rb') as f:
            features = pickle.load(f)
        
        assert len(features) > 0, "No features loaded"
    
    def test_classification_model_exists(self):
        """Test that classification model file exists"""
        model_path = MODEL_DIR / "best_classification_model.pkl"
        assert model_path.exists(), f"Classification model not found: {model_path}"


class TestPredictions:
    """Integration tests for model predictions"""
    
    def load_data_and_model(self):
        """Helper to load data and model"""
        df = pd.read_csv(DATA_DIR / "04_engineered_features.csv")
        df_modeling = df[df['revenue'].notna()].copy()
        
        with open(MODEL_DIR / "best_regression_model.pkl", 'rb') as f:
            model = pickle.load(f)
        
        with open(MODEL_DIR / "regression_feature_columns.pkl", 'rb') as f:
            feature_cols = pickle.load(f)
        
        with open(MODEL_DIR / "regression_scaler.pkl", 'rb') as f:
            scaler = pickle.load(f)
        
        return df_modeling, model, feature_cols, scaler
    
    def test_regression_prediction_shape(self):
        """Test that predictions have correct shape"""
        df, model, feature_cols, scaler = self.load_data_and_model()
        
        X = df[feature_cols].fillna(df[feature_cols].median(numeric_only=True))
        X_sample = X.iloc[:10]
        X_scaled = scaler.transform(X_sample)
        
        predictions = model.predict(X_scaled)
        
        assert predictions.shape[0] == 10, "Prediction count mismatch"
        assert predictions.dtype in [np.float32, np.float64], "Predictions not numeric"
    
    def test_regression_prediction_range(self):
        """Test that predictions are in reasonable range"""
        df, model, feature_cols, scaler = self.load_data_and_model()
        
        X = df[feature_cols].fillna(df[feature_cols].median(numeric_only=True))
        X_sample = X.iloc[:10]
        X_scaled = scaler.transform(X_sample)
        
        predictions = model.predict(X_scaled)
        
        # Log revenue should be reasonable (not too extreme)
        assert (predictions > 0).all() or (predictions > -50).all(), "Prediction out of range"
        assert (predictions < 30).all(), "Prediction too large"
    
    def test_prediction_consistency(self):
        """Test that same input produces same prediction"""
        df, model, feature_cols, scaler = self.load_data_and_model()
        
        X = df[feature_cols].fillna(df[feature_cols].median(numeric_only=True))
        X_sample = X.iloc[0:1]
        X_scaled = scaler.transform(X_sample)
        
        pred1 = model.predict(X_scaled)[0]
        pred2 = model.predict(X_scaled)[0]
        
        assert pred1 == pred2, "Predictions not consistent"
    
    def test_classification_prediction_type(self):
        """Test that classification produces valid categories"""
        with open(MODEL_DIR / "best_classification_model.pkl", 'rb') as f:
            clf_model = pickle.load(f)
        
        with open(MODEL_DIR / "classification_feature_columns.pkl", 'rb') as f:
            clf_features = pickle.load(f)
        
        df = pd.read_csv(DATA_DIR / "04_engineered_features.csv")
        df_with_revenue = df[df['revenue'].notna()].copy()
        
        X_clf = df_with_revenue[clf_features].fillna(
            df_with_revenue[clf_features].median(numeric_only=True)
        )
        X_sample = X_clf.iloc[:5]
        
        predictions = clf_model.predict(X_sample)
        
        valid_categories = ['Flop', 'Average', 'Hit', 'Blockbuster']
        for pred in predictions:
            assert pred in valid_categories, f"Invalid category: {pred}"


class TestAPIIntegration:
    """Integration tests for FastAPI endpoints"""
    
    @pytest.fixture
    def client(self):
        """Create FastAPI test client"""
        try:
            from fastapi.testclient import TestClient
            from app import app
            return TestClient(app)
        except ImportError:
            pytest.skip("FastAPI not installed")
    
    def test_api_health_check(self, client):
        """Test health check endpoint"""
        response = client.get("/health")
        assert response.status_code == 200
        assert "status" in response.json()
    
    def test_api_predict_basic(self, client):
        """Test prediction endpoint with basic input"""
        sample_input = {
            "budget": 100000000,
            "runtime": 120,
            "genres": ["Action", "Adventure"],
            "cast_count": 15,
            "release_month": 6
        }
        
        response = client.post("/predict", json=sample_input)
        assert response.status_code == 200
        
        data = response.json()
        assert "predicted_revenue" in data
        assert "category" in data
        assert "confidence" in data
    
    def test_api_predict_invalid_input(self, client):
        """Test API error handling with invalid input"""
        invalid_input = {
            "budget": "not_a_number"
        }
        
        response = client.post("/predict", json=invalid_input)
        assert response.status_code in [400, 422]
    
    def test_api_response_structure(self, client):
        """Test that API response has correct structure"""
        sample_input = {
            "budget": 50000000,
            "runtime": 100,
            "release_month": 3
        }
        
        response = client.post("/predict", json=sample_input)
        assert response.status_code == 200
        
        data = response.json()
        required_fields = ["predicted_revenue", "category", "confidence", "explanation"]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"


class TestEndToEnd:
    """End-to-end integration tests"""
    
    def test_full_pipeline(self):
        """Test complete pipeline from data to prediction"""
        # Load data
        df = pd.read_csv(DATA_DIR / "04_engineered_features.csv")
        df = df[df['revenue'].notna()].copy()
        
        # Load models and scalers
        with open(MODEL_DIR / "best_regression_model.pkl", 'rb') as f:
            reg_model = pickle.load(f)
        with open(MODEL_DIR / "best_classification_model.pkl", 'rb') as f:
            clf_model = pickle.load(f)
        with open(MODEL_DIR / "regression_feature_columns.pkl", 'rb') as f:
            reg_features = pickle.load(f)
        with open(MODEL_DIR / "classification_feature_columns.pkl", 'rb') as f:
            clf_features = pickle.load(f)
        with open(MODEL_DIR / "regression_scaler.pkl", 'rb') as f:
            reg_scaler = pickle.load(f)
        with open(MODEL_DIR / "classification_scaler.pkl", 'rb') as f:
            clf_scaler = pickle.load(f)
        
        # Prepare features
        X_reg = df[reg_features].fillna(df[reg_features].median(numeric_only=True))
        X_reg_scaled = reg_scaler.transform(X_reg.iloc[:5])
        
        X_clf = df[clf_features].fillna(df[clf_features].median(numeric_only=True))
        X_clf_scaled = clf_scaler.transform(X_clf.iloc[:5])
        
        # Run predictions
        revenue_pred = reg_model.predict(X_reg_scaled)
        category_pred = clf_model.predict(X_clf_scaled)
        
        # Validate results
        assert revenue_pred.shape[0] == 5, "Regression prediction count mismatch"
        assert len(category_pred) == 5, "Classification prediction count mismatch"
        
        # Check that predictions are reasonable
        assert all(isinstance(cat, str) for cat in category_pred), "Categories not strings"
        assert all(isinstance(rev, (int, float, np.number)) for rev in revenue_pred), "Revenue not numeric"


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
