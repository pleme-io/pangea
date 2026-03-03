# Pangea Guides

Welcome to the comprehensive guide collection for Pangea - scalable infrastructure management with Ruby DSL and template-level state isolation.

## 📚 Guide Index

### Getting Started
**[Getting Started with Pangea](getting-started.md)**
Your first steps with Pangea, from installation to deploying your first infrastructure template. Learn the core concepts through hands-on examples.

**What you'll learn:**
- Installation and setup
- Basic template structure
- Resource references and dependencies
- Environment promotion workflow
- Template isolation benefits

---

### Core Concepts

**[Template Isolation: Pangea's Secret to Scalable Infrastructure](template-isolation.md)**
Deep dive into Pangea's unique template-level state isolation approach and how it solves traditional Terraform scaling challenges.

**What you'll learn:**
- How template isolation works
- Benefits over directory-based approaches
- Cross-template communication patterns
- Team collaboration strategies
- Best practices for template organization

**[Multi-Environment Management: One Codebase, Multiple Environments](multi-environment-management.md)**
Master Pangea's namespace system for managing development, staging, production, and specialized environments with the same infrastructure code.

**What you'll learn:**
- Namespace configuration patterns
- Environment-specific customizations
- Backend security per environment
- Blue-green deployment strategies
- Environment promotion workflows

**[Type-Safe Infrastructure: Catching Errors Before Deployment](type-safe-infrastructure.md)**
Leverage Pangea's type-safe approach with RBS definitions and dry-struct validation to prevent configuration errors.

**What you'll learn:**
- Three layers of type safety
- RBS integration and IDE support
- Runtime validation patterns
- Complex nested validation
- Migration from untyped infrastructure

---

### Migration and Integration

**[Migration from Terraform: Your Path to Scalable Infrastructure](migration-from-terraform.md)**
Complete strategy for migrating existing Terraform codebases to Pangea while maintaining infrastructure availability.

**What you'll learn:**
- Migration assessment and planning
- Three migration approaches
- Converting modules to components
- State migration strategies
- Common challenges and solutions

**[CI/CD Integration: Automating Infrastructure with Pangea](cicd-integration.md)**
Integrate Pangea with popular CI/CD platforms and implement best practices for automated infrastructure deployment.

**What you'll learn:**
- GitHub Actions integration
- GitLab CI and Jenkins setup
- Azure DevOps pipelines
- Blue-green and canary deployments
- Security and monitoring in CI/CD

---

### Advanced Usage

**[Advanced Patterns: Mastering Complex Infrastructure with Pangea](advanced-patterns.md)**
Explore sophisticated infrastructure patterns using Pangea's component and architecture systems for enterprise-grade solutions.

**What you'll learn:**
- Component composition patterns
- Complete architecture abstractions
- Event-driven microservices platforms
- ML/AI infrastructure platforms
- Multi-cloud abstraction strategies

---

## 🎯 Learning Path Recommendations

### **For Beginners**
1. [Getting Started](getting-started.md) - Essential first steps
2. [Template Isolation](template-isolation.md) - Core concept understanding
3. [Multi-Environment Management](multi-environment-management.md) - Production readiness

### **For Terraform Users**
1. [Migration from Terraform](migration-from-terraform.md) - Migration strategies
2. [Type-Safe Infrastructure](type-safe-infrastructure.md) - Safety improvements
3. [CI/CD Integration](cicd-integration.md) - Automation benefits

### **For Enterprise Teams**
1. [Template Isolation](template-isolation.md) - Team collaboration
2. [Advanced Patterns](advanced-patterns.md) - Enterprise architectures
3. [CI/CD Integration](cicd-integration.md) - Production deployment

### **For DevOps Engineers**
1. [CI/CD Integration](cicd-integration.md) - Automation strategies
2. [Multi-Environment Management](multi-environment-management.md) - Environment workflows
3. [Advanced Patterns](advanced-patterns.md) - Complex deployments

---

## 📖 Guide Format

Each guide follows a consistent structure:

- **Real-world problems** that Pangea solves
- **Step-by-step examples** with working code
- **Best practices** from production usage
- **Comparison with alternatives** (Terraform, Terragrunt, etc.)
- **Troubleshooting sections** for common issues

## 🚀 Quick Start

If you're new to Pangea, start with the [Getting Started Guide](getting-started.md) which will have you deploying infrastructure in minutes.

For specific use cases:
- **Migrating from Terraform?** → [Migration Guide](migration-from-terraform.md)
- **Setting up CI/CD?** → [CI/CD Integration](cicd-integration.md)
- **Building complex architectures?** → [Advanced Patterns](advanced-patterns.md)

## 💡 Key Benefits Covered

Throughout these guides, you'll discover how Pangea provides:

- **90% less configuration overhead** compared to traditional Terraform
- **Template-level state isolation** for team scalability
- **Type-safe infrastructure** to prevent deployment errors
- **Automation-first design** for seamless CI/CD integration
- **Enterprise-grade patterns** for complex infrastructure needs

## 🤝 Contributing to the Guides

Found an error or have suggestions? See our [Contributing Guidelines](../CONTRIBUTING.md) for information on how to improve these guides.

## 📞 Getting Help

- **GitHub Issues**: [Report problems or request features](https://github.com/drzln/pangea/issues)
- **Discussions**: [Ask questions and share experiences](https://github.com/drzln/pangea/discussions)
- **Documentation**: [Full API reference](../README.md)

---

*Ready to transform your infrastructure management? Start with the [Getting Started Guide](getting-started.md) and discover why teams are switching to Pangea for scalable, maintainable infrastructure.*