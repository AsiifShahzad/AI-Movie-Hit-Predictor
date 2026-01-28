#!/bin/bash
# Step 3: Get AWS Account ID and set environment variables

set -e

echo "🆔 Step 3: Get Your AWS Account ID"
echo "===================================="
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed."
    echo "Run: bash deploy-setup.sh"
    exit 1
fi

# Check if AWS is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials are not configured or invalid."
    echo ""
    echo "Run: aws configure"
    echo ""
    echo "You will need:"
    echo "  - AWS Access Key ID"
    echo "  - AWS Secret Access Key"
    echo "  - Default region (e.g., us-east-1)"
    echo "  - Default output format (json)"
    exit 1
fi

# Get AWS Account ID
echo "Getting your AWS Account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "❌ Failed to get AWS Account ID"
    exit 1
fi

echo "✅ Successfully retrieved AWS Account ID!"
echo ""
echo "Account ID: $AWS_ACCOUNT_ID"
echo ""

# Set environment variables
export AWS_ACCOUNT_ID
export AWS_REGION="${AWS_REGION:-us-east-1}"

echo "Environment variables set:"
echo "  AWS_ACCOUNT_ID = $AWS_ACCOUNT_ID"
echo "  AWS_REGION     = $AWS_REGION"
echo ""

# Get caller identity details
echo "📋 AWS Account Details:"
echo "────────────────────────────────────────"
aws sts get-caller-identity
echo "────────────────────────────────────────"
echo ""

# Save to a file for later use
echo "Saving environment variables to .env file..."
cat > .env << EOF
# AWS Deployment Environment Variables
# Generated on $(date)
export AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID
export AWS_REGION=$AWS_REGION
export ECR_REPO_NAME=movie-revenue-predictor
export ECR_IMAGE_TAG=latest
export ECR_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/movie-revenue-predictor:latest
EOF

echo "✅ Environment variables saved to .env"
echo ""
echo "To use these variables in your current shell, run:"
echo "────────────────────────────────────────"
echo "source .env"
echo "────────────────────────────────────────"
echo ""
echo "Next step: Run bash step4-create-ecr.sh"
echo ""
