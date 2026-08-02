# warnetech-server — Zero Trust Setup & Implementation Guide

**Status:** Ready for deployment  
**Last updated:** 2026-08-02  
**Target:** Complete end-to-end Zero Trust for warnetech-server VPC and Worker

---

## Overview

This document outlines the complete Zero Trust architecture for warnetech-server, including:
- **Access policies** for both the Cloudflare Worker and Warp connector
- **Firewall rules** to protect the VPC mesh and Worker endpoints
- **Device posture** requirements
- **Gateway logging** for audit trails
- **Traffic verification** to confirm everything is flowing correctly

All configurations are defined in `zero-trust-policy.json` and should be applied in the order below.

---

## Phase 1: Foundation Setup (Do This First)

### 1.1 Enable Cloudflare Zero Trust for the Account

```bash
# Via Cloudflare Dashboard:
# 1. Go to Dashboard → Zero Trust
# 2. Click "Get started"
# 3. Select a plan (Business or Enterprise required for full feature set)
# 4. Confirm organization name and proceed
```

**Expected outcome:** Zero Trust dashboard is active; you can now create policies.

### 1.2 Invite Team Members

```bash
# Via Zero Trust Dashboard:
# 1. Settings → Account → Members
# 2. Add accounts that should have access to:
#    - Access policies (your account)
#    - Gateway rules (your account)
#    - Device posture (optional, for BYOD enforcement)
```

**Expected outcome:** Team members can see Zero Trust settings and policies.

---

## Phase 2: Authentication & Device Posture

### 2.1 Configure Cloudflare Identity Provider

```bash
# Via Zero Trust Dashboard:
# 1. Settings → Authentication → Login methods
# 2. Enable: Cloudflare (default)
# 3. Settings → Authentication → Social OAuth (optional)
#    - Add Google OAuth (for warnetwork.cloud users)
#    - Add GitHub OAuth (for development/testing)
```

**What it does:** Users can now log in via Cloudflare, Google, or GitHub accounts.

### 2.2 Set Up Device Posture Checks

```bash
# Via Zero Trust Dashboard:
# 1. Settings → Device Posture → Managed Devices (optional, requires WARP client)
# 2. Settings → Device Posture → Integrations
#    - Add Jamf (if you use Jamf for device management)
#    - Add Crowdstrike (if you use Crowdstrike)
#    - Add Microsoft Intune (if using Microsoft MDM)
# 3. Create checks for:
#    ✓ Antivirus installed (Windows/Mac)
#    ✓ Firewall enabled
#    ✓ Disk encryption enabled
```

**What it does:** Before accessing the VPC, devices must be verified healthy.

---

## Phase 3: Application Access Policies

### 3.1 Create Access Policy for warnetech-server Worker

```bash
# Via Zero Trust Dashboard:
# 1. Access → Applications → Add an application
# 2. Configure:
#    Name: warnetech-server-worker
#    Subdomain: testllm (if using *.warnetwork.cloud)
#    Domain: warnetwork.cloud
# 3. Session Management:
#    - Session duration: 8 hours
#    - Require re-auth for sensitive operations: YES
# 4. Add Policy Rules (from zero-trust-policy.json):
#
#    Rule 1 (Allow Authenticated Users):
#    - Action: Allow
#    - Include: Emails ending in @warnetwork.cloud
#    - Require: Cloudflare login
#
#    Rule 2 (Allow Service Tokens):
#    - Action: Allow
#    - Include: Service token "warnetech-connector-token"
#    - Require: MFA
#
#    Rule 3 (Deny by default):
#    - Action: Block
#    - Include: Everyone else
```

**Test immediately:**
```bash
curl -I https://testllm.warnetwork.cloud/health
# Expected: 401 Unauthorized (redirects to login page)
# After login: 200 OK or 204 No Content
```

### 3.2 Configure mTLS for Service-to-Service Communication

```bash
# Via Zero Trust Dashboard:
# 1. Access → Applications → warnetech-server-worker → Settings
# 2. Enable "Require certificate" (if your services can present mTLS certs)
# 3. Upload CA certificate chain (optional for now, use if you have internal PKI)
```

**What it does:** Connector can authenticate to Worker securely using mutual TLS.

---

## Phase 4: Gateway & Firewall Rules

### 4.1 Enable Cloudflare Gateway

```bash
# Via Zero Trust Dashboard:
# 1. Gateway → General Settings
# 2. Set as DNS resolver:
#    - For WARP clients, set to automatic
#    - For DNS queries, Gateway is now the resolver
# 3. Confirm Firewall/Gateway is active
```

