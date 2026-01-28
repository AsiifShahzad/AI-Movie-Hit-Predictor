#!/bin/bash
# Direct Lambda test with simpler payload

echo "🧪 Testing Lambda with Direct Invocation"
echo "========================================"
echo ""

source .env

# Create a simpler test payload that matches Lambda's expectations
TEST_PAYLOAD='{
  "body": "{\"budget\": 100000000, \"runtime\": 120, \"cast_count\": 15, \"release_month\": 6}",
  "headers": {"Content-Type": "application/json"},
  "requestContext": {"http": {"method": "POST", "path": "/predict"}},
  "isBase64Encoded": false
}'

echo "$TEST_PAYLOAD" > /tmp/simple-test.json

echo "Invoking Lambda..."
aws lambda invoke \
    --function-name movie-revenue-predictor \
    --payload file:///tmp/simple-test.json \
    --region $AWS_REGION \
    /tmp/lambda-response.json

echo ""
echo "Response:"
cat /tmp/lambda-response.json | jq . 2>/dev/null || cat /tmp/lambda-response.json
echo ""

rm -f /tmp/simple-test.json /tmp/lambda-response.json
