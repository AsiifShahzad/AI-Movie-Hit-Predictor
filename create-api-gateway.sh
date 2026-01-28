#!/bin/bash
# Create API Gateway in us-east-1 automatically

echo "🚀 Creating API Gateway in us-east-1..."
echo "======================================"

source .env

# 1. Create API
echo "Creating REST API..."
API_ID=$(aws apigateway create-rest-api \
    --name "movie-revenue-predictor-cli" \
    --region us-east-1 \
    --query 'id' --output text)

echo "✅ Created API with ID: $API_ID"

# 2. Get Root Resource
ROOT_ID=$(aws apigateway get-resources \
    --rest-api-id $API_ID \
    --region us-east-1 \
    --query 'items[?path==`/`].id' --output text)

# 3. Create /predict Resource
echo "Creating /predict resource..."
RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ROOT_ID \
    --path-part predict \
    --region us-east-1 \
    --query 'id' --output text)

# 4. Create POST Method
echo "Creating POST method..."
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --authorization-type NONE \
    --region us-east-1 > /dev/null

# 5. Integrate with Lambda
echo "Integrating with Lambda..."
LAMBDA_ARN="arn:aws:lambda:us-east-1:$AWS_ACCOUNT_ID:function:movie-revenue-predictor"

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations" \
    --region us-east-1 > /dev/null

# 6. Add Permission to Lambda
echo "Adding permission to Lambda..."
aws lambda add-permission \
    --function-name movie-revenue-predictor \
    --statement-id "apigateway-predict-$RANDOM" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:us-east-1:$AWS_ACCOUNT_ID:$API_ID/*/POST/predict" \
    --region us-east-1 > /dev/null 2>&1 || echo "Permission might already exist"

# 7. Deploy API
echo "Deploying API..."
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --region us-east-1 > /dev/null

echo ""
echo "✅ SUCCESS! Your API is ready!"
echo "======================================"
echo "URL: https://$API_ID.execute-api.us-east-1.amazonaws.com/prod/predict"
echo "======================================"
echo ""
echo "Try testing with:"
echo "curl -X POST https://$API_ID.execute-api.us-east-1.amazonaws.com/prod/predict \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"budget\": 100000000}'"
