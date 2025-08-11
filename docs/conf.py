# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

import os
import sys
import yaml

# Add the parent directory to the path to access galaxy.yml
sys.path.insert(0, os.path.abspath('..'))

# Read version from galaxy.yml
def get_version_from_galaxy():
    galaxy_path = os.path.join(os.path.dirname(__file__), '..', 'galaxy.yml')
    try:
        with open(galaxy_path, 'r') as f:
            galaxy_data = yaml.safe_load(f)
            return galaxy_data.get('version', '0.9.7')
    except (FileNotFoundError, yaml.YAMLError):
        return '0.9.7'  # Fallback version

project = 'Qubinode KVM Host Setup Collection'
copyright = '2025, Qubinode Project'
author = 'Tosin Akinosho, Rodrique Heron'
release = get_version_from_galaxy()
version = release

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.viewcode',
    'sphinx.ext.napoleon',
    'sphinx.ext.intersphinx',
    'sphinx.ext.todo',
    'sphinx.ext.coverage',
    'sphinx.ext.ifconfig',
    'myst_parser',
    'sphinx_copybutton',
    'sphinx_tabs.tabs',
    'sphinx_design',
]

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store', 'archive/**', 'venv/**', '**/.git/**']

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'furo'
html_static_path = ['_static']

# Theme options for Furo
html_theme_options = {
    "source_repository": "https://github.com/Qubinode/qubinode_kvmhost_setup_collection/",
    "source_branch": "main",
    "source_directory": "docs/",
    "navigation_with_keys": True,
    "top_of_page_button": "edit",
}

# Furo theme doesn't use custom sidebars

# -- MyST Parser configuration -----------------------------------------------

myst_enable_extensions = [
    "amsmath",
    "colon_fence",
    "deflist",
    "dollarmath",
    "fieldlist",
    "html_admonition",
    "html_image",
    "linkify",
    "replacements",
    "smartquotes",
    "strikethrough",
    "substitution",
    "tasklist",
]

# -- Intersphinx configuration -----------------------------------------------

intersphinx_mapping = {
    'python': ('https://docs.python.org/3/', None),
    'ansible': ('https://docs.ansible.com/ansible/latest/', None),
}

# -- Options for todo extension ----------------------------------------------

todo_include_todos = True

# -- Project-specific configuration ------------------------------------------

# GitHub repository information
html_context = {
    "display_github": True,
    "github_user": "Qubinode",
    "github_repo": "qubinode_kvmhost_setup_collection",
    "github_version": "main",
    "conf_py_path": "/docs/",
}

# Custom CSS
html_css_files = [
    'custom.css',
]

# Custom JavaScript
html_js_files = [
    'custom.js',
]

# Logo configuration (uncomment when files are available)
# html_logo = '_static/logo.png'
# html_favicon = '_static/favicon.ico'

# GitHub integration
html_context = {
    "display_github": True,
    "github_user": "Qubinode",
    "github_repo": "qubinode_kvmhost_setup_collection",
    "github_version": "main",
    "conf_py_path": "/docs/",
}

# Search configuration
html_search_language = 'en'

# Copy button configuration
copybutton_prompt_text = r">>> |\.\.\. |\$ |In \[\d*\]: | {2,5}\.\.\.: | {5,8}: "
copybutton_prompt_is_regexp = True
copybutton_only_copy_prompt_lines = True
copybutton_remove_prompts = True

# Tabs configuration
sphinx_tabs_valid_builders = ['html']
sphinx_tabs_disable_tab_closing = True

# Custom roles and directives
rst_prolog = """
.. |project| replace:: Qubinode KVM Host Setup Collection
.. |version| replace:: 0.9.7
.. |ansible_version| replace:: 2.13+
.. |python_version| replace:: 3.9+
"""

# -- Custom configuration for Diátaxis structure ----------------------------

# Keep theme options simple for karma-sphinx-theme compatibility

# Source file suffixes
source_suffix = {
    '.rst': None,
    '.md': None,
}

# Master document
master_doc = 'index'

# Language
language = 'en'

# Pygments style
pygments_style = 'sphinx'

# If true, `todo` and `todoList` produce output, else they produce nothing.
todo_include_todos = False

# -- Options for LaTeX output ------------------------------------------------

latex_elements = {
    'papersize': 'letterpaper',
    'pointsize': '10pt',
    'preamble': '',
    'fncychap': '',
    'maketitle': '',
    'printindex': '',
}

# Grouping the document tree into LaTeX files. List of tuples
# (source start file, target name, title, author, documentclass [howto, manual, or own class]).
latex_documents = [
    (master_doc, 'QuibodeKVMHostSetupCollection.tex', 'Qubinode KVM Host Setup Collection Documentation',
     'Qubinode Project', 'manual'),
]

# -- Options for manual page output ------------------------------------------

# One entry per manual page. List of tuples
# (source start file, name, description, authors, manual section).
man_pages = [
    (master_doc, 'qubinode-kvm-host-setup-collection', 'Qubinode KVM Host Setup Collection Documentation',
     [author], 1)
]

# -- Options for Texinfo output ----------------------------------------------

# Grouping the document tree into Texinfo files. List of tuples
# (source start file, target name, title, author,
#  dir menu entry, description, category)
texinfo_documents = [
    (master_doc, 'QuibodeKVMHostSetupCollection', 'Qubinode KVM Host Setup Collection Documentation',
     author, 'QuibodeKVMHostSetupCollection', 'Ansible Collection for KVM Host Setup.',
     'Miscellaneous'),
]

# -- Extension configuration -------------------------------------------------

# Napoleon settings
napoleon_google_docstring = True
napoleon_numpy_docstring = True
napoleon_include_init_with_doc = False
napoleon_include_private_with_doc = False
napoleon_include_special_with_doc = True
napoleon_use_admonition_for_examples = False
napoleon_use_admonition_for_notes = False
napoleon_use_admonition_for_references = False
napoleon_use_ivar = False
napoleon_use_param = True
napoleon_use_rtype = True
napoleon_preprocess_types = False
napoleon_type_aliases = None
napoleon_attr_annotations = True
