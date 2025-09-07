# Pangea

[![CI Status](https://github.com/drzln/pangea/workflows/CI/badge.svg)](https://github.com/drzln/pangea/actions)
[![Ruby](https://img.shields.io/badge/ruby-3.1%2B-red.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Gem Version](https://badge.fury.io/rb/pangea.svg)](https://badge.fury.io/rb/pangea)

**Scalable infrastructure management with Ruby DSL and template-level state isolation**

Pangea is an automation-first infrastructure management tool that addresses key Terraform/OpenTofu scalability challenges through template-level state isolation, Ruby DSL compilation, and configuration-driven namespace management.

## Overview

Pangea compiles Ruby DSL templates to Terraform JSON and manages infrastructure with isolated workspaces per template, enabling infrastructure that scales with team size and complexity.

## Prerequisites

- Ruby 3.1+ (Ruby 3.3+ recommended)
- Terraform 1.5+ or OpenTofu 1.6+
- AWS CLI configured (if using AWS resources)

## Installation

### From RubyGems

```bash
gem install pangea
```

### From Source

```bash
git clone https://github.com/drzln/pangea.git
cd pangea
bundle install
bundle exec rake install
```

### Using Bundler

Add to your Gemfile:

```ruby
gem 'pangea'
```

Then run:

```bash
bundle install
```

## Usage

### Template Structure

Create Ruby files with template declarations:

```ruby
# infrastructure.rb
template :web_server do
  provider :aws do
    region "us-east-1"
  end
  
  resource :aws_instance, :web do
    ami "ami-12345678"
    instance_type "t2.micro"
    
    tags do
      Name "WebServer"
    end
  end
end

template :database do
  provider :aws do
    region "us-east-1"
  end
  
  resource :aws_rds_instance, :main do
    engine "postgres"
    instance_class "db.t2.micro"
  end
end
```

### Configuration

Create `pangea.yaml` in your project root (see `pangea.yaml.example` for a complete example):

```yaml
default_namespace: development

namespaces:
  development:
    state:
      type: local
      path: "terraform.tfstate"
  
  production:
    state:
      type: s3
      bucket: "terraform-state-prod"
      key: "pangea/terraform.tfstate"
      region: "us-east-1"
      dynamodb_table: "terraform-locks"
```

### Commands

#### Plan Changes
```bash
# Plan all templates in file (uses default namespace)
pangea plan infrastructure.rb

# Plan specific template
pangea plan infrastructure.rb --template web_server

# Plan with specific namespace
pangea plan infrastructure.rb --namespace production
```

#### Apply Changes
```bash
# Apply (auto-approves by default)
pangea apply infrastructure.rb --template web_server

# Apply with confirmation prompt (rare)
pangea apply infrastructure.rb --template web_server --no-auto-approve
```

#### Destroy Infrastructure
```bash
# Destroy (auto-approves by default)
pangea destroy infrastructure.rb --template web_server

# Destroy with confirmation prompt (rare)
pangea destroy infrastructure.rb --template web_server --no-auto-approve
```

## Key Features

### 🏗️ Template-Level State Isolation
- Each template gets its own workspace and state file
- More granular than industry standard directory-based approaches
- Reduces blast radius and enables parallel development

### 🤖 Automation-First Design
- Auto-approval by default for streamlined CI/CD
- No `init` command needed - initialization is automatic
- Non-interactive operation for automation workflows

### 📦 Ruby DSL Compilation
- Type-safe resource functions with RBS definitions
- Compile-time validation using dry-struct
- Access to full Ruby ecosystem for complex logic

### 🌐 Multi-Environment Management
- Configuration-driven namespace management
- Support for local, S3, and custom backends
- Automatic state key generation prevents conflicts

### 🔧 Developer Experience
- Beautiful colorized output and progress indicators  
- Default namespace support reduces CLI verbosity
- Comprehensive examples and documentation

## Architecture

- Templates are compiled to separate workspaces
- Each workspace manages its own Terraform state
- Namespaces configure shared backend settings
- No init command needed - initialization is automatic

## Why Pangea?

### vs. Directory-Based Terraform
- **Reduced File Sprawl**: Multiple templates in single files vs scattered directories
- **Automatic Backend Management**: No manual backend configuration per component  
- **Ruby DSL Power**: Better abstraction than HCL for complex logic
- **Code Reuse**: Shared helper methods and logic within files

### vs. Terragrunt
- **Configuration Simplicity**: Single YAML file vs multiple terragrunt.hcl files
- **Template Isolation**: Built-in template-level isolation vs manual workspace management
- **Ruby Ecosystem**: Access to full Ruby library ecosystem
- **No DRY Complexity**: Templates handle repetition naturally

### vs. Terraform Workspaces
- **True State Isolation**: Completely separate state files vs shared backend
- **Security Boundaries**: No cross-template state access
- **Template Granularity**: Template-specific configurations
- **Operational Clarity**: Template names match infrastructure components

## Examples

See the [`examples/`](examples/) directory for complete infrastructure templates:

- [Simple Web Server](examples/simple.rb) - Basic single-template example
- [Scalable Infrastructure](examples/scalable_infrastructure.rb) - Multi-template web application
- [Advanced ML Infrastructure](examples/advanced_ml_healthcare_infrastructure.rb) - Complex healthcare ML platform

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on:

- Development setup
- Running tests
- Submitting pull requests
- Code style guidelines

## Community

- [GitHub Discussions](https://github.com/drzln/pangea/discussions) - Questions and community
- [Issues](https://github.com/drzln/pangea/issues) - Bug reports and feature requests
- [Security Policy](SECURITY.md) - Reporting security vulnerabilities

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on [terraform-synthesizer](https://github.com/VaultTech/terraform-synthesizer) for Ruby-to-Terraform compilation
- Inspired by the need for better infrastructure-as-code scalability
- Thanks to all [contributors](https://github.com/drzln/pangea/contributors)
