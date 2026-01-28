#!/bin/bash
# Complete Step 5 - Run this after fixing Docker permissions

echo "🔧 Docker Permission Quick Fix"
echo "=============================="
echo ""
echo "You need to run this command to activate docker group:"
echo ""
echo "  newgrp docker"
echo ""
echo "This will start a new shell with docker permissions."
echo "Then run this script again from that new shell."
echo ""

# Check if docker works without
sudo
if docker ps &> /dev/null; then
    echo "✅ Docker permissions are working!"
    echo ""
    echo "Continuing with Step 5..."
    echo ""
    
    # Source environment and continue
    source .env
    bash step5-push-to-ecr.sh
else
    echo "⚠️  Docker still needs permission fix."
    echo ""
    echo "Please run:"
    echo "  newgrp docker"
    echo ""
    echo "Then run this script again:"
    echo "  bash complete-step5.sh"
    echo ""
    exit 1
fi