### 4.2 Deploy Worker Endpoint Firewall Rules

```bash
# Via Cloudflare Dashboard (standard, not Zero Trust):
# 1. Go to Domain (warnetwork.cloud) → Security → WAF/DDoS
# 2. Create Firewall Rules (from zero-trust-policy.json):
#
#    Rule 1: Challenge low-trust bots
#    - Expression: (cf.bot_management.score < 30)
#    - Action: Challenge (CAPTCHA)
#
#    Rule 2: Block high-threat traffic
#    - Expression: (cf.threat_score > 70)
#    - Action: Block
#
#    Rule 3: Allow legitimate bots
#    - Expression: (cf.verified_bot_category == "search engine crawler")
#    - Action: Allow
#
#    Rule 4: Allow everything else
#    - Expression: true
#    - Action: Allow
```

**Test immediately:**
```bash
# Legitimate request (should allow):
curl -I https://testllm.warnetwork.cloud/health

# Then check Gateway Logs:
# - Zero Trust Dashboard → Logs → Gateway
# - Filter by domain: testllm.warnetwork.cloud
# - Verify "Allow" entries
```

### 4.3 Deploy VPC Mesh Firewall Rules

```bash
# Via Zero Trust Dashboard:
# 1. Gateway → Firewall Policies → L7 Firewall
# 2. Create rules for internal VPC traffic:
#
#    Allow Rule 1: Client → VPC Services (HTTPS)
#    - Source: 10.64.0.0/12
#    - Destination: 100.64.0.0/10
#    - Protocol: TCP
#    - Ports: 443, 80
#    - Action: Allow
#
#    Allow Rule 2: VPC → Databases (standard DB ports)
#    - Source: 100.80.0.0/16
#    - Destination: 100.64.0.0/10
#    - Protocol: TCP
#    - Ports: 5432 (PostgreSQL), 3306 (MySQL), 6379 (Redis)
#    - Action: Allow
#
#    Log Rule: Log all traffic for audit
#    - Source: any
#    - Destination: any
#    - Action: Log
#
#    Deny Rule: Block by default
#    - Source: any
#    - Destination: any
#    - Action: Block
```

---

## Phase 5: Connector Integration

### 5.1 Register Service Token for Connector

```bash
# Via Zero Trust Dashboard:
# 1. Settings → Service Tokens → Create new token
# 2. Configure:
#    Name: warnetech-connector-token
#    Expires: 90 days
# 3. Copy the issued credentials (you'll use these once)
# 4. Store in secure location (vault, password manager, etc.)
```

### 5.2 Add Connector to Split Tunnel (Optional but Recommended)

```bash
# Via Zero Trust Dashboard:
# 1. Settings → WARP Client → Device Settings
# 2. Configure Split Tunnel:
#    - Mode: Exclude mode (split-tunnel only specified routes)
#    - Routes to include:
#      10.64.0.0/12
#      100.64.0.0/10
#      100.80.0.0/16
#    - Routes to exclude (bypass Warp for):
#      10.0.0.0/8
#      172.16.0.0/12
#      192.168.0.0/16
```

**What it does:** Only traffic to your VPC/services goes through the Warp tunnel; everything else is normal.

### 5.3 Configure Split DNS

```bash
# Via Zero Trust Dashboard:
# 1. Settings → Network → Split DNS
# 2. Add domains:
#    - Domain: *.warnetech.cloud → Upstream: 1.1.1.1
#    - Domain: *.warnetwork.cloud → Upstream: 1.1.1.1
#    - Domain: *.workers.dev → Upstream: 1.1.1.1
```

---

## Phase 6: Logging & Audit Trail

### 6.1 Enable Logpush for Audit Trail

```bash
# Via Zero Trust Dashboard:
# 1. Logs → Logpush → Create new dataset
# 2. Select dataset: HTTP Requests (standard)
# 3. Configure:
#    Frequency: Hourly
#    Destination: (choose one)
#      - Cloudflare Logpush (free, built-in)
#      - AWS S3 (for long-term archive)
#      - Google Cloud Storage (alternative)
#      - Datadog (if you use Datadog)
# 4. Filter: Include only requests to testllm.warnetwork.cloud
```

### 6.2 Enable Gateway Logging

```bash
# Via Zero Trust Dashboard:
# 1. Logs → Logpush → Create new dataset
# 2. Select dataset: Gateway HTTP
# 3. Configure same as above for access audits
```

### 6.3 Set Up Alerts

