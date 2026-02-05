#!/bin/bash
#
# E2E Test Script for flutter_scaffold
#
# This script performs end-to-end testing by:
# 1. Creating a new Flutter project in /tmp
# 2. Applying scaffold
# 3. Running all tests
# 4. Cleaning up
#
# Usage: ./scripts/e2e_test.sh [--keep] [--verbose]
#   --keep     Keep the generated project after test (for debugging)
#   --verbose  Show detailed output during test

set -e

# Configuration
PROJECT_NAME="e2e_test_app_$(date +%s)"
PROJECT_PATH="/tmp/$PROJECT_NAME"
LOG_FILE="$(pwd)/e2e_test.log"
KEEP_PROJECT=false
VERBOSE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
for arg in "$@"; do
  case $arg in
    --keep)
      KEEP_PROJECT=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
  esac
done

# Helpers
log() {
  echo -e "${BLUE}[E2E]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[E2E]${NC} ✓ $1"
}

log_error() {
  echo -e "${RED}[E2E]${NC} ✗ $1"
}

log_warn() {
  echo -e "${YELLOW}[E2E]${NC} ⚠ $1"
}

cleanup() {
  if [ "$KEEP_PROJECT" = false ]; then
    log "Cleaning up $PROJECT_PATH..."
    rm -rf "$PROJECT_PATH"
    log_success "Cleanup complete"
  else
    log_warn "Project kept at: $PROJECT_PATH"
  fi
}

# Set up cleanup on exit
trap cleanup EXIT

# Start
echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Flutter Scaffold E2E Test"
echo "════════════════════════════════════════════════════════════"
echo ""

# Clear log file
> "$LOG_FILE"
echo "E2E Test Log - $(date)" >> "$LOG_FILE"
echo "Project: $PROJECT_PATH" >> "$LOG_FILE"
echo "────────────────────────────────────────" >> "$LOG_FILE"

# Step 1: Build and activate the CLI
log "Building flutter_scaffold CLI..."
if $VERBOSE; then
  dart pub global activate --source path . 2>&1 | tee -a "$LOG_FILE"
else
  dart pub global activate --source path . >> "$LOG_FILE" 2>&1
fi
log_success "CLI built and activated"

# Clear cached snapshot to ensure latest code
rm -rf .dart_tool/pub/bin/flutter_scaffold/

# Step 2: Create and scaffold the project
log "Creating project: $PROJECT_NAME"
echo "" >> "$LOG_FILE"
echo "Creating project..." >> "$LOG_FILE"
if $VERBOSE; then
  flutter_scaffold create "$PROJECT_NAME" /tmp 2>&1 | tee -a "$LOG_FILE"
else
  if ! flutter_scaffold create "$PROJECT_NAME" /tmp >> "$LOG_FILE" 2>&1; then
    log_error "Failed to create project"
    echo ""
    echo "See log for details: $LOG_FILE"
    exit 1
  fi
fi
log_success "Project created and scaffolded"

# Step 3: Run Flutter analyze
log "Running flutter analyze..."
echo "" >> "$LOG_FILE"
echo "Running flutter analyze..." >> "$LOG_FILE"
cd "$PROJECT_PATH"
if $VERBOSE; then
  if flutter analyze 2>&1 | tee -a "$LOG_FILE"; then
    ANALYZE_RESULT=0
  else
    ANALYZE_RESULT=1
  fi
else
  if flutter analyze >> "$LOG_FILE" 2>&1; then
    ANALYZE_RESULT=0
  else
    ANALYZE_RESULT=1
  fi
fi

if [ $ANALYZE_RESULT -eq 0 ]; then
  log_success "Flutter analyze passed"
else
  log_error "Flutter analyze failed"
  echo ""
  echo "See log for details: $LOG_FILE"
  exit 1
fi

# Step 4: Run Flutter tests
log "Running flutter test..."
echo "" >> "$LOG_FILE"
echo "Running flutter test..." >> "$LOG_FILE"
if $VERBOSE; then
  if flutter test --reporter compact 2>&1 | tee -a "$LOG_FILE"; then
    TEST_RESULT=0
  else
    TEST_RESULT=1
  fi
else
  if flutter test --reporter compact >> "$LOG_FILE" 2>&1; then
    TEST_RESULT=0
  else
    TEST_RESULT=1
  fi
fi

if [ $TEST_RESULT -eq 0 ]; then
  log_success "All tests passed"
else
  log_error "Tests failed"
  echo ""
  echo "See log for details: $LOG_FILE"
  exit 1
fi

# Step 5: Summary
echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "  ${GREEN}E2E Test PASSED${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Log file: $LOG_FILE"

if [ "$KEEP_PROJECT" = true ]; then
  echo "Project kept at: $PROJECT_PATH"
fi

exit 0
