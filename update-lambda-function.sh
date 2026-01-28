#!/bin/bash
# Update existing Lambda function with new image

echo "🔄 Updating Lambda Function with New Image"
echo "=========================================="
echo ""

source .env

FUNCTION_NAME="movie-revenue-predictor"
IMAGE_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/movie-revenue-predictor:latest"

echo "Function: $FUNCTION_NAME"
echo "New Image: $IMAGE_URI"
echo ""

# Update Lambda function code with new image
echo "📤 Updating Lambda function code..."
aws lambda update-function-code \
    --function-name $FUNCTION_NAME \
    --image-uri $IMAGE_URI \
    --region $AWS_REGION

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Function code update initiated!"
    echo ""
    echo "⏳ Waiting for function to be ready..."
    
    # Wait for function to be updated
    aws lambda wait function-updated \
        --function-name $FUNCTION_NAME \
        --region $AWS_REGION
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Lambda function updated successfully!"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Next steps:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "1. Test the Lambda function:"
        echo "   bash test-lambda.sh"
        echo ""
        echo "2. Or test in AWS Console:"
        echo "   https://console.aws.amazon.com/lambda/home?region=$AWS_REGION#/functions/$FUNCTION_NAME"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
        echo "⚠️  Function update may still be in progress"
        echo "   Check status in AWS Console"
    fi
else
    echo ""
    echo "❌ Failed to update Lambda function"
    echo ""
    echo "Possible issues:"
    echo "  - Function doesn't exist yet (create it first)"
    echo "  - Insufficient permissions"
    echo "  - Invalid image URI"
    exit 1
fi
