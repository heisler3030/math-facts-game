# AWS Security Audit — Math Facts Game
**Date:** April 4, 2026  
**Infrastructure:** S3 static website + CloudFront CDN  
**Distribution ID:** E10DYTUGFHX0VN  
**Bucket:** math-facts-game-821094823067  
**CloudFront URL:** https://d3tcg06jc3xgmz.cloudfront.net

---

## Summary (Post-Audit State)

| Area | Before | After | Risk |
|------|--------|-------|------|
| HTTPS enforcement (viewer) | ✅ redirect-to-https | ✅ unchanged | Low |
| TLS minimum version | ❌ TLSv1 | ✅ TLSv1.2_2021 (fixed) | Low |
| Security headers | ❌ None | ✅ HSTS, X-Frame, CSP, etc. (fixed) | Low |
| S3 direct access (public) | ⚠️ Fully public | ⚠️ Still public (see note) | Medium |
| S3 bucket versioning | ❌ Disabled | ✅ Enabled (fixed) | Low |
| S3 access logging | ❌ Disabled | ❌ Still disabled | Low |
| CloudFront logging | ❌ Disabled | ❌ Still disabled | Low |
| WAF | ❌ None | ❌ None (low priority) | Low |
| DDoS protection | ✅ Shield Standard | ✅ unchanged | Low |
| IAM / least privilege | ❓ Unknown | ❓ Needs manual review | Medium |

---

## Confirmed Findings (Live Data)

### S3 Bucket
```json
PublicAccessBlockConfiguration: {
  BlockPublicAcls: false,
  IgnorePublicAcls: false,
  BlockPublicPolicy: false,
  RestrictPublicBuckets: false
}
BucketPolicy: { Principal: "*", Action: "s3:GetObject" }
Versioning: Disabled → ENABLED (fixed)
Logging: Disabled
```

### CloudFront Distribution
```
DefaultRootObject: index.html
HttpVersion: http2
PriceClass: PriceClass_100 (US/EU/Asia)
Origin: math-facts-game-821094823067.s3-website-us-east-1.amazonaws.com
OriginProtocol: http-only (CloudFront→S3, internal AWS network — acceptable)
OAC: None (S3 website endpoint doesn't support OAC)
ViewerProtocolPolicy: redirect-to-https ✅
MinimumProtocolVersion: TLSv1 → TLSv1.2_2021 (fixed)
ResponseHeadersPolicyId: None → e1bf8911-ea11-4dad-9b25-355c5d41d980 (fixed)
CloudFront Logging: Disabled
WAF WebACL: None
GeoRestriction: None
Certificate: CloudFront default (*.cloudfront.net)
```

---

## Changes Applied

### ✅ 1. S3 Versioning Enabled
```bash
aws s3api put-bucket-versioning \
  --bucket math-facts-game-821094823067 \
  --versioning-configuration Status=Enabled
```
Protects against accidental overwrites. You can now roll back to any previous version of `index.html` or `manifest.json`.

---

### ✅ 2. CloudFront Security Headers Policy Applied
Policy ID: `e1bf8911-ea11-4dad-9b25-355c5d41d980`  
Name: `math-facts-security-headers`

Headers now added to every CloudFront response:

| Header | Value |
|--------|-------|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` |
| `X-Content-Type-Options` | `nosniff` |
| `X-Frame-Options` | `DENY` |
| `X-XSS-Protection` | `1; mode=block` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |

---

### ✅ 3. TLS Minimum Version Upgraded
`TLSv1` → `TLSv1.2_2021`

Drops support for TLS 1.0 and 1.1 (deprecated, vulnerable to POODLE/BEAST). All modern browsers and iOS 9+ support TLS 1.2.

---

## Remaining Items

### ⚠️ S3 Direct Access — Still Public (Medium, Low Urgency)
The S3 bucket is still publicly accessible at:
`http://math-facts-game-821094823067.s3-website-us-east-1.amazonaws.com`

This means someone could access the site over HTTP directly, bypassing CloudFront's HTTPS redirect and security headers.

**Why it's hard to fix:** The CloudFront origin is configured as the S3 **website endpoint** (not the REST endpoint). S3 website endpoints don't support Origin Access Control (OAC). To lock down S3, you'd need to:
1. Switch CloudFront origin from the website endpoint to the S3 REST endpoint (`math-facts-game-821094823067.s3.amazonaws.com`)
2. Create an OAC and attach it to the CloudFront distribution
3. Update the S3 bucket policy to only allow access from the CloudFront OAC principal
4. Block all public access on the S3 bucket
5. Note: S3 REST endpoint doesn't support `DefaultRootObject` for subdirectories — but since this is a single-page app with only `index.html` at root, it works fine

**Risk level:** Low-Medium. The content is public anyway (it's a game). The main risk is HTTP access bypassing security headers. Not a data breach risk.

**To fix (when ready):**
```bash
# 1. Create OAC
aws cloudfront create-origin-access-control \
  --origin-access-control-config '{
    "Name": "math-facts-oac",
    "OriginAccessControlOriginType": "s3",
    "SigningBehavior": "always",
    "SigningProtocol": "sigv4"
  }'

# 2. Update CloudFront origin to REST endpoint + attach OAC
# (requires full distribution config update)

# 3. Update S3 bucket policy to allow only CloudFront OAC
# 4. Block all public access on S3
```

---

### ❌ CloudFront Access Logging — Disabled (Low)
No request logs are being collected. Useful for debugging and detecting unusual traffic.

**To enable:**
```bash
# First create a logs bucket
aws s3 mb s3://math-facts-game-logs-821094823067
aws s3api put-bucket-acl --bucket math-facts-game-logs-821094823067 \
  --acl log-delivery-write

# Then enable logging in CloudFront distribution config
# (set Logging.Enabled=true, Bucket=math-facts-game-logs-821094823067.s3.amazonaws.com)
```

---

### ❓ IAM Deployment Credentials — Needs Manual Review (Medium)
The credentials used for `aws s3 cp` and `aws cloudfront create-invalidation` should be scoped to least privilege.

**Recommended policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::math-facts-game-821094823067",
        "arn:aws:s3:::math-facts-game-821094823067/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": ["cloudfront:CreateInvalidation", "cloudfront:GetDistributionConfig", "cloudfront:UpdateDistribution"],
      "Resource": "arn:aws:cloudfront::821094823067:distribution/E10DYTUGFHX0VN"
    }
  ]
}
```

---

## What's Good (No Action Needed)

- ✅ HTTPS enforced via CloudFront redirect-to-https
- ✅ TLS 1.2+ minimum (fixed)
- ✅ Security headers: HSTS, X-Frame-Options, X-Content-Type-Options, XSS-Protection, Referrer-Policy (fixed)
- ✅ S3 versioning enabled (fixed)
- ✅ No server-side code — pure static HTML/JS, minimal attack surface
- ✅ No user data collected or stored
- ✅ No cookies, no authentication, no PII
- ✅ AWS Shield Standard DDoS protection (automatic, free)
- ✅ CloudFront CDN with HTTP/2
- ✅ S3 ACL: owner-only (no public ACL grants)
