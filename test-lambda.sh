#!/bin/bash
# Test Lambda function

echo "🧪 Testing Lambda Function"
echo "=========================="
echo ""

source .env

FUNCTION_NAME="movie-revenue-predictor"

echo "Testing function: $FUNCTION_NAME"
echo ""

# Create test payload
TEST_PAYLOAD='{
  "resource": "/predict",
  "path": "/predict",
  "httpMethod": "POST",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": "{\"budget\": 100000000, \"runtime\": 120, \"cast_count\": 15, \"release_month\": 6}"
}'

# Save payload to file
echo "$TEST_PAYLOAD" > /tmp/lambda-test-payload.json

echo "Test payload:"
echo "$TEST_PAYLOAD" | jq . 2>/dev/null || echo "$TEST_PAYLOAD"
echo ""

# Invoke Lambda function
echo "📤 Invoking Lambda function..."
aws lambda invoke \
    --function-name $FUNCTION_NAME \
    --payload file:///tmp/lambda-test-payload.json \
    --region $AWS_REGION \
    /tmp/lambda-response.json

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Lambda invocation successful!"
    echo ""
    echo "📋 Response:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat /tmp/lambda-response.json | jq . 2>/dev/null || cat /tmp/lambda-response.json
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Clean up
    rm -f /tmp/lambda-test-payload.json /tmp/lambda-response.json
    
    echo "✅ Test complete!"
    echo ""
    echo "If you see a prediction response above, Lambda is working!"
    echo "Next step: Create API Gateway (see STEPS-6-7-8.md)"
else
    echo ""
    echo "❌ Lambda invocation failed"
    echo ""
    echo "Check CloudWatch logs:"
    echo "  aws logs tail /aws/lambda/$FUNCTION_NAME --follow"
    exit 1
fi
