# Sphinx Documentation Setup Guide

This guide explains how to set up and deploy the Sphinx documentation with karma-sphinx-theme for GitHub Pages.

## 🚀 Quick Setup

### 1. Install Dependencies

```bash
# Navigate to docs directory
cd docs

# Install Python dependencies
pip install -r requirements.txt

# Or install karma-sphinx-theme specifically
pip install karma-sphinx-theme
```

### 2. Build Documentation Locally

```bash
# Using the build script (recommended)
./build-docs.sh

# Or manually
make clean
make html

# For live development
make livehtml  # Opens at http://localhost:8000
```

### 3. Deploy to GitHub Pages

The documentation automatically deploys to GitHub Pages when you push changes to the `main` branch that affect the `docs/` directory.

**GitHub Pages URL**: `https://qubinode.github.io/qubinode_kvmhost_setup_collection/`

## 📁 Documentation Structure

### Sphinx Configuration
```
docs/
├── conf.py                 # Sphinx configuration
├── index.rst              # Main documentation index
├── requirements.txt        # Python dependencies
├── Makefile               # Build commands
├── build-docs.sh          # Local build script
├── _static/               # Static assets (CSS, JS, images)
├── _templates/            # Custom Sphinx templates
└── diataxis/              # Diátaxis documentation structure
    ├── tutorials/         # Learning-oriented guides
    ├── how-to-guides/     # Problem-oriented guides
    ├── reference/         # Information-oriented docs
    └── explanations/      # Understanding-oriented docs
```

### Key Configuration Files

#### conf.py
- **Theme**: karma-sphinx-theme
- **Extensions**: MyST parser, copy button, tabs, design
- **GitHub Integration**: Repository links and edit buttons
- **Search**: Full-text search functionality

#### requirements.txt
- **Sphinx**: Core documentation framework
- **karma-sphinx-theme**: Modern, responsive theme
- **Extensions**: MyST parser, copy button, tabs, design elements

## 🎨 Theme Customization

### karma-sphinx-theme Features
- **Responsive Design**: Works on desktop, tablet, and mobile
- **Modern UI**: Clean, professional appearance
- **Search Integration**: Fast, client-side search
- **Navigation**: Collapsible sidebar with deep navigation
- **Code Highlighting**: Syntax highlighting for multiple languages

### Custom Styling
Custom CSS in `_static/custom.css`:
- **Diátaxis Colors**: Visual indicators for each documentation type
- **Enhanced Navigation**: Improved navigation experience
- **Mobile Optimization**: Better mobile responsiveness
- **Print Styles**: Optimized for printing

### Custom JavaScript
Custom JS in `_static/custom.js`:
- **Keyboard Navigation**: Ctrl+K for search, Ctrl+H for home
- **Copy Button Enhancement**: Visual feedback for copy operations
- **Search Suggestions**: Context-aware search suggestions
- **Section Indicators**: Visual indicators for Diátaxis sections

## 🔧 GitHub Pages Configuration

### Workflow Setup
The `.github/workflows/docs-deploy.yml` workflow:

1. **Triggers**: Pushes to main, PR changes to docs/, manual dispatch
2. **Build**: Installs dependencies, builds Sphinx documentation
3. **Validation**: Checks for broken links and build warnings
4. **Deploy**: Deploys to GitHub Pages (main branch only)
5. **Preview**: Comments on PRs with build status

### Repository Settings
To enable GitHub Pages:

1. Go to repository **Settings** → **Pages**
2. Set **Source** to "GitHub Actions"
3. The workflow will handle the rest automatically

### Custom Domain (Optional)
To use a custom domain:

1. Add `CNAME` file to `docs/_static/` with your domain
2. Configure DNS to point to `username.github.io`
3. Enable HTTPS in repository settings

## 🧪 Local Development

### Development Workflow

```bash
# 1. Set up environment
cd docs
./build-docs.sh

# 2. Start live reload (recommended for development)
make livehtml

# 3. Make changes to documentation files

# 4. View changes automatically in browser at http://localhost:8000

# 5. Build final version
make clean && make html

# 6. Check for issues
make linkcheck
```

### Testing Documentation

```bash
# Build with warnings as errors
make html SPHINXOPTS="-W --keep-going -n"

# Check for broken links
make linkcheck

# Test different output formats
make epub    # EPUB format
make latex   # LaTeX format
make text    # Plain text format
```

## 🔍 Troubleshooting

### Common Issues

#### Build Failures
```bash
# Check Python version (3.9+ required)
python --version

# Reinstall dependencies
pip install --upgrade -r requirements.txt

# Clear cache and rebuild
make clean && make html
```

#### Missing Dependencies
```bash
# Install missing extensions
pip install sphinx-copybutton sphinx-tabs sphinx-design

# Update all dependencies
pip install --upgrade -r requirements.txt
```

#### Theme Issues
```bash
# Reinstall karma-sphinx-theme
pip uninstall karma-sphinx-theme
pip install karma-sphinx-theme

# Check theme configuration in conf.py
grep -n "karma_sphinx_theme" conf.py
```

### GitHub Pages Issues

#### Deployment Failures
1. Check workflow logs in GitHub Actions
2. Verify permissions are set correctly
3. Ensure Pages is enabled in repository settings
4. Check for build warnings or errors

#### Missing Content
1. Verify all files are committed to Git
2. Check `.gitignore` doesn't exclude documentation files
3. Ensure file paths are correct in `index.rst`
4. Validate RST/Markdown syntax

## 📊 Documentation Metrics

### Build Performance
- **Build Time**: ~2-3 minutes for complete build
- **Page Count**: 25+ documentation pages
- **Search Index**: Full-text search across all content
- **Mobile Support**: Responsive design for all devices

### Content Coverage
- **Tutorials**: 4 comprehensive learning guides
- **How-To Guides**: 6+ problem-solving guides
- **Reference**: 8+ technical specification documents
- **Explanations**: 4+ architectural and conceptual documents

## 🔄 Maintenance

### Regular Tasks
- **Dependency Updates**: Monthly dependency updates
- **Link Validation**: Weekly link checking
- **Content Review**: Quarterly content accuracy review
- **Performance Monitoring**: Monitor build times and site performance

### Automation
- **Automated Builds**: Every push to main branch
- **Dependency Updates**: Dependabot manages Python dependencies
- **Link Checking**: Automated link validation in CI/CD
- **Quality Gates**: Build must pass before deployment

## 🔗 Resources

### Sphinx Documentation
- [Sphinx Documentation](https://www.sphinx-doc.org/)
- [MyST Parser](https://myst-parser.readthedocs.io/)
- [Sphinx Design](https://sphinx-design.readthedocs.io/)

### Theme Documentation
- [karma-sphinx-theme](https://pypi.org/project/karma-sphinx-theme/)
- [Sphinx Themes Gallery](https://sphinx-themes.org/)

### GitHub Pages
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [GitHub Actions for Pages](https://github.com/actions/deploy-pages)

---

*This guide covers the complete Sphinx setup for the collection. For content creation guidelines, see the [Contributing Guidelines](diataxis/how-to-guides/developer/contributing-guidelines.md).*
