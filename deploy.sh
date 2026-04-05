#!/bin/bash
# Deploy Math Facts Game to AWS S3 + CloudFront
# Usage: ./deploy.sh

BUCKET="math-facts-game-821094823067"
DISTRIBUTION_ID="E10DYTUGFHX0VN"
CLOUDFRONT_URL="https://d3tcg06jc3xgmz.cloudfront.net"

echo "📤 Uploading index.html to S3..."
aws s3 cp index.html s3://$BUCKET/index.html \
  --content-type "text/html" \
  --cache-control "no-cache"

echo "🔄 Invalidating CloudFront cache..."
aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*" \
  --query 'Invalidation.{Id:Id,Status:Status}' \
  --output json

echo ""
echo "✅ Deployed! Live at: $CLOUDFRONT_URL"
echo "   (CloudFront cache invalidation takes ~30 seconds)"
