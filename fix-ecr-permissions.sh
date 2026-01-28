#!/bin/bash
# Add Lambda permissions to access ECR repository

echo "🔐 Adding Lambda permissions to ECR repository..."
echo ""

source .env

# Set repository policy to allow Lambda to pull images
aws ecr set-repository-policy \
  --repository-name movie-revenue-predictor \
  --region $AWS_REGION \
  --policy-text '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "LambdaECRImageRetrievalPolicy",
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      }
    ]
  }'

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully added Lambda permissions to ECR repository!"
    echo ""
    echo "Now try creating the Lambda function again with this URI:"
    echo "302842979563.dkr.ecr.us-east-1.amazonaws.com/movie-revenue-predictor:latest"
else
    echo ""
    echo "❌ Failed to set repository policy"
    exit 1
fi
