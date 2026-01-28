#!/bin/bash
# Enable CORS for API Gateway
# This script adds OPTIONS method and mocking to support browser requests

echo "🌐 Enabling CORS for API Gateway..."
echo "==================================="

API_ID="7jocjn150c"
REGION="us-east-1"

# Get Resource ID for /predict
RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id $API_ID \
    --region $REGION \
    --query 'items[?pathPart==`predict`].id' \
    --output text)

echo "API ID: $API_ID"
echo "Resource ID: $RESOURCE_ID"

if [ -z "$RESOURCE_ID" ]; then
    echo "❌ Could not find /predict resource id"
    exit 1
fi

# 1. Create OPTIONS method
echo "Creating OPTIONS method..."
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method OPTIONS \
    --authorization-type NONE \
    --region $REGION \
    2>/dev/null || echo "OPTIONS method might already exist"

# 2. Setup Mock Integration for OPTIONS
echo "Setting up Mock Integration..."
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method OPTIONS \
    --type MOCK \
    --request-templates '{"application/json":"{\"statusCode\": 200}"}' \
    --region $REGION

# 3. Add Method Response for OPTIONS (200)
echo "Adding OPTIONS Method Response..."
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-models '{"application/json": "Empty"}' \
    --response-parameters '{"method.response.header.Access-Control-Allow-Headers": true, "method.response.header.Access-Control-Allow-Methods": true, "method.response.header.Access-Control-Allow-Origin": true}' \
    --region $REGION

# 4. Add Integration Response for OPTIONS (Return headers)
echo "Adding OPTIONS Integration Response..."
aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-templates '{"application/json": ""}' \
    --response-parameters '{"method.response.header.Access-Control-Allow-Headers": "'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'", "method.response.header.Access-Control-Allow-Methods": "'"'POST,OPTIONS'"'", "method.response.header.Access-Control-Allow-Origin": "'"'*'"'"}' \
    --region $REGION

# 5. Enable CORS for POST method (add header to response)
echo "Updating POST method response for CORS..."
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Origin": true}' \
    --region $REGION 2>/dev/null || echo "POST method response exists"

echo "Updating POST integration response for CORS..."
aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --status-code 200 \
    --selection-pattern "" \
    --response-parameters '{"method.response.header.Access-Control-Allow-Origin": "'"'*'"'"}' \
    --region $REGION 2>/dev/null || echo "POST integration response update attempted"

# 6. Redeploy API
echo "Redeploying API..."
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --region $REGION

echo ""
echo "✅ CORS Enabled!"
echo "Try your frontend again. If it still fails, wait 30 seconds for deployment to propagate."
