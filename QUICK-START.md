# 🚀 Quick Start Guide

## ✅ What's Already Done
- ✅ AWS CLI installed successfully
- ✅ pip3 installed
- ✅ Deployment scripts created

## ⚠️ What You Need to Do Now

### Step 1: Fix Docker Permissions (Required)

Your user needs to be added to the docker group to run Docker without sudo.

**Run this command:**
```bash
bash fix-prerequisites.sh
```

This will:
- Add your user to the docker group (requires sudo password)
- Give you the option to apply changes immediately

**OR manually run:**
```bash
sudo usermod -aG docker $USER
newgrp docker
```

**Verify Docker works:**
```bash
docker ps  # Should work without permission error
```

---

### Step 2: Configure AWS Credentials (Required)

```bash
aws configure
```

You'll be asked for:
- **AWS Access Key ID**: Get from AWS Console → IAM → Users → Security credentials
- **AWS Secret Access Key**: (from the same place)
- **Default region**: `us-east-1` (or your preferred region)
- **Default output format**: `json`

**Don't have AWS keys?** Follow these steps:
1. Go to https://console.aws.amazon.com/iam/
2. Click "Users" → Select your username
3. Go to "Security credentials" tab
4. Click "Create access key"
5. Select "Command Line Interface (CLI)"
6. Download and save both keys securely

**Verify AWS is configured:**
```bash
aws sts get-caller-identity
# Should show your AWS account details
```

---

### Step 3: Run Deployment Scripts (Automated)

Once Docker permissions and AWS are configured:

```bash
# Step 3: Get AWS Account ID
bash step3-get-account-id.sh

# Load environment variables
source .env

# Step 4: Create ECR Repository
bash step4-create-ecr.sh

# Step 5: Build & Push Docker Image (takes 5-10 minutes)
bash step5-push-to-ecr.sh
```

After Step 5 completes, you'll have a file `ecr-deployment-info.txt` with your ECR Image URI.

---

### Step 4: Create Lambda & API Gateway (AWS Console)

Follow the detailed instructions in [deployment-guide.md](./deployment-guide.md):

**Step 6:** Create Lambda Function
- Go to AWS Lambda Console
- Create function from container image
- Use ECR URI from `ecr-deployment-info.txt`
- Set Memory: 1024 MB, Timeout: 60 seconds

**Step 7:** Create API Gateway
- Create REST API
- Create `/predict` POST endpoint  
- Deploy to `prod` stage
- Copy API URL

**Step 8:** Test Your API
```bash
curl -X POST "https://YOUR_API_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "budget": 100000000,
    "runtime": 120,
    "cast_count": 15,
    "release_month": 6
  }'
```

---

## 📁 Important Files

| File | Purpose |
|------|---------|
| [fix-prerequisites.sh](./fix-prerequisites.sh) | Fix Docker permissions |
| [step3-get-account-id.sh](./step3-get-account-id.sh) | Get AWS Account ID |
| [step4-create-ecr.sh](./step4-create-ecr.sh) | Create ECR repository |
| [step5-push-to-ecr.sh](./step5-push-to-ecr.sh) | Build & push Docker image |
| [deployment-guide.md](./deployment-guide.md) | Complete reference guide |
| `.env` | (Generated) Environment variables |
| `ecr-deployment-info.txt` | (Generated) ECR URI for Lambda |

---

## 🆘 Quick Troubleshooting

**Docker permission denied?**
```bash
bash fix-prerequisites.sh
# OR
sudo usermod -aG docker $USER && newgrp docker
```

**AWS CLI not found?**
```bash
export PATH="$HOME/.local/bin:$PATH"
aws --version
```

**Need to reconfigure AWS?**
```bash
aws configure
```

**Check your current status:**
```bash
docker ps                    # Test Docker
aws sts get-caller-identity  # Test AWS
aws --version                # Check AWS CLI version
```

---

## ⏱️ Time Estimate

- Fix Docker permissions: 2 minutes
- Configure AWS: 5 minutes  
- Run automated scripts: 15 minutes
- AWS Console setup: 15 minutes
- **Total: ~35-40 minutes**

---

**Ready to start?** Run `bash fix-prerequisites.sh` now! 🚀
