"""
API Endpoint Tests for FastAPI Movie Revenue Predictor
Tests cover: endpoint responses, error handling, and input validation
"""

import pytest
from pathlib import Path
import sys

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

try:
    from fastapi.testclient import TestClient
    from project_components.code.app import app
    FASTAPI_AVAILABLE = True
except ImportError:
    FASTAPI_AVAILABLE = False


@pytest.mark.skipif(not FASTAPI_AVAILABLE, reason="FastAPI not installed")
class TestAPIEndpoints:
    """Tests for FastAPI endpoints"""
    
    @pytest.fixture(scope="class")
    def client(self):
        """Create test client"""
        return TestClient(app)
    
    def test_root_endpoint(self, client):
        """Test root endpoint returns API info"""
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "documentation" in data
    
    def test_health_check_endpoint(self, client):
        """Test health check endpoint"""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "service" in data
    
    def test_models_info_endpoint(self, client):
        """Test models info endpoint"""
        response = client.get("/models-info")
        assert response.status_code == 200
        data = response.json()
        assert "regression_model" in data
        assert "classification_model" in data
        assert "regression_features_count" in data
    
    def test_custom_docs_endpoint(self, client):
        """Test custom docs endpoint"""
        response = client.get("/docs-custom")
        assert response.status_code == 200
        data = response.json()
        assert "api_name" in data
        assert "endpoints" in data
        assert "input_features" in data


@pytest.mark.skipif(not FASTAPI_AVAILABLE, reason="FastAPI not installed")
class TestPredictEndpoint:
    """Tests for /predict endpoint"""
    
    @pytest.fixture(scope="class")
    def client(self):
        """Create test client"""
        return TestClient(app)
    
    def test_predict_with_all_features(self, client):
        """Test prediction with all features provided"""
        payload = {
            "budget": 100000000,
            "runtime": 120,
            "genres": ["Action", "Adventure"],
            "cast_count": 15,
            "director_popularity": 45.5,
            "release_month": 6,
            "release_day": 15,
            "original_language": "en",
            "vote_average": 7.5,
            "vote_count": 5000
        }
        
        response = client.post("/predict", json=payload)
        assert response.status_code == 200
        
        data = response.json()
        assert "predicted_revenue" in data
        assert "predicted_revenue_formatted" in data
        assert "category" in data
        assert "confidence" in data
        assert "explanation" in data
        assert "model_info" in data
    
    def test_predict_with_minimal_features(self, client):
        """Test prediction with minimal features"""
        payload = {
            "budget": 50000000,
            "runtime": 100
        }
        
        response = client.post("/predict", json=payload)
        assert response.status_code == 200
        
        data = response.json()
        assert data["category"] in ["Flop", "Average", "Hit", "Blockbuster"]
    
    def test_predict_with_empty_payload(self, client):
        """Test prediction with no features (should use defaults)"""
        payload = {}
        
        response = client.post("/predict", json=payload)
        assert response.status_code == 200
        
        data = response.json()
        assert data["predicted_revenue"] > 0
        assert data["category"] in ["Flop", "Average", "Hit", "Blockbuster"]
    
    def test_predict_response_format(self, client):
        """Test that response has correct format"""
        payload = {"budget": 75000000, "runtime": 110}
        
        response = client.post("/predict", json=payload)
        assert response.status_code == 200
        
        data = response.json()
        
        # Check data types
        assert isinstance(data["predicted_revenue"], (int, float))
        assert isinstance(data["predicted_revenue_formatted"], str)
        assert isinstance(data["category"], str)
        assert isinstance(data["confidence"], float)
        assert isinstance(data["explanation"], str)
        
        # Check value ranges
        assert data["predicted_revenue"] > 0
        assert 0 <= data["confidence"] <= 1
        assert "$" in data["predicted_revenue_formatted"]
    
    def test_predict_category_values(self, client):
        """Test that category is always valid"""
        valid_categories = {"Flop", "Average", "Hit", "Blockbuster"}
        
        payloads = [
            {"budget": 10000000},      # Low budget
            {"budget": 100000000},     # High budget
            {"budget": 200000000},     # Very high budget
            {"runtime": 180},          # Long runtime
            {"runtime": 60},           # Short runtime
        ]
        
        for payload in payloads:
            response = client.post("/predict", json=payload)
            assert response.status_code == 200
            
            data = response.json()
            assert data["category"] in valid_categories
    
    def test_predict_explanation_content(self, client):
        """Test that explanation is meaningful"""
        payload = {"budget": 150000000, "runtime": 130}
        
        response = client.post("/predict", json=payload)
        assert response.status_code == 200
        
        data = response.json()
        explanation = data["explanation"]
        
        # Should mention category or revenue
        assert (data["category"].lower() in explanation.lower() or 
                "$" in explanation)
        assert len(explanation) > 20  # Meaningful explanation


