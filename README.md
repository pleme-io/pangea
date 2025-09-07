# Pangea

Beautiful infrastructure management with Ruby DSL and OpenTofu/Terraform.

## Overview

Pangea compiles Ruby DSL templates to Terraform JSON and manages infrastructure with isolated workspaces per template.

## Installation

```bash
gem install pangea
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

Create `pangea.yml` in your project or `~/.config/pangea/pangea.yml`:

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

- **Template Isolation**: Each template creates its own workspace
- **Automation-First**: Auto-approval is default, --no-auto-approve for confirmation
- **Default Namespace**: Configure once in config file, no need to repeat --namespace
- **Beautiful Output**: Colorized diffs and progress indicators
- **State Management**: Automatic backend configuration and workspace isolation
- **Multiple Backends**: Support for S3 (with DynamoDB locking) and local state

## Architecture

- Templates are compiled to separate workspaces
- Each workspace manages its own Terraform state
- Namespaces configure shared backend settings
- No init command needed - initialization is automatic

## Examples

See the `examples/` directory for complete infrastructure templates.
