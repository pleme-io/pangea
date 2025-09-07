# Pangea Agent Guide

This guide explains how AI agents and automation tools can effectively use Pangea for infrastructure management.

## Overview

Pangea provides comprehensive JSON-based interfaces designed specifically for agents. All commands support JSON output, and special agent commands provide deep introspection capabilities.

## Agent-Specific Commands

### 1. Inspect Command

The `inspect` command provides comprehensive information about Pangea's capabilities and infrastructure:

```bash
# Inspect all available information
pangea inspect --format json

# Inspect specific types
pangea inspect --type resources     # List all resource functions
pangea inspect --type architectures # List architecture patterns
pangea inspect --type components     # List available components
pangea inspect --type namespaces    # Show namespace configurations
pangea inspect --type config        # Show Pangea configuration

# Inspect a specific template file
pangea inspect infrastructure.rb --type templates

# Render a template to Terraform JSON
pangea inspect infrastructure.rb --type render --template web_server
```

### 2. Agent Command

The `agent` command provides advanced analysis and suggestions:

```bash
# Analyze infrastructure for issues and improvements
pangea agent analyze infrastructure.rb

# Validate template syntax and structure
pangea agent validate infrastructure.rb

# Estimate infrastructure costs
pangea agent cost infrastructure.rb

# Security scan for common issues
pangea agent security infrastructure.rb

# Analyze dependencies between resources
pangea agent dependencies infrastructure.rb

# Get improvement suggestions
pangea agent suggest infrastructure.rb

# Explain what infrastructure does
pangea agent explain infrastructure.rb
```

## JSON Output for Standard Commands

All standard commands support JSON output with the `--json` flag:

```bash
# Plan with JSON output
pangea plan infrastructure.rb --json

# Apply with JSON output  
pangea apply infrastructure.rb --json

# Destroy with JSON output
pangea destroy infrastructure.rb --json
```

## Using the Ruby Agent API

For deeper integration, use the Pangea Agent API directly:

```ruby
require 'pangea/agent'

agent = Pangea::Agent.new

# List all available resources
resources = agent.list_resources
puts resources[:total]  # Total count
puts resources[:resources]  # Array of resource details

# Analyze a template
analysis = agent.analyze_template('infrastructure.rb')
puts analysis[:templates]  # Template analysis

# Compile template to Terraform JSON
result = agent.compile_template('infrastructure.rb', namespace: 'production')
puts result[:results]  # Compiled JSON

# Validate template syntax
validation = agent.validate_template('infrastructure.rb')
puts validation[:all_valid]  # Boolean
puts validation[:validations]  # Detailed results

# Search for resources
matches = agent.search_resources('vpc')
puts matches[:matches]  # Matching resources

# Get resource information
info = agent.get_resource_info('aws_vpc')
puts info[:documentation]  # Resource docs
```

## Response Formats

### Resource Listing
```json
{
  "total": 523,
  "resources": [
    {
      "function": "aws_vpc",
      "service": "vpc",
      "resource": "vpc",
      "file": "/path/to/vpc.rb"
    }
  ]
}
```

### Template Analysis
```json
{
  "file": "infrastructure.rb",
  "templates": [
    {
      "name": "networking",
      "line_number": 10,
      "metrics": {
        "lines": 45,
        "resources": 12,
        "outputs": 3,
        "providers": ["aws"]
      },
      "resource_functions": [
        {"function": "aws_vpc", "name": "main"},
        {"function": "aws_subnet", "name": "public"}
      ],
      "dependencies": [
        {"type": "aws_vpc", "name": "main", "attribute": "id"}
      ]
    }
  ]
}
```

