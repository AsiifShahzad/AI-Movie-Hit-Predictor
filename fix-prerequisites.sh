#!/bin/bash
# Quick Fix Script for Prerequisites
# Run this to complete the prerequisites setup

echo "🔧 Quick Prerequisites Fix"
echo "=========================="
echo ""

# Fix 1: Add user to docker group (requires sudo password)
echo "1️⃣  Adding user to docker group..."
echo "   This requires your sudo password."
echo ""

sudo usermod -aG docker $USER

if [ $? -eq 0 ]; then
    echo "✅ Successfully added user to docker group!"
    echo ""
    echo "⚠️  IMPORTANT: You need to apply the changes:"
    echo "   Option A: Run 'newgrp docker' (applies immediately in current terminal)"
    echo "   Option B: Logout and login again (applies system-wide)"
    echo ""
    
    # Ask user which option they prefer
    read -p "Do you want to apply changes now with 'newgrp docker'? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Applying changes with newgrp docker..."
        echo "Note: This will start a new shell session."
        echo ""
        exec newgrp docker
    else
        echo "Please logout and login again to apply the changes."
        echo "Then continue with the deployment steps."
    fi
else
    echo "❌ Failed to add user to docker group"
    echo "   You may need to run this script with: bash fix-prerequisites.sh"
    exit 1
fi

echo ""
echo "✅ Prerequisites fix complete!"
echo ""
echo "Next steps:"
echo "1. Verify Docker works: docker ps"
echo "2. Verify AWS CLI works: aws --version"
echo "3. Configure AWS: aws configure"
echo "4. Continue with: bash step3-get-account-id.sh"
echo ""
