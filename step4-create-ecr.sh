#!/bin/bash
# Step 4: Create ECR Repository

set -e

echo "📦 Step 4: Create ECR Repository"
echo "================================="
echo ""

# Load environment variables if .env exists
if [ -f .env ]; then
    echo "Loading environment variables from .env..."
    source .env
else
    echo "⚠️  .env file not found. Run step3-get-account-id.sh first."
    echo ""
    echo "Using default values or environment variables..."
fi

# Set defaults if not set
AWS_REGION="${AWS_REGION:-us-east-1}"
ECR_REPO_NAME="${ECR_REPO_NAME:-movie-revenue-predictor}"

echo "Configuration:"
echo "  Region: $AWS_REGION"
echo "  Repository Name: $ECR_REPO_NAME"
echo ""

# Check if repository already exists
echo "Checking if ECR repository exists..."
if aws ecr describe-repositories \
    --repository-names $ECR_REPO_NAME \
    --region $AWS_REGION &> /dev/null; then
    
    echo "✅ ECR repository '$ECR_REPO_NAME' already exists!"
    echo ""
    
    # Get repository URI
    REPO_URI=$(aws ecr describe-repositories \
        --repository-names $ECR_REPO_NAME \
        --region $AWS_REGION \
        --query 'repositories[0].repositoryUri' \
        --output text)
    
    echo "Repository URI: $REPO_URI"
    echo ""
else
    echo "Creating ECR repository '$ECR_REPO_NAME'..."
    
    # Create the repository
    CREATE_OUTPUT=$(aws ecr create-repository \
        --repository-name $ECR_REPO_NAME \
        --region $AWS_REGION \
        --image-scanning-configuration scanOnPush=true \
        --output json)
    
    if [ $? -eq 0 ]; then
        echo "✅ ECR repository created successfully!"
        echo ""
        
        # Extract and display repository URI
        REPO_URI=$(echo $CREATE_OUTPUT | grep -o '"repositoryUri": "[^"]*' | cut -d'"' -f4)
        echo "Repository URI: $REPO_URI"
        echo ""
        
        # Display full details
        echo "📋 Repository Details:"
        echo "────────────────────────────────────────"
        echo $CREATE_OUTPUT | python3 -m json.tool
        echo "────────────────────────────────────────"
        echo ""
    else
        echo "❌ Failed to create ECR repository"
        exit 1
    fi
fi

# List images in repository (if any)
echo "Checking for existing images..."
IMAGE_COUNT=$(aws ecr describe-images \
    --repository-name $ECR_REPO_NAME \
    --region $AWS_REGION \
    --query 'length(imageDetails)' \
    --output text 2>/dev/null || echo "0")

if [ "$IMAGE_COUNT" -gt 0 ]; then
    echo "Found $IMAGE_COUNT image(s) in repository"
    echo ""
    echo "Latest images:"
    aws ecr describe-images \
        --repository-name $ECR_REPO_NAME \
        --region $AWS_REGION \
        --query 'sort_by(imageDetails, &imagePushedAt)[-3:]' \
        --output table
else
    echo "No images found in repository (this is expected for new repositories)"
fi

echo ""
echo "✅ Step 4 complete!"
echo ""
echo "Next step: Run bash step5-push-to-ecr.sh"
echo ""
