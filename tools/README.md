# Pangea Resource Generation Tools

This directory contains automation tools to accelerate the implementation of AWS resources in Pangea.

## Available Tools

### 1. `generate_resource.rb`

Generate a single AWS resource with the complete directory structure and boilerplate code.

#### Usage

```bash
# Generate a single resource
./tools/generate_resource.rb aws_elasticache_cluster

# Force overwrite existing files
./tools/generate_resource.rb aws_elasticache_cluster --force

# Show help
./tools/generate_resource.rb --help
```

#### What it generates

For each resource, this tool creates:
- `lib/pangea/resources/aws_[resource]/` directory
- `types.rb` - Dry-struct type definitions with common patterns
- `resource.rb` - Resource function implementation
- `CLAUDE.md` - Implementation documentation template
- `README.md` - User-facing documentation template
- Updates `aws_resources.rb` to include the new resource

### 2. `batch_generate_resources.rb`

Generate multiple AWS resources at once from a list or predefined category.

#### Usage

```bash
# Generate from a category
./tools/batch_generate_resources.rb --category networking

# Generate from a file
./tools/batch_generate_resources.rb --file resources.yaml

# List available categories
./tools/batch_generate_resources.rb --list

# Available categories:
# - networking (14 resources)
# - compute (12 resources)
# - containers (11 resources)
# - serverless (16 resources)
# - database (17 resources)
# - security (17 resources)
# - monitoring (10 resources)
# - storage (16 resources)
```

#### File Formats

**YAML Format** (`resources.yaml`):
```yaml
resources:
  - aws_eip
  - aws_eip_association
  - aws_network_interface
```

**JSON Format** (`resources.json`):
```json
{
  "resources": [
    "aws_eip",
    "aws_eip_association",
    "aws_network_interface"
  ]
}
```

**Text Format** (`resources.txt`):
```
aws_eip
aws_eip_association
aws_network_interface
```

### 3. `analyze_terraform_docs.rb`

Analyze Terraform AWS Provider documentation to extract resource information and generate enhanced implementations.

#### Usage

```bash
# Analyze a resource and display info
./tools/analyze_terraform_docs.rb aws_elasticache_cluster

# Save analysis to YAML file
./tools/analyze_terraform_docs.rb aws_elasticache_cluster --output

# Generate enhanced code from analysis
./tools/analyze_terraform_docs.rb --generate aws_elasticache_cluster_analysis.yaml
```

#### Features

- Extracts resource arguments (required/optional)
- Identifies attribute types from descriptions
- Collects available outputs/attributes
- Finds example usage from documentation
- Generates enhanced type definitions based on actual Terraform docs

## Workflow Examples

### Quick Start: Generate a Single Resource

```bash
# 1. Generate the resource structure
./tools/generate_resource.rb aws_elasticache_cluster

# 2. Review and customize the generated files
# 3. Add specific validations and computed properties
# 4. Update examples in README.md
# 5. Test the implementation
```

### Batch Generation for a Service

```bash
# 1. Generate all database-related resources
./tools/batch_generate_resources.rb --category database

# 2. Review generated resources in lib/pangea/resources/
# 3. Prioritize which ones to implement first
# 4. Customize each resource with proper validations
```

### Enhanced Generation from Terraform Docs

```bash
# 1. Analyze the Terraform documentation
./tools/analyze_terraform_docs.rb aws_rds_cluster --output

# 2. Generate enhanced implementation
./tools/analyze_terraform_docs.rb --generate aws_rds_cluster_analysis.yaml

# 3. Copy the enhanced content into your resource files
# 4. Further customize based on Pangea patterns
```

## Best Practices

### 1. Start with Generation
Use the tools to generate the initial structure, then customize:
- Add resource-specific validations
- Implement computed properties
- Add comprehensive examples
- Include security best practices

### 2. Batch Similar Resources
Generate related resources together to maintain consistency:
```bash
# Generate all S3-related resources
./tools/batch_generate_resources.rb --file s3_resources.txt
```

### 3. Use Documentation Analysis
For complex resources, analyze Terraform docs first:
```bash
# Analyze first
./tools/analyze_terraform_docs.rb aws_complex_resource --output

# Review the analysis
cat aws_complex_resource_analysis.yaml

# Generate with better understanding
./tools/generate_resource.rb aws_complex_resource
```

### 4. Customize Templates
The generators use ERB templates that can be customized for your needs. Look for:
- `attribute_definitions` method for common attribute patterns
- `resource_attributes` method for terraform synthesis patterns
- `resource_outputs` method for common outputs

## Adding New Categories

To add new resource categories to `batch_generate_resources.rb`:

```ruby
SAMPLE_RESOURCES = {
  # ... existing categories ...
  
  my_category: %w[
    aws_my_resource_1
    aws_my_resource_2
    aws_my_resource_3
  ]
}
```

## Extending the Tools

The tools are designed to be extended:

1. **Custom Templates**: Modify the ERB templates in `generate_resource.rb`
2. **New Patterns**: Add new attribute patterns for different resource types
3. **Integration**: Add hooks to run tests or linting after generation
4. **Validation**: Add checks to ensure generated code follows conventions

## Future Enhancements

Planned improvements for the generation tools:

1. **Terraform Provider Schema Integration**
   - Direct schema extraction from provider
   - Automatic type inference
   - Complete attribute discovery

2. **AI-Assisted Generation**
   - Use LLMs to generate examples
   - Suggest computed properties
   - Generate comprehensive documentation

3. **Testing Integration**
   - Generate RSpec tests automatically
   - Include integration test templates
   - Validation test generation

4. **Resource Relationships**
   - Detect resource dependencies
   - Generate relationship helpers
   - Create composition patterns

## Contributing

When adding new generation capabilities:

1. Follow existing patterns in the tools
2. Add documentation for new features
3. Include examples of generated output
4. Test with various resource types

These tools significantly accelerate the process of implementing the 1000+ AWS resources in Pangea while maintaining consistency and quality.