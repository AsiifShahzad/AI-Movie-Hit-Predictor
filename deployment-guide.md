# 🚀 AWS Lambda Deployment Guide
## Complete Step-by-Step Instructions

This guide walks you through deploying your AI Movie Revenue Predictor to AWS Lambda using Docker containers.

---

## 📋 Prerequisites Checklist

Before you begin, ensure you have:

- [ ] AWS Account with permissions for ECR, Lambda, API Gateway
- [ ] AWS Access Key ID and Secret Access Key
- [ ] Docker installed and running
- [ ] Python 3 installed
- [ ] Git repository with your code

---

## 🔧 Initial Setup (One-Time)

### Step 1: Run Prerequisites Setup

```bash
cd /home/asif/AI-Movie-Hit-Predictor

# Make scripts executable
chmod +x deploy-setup.sh
chmod +x step3-get-account-id.sh
chmod +x step4-create-ecr.sh
chmod +x step5-push-to-ecr.sh

# Run setup script
bash deploy-setup.sh
```

**Expected Output:**
- ✅ Docker installed
- ✅ User in docker group (or instructions to fix)
- ✅ Python3 installed
- ✅ AWS CLI installed
- Status of AWS credentials

### Step 2: Fix Docker Permissions (if needed)

If you see "User NOT in docker group", run:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Or logout and login again.

### Step 3: Configure AWS Credentials (if needed)

```bash
aws configure
```

You'll be prompted for:
- **AWS Access Key ID**: [Your access key]
- **AWS Secret Access Key**: [Your secret key]
- **Default region**: us-east-1 (or your preferred region)
- **Default output format**: json

---

## 🐳 Build and Test Locally (Recommended)

Before deploying to AWS, test your Docker image locally:

```bash
# Build the Docker image
docker build -t movie-revenue-predictor:latest .

# Run container
docker run -d -p 8000:8000 --name test-movie-api movie-revenue-predictor:latest

# Wait a few seconds for startup
sleep 10

# Test health endpoint
curl http://localhost:8000/health

# Expected: {"status":"healthy"}

# Test prediction endpoint
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "budget": 100000000,
    "runtime": 120,
    "cast_count": 15,
    "release_month": 6
  }'

# Expected: JSON response with predicted_revenue, category, etc.

# Stop and remove container
docker stop test-movie-api
docker rm test-movie-api
```

---

## ☁️ AWS Deployment Steps

### Step 3: Get Your AWS Account ID

```bash
bash step3-get-account-id.sh
```

**What this does:**
- Gets your AWS Account ID
- Sets environment variables
- Saves configuration to `.env` file

**Expected Output:**
```
Account ID: 123456789012
Environment variables set:
  AWS_ACCOUNT_ID = 123456789012
  AWS_REGION     = us-east-1
```

**Important:** After running, load the environment:
```bash
source .env
```

---

### Step 4: Create ECR Repository

```bash
bash step4-create-ecr.sh
```

**What this does:**
- Creates ECR repository named `movie-revenue-predictor`
- Shows repository URI
- Lists existing images (if any)

**Expected Output:**
```
✅ ECR repository created successfully!
Repository URI: 123456789012.dkr.ecr.us-east-1.amazonaws.com/movie-revenue-predictor
```

---

### Step 5: Login to ECR & Push Image

```bash
bash step5-push-to-ecr.sh
```

**What this does:**
- Checks for local Docker image (builds if needed)
- Logs in to Amazon ECR
- Tags image for ECR
- Pushes image to ECR (takes 5-10 minutes)
- Verifies push succeeded
- Saves ECR URI to `ecr-deployment-info.txt`

