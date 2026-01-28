#!/bin/bash
# Rebuild and push updated Docker image with Lambda support

echo "🔄 Rebuilding Docker Image with Lambda Support"
echo "=============================================="
echo ""

source .env

echo "Changes made:"
echo "  ✅ Added Mangum to requirements.txt"
echo "  ✅ Added Lambda handler to app.py"
echo "  ✅ Updated Dockerfile for Lambda compatibility"
echo ""

# Step 1: Build Docker image
echo "🔨 Building Docker image..."
docker build -t movie-revenue-predictor:latest .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed"
    exit 1
fi

echo "✅ Docker build successful!"
echo ""

# Step 2: Tag for ECR
echo "🏷️  Tagging image for ECR..."
docker tag movie-revenue-predictor:latest \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/movie-revenue-predictor:latest

# Step 3: Login to ECR
echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Step 4: Push to ECR
echo ""
echo "📤 Pushing image to ECR (5-10 minutes)..."
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/movie-revenue-predictor:latest

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully pushed Lambda-compatible image!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Next steps:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1. Go to AWS Lambda Console"
   echo "2. If you already created the function, go to Configuration → Image"
    echo "3. Click 'Deploy new image'"
    echo "4. Select the latest image"
    echo "5. Test your function again"
    echo ""
    echo "OR create a new Lambda function with the updated image!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo "❌ Failed to push image"
    exit 1
fi
