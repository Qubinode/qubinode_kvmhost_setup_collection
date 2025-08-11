// Custom JavaScript for Qubinode KVM Host Setup Collection Documentation

document.addEventListener('DOMContentLoaded', function() {
    // Add Diátaxis section indicators
    addDiataxisIndicators();
    
    // Enhance navigation
    enhanceNavigation();
    
    // Add copy functionality
    enhanceCopyButtons();
    
    // Add search enhancements
    enhanceSearch();
});

function addDiataxisIndicators() {
    // Add visual indicators for Diátaxis sections
    const path = window.location.pathname;
    
    if (path.includes('/tutorials/')) {
        document.body.classList.add('diataxis-tutorials');
    } else if (path.includes('/how-to-guides/developer/')) {
        document.body.classList.add('diataxis-developer');
    } else if (path.includes('/how-to-guides/')) {
        document.body.classList.add('diataxis-howto');
    } else if (path.includes('/reference/')) {
        document.body.classList.add('diataxis-reference');
    } else if (path.includes('/explanations/')) {
        document.body.classList.add('diataxis-explanation');
    }
}

function enhanceNavigation() {
    // Add keyboard navigation
    document.addEventListener('keydown', function(e) {
        if (e.ctrlKey || e.metaKey) {
            switch(e.key) {
                case 'k':
                    e.preventDefault();
                    focusSearch();
                    break;
                case 'h':
                    e.preventDefault();
                    goHome();
                    break;
            }
        }
    });
    
    // Add navigation hints
    const searchBox = document.querySelector('input[type="search"]');
    if (searchBox) {
        searchBox.placeholder = 'Search documentation (Ctrl+K)';
    }
}

function enhanceCopyButtons() {
    // Add success feedback for copy buttons
    document.addEventListener('click', function(e) {
        if (e.target.classList.contains('copybtn')) {
            const button = e.target;
            const originalText = button.textContent;
            
            button.textContent = '✓ Copied!';
            button.style.color = '#28a745';
            
            setTimeout(() => {
                button.textContent = originalText;
                button.style.color = '';
            }, 2000);
        }
    });
}

function enhanceSearch() {
    // Add search suggestions based on current section
    const searchBox = document.querySelector('input[type="search"]');
    if (!searchBox) return;
    
    const path = window.location.pathname;
    let suggestions = [];
    
    if (path.includes('/tutorials/')) {
        suggestions = ['installation', 'setup', 'configuration', 'first time'];
    } else if (path.includes('/how-to-guides/')) {
        suggestions = ['troubleshoot', 'configure', 'manage', 'fix'];
    } else if (path.includes('/reference/')) {
        suggestions = ['variables', 'api', 'configuration', 'parameters'];
    } else if (path.includes('/explanations/')) {
        suggestions = ['architecture', 'design', 'decisions', 'concepts'];
    }
    
    // Add search suggestions on focus
    searchBox.addEventListener('focus', function() {
        if (suggestions.length > 0 && !this.value) {
            this.placeholder = `Try: ${suggestions.join(', ')}`;
        }
    });
    
    searchBox.addEventListener('blur', function() {
        this.placeholder = 'Search documentation (Ctrl+K)';
    });
}

function focusSearch() {
    const searchBox = document.querySelector('input[type="search"]');
    if (searchBox) {
        searchBox.focus();
        searchBox.select();
    }
}

function goHome() {
    window.location.href = '/';
}

// Add version warning for development builds
if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    console.log('📚 Qubinode Documentation - Development Build');
    console.log('🔗 Production documentation: https://qubinode.github.io/qubinode_kvmhost_setup_collection/');
}