**Expected Output:**
```
✅ Image pushed successfully to ECR!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 IMPORTANT: Save this information!
ECR Image URI (use this in Lambda):
  123456789012.dkr.ecr.us-east-1.amazonaws.com/movie-revenue-predictor:latest
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**⚠️ SAVE THE ECR IMAGE URI** - You'll need it in the next step!

---

### Step 6: Create Lambda Function (AWS Console)

Open the file `ecr-deployment-info.txt` for the ECR Image URI, then:

1. **Navigate to AWS Lambda Console**
   ```
   https://console.aws.amazon.com/lambda
   ```

2. **Create Function**
   - Click **"Create function"** button (orange)
   - Select **"Container image"** option

3. **Function Settings**
   - **Function name**: `movie-revenue-predictor`
   - **Container image URI**: Paste your ECR URI from Step 5
     ```
     123456789012.dkr.ecr.us-east-1.amazonaws.com/movie-revenue-predictor:latest
     ```
   - Click **"Browse images"** if you want to select from ECR directly

4. **Click "Create function"**
   - Wait for function to be created (~30 seconds)

5. **Configure Function Settings**
   - Go to **Configuration** tab
   - Click **"General configuration"** → **"Edit"**
   - Set **Memory**: 1024 MB (or higher)
   - Set **Timeout**: 1 min 0 sec (60 seconds)
   - Click **"Save"**

6. **Test Lambda Function** (Optional)
   - Go to **Test** tab
   - Create new test event:
     ```json
     {
       "body": "{\"budget\": 100000000, \"runtime\": 120, \"cast_count\": 15, \"release_month\": 6}"
     }
     ```
   - Click **"Test"**
   - Check execution results

---

### Step 7: Create API Gateway

1. **Navigate to API Gateway Console**
   ```
   https://console.aws.amazon.com/apigateway
   ```

2. **Create API**
   - Click **"Create API"**
   - Choose **"REST API"** (not REST API Private)
   - Click **"Build"**

3. **API Settings**
   - **API name**: `movie-revenue-predictor`
   - **Description**: API for movie revenue prediction
   - **Endpoint Type**: Regional
   - Click **"Create API"**

4. **Create Resource**
   - Click **"Actions"** dropdown → **"Create Resource"**
   - **Resource Name**: `predict`
   - **Resource Path**: `/predict`
   - ✅ Check **"Enable API Gateway CORS"**
   - Click **"Create Resource"**

5. **Create POST Method**
   - Select `/predict` resource (click on it)
   - Click **"Actions"** → **"Create Method"** → Select **"POST"**
   - Click the checkmark ✓

6. **Configure POST Method**
   - **Integration type**: Lambda Function
   - ✅ Check **"Use Lambda Proxy integration"**
   - **Lambda Region**: us-east-1 (or your region)
   - **Lambda Function**: `movie-revenue-predictor`
   - Click **"Save"**
   - Click **"OK"** on the permission prompt

7. **Deploy API**
   - Click **"Actions"** → **"Deploy API"**
   - **Deployment stage**: [New Stage]
   - **Stage name**: `prod`
   - Click **"Deploy"**

8. **Get API URL**
   - After deployment, you'll see the **Invoke URL**:
     ```
     https://abc123def4.execute-api.us-east-1.amazonaws.com/prod
     ```
   - **SAVE THIS URL** - This is your API endpoint!

---

### Step 8: Test Your Lambda API

Now test your complete deployment:

```bash
# Replace with YOUR actual API URL from Step 7
API_URL="https://abc123def4.execute-api.us-east-1.amazonaws.com/prod"

# Test the prediction endpoint
curl -X POST "$API_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "budget": 100000000,
    "runtime": 120,
    "cast_count": 15,
    "release_month": 6
  }'
```

**Expected Response:**
```json
{
  "predicted_revenue": 275000000.0,
  "predicted_revenue_formatted": "$275,000,000.00",
  "category": "Blockbuster",
  "confidence": 0.87,
  "explanation": "Based on the input features...",
  "input_features": {
    "budget": 100000000,
    "runtime": 120,
    "cast_count": 15,
    "release_month": 6
  }
}
```

### More Test Cases

```bash
# Test a low-budget film
curl -X POST "$API_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "budget": 5000000,
    "runtime": 90,
    "cast_count": 5,
    "release_month": 2
  }'

# Test without optional parameters
curl -X POST "$API_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "budget": 50000000
  }'

# Test health endpoint
curl "$API_URL/health"
```

---

## 🔄 Updating Your Deployment

When you make code changes:

```bash
# 1. Rebuild Docker image
docker build -t movie-revenue-predictor:latest .

