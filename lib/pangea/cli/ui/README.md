# Pangea CLI Output Design System

Unified, beautiful, and consistent CLI output system for Pangea commands.

## Overview

This design system provides reusable components and utilities for creating consistent, beautiful command-line output across all Pangea commands.

## Core Components

### OutputFormatter (`output_formatter.rb`)

The foundational formatter providing consistent styling, icons, colors, and layout primitives.

**Key Features:**
- Icon system with 30+ semantic icons
- Consistent color scheme for status, actions, and resources
- Layout primitives (headers, sections, lists, tables)
- Box displays (info, warning, error)
- JSON syntax highlighting
- Diff output formatting

**Usage:**
```ruby
formatter = Pangea::CLI::UI::OutputFormatter.new

# Section headers
formatter.section_header('My Section', icon: :template)

# Status messages
formatter.status(:success, 'Operation completed')

# Key-value pairs
formatter.kv_pair('Name', 'production_dns')

# Resource display
formatter.resource('aws_route53_record', 'www_domain', attributes: {
  name: 'www.example.com',
  type: 'CNAME'
})

# Tables
formatter.table(['Name', 'Type'], [['resource1', 'EC2'], ['resource2', 'S3']])

# Boxes
formatter.warning_box('Warnings', ['Warning 1', 'Warning 2'])
```

### TemplateDisplay (`template_display.rb`)

Specialized module for displaying compiled Terraform templates consistently.

**Features:**
- Template metadata display
- Backend configuration
- Provider configuration
- Resource summary with grouping
- Variables and outputs
- Full JSON display option
- Resource-specific attribute extraction

**Usage:**
```ruby
include Pangea::CLI::UI::TemplateDisplay

# Display complete template
resource_analysis = display_compiled_template(template_name, terraform_json, show_full: false)

# Individual sections
display_backend_config(parsed_json)
display_provider_config(parsed_json)
display_resources_summary(parsed_json)
```

### PlanDisplay (`plan_display.rb`)

Specialized module for displaying Terraform plans and diffs.

**Features:**
- Complete plan visualization
- Resource change details by action (create/update/delete/replace)
- Terraform diff output
- Impact visualization
- Confirmation prompts
- Next steps guidance

**Usage:**
```ruby
include Pangea::CLI::UI::PlanDisplay

# Display complete plan
display_plan(plan_result, resource_analysis: analysis, show_diff: true)

# Individual components
display_resource_changes(changes, resource_analysis)
display_impact_visualization(changes)
display_confirmation_prompt(action: 'apply', timeout: 5)
```

### CommandDisplay (`command_display.rb`)

Common display utilities for all commands.

**Features:**
- Command headers
- Namespace information
- Workspace information
- Operation success/failure banners
- State display
- Terraform outputs
- Cost estimation
- Execution time tracking

**Usage:**
```ruby
include Pangea::CLI::UI::CommandDisplay

# Command header
display_command_header('Apply Infrastructure', icon: :applying)

# Namespace info
display_namespace_info(namespace_entity)

# Success/failure
display_operation_success('Apply', details: { 'Resources' => '4' })
display_operation_failure('Apply', error_message)

# Outputs
display_terraform_outputs(output_result)
```

## Design System Constants

### Icons

Over 30 semantic icons for different purposes:

**Status:** ✓ ✗ ⚠ ℹ ⧖
**Actions:** + ~ - ± ⬇ ↻
**Resources:** 📄 🏗️ ☁️ 🔧 🏷️ 📁 ⚙️ 📊 📋 📤 📈 🔄 🔒 🌐 🗄️ 💻 💾
**Process:** ⚙️ ✅ ❌ 🔍 🚀 💥

### Colors

Consistent color scheme across all output:

**Status:**
- Success: green
- Error: red
- Warning: yellow
- Info: blue
- Pending: cyan

**Actions:**
- Create: green
- Update: yellow
- Delete: red
- Replace: magenta

**Emphasis:**
- Primary: cyan
- Secondary: bright_cyan
- Muted: bright_black
- Highlight: bright_white

## Integration Guide

### For New Commands

1. Include the relevant display modules:
```ruby
class MyCommand < BaseCommand
  include UI::TemplateDisplay
  include UI::PlanDisplay
  include UI::CommandDisplay

  def run
    display_command_header('My Command', icon: :template)
    # ... command logic
  end
end
```

2. Use shared display methods consistently
3. Follow the established patterns for output structure

### For Existing Commands

1. Identify repeated display code
2. Replace with appropriate shared methods
3. Test for visual consistency
4. Update error handling to use shared error displays

## Layout Patterns

### Standard Command Flow

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Command Name
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏷️  Namespace:
  Name: production
  Backend: s3
    Bucket: my-bucket
    Region: us-east-1

📄 Compiled Template: template_name
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Template Information ℹ:
  Name: template_name
  Resources: 4
  Providers: 1

🔧 Backend Configuration:
  Type: s3
  Bucket: my-bucket
  Key: state/template_name/terraform.tfstate

... (operation output) ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Operation Completed Successfully!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Summary:
  Template: template_name
  Resources managed: 4
  Duration: 2.5s
```

## Best Practices

1. **Consistency First**: Always use shared components rather than custom formatting
2. **Semantic Icons**: Choose icons that match the content semantics
3. **Color Purpose**: Use colors to convey meaning (success/error/warning)
4. **Progressive Disclosure**: Show summaries first, details on demand
5. **Helpful Context**: Always provide actionable next steps
6. **Error Clarity**: Make errors obvious and provide remediation steps
7. **Performance Awareness**: Show progress indicators for long operations

## Examples

See `apply.rb` for a complete example of using all components together.

## Future Enhancements

- [ ] Interactive mode with prompts
- [ ] Progress bars for multi-step operations
- [ ] ASCII art for large operations
- [ ] Export functionality (JSON, YAML, Markdown)
- [ ] Customizable color schemes
- [ ] Accessibility modes (no colors, screen reader friendly)