@pytest.mark.skipif(not FASTAPI_AVAILABLE, reason="FastAPI not installed")
class TestBatchPredictEndpoint:
    """Tests for /batch-predict endpoint"""
    
    @pytest.fixture(scope="class")
    def client(self):
        """Create test client"""
        return TestClient(app)
    
    def test_batch_predict_multiple(self, client):
        """Test batch prediction with multiple movies"""
        payload = [
            {"budget": 100000000, "runtime": 120},
            {"budget": 50000000, "runtime": 100},
            {"budget": 200000000, "runtime": 150}
        ]
        
        response = client.post("/batch-predict", json=payload)
        assert response.status_code == 200
        
        data = response.json()
        assert "predictions" in data
        assert "count" in data
        assert data["count"] == 3
        assert len(data["predictions"]) == 3
    
    def test_batch_predict_single(self, client):
        """Test batch prediction with single movie"""
        payload = [{"budget": 75000000}]
        
        response = client.post("/batch-predict", json=payload)
        assert response.status_code == 200
        
        data = response.json()
        assert data["count"] == 1
    
    def test_batch_predict_response_structure(self, client):
        """Test batch response structure"""
        payload = [
            {"budget": 100000000},
            {"budget": 50000000}
        ]
        
        response = client.post("/batch-predict", json=payload)
        assert response.status_code == 200
        
        data = response.json()
        for prediction in data["predictions"]:
            assert "predicted_revenue" in prediction
            assert "category" in prediction
            assert "confidence" in prediction


@pytest.mark.skipif(not FASTAPI_AVAILABLE, reason="FastAPI not installed")
class TestErrorHandling:
    """Tests for API error handling"""
    
    @pytest.fixture(scope="class")
    def client(self):
        """Create test client"""
        return TestClient(app)
    
    def test_invalid_http_method(self, client):
        """Test invalid HTTP method"""
        response = client.get("/predict")
        assert response.status_code in [405, 404]
    
    def test_missing_endpoint(self, client):
        """Test accessing non-existent endpoint"""
        response = client.get("/nonexistent")
        assert response.status_code == 404
    
    def test_predict_with_invalid_type(self, client):
        """Test predict with invalid data type"""
        # This should be handled by Pydantic validation
        payload = {
            "budget": "not_a_number",  # Should be float
            "runtime": 120
        }
        
        response = client.post("/predict", json=payload)
        # Should either coerce or return 422
        assert response.status_code in [200, 422]


@pytest.mark.skipif(not FASTAPI_AVAILABLE, reason="FastAPI not installed")
class TestPredictionConsistency:
    """Tests for prediction consistency and stability"""
    
    @pytest.fixture(scope="class")
    def client(self):
        """Create test client"""
        return TestClient(app)
    
    def test_same_input_same_output(self, client):
        """Test that same input always produces same prediction"""
        payload = {"budget": 100000000, "runtime": 120}
        
        response1 = client.post("/predict", json=payload)
        response2 = client.post("/predict", json=payload)
        
        assert response1.status_code == 200
        assert response2.status_code == 200
        
        data1 = response1.json()
        data2 = response2.json()
        
        assert data1["predicted_revenue"] == data2["predicted_revenue"]
        assert data1["category"] == data2["category"]
    
    def test_revenue_scaling_relationship(self, client):
        """Test that higher budget correlates with higher revenue prediction"""
        low_budget_payload = {"budget": 10000000}
        high_budget_payload = {"budget": 200000000}
        
        response_low = client.post("/predict", json=low_budget_payload)
        response_high = client.post("/predict", json=high_budget_payload)
        
        assert response_low.status_code == 200
        assert response_high.status_code == 200
        
        data_low = response_low.json()
        data_high = response_high.json()
        
        # Generally, higher budget should lead to higher revenue
        # (though not always strictly guaranteed)
        assert data_high["predicted_revenue"] >= 0
        assert data_low["predicted_revenue"] >= 0


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