```bash
# Via Zero Trust Dashboard:
# 1. Notifications → Alert Settings (or via your email provider)
# 2. Alert on:
#    - High-risk threat score (> 70) = block
#    - Repeated auth failures = potential compromise
#    - Rate limit exceeded = DDoS or runaway process
```

---

## Phase 7: Traffic Verification & Testing

### 7.1 Verify Worker Endpoint is Reachable

```bash
# Test 1: Basic connectivity
curl -v https://testllm.warnetwork.cloud/health
# Expected: 401 (auth required) or 200 (if public health endpoint)

# Test 2: After authenticating (via login)
curl -b cookies.txt -c cookies.txt https://testllm.warnetwork.cloud/api/connectors/status
# Expected: 200 with connector status JSON

# Test 3: Check response headers
curl -I https://testllm.warnetwork.cloud/
# Expected: Cloudflare headers present (cf-ray, cf-request-id, etc.)
```

### 7.2 Verify VPC Mesh Connectivity

```bash
# If you have a device with WARP client installed:
# 1. Enable WARP on your device
# 2. Verify you can ping VPC hosts:
ping 100.64.0.1  # Should respond if inside VPC mesh
# 3. Check DNS resolution:
nslookup vpcmesh.warnetwork.cloud
# Expected: 100.x.x.x address (not public IP)
```

### 7.3 Check Firewall Logs

```bash
# Via Zero Trust Dashboard:
# 1. Logs → Gateway → Filter by domain/IP
# 2. Verify entries:
#    - ✓ Allowed requests from your IP/device
#    - ✓ Blocked requests from unknown sources
#    - ✓ Challenged requests from low-trust bots
```

### 7.4 Verify Service Token Works

```bash
# Once connector is deployed:
curl -H "Authorization: Bearer <SERVICE_TOKEN>" \
     https://testllm.warnetwork.cloud/api/connectors/status
# Expected: 200 OK
```

---

## Phase 8: Monitoring & Compliance

### 8.1 Set Up Dashboard Alerts

```bash
# Monitor these metrics:
# - Failed authentications (potential brute force)
# - Blocked requests by threat score (DDoS patterns)
# - Unusual geographic access
# - Rate limit triggers
```

### 8.2 Regular Audit

```bash
# Weekly:
# - Review Logpush logs for anomalies
# - Check device posture status (any non-compliant devices?)
# - Verify all access policies are still appropriate

# Monthly:
# - Rotate service tokens
# - Review firewall rule effectiveness
# - Check for unused rules (remove them)
# - Verify MFA adoption across team
```

### 8.3 Compliance Checklist

```
Zero Trust Deployment Checklist
================================
☑ Authentication enabled (Cloudflare/OAuth)
☑ MFA required for sensitive access
☑ Device posture checks active
☑ Firewall rules deployed
☑ Gateway logging enabled
☑ Split tunnel configured (if using WARP)
☑ Split DNS configured
☑ Service tokens issued (for automation)
☑ Audit logs accessible
☑ Alerts configured
☑ Documented runbook for incident response
```

---

## Rollback Plan (If Something Goes Wrong)

```bash
# If Zero Trust policies are too restrictive and block legitimate access:

# 1. Temporarily disable the policy:
#    Zero Trust Dashboard → Access → Applications → warnetech-server-worker
#    → Disable the problematic policy rule
#    → Re-enable after fixing

# 2. Or temporarily allow everyone (emergency only):
#    Add rule: Action Allow, Include Everyone
#    (This should be removed immediately after emergency resolves)

# 3. If Firewall rules break traffic:
#    Temporarily disable rules via:
#    Dashboard → Security → WAF/DDoS → Disable
#    Then redeploy corrected rules

# 4. Restore from saved policy snapshot (if available)
```

---

## Next Steps

1. **Complete Phase 1-4** to get basic Zero Trust running
2. **Run Phase 7 tests** to verify traffic flows
3. **Deploy connector** using the service token from Phase 5
4. **Monitor Phase 8** for anomalies
5. **Schedule Phase 8 compliance review** for next month

---

## Support & Troubleshooting

**Still blocked after login?**
→ Check Logpush logs in Zero Trust dashboard for the exact deny reason

**DNS not resolving?**
→ Verify Split DNS config points to 1.1.1.1 (Cloudflare's DNS)

**Service token failing?**
→ Verify token hasn't expired; rotate if > 60 days old

**Need to add a new route?**
→ Update firewall rules in Phase 4.3; restart WARP clients for split-tunnel changes

For full support, see `RUNBOOK.md` § Unpredictable failures → Malicious content / Vault compromise.
