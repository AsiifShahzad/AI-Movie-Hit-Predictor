#!/bin/bash
# Setup script for AWS Lambda deployment prerequisites

set -e

echo "🚀 AWS Lambda Deployment - Prerequisites Setup"
echo "=============================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "⚠️  Please do not run this script as root/sudo"
    exit 1
fi

# Step 1: Check Docker installation
echo "📦 Checking Docker installation..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo "✅ Docker is installed: $DOCKER_VERSION"
else
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Step 2: Check Docker permissions
echo ""
echo "🔐 Checking Docker permissions..."
if groups | grep -q docker; then
    echo "✅ User is in docker group"
    
    # Test if docker actually works
    if docker ps &> /dev/null; then
        echo "✅ Docker daemon is accessible"
    else
        echo "⚠️  Docker daemon is not accessible. You may need to restart your session."
        echo "   Run: newgrp docker"
        echo "   Or logout and login again"
    fi
else
    echo "⚠️  User is NOT in docker group"
    echo ""
    echo "To fix this, run the following commands:"
    echo "────────────────────────────────────────"
    echo "sudo usermod -aG docker \$USER"
    echo "newgrp docker"
    echo "────────────────────────────────────────"
    echo ""
    echo "Or logout and login again for changes to take effect."
    echo ""
fi

# Step 3: Check Python3 installation
echo ""
echo "🐍 Checking Python installation..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✅ Python3 is installed: $PYTHON_VERSION"
else
    echo "❌ Python3 is not installed. Please install Python3 first."
    exit 1
fi

# Step 4: Check pip3 installation
echo ""
echo "📦 Checking pip installation..."
if command -v pip3 &> /dev/null; then
    PIP_VERSION=$(pip3 --version)
    echo "✅ pip3 is installed: $PIP_VERSION"
else
    echo "❌ pip3 is not installed. Installing..."
    sudo apt-get update
    sudo apt-get install -y python3-pip
fi

# Step 5: Check/Install AWS CLI
echo ""
echo "☁️  Checking AWS CLI installation..."
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version)
    echo "✅ AWS CLI is already installed: $AWS_VERSION"
else
    echo "⚠️  AWS CLI is not installed."
    echo ""
    
    # Try pipx first (recommended for Ubuntu 24.04+)
    if command -v pipx &> /dev/null; then
        echo "Installing AWS CLI via pipx (recommended)..."
        pipx install awscli
        pipx ensurepath
    else
        # Check if pipx is available to install
        echo "pipx not found. Installing pipx first..."
        if sudo apt-get install -y pipx 2>/dev/null; then
            echo "Installing AWS CLI via pipx..."
            pipx install awscli
            pipx ensurepath
        else
            # Fallback to pip with --break-system-packages
            echo "Installing AWS CLI via pip3..."
            echo "Note: Using --break-system-packages flag for Ubuntu 24.04 compatibility"
            pip3 install --user --break-system-packages awscli
            
            # Add to PATH if not already there
            if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                echo ""
                echo "Adding ~/.local/bin to PATH..."
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
                export PATH="$HOME/.local/bin:$PATH"
            fi
        fi
    fi
    
    echo ""
    echo "✅ AWS CLI installation completed!"
    echo "   Restart your terminal or run: source ~/.bashrc"
    echo "   Then verify with: aws --version"
fi

# Step 6: Check AWS credentials
echo ""
echo "🔑 Checking AWS credentials..."
if [ -f ~/.aws/credentials ] || [ ! -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "✅ AWS credentials file or environment variables found"
    
    # Try to verify credentials
    if aws sts get-caller-identity &> /dev/null; then
        echo "✅ AWS credentials are valid!"
        AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
        echo "   Account ID: $AWS_ACCOUNT"
    else
        echo "⚠️  AWS credentials found but may be invalid"
        echo "   Run: aws configure"
    fi
else
    echo "⚠️  AWS credentials not configured"
    echo ""
    echo "To configure AWS credentials, run:"
    echo "────────────────────────────────────────"
    echo "aws configure"
    echo "────────────────────────────────────────"
    echo ""
    echo "You will need:"
    echo "  - AWS Access Key ID"
    echo "  - AWS Secret Access Key"
    echo "  - Default region (e.g., us-east-1)"
    echo "  - Default output format (json)"
fi

# Summary
echo ""
echo "=============================================="
echo "📋 Setup Summary:"
echo "=============================================="

# Create checklist
DOCKER_OK="❌"
DOCKER_GROUP_OK="❌"
PYTHON_OK="❌"
AWS_CLI_OK="❌"
AWS_CREDS_OK="❌"

command -v docker &> /dev/null && DOCKER_OK="✅"
groups | grep -q docker && DOCKER_GROUP_OK="✅"
command -v python3 &> /dev/null && PYTHON_OK="✅"
command -v aws &> /dev/null && AWS_CLI_OK="✅"
([ -f ~/.aws/credentials ] || [ ! -z "$AWS_ACCESS_KEY_ID" ]) && AWS_CREDS_OK="✅"

echo "$DOCKER_OK Docker installed"
echo "$DOCKER_GROUP_OK User in docker group"
echo "$PYTHON_OK Python3 installed"
echo "$AWS_CLI_OK AWS CLI installed"
echo "$AWS_CREDS_OK AWS credentials configured"

echo ""
echo "Next steps:"
echo "1. Fix any ❌ items above"
echo "2. Run: bash step3-get-account-id.sh"
echo ""
