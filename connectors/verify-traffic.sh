#!/bin/bash

# warnetech-server — Zero Trust Traffic Verification Script
# Tests connectivity and traffic flow for the complete Zero Trust setup
# Usage: ./verify-traffic.sh [--verbose] [--continuous]

set -e

VERBOSE=false
CONTINUOUS=false
DOMAIN="testllm.warnetwork.cloud"
VPC_CIDR="100.64.0.0/10"
MESH_DOMAIN="vpcmesh.warnetwork.cloud"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose) VERBOSE=true; shift ;;
    --continuous) CONTINUOUS=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

log() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
  echo -e "${GREEN}[PASS]${NC} $1"
}

error() {
  echo -e "${RED}[FAIL]${NC} $1"
}

warning() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

debug() {
  if [ "$VERBOSE" = true ]; then
    echo -e "${BLUE}[DEBUG]${NC} $1"
  fi
}

# Test 1: DNS Resolution
test_dns_resolution() {
  log "Testing DNS resolution for $DOMAIN..."

  if nslookup "$DOMAIN" > /dev/null 2>&1; then
    IP=$(nslookup "$DOMAIN" | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | head -1)
    success "DNS resolved: $DOMAIN → $IP"
    debug "Full DNS response:"
    debug "$(nslookup $DOMAIN)"
    return 0
  else
    error "DNS resolution failed for $DOMAIN"
    return 1
  fi
}

# Test 2: HTTP Connectivity
test_http_connectivity() {
  log "Testing HTTP connectivity to $DOMAIN..."

  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/health" 2>/dev/null || echo "000")

  if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "204" ] || [ "$RESPONSE" = "401" ]; then
    success "HTTP connectivity successful (status: $RESPONSE)"
    debug "Note: 401 means auth required (expected); 200/204 means health check passes"
    return 0
  elif [ "$RESPONSE" = "000" ]; then
    error "Connection timeout or network error"
    return 1
  else
    error "Unexpected HTTP status: $RESPONSE"
    return 1
  fi
}

# Test 3: TLS/SSL Certificate Validation
test_tls_certificate() {
  log "Testing TLS certificate validity for $DOMAIN..."

  if openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" < /dev/null 2>/dev/null | grep -q "Verify return code: 0"; then
    success "TLS certificate is valid"
    debug "Certificate details:"
    debug "$(openssl s_client -connect $DOMAIN:443 -servername $DOMAIN < /dev/null 2>/dev/null | grep -A5 'subject=')"
    return 0
  else
    error "TLS certificate validation failed"
    return 1
  fi
}

# Test 4: Cloudflare Headers
test_cloudflare_headers() {
  log "Testing Cloudflare headers..."

  HEADERS=$(curl -s -I "https://$DOMAIN/health" 2>/dev/null)

  if echo "$HEADERS" | grep -q "cf-ray"; then
    CF_RAY=$(echo "$HEADERS" | grep "cf-ray" | awk '{print $2}')
    success "Cloudflare headers present (CF-Ray: $CF_RAY)"
    debug "All headers:"
    debug "$HEADERS"
    return 0
  else
    warning "Cloudflare headers not found (may indicate bypass or misconfiguration)"
    return 1
  fi
}

# Test 5: API Endpoint
test_api_endpoint() {
  log "Testing API endpoint (requires auth)..."

  # Try to hit /api/connectors/status without auth (should fail with 401/403)
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/api/connectors/status" 2>/dev/null || echo "000")

  if [ "$RESPONSE" = "401" ] || [ "$RESPONSE" = "403" ]; then
    success "API authentication required (correct behavior) - status: $RESPONSE"
    return 0
  elif [ "$RESPONSE" = "200" ]; then
    warning "API is publicly accessible (check if this is intended) - status: 200"
    return 1
  elif [ "$RESPONSE" = "000" ]; then
    error "API endpoint unreachable"
    return 1
  else
    error "Unexpected API response: $RESPONSE"
    return 1
  fi
}

