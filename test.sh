#!/bin/bash
# Quick test script for Ironcore Arena
# Runs integration tests and basic sanity checks

set -e

PROJECT_DIR="project"

echo "=== Ironcore Arena Test Suite ==="
echo ""

# Check if Godot is available
if ! command -v godot &> /dev/null; then
    echo "Error: Godot not found in PATH"
    exit 1
fi

echo "Running integration tests..."
godot --headless --path "${PROJECT_DIR}" --script "src/tests/integration_test.gd"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ All tests passed!"
    exit 0
else
    echo ""
    echo "✗ Tests failed!"
    exit 1
fi