### Plan Output
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "success": true,
  "namespace": "production",
  "template": "web_server",
  "changes": {
    "has_changes": true,
    "summary": {
      "add": 5,
      "change": 2,
      "destroy": 0
    }
  },
  "resources": {
    "create": [
      {"type": "aws_instance", "name": "web", "full_address": "aws_instance.web"}
    ],
    "update": [],
    "delete": []
  }
}
```

## Best Practices for Agents

### 1. Always Validate Before Apply
```bash
# First validate
pangea agent validate infrastructure.rb

# Then plan
pangea plan infrastructure.rb --json

# Finally apply if validation and plan succeed
pangea apply infrastructure.rb --json
```

### 2. Use Introspection for Discovery
```bash
# Discover available resources before generating code
pangea inspect --type resources | jq '.resources[] | select(.service == "ec2")'

# Check existing templates for patterns
pangea inspect project.rb --type templates
```

### 3. Leverage Analysis for Better Code Generation
```bash
# Analyze existing infrastructure to understand patterns
pangea agent analyze infrastructure.rb

# Use suggestions to improve generated code
pangea agent suggest infrastructure.rb
```

### 4. Handle Errors Gracefully
All JSON responses include error information when failures occur:

```json
{
  "error": true,
  "message": "File not found: infrastructure.rb",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### 5. Use Cost Estimation
Before applying changes, estimate costs:

```bash
pangea agent cost infrastructure.rb
```

## Common Agent Workflows

### 1. Generate New Infrastructure
```bash
# 1. List available resources
pangea inspect --type resources

# 2. Generate template code
# (Agent generates infrastructure.rb)

# 3. Validate the generated code
pangea agent validate infrastructure.rb

# 4. Analyze for issues
pangea agent analyze infrastructure.rb

# 5. Plan changes
pangea plan infrastructure.rb --json

# 6. Apply if everything looks good
pangea apply infrastructure.rb --json
```

### 2. Modify Existing Infrastructure
```bash
# 1. Analyze current state
pangea agent analyze infrastructure.rb

# 2. Understand dependencies
pangea agent dependencies infrastructure.rb

# 3. Make modifications
# (Agent modifies infrastructure.rb)

# 4. Validate changes
pangea agent validate infrastructure.rb

# 5. Check what will change
pangea plan infrastructure.rb --json

# 6. Apply changes
pangea apply infrastructure.rb --json
```

### 3. Infrastructure Explanation
```bash
# Get a human-readable explanation
pangea agent explain infrastructure.rb

# Get detailed technical analysis
pangea agent analyze infrastructure.rb
```

## Tips for Effective Agent Usage

1. **Resource Function Discovery**: Use `search_resources` to find the right resource functions
2. **Template Isolation**: Use `--template` flag to work with specific templates
3. **Namespace Awareness**: Always specify namespace or use default_namespace in config
4. **Incremental Changes**: Make small, validated changes rather than large rewrites
5. **State Awareness**: Use inspect with `--type state` to understand current state
6. **Cost Consciousness**: Always estimate costs before applying changes
7. **Security First**: Run security scans on generated infrastructure

## Advanced Agent Features

### Batch Operations
Process multiple templates or files:

```ruby
files = Dir.glob("infrastructure/*.rb")
files.each do |file|
  result = agent.analyze_template(file)
  # Process results
end
```

### Custom Analysis
Extend the agent with custom analysis:

```ruby
class CustomAgent < Pangea::Agent
  def custom_analysis(file_path)
    analysis = analyze_template(file_path)
    # Add custom logic
    analysis
  end
end
```

### Integration with CI/CD
Use JSON output for CI/CD integration:

```bash
# In CI pipeline
PLAN_OUTPUT=$(pangea plan infrastructure.rb --json)
HAS_CHANGES=$(echo $PLAN_OUTPUT | jq '.changes.has_changes')

if [ "$HAS_CHANGES" = "true" ]; then
  # Notify for approval
fi
```

## Conclusion

Pangea is designed to be agent-friendly from the ground up. With comprehensive JSON interfaces, deep introspection capabilities, and analysis tools, agents can effectively manage infrastructure as code with confidence and precision.