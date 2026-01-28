import sys
from pathlib import Path
import json

# Add project root to path
PROJECT_ROOT = Path(__file__).parent
sys.path.insert(0, str(PROJECT_ROOT))

def print_header(text):
    """Print formatted header"""
    print(f"\n{'='*60}")
    print(f"  {text}")
    print(f"{'='*60}\n")

def check_file_exists(filepath, description):
    """Check if file exists"""
    if Path(filepath).exists():
        size = Path(filepath).stat().st_size / (1024 * 1024)  # MB
        print(f"  ✓ {description}")
        if size > 0:
            print(f"    Size: {size:.2f} MB")
        return True
    else:
        print(f"  ✗ {description} - FILE NOT FOUND")
        return False

def validate_imports():
    """Validate all required packages can be imported"""
    print_header("CHECKING DEPENDENCIES")
    
    packages = {
        'pandas': 'Data manipulation',
        'numpy': 'Numerical computing',
        'sklearn': 'Machine learning (scikit-learn)',
        'xgboost': 'XGBoost models',
        'lightgbm': 'LightGBM models',
        'shap': 'SHAP explanations',
        'fastapi': 'FastAPI framework',
        'pydantic': 'Data validation',
    }
    
    missing = []
    for package, description in packages.items():
        try:
            __import__(package)
            print(f"  ✓ {package}: {description}")
        except ImportError:
            print(f"  ✗ {package}: {description} - NOT INSTALLED")
            missing.append(package)
    
    return len(missing) == 0, missing

def validate_data_files():
    """Validate all data files exist"""
    print_header("CHECKING DATA FILES")
    
    data_dir = PROJECT_ROOT / "project_components" / "data"
    files = {
        data_dir / "04_engineered_features.csv": "Engineered features dataset",
    }
    
    all_exist = True
    for filepath, description in files.items():
        if not check_file_exists(filepath, description):
            all_exist = False
    
    return all_exist

def validate_model_files():
    """Validate all model files exist"""
    print_header("CHECKING MODEL FILES")
    
    model_dir = PROJECT_ROOT / "project_components" / "data" / "models"
    files = {
        model_dir / "best_regression_model.pkl": "Best regression model",
        model_dir / "best_classification_model.pkl": "Best classification model",
        model_dir / "regression_scaler.pkl": "Regression scaler",
        model_dir / "classification_scaler.pkl": "Classification scaler",
        model_dir / "regression_feature_columns.pkl": "Regression feature columns",
        model_dir / "classification_feature_columns.pkl": "Classification feature columns",
        model_dir / "category_definitions.pkl": "Category definitions",
    }
    
    all_exist = True
    for filepath, description in files.items():
        if not check_file_exists(filepath, description):
            all_exist = False
    
    return all_exist

def validate_code_files():
    """Validate all code files exist"""
    print_header("CHECKING CODE FILES")
    
    code_dir = PROJECT_ROOT / "project_components" / "code"
    files = {
        code_dir / "app.py": "FastAPI application",
        code_dir / "05_regression_models.ipynb": "Regression models notebook",
        code_dir / "06_classification_models.ipynb": "Classification models notebook",
        code_dir / "07_shap_feature_importance.ipynb": "SHAP analysis notebook",
    }
    
    all_exist = True
    for filepath, description in files.items():
        if not check_file_exists(filepath, description):
            all_exist = False
    
    return all_exist

def validate_test_files():
    """Validate test files exist"""
    print_header("CHECKING TEST FILES")
    
    test_dir = PROJECT_ROOT / "tests"
    files = {
        test_dir / "test_pipeline.py": "Pipeline tests",
        test_dir / "test_api.py": "API tests",
    }
    
    all_exist = True
    for filepath, description in files.items():
        if not check_file_exists(filepath, description):
            all_exist = False
    
    return all_exist

def validate_config_files():
    """Validate configuration files"""
    print_header("CHECKING CONFIGURATION FILES")
    
    files = {
        PROJECT_ROOT / "requirements.txt": "Requirements file",
        PROJECT_ROOT / "SETUP_GUIDE.txt": "Setup guide",
        PROJECT_ROOT / "QUICK_START.txt": "Quick start guide",
    }
    
    all_exist = True
    for filepath, description in files.items():
        if not check_file_exists(filepath, description):
            all_exist = False
    
    return all_exist

