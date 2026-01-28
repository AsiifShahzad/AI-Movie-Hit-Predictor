#!/bin/bash
# Force Wildcard CORS on API Gateway OPTIONS Request

echo "🔧 Fixing CORS Pre-flight on API Gateway..."
echo "==========================================="

API_ID="7jocjn150c"
REGION="us-east-1"

# Get Resource ID
RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id $API_ID \
    --region $REGION \
    --query 'items[?pathPart==`predict`].id' \
    --output text)

echo "API: $API_ID | Resource: $RESOURCE_ID"

# Update OPTIONS Method Response to return '*'
echo "Updating OPTIONS method to return wildcard origin..."

# 1. Update Integration Response (The mock response)
aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-templates '{"application/json": ""}' \
    --response-parameters '{"method.response.header.Access-Control-Allow-Headers": "'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,Origin,Accept'"'", "method.response.header.Access-Control-Allow-Methods": "'"'POST,OPTIONS'"'", "method.response.header.Access-Control-Allow-Origin": "'"'*'"'"}' \
    --region $REGION

# 2. Redeploy API
echo "Redeploying API..."
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --region $REGION

echo ""
echo "✅ CORS Fixed: Options method now returns '*'"
echo "Wait 30 seconds and try again!"
