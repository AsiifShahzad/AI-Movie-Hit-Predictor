#!/bin/bash
# Build and push Docker image to AWS ECR

set -e

# Configuration
AWS_REGION="us-east-1"  # Change to your region
AWS_ACCOUNT_ID="YOUR_AWS_ACCOUNT_ID"  # Replace with your account ID
ECR_REPO_NAME="movie-revenue-predictor"
IMAGE_TAG="latest"

echo "🐳 Docker build and push script for AWS ECR"
echo "================================================"

# Step 1: Get AWS Account ID if not provided
if [ "$AWS_ACCOUNT_ID" = "YOUR_AWS_ACCOUNT_ID" ]; then
    echo "⚠️  Please update AWS_ACCOUNT_ID in this script"
    echo "Get your account ID: aws sts get-caller-identity --query Account"
    exit 1
fi

# Step 2: Create ECR repository if it doesn't exist
echo "📦 Checking ECR repository..."
aws ecr describe-repositories \
    --repository-names $ECR_REPO_NAME \
    --region $AWS_REGION 2>/dev/null || {
    echo "Creating ECR repository: $ECR_REPO_NAME"
    aws ecr create-repository \
        --repository-name $ECR_REPO_NAME \
        --region $AWS_REGION
}

# Step 3: Get ECR login token and login to Docker
echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Step 4: Build Docker image
echo "🔨 Building Docker image..."
docker build -t $ECR_REPO_NAME:$IMAGE_TAG .

# Step 5: Tag image for ECR
ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG"
echo "🏷️  Tagging image: $ECR_URI"
docker tag $ECR_REPO_NAME:$IMAGE_TAG $ECR_URI

# Step 6: Push to ECR
echo "📤 Pushing image to ECR..."
docker push $ECR_URI

echo ""
echo "✅ Docker image pushed successfully!"
echo "================================================"
echo "Image URI: $ECR_URI"
echo "Use this URI in AWS Lambda or ECS configuration"
