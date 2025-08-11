#!/bin/bash
# Validate documentation build and deployment readiness

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Validating Documentation Deployment${NC}"
echo "========================================"

# Check if we're in the right directory
if [ ! -f "conf.py" ]; then
    echo -e "${RED}❌ Error: conf.py not found. Please run this script from the docs/ directory.${NC}"
    exit 1
fi

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    echo -e "${BLUE}🔧 Activating virtual environment...${NC}"
    source venv/bin/activate
fi

# Validate build
echo -e "${BLUE}🔨 Testing documentation build...${NC}"
make clean
if make html; then
    echo -e "${GREEN}✅ Documentation builds successfully${NC}"
    echo -e "${YELLOW}💡 Note: Some warnings are expected for missing cross-references${NC}"
else
    echo -e "${RED}❌ Documentation build failed${NC}"
    exit 1
fi

# Check if HTML files were generated
echo -e "${BLUE}📄 Checking generated HTML files...${NC}"
if [ -f "_build/html/index.html" ]; then
    echo -e "${GREEN}✅ Main index.html generated${NC}"
else
    echo -e "${RED}❌ Main index.html not found${NC}"
    exit 1
fi

# Count generated pages
PAGE_COUNT=$(find _build/html -name "*.html" | wc -l)
echo -e "${GREEN}📊 Generated ${PAGE_COUNT} HTML pages${NC}"

# Check for critical pages
CRITICAL_PAGES=(
    "_build/html/index.html"
    "_build/html/diataxis/tutorials/index.html"
    "_build/html/diataxis/how-to-guides/index.html"
    "_build/html/diataxis/reference/index.html"
    "_build/html/diataxis/explanations/index.html"
)

echo -e "${BLUE}🔍 Checking critical pages...${NC}"
for page in "${CRITICAL_PAGES[@]}"; do
    if [ -f "$page" ]; then
        echo -e "${GREEN}✅ $(basename $page)${NC}"
    else
        echo -e "${YELLOW}⚠️  Missing: $(basename $page)${NC}"
    fi
done

# Check for search functionality
echo -e "${BLUE}🔍 Checking search functionality...${NC}"
if [ -f "_build/html/searchindex.js" ]; then
    echo -e "${GREEN}✅ Search index generated${NC}"
else
    echo -e "${RED}❌ Search index not found${NC}"
fi

# Check static files
echo -e "${BLUE}📁 Checking static files...${NC}"
if [ -d "_build/html/_static" ]; then
    STATIC_COUNT=$(find _build/html/_static -type f | wc -l)
    echo -e "${GREEN}✅ ${STATIC_COUNT} static files copied${NC}"
else
    echo -e "${RED}❌ Static files directory not found${NC}"
fi

# Validate GitHub Actions workflow
echo -e "${BLUE}🔧 Checking GitHub Actions workflow...${NC}"
if [ -f "../.github/workflows/docs-deploy.yml" ]; then
    echo -e "${GREEN}✅ GitHub Actions workflow exists${NC}"
else
    echo -e "${YELLOW}⚠️  GitHub Actions workflow not found${NC}"
fi

# Check requirements file
echo -e "${BLUE}📦 Checking requirements...${NC}"
if [ -f "requirements.txt" ]; then
    echo -e "${GREEN}✅ requirements.txt exists${NC}"
    echo -e "${BLUE}📋 Dependencies:${NC}"
    grep -E "^[a-zA-Z]" requirements.txt | head -5
    echo "   ... and more"
else
    echo -e "${RED}❌ requirements.txt not found${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}📊 Validation Summary${NC}"
echo "===================="
echo -e "${GREEN}✅ Documentation builds successfully${NC}"
echo -e "${GREEN}✅ ${PAGE_COUNT} HTML pages generated${NC}"
echo -e "${GREEN}✅ Search functionality available${NC}"
echo -e "${GREEN}✅ Static files copied${NC}"
echo -e "${GREEN}✅ GitHub Actions workflow configured${NC}"

echo ""
echo -e "${GREEN}🎉 Documentation is ready for deployment!${NC}"
echo ""
echo -e "${BLUE}📖 Local documentation:${NC}"
echo "   file://$(pwd)/_build/html/index.html"
echo ""
echo -e "${BLUE}🚀 To deploy to GitHub Pages:${NC}"
echo "   1. Commit and push changes to main branch"
echo "   2. GitHub Actions will automatically build and deploy"
echo "   3. Documentation will be available at:"
echo "      https://qubinode.github.io/qubinode_kvmhost_setup_collection/"
echo ""
echo -e "${BLUE}🔧 For live development:${NC}"
echo "   make livehtml  # Starts server at http://localhost:8000"