# 2. Push to ECR
bash step5-push-to-ecr.sh

# 3. Update Lambda function
aws lambda update-function-code \
    --function-name movie-revenue-predictor \
    --image-uri $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/movie-revenue-predictor:latest \
    --region $AWS_REGION

# 4. Wait for update to complete
aws lambda wait function-updated \
    --function-name movie-revenue-predictor \
    --region $AWS_REGION

echo "✅ Lambda function updated!"
```

---

## 💰 Cost Estimation

**AWS Free Tier** (first 12 months):
- Lambda: 1M requests/month + 400,000 GB-seconds compute
- API Gateway: 1M API calls/month
- ECR: 500 MB storage

**After Free Tier:**
- Lambda: ~$0.20 per 1M requests + ~$0.0000166667 per GB-second
- API Gateway: $3.50 per 1M requests
- ECR: $0.10 per GB/month storage

**Example:** 1,000 predictions/day = ~$0.05/day = ~$1.50/month

---

## 🆘 Troubleshooting

### Lambda Timeout Error

**Symptom:** Function times out after 3-30 seconds

**Solution:**
- Increase timeout in Lambda Configuration → General configuration
- Set to 60 seconds minimum
- Check CloudWatch logs for actual execution time

### Out of Memory Error

**Symptom:** Lambda fails with memory exceeded error

**Solution:**
- Increase memory in Lambda Configuration → General configuration
- Try 1024 MB, 1536 MB, or 2048 MB
- Model loading requires ~500-800 MB

### 502 Bad Gateway from API Gateway

**Symptom:** API returns 502 error

**Possible causes:**
1. Lambda function not responding correctly
2. Lambda timeout
3. Missing Lambda proxy integration

**Solution:**
- Check Lambda CloudWatch logs
- Ensure "Use Lambda Proxy integration" is enabled
- Test Lambda function directly first

### Docker Build Fails

**Symptom:** `docker build` command fails

**Solution:**
- Check Dockerfile syntax
- Ensure all files exist
- Check Docker daemon is running: `docker ps`
- Review build output for specific errors

### ECR Push Permission Denied

**Symptom:** Cannot push to ECR

**Solution:**
- Verify AWS credentials: `aws sts get-caller-identity`
- Check IAM permissions for ECR
- Re-run: `bash step5-push-to-ecr.sh` (includes login)

### CORS Errors in Browser

**Symptom:** API works with curl but not in browser

**Solution:**
- Enable CORS in API Gateway
- In API Gateway console: Select resource → Actions → Enable CORS
- Redeploy API after enabling CORS

---

## 📊 Monitoring & Logs

### View Lambda Logs

```bash
# View recent logs
aws logs tail /aws/lambda/movie-revenue-predictor --follow

# View logs for specific time range
aws logs filter-log-events \
    --log-group-name /aws/lambda/movie-revenue-predictor \
    --start-time $(date -d '1 hour ago' +%s)000
```

### CloudWatch Console

Navigate to: https://console.aws.amazon.com/cloudwatch

- Go to **Logs** → **Log groups**
- Find `/aws/lambda/movie-revenue-predictor`
- Click to view recent invocations

---

## ✅ Deployment Complete!

You now have:
- ✅ Docker image in ECR
- ✅ Lambda function running your ML model
- ✅ API Gateway providing HTTP access
- ✅ Complete ML prediction API in production

### Your API Endpoints

```
Health Check: GET https://YOUR_URL/prod/health
Prediction:   POST https://YOUR_URL/prod/predict
```

### Next Steps

1. Test with different movie parameters
2. Integrate into your frontend application
3. Add custom domain name (optional)
4. Set up monitoring alerts (optional)
5. Configure auto-scaling (if needed)

---

## 📚 Additional Resources

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [Amazon ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [Your Project Documentation](file:///home/asif/AI-Movie-Hit-Predictor/AWS_LAMBDA_DEPLOYMENT.txt)

---

**Need Help?** Check the troubleshooting section or review CloudWatch logs for error details.
