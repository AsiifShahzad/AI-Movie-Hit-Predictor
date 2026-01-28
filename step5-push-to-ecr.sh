#!/bin/bash
# Step 5: Login to ECR & Push Image

set -e

echo "🚀 Step 5: Login to ECR & Push Image"
echo "====================================="
echo ""

# Load environment variables if .env exists
if [ -f .env ]; then
    echo "Loading environment variables from .env..."
    source .env
else
    echo "⚠️  .env file not found. Run step3-get-account-id.sh first."
    exit 1
fi

# Verify required variables
if [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$AWS_REGION" ]; then
    echo "❌ Required environment variables not set"
    echo "Run: source .env"
    exit 1
fi

ECR_REPO_NAME="${ECR_REPO_NAME:-movie-revenue-predictor}"
IMAGE_TAG="${ECR_IMAGE_TAG:-latest}"
LOCAL_IMAGE_NAME="movie-revenue-predictor:latest"
ECR_IMAGE_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG"

echo "Configuration:"
echo "  AWS Account ID: $AWS_ACCOUNT_ID"
echo "  AWS Region: $AWS_REGION"
echo "  ECR Repository: $ECR_REPO_NAME"
echo "  Image Tag: $IMAGE_TAG"
echo "  ECR Image URI: $ECR_IMAGE_URI"
echo ""

# Step 5a: Check if Docker image exists locally
echo "📦 Checking for local Docker image..."
if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$LOCAL_IMAGE_NAME$"; then
    echo "✅ Local Docker image found: $LOCAL_IMAGE_NAME"
    
    # Show image details
    echo ""
    echo "Image details:"
    docker images $LOCAL_IMAGE_NAME --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    echo ""
else
    echo "⚠️  Local Docker image not found. Building now..."
    echo ""
    
    # Build the Docker image
    echo "🔨 Building Docker image..."
    docker build -t $LOCAL_IMAGE_NAME .
    
    if [ $? -eq 0 ]; then
        echo "✅ Docker image built successfully!"
    else
        echo "❌ Docker build failed"
        exit 1
    fi
fi

# Step 5b: Login to ECR
echo ""
echo "🔐 Logging in to Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

if [ $? -eq 0 ]; then
    echo "✅ Successfully logged in to ECR!"
else
    echo "❌ ECR login failed"
    exit 1
fi

# Step 5c: Tag image for ECR
echo ""
echo "🏷️  Tagging Docker image for ECR..."
docker tag $LOCAL_IMAGE_NAME $ECR_IMAGE_URI

if [ $? -eq 0 ]; then
    echo "✅ Image tagged: $ECR_IMAGE_URI"
else
    echo "❌ Image tagging failed"
    exit 1
fi

# Step 5d: Push to ECR
echo ""
echo "📤 Pushing image to ECR (this may take 5-10 minutes)..."
echo "Please wait..."
echo ""

docker push $ECR_IMAGE_URI

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Image pushed successfully to ECR!"
else
    echo "❌ Image push failed"
    exit 1
fi

# Step 5e: Verify push succeeded
echo ""
echo "✅ Verifying image in ECR..."
echo ""

VERIFY_OUTPUT=$(aws ecr describe-images \
    --repository-name $ECR_REPO_NAME \
    --region $AWS_REGION \
    --output json)

if [ $? -eq 0 ]; then
    echo "📋 Images in ECR repository:"
    echo "────────────────────────────────────────"
    echo $VERIFY_OUTPUT | python3 -m json.tool
    echo "────────────────────────────────────────"
    echo ""
    
    # Get image digest
    IMAGE_DIGEST=$(echo $VERIFY_OUTPUT | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['imageDetails'][0]['imageDigest'] if data.get('imageDetails') else 'N/A')")
    
    echo "✅ Step 5 complete!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 IMPORTANT: Save this information!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "ECR Image URI (use this in Lambda):"
    echo "  $ECR_IMAGE_URI"
    echo ""
    echo "Image Digest:"
    echo "  $IMAGE_DIGEST"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Save to file
    cat > ecr-deployment-info.txt << EOF
ECR Deployment Information
Generated: $(date)

ECR Image URI: $ECR_IMAGE_URI
Image Digest: $IMAGE_DIGEST
Repository: $ECR_REPO_NAME
Region: $AWS_REGION
Account ID: $AWS_ACCOUNT_ID

Next Steps:
1. Go to AWS Lambda Console: https://console.aws.amazon.com/lambda
2. Click "Create function" → Choose "Container image"
3. Enter function name: movie-revenue-predictor
4. Paste the ECR Image URI above
5. Click "Create function"
6. Set Memory: 1024 MB
7. Set Timeout: 60 seconds
EOF
    
    echo "✅ Deployment info saved to: ecr-deployment-info.txt"
    echo ""
else
    echo "⚠️  Could not verify images in ECR, but push may have succeeded"
fi

echo ""
echo "Next steps:"
echo "1. See ecr-deployment-info.txt for Lambda setup instructions"
echo "2. See deployment-guide.md for Steps 6-8"
echo ""
