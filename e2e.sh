#!/usr/bin/env bash

set -e

echo "Running E2E Tests..."

dart run test/e2e/e2e_runner.dart --force --verbose --reset-output 

echo "E2E Tests Completed. Check e2e.txt for details."