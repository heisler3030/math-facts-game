#!/bin/bash
# Deploy Math Facts Game to AWS S3 + CloudFront
# Usage: ./deploy.sh
#
# Requires a .env file in the same directory with:
#   BUCKET, DISTRIBUTION_ID, CLOUDFRONT_URL
# See .env.example

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "$SCRIPT_DIR/.env" ]; then
  echo "Error: .env file not found. Copy .env.example and fill in your values."
  exit 1
fi

# shellcheck source=.env
source "$SCRIPT_DIR/.env"

echo "Uploading index.html to S3..."
aws s3 cp index.html "s3://$BUCKET/index.html" \
  --content-type "text/html" \
  --cache-control "no-cache"

echo "Uploading sw.js to S3..."
aws s3 cp sw.js "s3://$BUCKET/sw.js" \
  --content-type "application/javascript" \
  --cache-control "no-cache"

echo "Invalidating CloudFront cache..."
aws cloudfront create-invalidation \
  --distribution-id "$DISTRIBUTION_ID" \
  --paths "/*" \
  --query 'Invalidation.{Id:Id,Status:Status}' \
  --output json

echo ""
echo "Deployed! Live at: $CLOUDFRONT_URL"
echo "(CloudFront cache invalidation takes ~30 seconds)"
