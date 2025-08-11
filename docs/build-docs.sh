#!/bin/bash
# Build documentation locally for development and testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📚 Building Qubinode KVM Host Setup Collection Documentation${NC}"
echo "=================================================================="

# Check if we're in the right directory
if [ ! -f "conf.py" ]; then
    echo -e "${RED}❌ Error: conf.py not found. Please run this script from the docs/ directory.${NC}"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}📦 Creating Python virtual environment...${NC}"
    python3 -m venv venv
fi

# Activate virtual environment
echo -e "${BLUE}🔧 Activating virtual environment...${NC}"
source venv/bin/activate

# Install/upgrade dependencies
echo -e "${BLUE}📥 Installing documentation dependencies...${NC}"
pip install --upgrade pip
pip install -r requirements.txt

# Clean previous build
echo -e "${BLUE}🧹 Cleaning previous build...${NC}"
make clean

# Build documentation
echo -e "${BLUE}🔨 Building HTML documentation...${NC}"
make html

# Check for warnings and errors
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Documentation built successfully!${NC}"
    echo ""
    echo -e "${GREEN}📖 Documentation available at:${NC}"
    echo -e "${GREEN}   file://$(pwd)/_build/html/index.html${NC}"
    echo ""
    
    # Offer to open in browser
    read -p "Open documentation in browser? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v xdg-open > /dev/null; then
            xdg-open "_build/html/index.html"
        elif command -v open > /dev/null; then
            open "_build/html/index.html"
        else
            echo -e "${YELLOW}⚠️  Could not detect browser command. Please open manually:${NC}"
            echo "   file://$(pwd)/_build/html/index.html"
        fi
    fi
    
    # Offer to start live reload server
    echo ""
    read -p "Start live reload server for development? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🔄 Starting live reload server...${NC}"
        echo -e "${GREEN}📖 Documentation will be available at: http://localhost:8000${NC}"
        echo -e "${YELLOW}💡 Press Ctrl+C to stop the server${NC}"
        echo ""
        make livehtml
    fi
else
    echo -e "${RED}❌ Documentation build failed!${NC}"
    echo -e "${YELLOW}💡 Check the output above for errors and warnings.${NC}"
    exit 1
fi
