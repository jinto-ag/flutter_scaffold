#!/bin/bash
# Setup script for git hooks
# Run this script to configure git to use the project's hooks

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔧 Setting up git hooks..."

# Configure git to use the .githooks directory
git config core.hooksPath .githooks

# Make hooks executable
chmod +x "$SCRIPT_DIR/pre-commit"
chmod +x "$SCRIPT_DIR/commit-msg"

echo "✅ Git hooks configured!"
echo ""
echo "Hooks enabled:"
echo "  - pre-commit: Runs analyzer, formatter, and tests"
echo "  - commit-msg: Validates conventional commit format"
echo ""
echo "To disable hooks temporarily, use: git commit --no-verify"
