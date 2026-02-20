#!/bin/bash
# Build script for Ironcore Arena
# Usage: ./build.sh [version] [platform]
# Example: ./build.sh 0.1.0 windows

set -e

# Configuration
PROJECT_NAME="Ironcore Arena"
PROJECT_DIR="project"
BUILD_DIR="builds"
VERSION="${1:-0.1.0}"
PLATFORM="${2:-all}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Building ${PROJECT_NAME} v${VERSION} ===${NC}"
echo ""

# Create build directory
mkdir -p "${BUILD_DIR}"

# Function to build for a specific platform
build_platform() {
    local platform=$1
    local preset=$2
    local extension=$3
    
    echo -e "${YELLOW}Building for ${platform}...${NC}"
    
    local output_name="ironcore-arena-v${VERSION}-${platform}${extension}"
    local output_path="${BUILD_DIR}/${output_name}"
    
    # Export using Godot
    godot --headless --path "${PROJECT_DIR}" --export-release "${preset}" "../${output_path}"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ ${platform} build complete: ${output_path}${NC}"
    else
        echo -e "${RED}✗ ${platform} build failed${NC}"
        return 1
    fi
}

# Build based on platform selection
case "${PLATFORM}" in
    windows|win)
        build_platform "windows" "Windows Desktop" ".exe"
        ;;
    linux)
        build_platform "linux" "Linux/X11" ""
        ;;
    macos|mac)
        build_platform "macos" "macOS" ".zip"
        ;;
    all)
        echo "Building for all platforms..."
        echo ""
        build_platform "windows" "Windows Desktop" ".exe"
        build_platform "linux" "Linux/X11" ""
        build_platform "macos" "macOS" ".zip"
        ;;
    *)
        echo -e "${RED}Unknown platform: ${PLATFORM}${NC}"
        echo "Supported platforms: windows, linux, macos, all"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}=== Build Complete ===${NC}"
echo ""
echo "Output directory: ${BUILD_DIR}/"
echo ""
ls -lh "${BUILD_DIR}/"