def test_data_loading():
    """Test if data can be loaded"""
    print_header("TESTING DATA LOADING")
    
    try:
        import pandas as pd
        import numpy as np
        
        data_path = PROJECT_ROOT / "project_components" / "data" / "04_engineered_features.csv"
        df = pd.read_csv(data_path)
        
        print(f"  ✓ Dataset loaded successfully")
        print(f"    Shape: {df.shape[0]} rows × {df.shape[1]} columns")
        print(f"    Memory: {df.memory_usage().sum() / (1024**2):.2f} MB")
        
        # Check for required columns
        if 'revenue' in df.columns:
            non_null = df['revenue'].notna().sum()
            print(f"  ✓ Revenue column found ({non_null} non-null values)")
        else:
            print(f"  ✗ Revenue column not found")
            return False
        
        return True
    except Exception as e:
        print(f"  ✗ Error loading data: {str(e)}")
        return False

def test_model_loading():
    """Test if models can be loaded"""
    print_header("TESTING MODEL LOADING")
    
    try:
        import pickle
        
        model_dir = PROJECT_ROOT / "project_components" / "data" / "models"
        
        # Test regression model
        with open(model_dir / "best_regression_model.pkl", 'rb') as f:
            reg_model = pickle.load(f)
        print(f"  ✓ Regression model loaded: {reg_model.__class__.__name__}")
        
        # Test classification model
        with open(model_dir / "best_classification_model.pkl", 'rb') as f:
            clf_model = pickle.load(f)
        print(f"  ✓ Classification model loaded: {clf_model.__class__.__name__}")
        
        # Test scalers
        with open(model_dir / "regression_scaler.pkl", 'rb') as f:
            reg_scaler = pickle.load(f)
        print(f"  ✓ Regression scaler loaded")
        
        with open(model_dir / "classification_scaler.pkl", 'rb') as f:
            clf_scaler = pickle.load(f)
        print(f"  ✓ Classification scaler loaded")
        
        return True
    except Exception as e:
        print(f"  ✗ Error loading models: {str(e)}")
        return False

def test_api_startup():
    """Test if API can start"""
    print_header("TESTING API STARTUP")
    
    try:
        from fastapi.testclient import TestClient
        from project_components.code.app import app
        
        client = TestClient(app)
        
        # Test health endpoint
        response = client.get("/health")
        if response.status_code == 200:
            data = response.json()
            print(f"  ✓ Health check successful")
            print(f"    Status: {data['status']}")
            print(f"    Service: {data['service']}")
        else:
            print(f"  ✗ Health check failed with status {response.status_code}")
            return False
        
        # Test models info endpoint
        response = client.get("/models-info")
        if response.status_code == 200:
            print(f"  ✓ Models info endpoint working")
        else:
            print(f"  ✗ Models info failed with status {response.status_code}")
            return False
        
        return True
    except Exception as e:
        print(f"  ✗ Error testing API: {str(e)}")
        return False

def test_prediction():
    """Test if predictions work"""
    print_header("TESTING PREDICTIONS")
    
    try:
        from fastapi.testclient import TestClient
        from project_components.code.app import app
        
        client = TestClient(app)
        
        payload = {
            "budget": 100000000,
            "runtime": 120,
            "cast_count": 15,
            "release_month": 6
        }
        
        response = client.post("/predict", json=payload)
        
        if response.status_code == 200:
            data = response.json()
            print(f"  ✓ Prediction successful")
            print(f"    Revenue: {data['predicted_revenue_formatted']}")
            print(f"    Category: {data['category']}")
            print(f"    Confidence: {data['confidence']:.2%}")
            return True
        else:
            print(f"  ✗ Prediction failed with status {response.status_code}")
            print(f"    Error: {response.json().get('detail', 'Unknown error')}")
            return False
    except Exception as e:
        print(f"  ✗ Error testing prediction: {str(e)}")
        return False

def main():
    
    results = {
        "Dependencies": validate_imports()[0],
        "Data Files": validate_data_files(),
        "Model Files": validate_model_files(),
        "Code Files": validate_code_files(),
        "Test Files": validate_test_files(),
        "Configuration Files": validate_config_files(),
        "Data Loading": test_data_loading(),
        "Model Loading": test_model_loading(),
        "API Startup": test_api_startup(),
        "Predictions": test_prediction(),
    }
    
    # Summary
    print_header("VALIDATION SUMMARY")
    
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    
    for check, result in results.items():
        status = "✓ PASS" if result else "✗ FAIL"
        print(f"  {status}: {check}")
    
    print(f"\nTotal: {passed}/{total} checks passed")
    
    if passed == total:
        print("\n All validations passed! System is ready to use.")
        print("\nNext steps:")
        print("  1. Run tests: pytest tests/ -v")
        print("  2. Start API: python project_components/code/app.py")
        print("  3. Access docs: http://localhost:8000/docs")
        return 0
    else:
        print(f"\n {total - passed} validation(s) failed. Please review above.")
        print("See SETUP_GUIDE.txt for troubleshooting steps.")
        return 1
4333334
if __name__ == "__main__":
    sys.exit(main())
