# 🎯 Steps 6-8: AWS Console Setup Guide

**✅ Automated Steps Complete!**
- Account ID: 302842979563
- ECR Image URI: `302842979563.dkr.ecr.us-east-1.amazonaws.com/movie-revenue-predictor:latest`
- Image Size: 784.8 MB
- Image Digest: sha256:166c143f051a873acb404e1f02396ce8643efbd213c761060b5df3cf8cb2c341

---

## 📝 Step 6: Create Lambda Function (~5 minutes)

### 1. Open AWS Lambda Console
**Click this link:** https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions

### 2. Create Function
- Click the orange **"Create function"** button (top right)

### 3. Select Container Image
- Choose **"Container image"** option (second radio button)

### 4. Configure Function
Fill in these details:

**Function name:**
```
movie-revenue-predictor
```

**Container image URI:**
```
302842979563.dkr.ecr.us-east-1.amazonaws.com/movie-revenue-predictor:latest
```

**Architecture:**
- Leave as default (x86_64)

### 5. Create Function
- Click **"Create function"** button (bottom right)
- ⏳ Wait ~30 seconds for function to be created

### 6. Configure Memory and Timeout
After the function is created:

1. Go to **Configuration** tab
2. Click **"General configuration"** (left sidebar)
3. Click **"Edit"** button (top right)
4. Set **Memory**: `1024 MB` (or higher)
5. Set **Timeout**: `1 min 0 sec` (60 seconds)
6. Click **"Save"** button

### 7. Test Lambda Function (Optional but Recommended)
1. Go to **Test** tab
2. Click **"Create new test event"**
3. Event name: `test-prediction`
4. Paste this JSON:
```json
{
  "body": "{\"budget\": 100000000, \"runtime\": 120, \"cast_count\": 15, \"release_month\": 6}"
}
```
5. Click **"Test"** button
6. ✅ You should see a successful execution with a prediction response

---

## 🌐 Step 7: Create API Gateway (~10 minutes)

### 1. Open API Gateway Console
**Click this link:** https://console.aws.amazon.com/apigateway/main/apis?region=us-east-1

### 2. Create API
- Click **"Create API"** button (orange)

### 3. Choose REST API
- Find **"REST API"** (NOT "REST API Private")
- Click **"Build"** button under it

### 4. API Settings
- **Choose the protocol:** REST
- **Create new API:** New API
- **API name:** `movie-revenue-predictor`
- **Description:** `API for AI Movie Revenue Predictor` (optional)
- **Endpoint Type:** Regional
- Click **"Create API"**

### 5. Create Resource (/predict)
1. Click **"Actions"** dropdown → **"Create Resource"**
2. **Resource Name:** `predict`
3. **Resource Path:** `/predict` (auto-filled)
4. ✅ Check **"Enable API Gateway CORS"**
5. Click **"Create Resource"**

### 6. Create POST Method
1. Click on `/predict` resource (you just created)
2. Click **"Actions"** dropdown → **"Create Method"**
3. Select **"POST"** from the dropdown
4. Click the **✓** checkmark

### 7. Setup POST Integration
You'll see a setup form:

- **Integration type:** Lambda Function
- ✅ Check **"Use Lambda Proxy integration"**
- **Lambda Region:** us-east-1
- **Lambda Function:** Type `movie-revenue-predictor` (should auto-suggest)
- Click **"Save"**
- Click **"OK"** on the permission popup

### 8. Deploy API
1. Click **"Actions"** dropdown → **"Deploy API"**
2. **Deployment stage:** [New Stage]
3. **Stage name:** `prod`
4. **Stage description:** `Production` (optional)
5. Click **"Deploy"**

### 9. Get Your API URL ⭐
After deployment, you'll see:

**Invoke URL** at the top:
```
https://XXXXXXXXXX.execute-api.us-east-1.amazonaws.com/prod
```

**📋 COPY THIS URL!** You'll use it for testing.

---

## 🧪 Step 8: Test Your API (~2 minutes)

### Test in Terminal

Replace `YOUR_API_URL` with the Invoke URL from Step 7:

```bash
# Set your API URL (replace the URL)
API_URL="https://XXXXXXXXXX.execute-api.us-east-1.amazonaws.com/prod"

# Test prediction endpoint
curl -X POST "$API_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "budget": 100000000,
    "runtime": 120,
    "cast_count": 15,
    "release_month": 6
  }'
```

### Expected Response
```json
{
  "predicted_revenue": 275000000.0,
  "predicted_revenue_formatted": "$275,000,000.00",
  "category": "Blockbuster",
  "confidence": 0.87,
  "explanation": "Based on the features provided...",
  "input_features": {
    "budget": 100000000,
    "runtime": 120,
    "cast_count": 15,
    "release_month": 6
  }
}
```

### More Test Cases

**Low-budget film:**
```bash
curl -X POST "$API_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "budget": 5000000,
    "runtime": 90,
    "cast_count": 5,
    "release_month": 2
  }'
```

**Just budget (minimal):**
```bash
curl -X POST "$API_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "budget": 50000000
  }'
```

**Health check:**
```bash
curl "$API_URL/health"
```

---

## ✅ Completion Checklist

- [ ] Lambda function created with container image
- [ ] Memory set to 1024 MB
- [ ] Timeout set to 60 seconds
- [ ] Lambda test successful
- [ ] API Gateway REST API created
- [ ] /predict resource created with POST method
- [ ] Lambda proxy integration enabled
- [ ] API deployed to prod stage
- [ ] API URL copied and saved
- [ ] curl test successful

---

## 🎉 You're Done!

Your AI Movie Revenue Predictor is now live on AWS Lambda with a public API!

**Your API Endpoints:**
```
Health: GET  https://YOUR_URL/prod/health
Predict: POST https://YOUR_URL/prod/predict
```

**Next Steps:**
- Integrate this API into your frontend application
- Share the API URL with your team
- Monitor usage in CloudWatch
- Add custom domain name (optional)

---

## 📊 Monitoring

**View Lambda Logs:**
```bash
aws logs tail /aws/lambda/movie-revenue-predictor --follow
```

**Or in AWS Console:**
- Go to CloudWatch → Log groups → `/aws/lambda/movie-revenue-predictor`

---

## 💡 Tips

- **Cold Start:** First request may take 10-30 seconds as Lambda loads the container
- **Keep Warm:** Use CloudWatch Events to ping the API every 5 minutes (optional)
- **Costs:** Very minimal for testing (~$0.05/day for 1,000 predictions)
- **Updates:** Run `bash step5-push-to-ecr.sh` again and Lambda will auto-update

---

Need help? Check [deployment-guide.md](./deployment-guide.md) for troubleshooting!
