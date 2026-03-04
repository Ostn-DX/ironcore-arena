#!/bin/bash
# Safe OpenClaw Config Updater
# Run this script after filling in your API keys

CONFIG_FILE="/home/node/.openclaw/openclaw.json"
BACKUP_DIR="/home/node/.openclaw"
TEMPLATE_FILE="/home/node/.openclaw/workspace/ironcore-work/CONFIG_TEMPLATE.json"

echo "=== OpenClaw Config Updater ==="
echo ""

# Check if template exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "ERROR: Template file not found at $TEMPLATE_FILE"
    exit 1
fi

# Create backup with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/openclaw.json.backup.$TIMESTAMP"

echo "1. Creating backup of current config..."
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo "   Backup created: $BACKUP_FILE"
echo ""

echo "2. Checking if template has been edited..."
if grep -q "YOUR_.*_KEY_HERE" "$TEMPLATE_FILE"; then
    echo "   WARNING: Template still contains placeholder values!"
    echo "   Please edit CONFIG_TEMPLATE.json and replace:"
    echo "     - YOUR_ANTHROPIC_KEY_HERE"
    echo "     - YOUR_OPENAI_KEY_HERE"
    echo "     - YOUR_OPENROUTER_KEY_HERE"
    echo ""
    read -p "Continue anyway? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Aborted. Please edit the template first."
        exit 1
    fi
fi

echo "3. Validating JSON syntax..."
if ! python3 -m json.tool "$TEMPLATE_FILE" > /dev/null 2>&1; then
    echo "   ERROR: Template contains invalid JSON!"
    echo "   Please fix the syntax errors before continuing."
    exit 1
fi
echo "   JSON is valid."
echo ""

echo "4. Applying new config..."
cp "$TEMPLATE_FILE" "$CONFIG_FILE"
echo "   Config updated!"
echo ""

echo "5. To restore from backup if something breaks:"
echo "   cp $BACKUP_FILE $CONFIG_FILE"
echo ""

echo "=== Done! ==="
echo "Restart OpenClaw to apply changes."
