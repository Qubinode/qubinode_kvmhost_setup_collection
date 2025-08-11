# Diátaxis Documentation Framework

This directory contains documentation organized according to the [Diátaxis framework](https://diataxis.fr/), which provides a systematic approach to technical documentation by organizing content into four distinct categories based on user needs and context.

## Documentation Structure

```
docs/diataxis/
├── tutorials/           # Learning-oriented documentation
├── how-to-guides/       # Problem-oriented documentation
│   └── developer/       # Developer-specific guides
├── reference/           # Information-oriented documentation
└── explanations/        # Understanding-oriented documentation
```

## The Four Categories

### 📚 Tutorials (Learning-Oriented)
**Purpose**: Help newcomers learn by doing
**Audience**: End-users new to the collection
**Content**: Step-by-step guides for foundational tasks
**Focus**: Getting users started with the built and deployed collection

### 🛠️ How-To Guides (Problem-Oriented)
**Purpose**: Solve specific problems
**Audience**: End-users with specific goals
**Content**: Goal-oriented guides for common tasks
**Focus**: Practical solutions using the deployed collection

### 👨‍💻 Developer How-To Guides (Contribution-Oriented)
**Purpose**: Enable contribution and development
**Audience**: Developers and contributors
**Content**: Development environment setup, testing, building
**Focus**: Working with the source code and development process

### 📖 Reference (Information-Oriented)
**Purpose**: Provide factual information
**Audience**: Users needing specific details
**Content**: Complete API documentation, variables, modules
**Focus**: Comprehensive technical specifications

### 💡 Explanations (Understanding-Oriented)
**Purpose**: Clarify concepts and design decisions
**Audience**: Users wanting deeper understanding
**Content**: Architecture, design rationale, concepts
**Focus**: The "why" behind the implementation

## Audience Separation

### End-User Documentation
- **Tutorials**: Getting started with the collection
- **How-To Guides**: Solving problems with the collection
- **Reference**: API and configuration reference
- **Explanations**: Understanding the collection's design

### Developer Documentation
- **Developer How-To Guides**: Contributing to the collection
  - Development environment setup
  - Running tests
  - Building from source
  - Contribution guidelines

## Navigation

- [Tutorials](tutorials/) - Start here if you're new to the collection
- [How-To Guides](how-to-guides/) - Solve specific problems
- [Developer Guides](how-to-guides/developer/) - Contribute to the project
- [Reference](reference/) - Look up specific information
- [Explanations](explanations/) - Understand the bigger picture

## Maintenance

This documentation follows the "documentation-as-code" principle and is maintained alongside the codebase. When code changes, the relevant documentation sections are updated to maintain accuracy and consistency.