# Test 6: Rate Limiting
test_rate_limiting() {
  log "Testing rate limiting (sending 15 requests)..."

  BLOCK_COUNT=0
  for i in {1..15}; do
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/health" 2>/dev/null || echo "000")
    if [ "$RESPONSE" = "429" ]; then
      ((BLOCK_COUNT++))
    fi
    sleep 0.1
  done

  if [ $BLOCK_COUNT -gt 0 ]; then
    success "Rate limiting detected ($BLOCK_COUNT requests blocked out of 15)"
    return 0
  else
    warning "No rate limiting detected (may not be configured yet)"
    return 1
  fi
}

# Test 7: Firewall Rules
test_firewall_rules() {
  log "Testing firewall rules (threat scoring)..."

  # Send a request with a suspicious User-Agent
  RESPONSE=$(curl -s -I -A "malicious-bot-scanner/1.0" "https://$DOMAIN/health" 2>/dev/null | head -1)

  if echo "$RESPONSE" | grep -q "403\|406\|403"; then
    success "Firewall rules are active (suspicious UA blocked)"
    return 0
  else
    debug "Firewall allowed suspicious UA (may be expected based on rules)"
    return 1
  fi
}

# Test 8: VPC Mesh Reachability (requires WARP)
test_vpc_mesh() {
  log "Testing VPC Mesh reachability (requires WARP client)..."

  if ping -c 1 -W 2 "100.64.0.1" > /dev/null 2>&1; then
    success "VPC Mesh is reachable via Warp tunnel"
    return 0
  else
    warning "VPC Mesh not reachable (WARP client may not be active)"
    return 1
  fi
}

# Test 9: Split DNS
test_split_dns() {
  log "Testing Split DNS configuration..."

  if nslookup "$MESH_DOMAIN" > /dev/null 2>&1; then
    IP=$(nslookup "$MESH_DOMAIN" | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | head -1)
    if [[ $IP == 100.* ]]; then
      success "Split DNS working (resolved to VPC IP: $IP)"
      return 0
    else
      warning "DNS resolved but to non-VPC IP ($IP)"
      return 1
    fi
  else
    warning "Split DNS query failed (Warp may not be active)"
    return 1
  fi
}

# Test 10: Health Check Loop
test_continuous_health() {
  log "Starting continuous health check (Ctrl+C to stop)..."

  ITERATION=0
  PASS_COUNT=0
  FAIL_COUNT=0

  while true; do
    ((ITERATION++))
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/health" 2>/dev/null || echo "000")

    if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "204" ] || [ "$RESPONSE" = "401" ]; then
      ((PASS_COUNT++))
      echo -ne "${GREEN}✓${NC} Iteration $ITERATION: $RESPONSE                \r"
    else
      ((FAIL_COUNT++))
      echo -ne "${RED}✗${NC} Iteration $ITERATION: $RESPONSE                \r"
    fi

    sleep 5
  done
}

# Main execution
main() {
  echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC} warnetech-server — Zero Trust Traffic Verification           ${BLUE}║${NC}"
  echo -e "${BLUE}║${NC} Domain: $DOMAIN                           ${BLUE}║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}\n"

  TESTS_PASSED=0
  TESTS_TOTAL=0

  # Run all tests
  for test_func in test_dns_resolution test_tls_certificate test_cloudflare_headers \
                   test_http_connectivity test_api_endpoint test_firewall_rules \
                   test_rate_limiting test_split_dns test_vpc_mesh; do
    ((TESTS_TOTAL++))
    if $test_func; then
      ((TESTS_PASSED++))
    fi
    echo ""
  done

  # Summary
  echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC} Test Results: ${GREEN}$TESTS_PASSED/$TESTS_TOTAL${NC} passed                                   ${BLUE}║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}\n"

  if [ "$CONTINUOUS" = true ]; then
    echo ""
    test_continuous_health
  fi

  if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    success "All tests passed! Zero Trust is configured correctly."
    exit 0
  else
    warning "Some tests failed. Review the output above and check ZERO_TRUST_SETUP.md"
    exit 1
  fi
}

main
