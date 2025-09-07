# AWS Systems Manager Document Implementation

## Overview

The `aws_ssm_document` resource provides type-safe AWS Systems Manager document management with comprehensive support for all document types (Command, Automation, Policy, Session, Package, etc.), cross-account sharing, dependencies, and attachments with full validation.

## Key Features

### 1. Comprehensive Document Type Support
- **Command Documents**: Shell/PowerShell script execution with target type validation
- **Automation Documents**: Multi-step AWS resource automation workflows
- **Policy Documents**: Configuration policies for SSM features
- **Session Documents**: Session Manager configuration and customization
- **Package Documents**: Software distribution and installation
- **CloudFormation Documents**: Infrastructure as code integration

### 2. Content Validation and Parsing
- **JSON/YAML Validation**: Automatic syntax validation for document content
- **Schema Version Support**: Flexible schema version specification and validation
- **Content Analysis**: Parse and analyze document steps and structure
- **Format Conversion**: Support for both JSON and YAML document formats

### 3. Cross-Account Sharing
- **Account-Based Permissions**: Share documents with specific AWS accounts
- **Version Control**: Share specific document versions
- **Permission Management**: Private vs shared document access control

### 4. Dependency Management
- **Document Dependencies**: Specify required documents with version constraints
- **Attachment Support**: S3-based file attachments for complex documents
- **Execution Orchestration**: Coordinate multi-document workflows

## Type Safety Implementation

### Core Validation
```ruby
def self.new(attributes = {})
  attrs = super(attributes)
  
  # Content validation based on format
  begin
    if attrs.document_format == "JSON"
      JSON.parse(attrs.content)
    elsif attrs.document_format == "YAML"
      YAML.safe_load(attrs.content)
    end
  rescue JSON::ParserError, Psych::SyntaxError => e
    raise Dry::Struct::Error, "Invalid #{attrs.document_format} content: #{e.message}"
  end
  
  # ... additional validations
end
```

### Document Type Validation
- **Command Document Requirements**: Validates target_type for Command documents
- **Schema Version Format**: Enforces major.minor version format
- **Name Format**: Validates document naming conventions (3-128 characters)

### Permission Validation
```ruby
if attrs.permissions[:type] == "Share"
  unless attrs.permissions[:account_ids] && attrs.permissions[:account_ids].any?
    raise Dry::Struct::Error, "account_ids is required when sharing document"
  end
  
  attrs.permissions[:account_ids].each do |account_id|
    unless account_id.match?(/\A\d{12}\z/)
      raise Dry::Struct::Error, "Invalid AWS account ID format: #{account_id}"
    end
  end
end
```

## Resource Synthesis

### Document Configuration
```ruby
resource(:aws_ssm_document, name) do
  document_name document_attrs.name
  document_type document_attrs.document_type
  content document_attrs.content
  document_format document_attrs.document_format
  
  # Optional target type (Command documents only)
  target_type document_attrs.target_type if document_attrs.target_type
end
```

### Permission Synthesis
```ruby
if document_attrs.is_shared?
  permissions do
    type document_attrs.permissions[:type]
    account_ids document_attrs.permissions[:account_ids]
    shared_document_version document_attrs.permissions[:shared_document_version] if document_attrs.permissions[:shared_document_version]
  end
end
```

### Dependency Synthesis
```ruby
document_attrs.requires.each do |requirement|
  requires do
    name requirement[:name]
    version requirement[:version] if requirement[:version]
  end
end
```

### Attachment Synthesis
```ruby
document_attrs.attachments_source.each do |attachment|
  attachments_source do
    key attachment[:key]
    values attachment[:values]
    name attachment[:name] if attachment[:name]
  end
end
```

## Helper Configurations

### Command Document Pattern
```ruby
def self.command_document(name, commands, description: nil)
  content = {
    schemaVersion: "2.2",
    description: description || "Execute commands on instances",
    mainSteps: [
      {
        action: "aws:runShellScript",
        name: "executeCommands",
        inputs: {
          runCommand: commands.is_a?(Array) ? commands : [commands]
        }
      }
    ]
  }

  {
    name: name,
    document_type: "Command",
    content: JSON.pretty_generate(content),
    document_format: "JSON",
    target_type: "/AWS::EC2::Instance"
  }
end
```

### Automation Document Pattern
```ruby
def self.automation_document(name, steps, description: nil)
  content = {
    schemaVersion: "0.3",
    description: description || "Automation document",
    assumeRole: "{{ AutomationAssumeRole }}",
    parameters: {
      AutomationAssumeRole: {
        type: "String",
        description: "IAM role for automation execution"
      }
    },
    mainSteps: steps
  }

  {
    name: name,
    document_type: "Automation",
    content: JSON.pretty_generate(content),
    document_format: "JSON"
  }
end
```

## Computed Properties

### Document Type Detection
```ruby
def is_command_document?
  document_type == "Command"
end

def is_automation_document?
  document_type == "Automation"
end

def is_policy_document?
  document_type == "Policy"
end
```

### Content Analysis
```ruby
def parsed_content
  if uses_json_format?
    JSON.parse(content)
  elsif uses_yaml_format?
    YAML.safe_load(content)
  end
rescue JSON::ParserError, Psych::SyntaxError
  nil
end

def document_steps
  parsed = parsed_content
  return [] unless parsed

  case document_type
  when "Command"
    parsed.dig("mainSteps") || []
  when "Automation"
    parsed.dig("mainSteps") || []
  else
    []
  end
end
```

### Execution Estimation
```ruby
def estimated_execution_time
  steps = document_steps
  return "Unknown" if steps.empty?
  
  estimated_minutes = steps.count * 2 # 2 minutes per step average
  "~#{estimated_minutes} minutes"
end
```

## Integration Patterns

### Command Document Automation
```ruby
# System maintenance document
maintenance_doc = aws_ssm_document(:system_maintenance, {
  name: "SystemMaintenanceCommands",
  document_type: "Command",
  content: JSON.pretty_generate({
    schemaVersion: "2.2",
    description: "Perform system maintenance tasks",
    parameters: {
      MaintenanceType: {
        type: "String",
        description: "Type of maintenance to perform",
        allowedValues: ["security", "full", "minimal"]
      }
    },
    mainSteps: [
      {
        action: "aws:runShellScript",
        name: "performMaintenance",
        inputs: {
          runCommand: [
            "#!/bin/bash",
            "case {{ MaintenanceType }} in",
            "  security) yum update-minimal --security -y ;;",
            "  full) yum update -y ;;",
            "  minimal) yum update-minimal -y ;;",
            "esac"
          ]
        }
      }
    ]
  }),
  target_type: "/AWS::EC2::Instance"
})
```

### Automation Workflow Integration
```ruby
# Complex automation workflow
automation_workflow = aws_ssm_document(:backup_and_patch, {
  name: "BackupAndPatchWorkflow",
  document_type: "Automation",
  content: JSON.pretty_generate({
    schemaVersion: "0.3",
    description: "Create backup snapshot then apply patches",
    assumeRole: "{{ AutomationAssumeRole }}",
    parameters: {
      InstanceId: { type: "String", description: "Instance to patch" },
      AutomationAssumeRole: { type: "String", description: "Automation role" }
    },
    mainSteps: [
      {
        name: "createSnapshot",
        action: "aws:executeAutomation",
        inputs: {
          DocumentName: "AWS-CreateSnapshot",
          Parameters: {
            InstanceId: "{{ InstanceId }}"
          }
        }
      },
      {
        name: "waitForSnapshot",
        action: "aws:sleep",
        inputs: { Duration: "PT5M" }
      },
      {
        name: "patchInstance",
        action: "aws:executeAutomation",
        inputs: {
          DocumentName: "AWS-RunPatchBaseline",
          Parameters: {
            InstanceId: "{{ InstanceId }}"
          }
        }
      }
    ]
  }),
  requires: [
    { name: "AWS-CreateSnapshot", version: "1.0" },
    { name: "AWS-RunPatchBaseline" }
  ]
})
```

### Session Manager Configuration
```ruby
# Custom session manager setup
session_config = aws_ssm_document(:custom_session_config, {
  name: "CustomSessionManagerConfig",
  document_type: "Session",
  content: JSON.pretty_generate({
    schemaVersion: "1.0",
    description: "Custom session configuration with logging",
    sessionType: "Standard_Stream",
    inputs: {
      s3BucketName: session_logs_bucket.outputs[:bucket],
      s3KeyPrefix: "session-logs/",
      s3EncryptionEnabled: true,
      cloudWatchLogGroupName: session_log_group.outputs[:name],
      cloudWatchEncryptionEnabled: true,
      kmsKeyId: session_kms_key.outputs[:arn],
      shellProfile: {
        linux: "export PS1='[SSM-Session] \\u@\\h:\\w\\$ '",
        windows: "prompt [SSM-Session] $P$G"
      }
    }
  })
})
```

## Error Handling

### Content Validation Errors
- **JSON Parse Errors**: Clear error messages for malformed JSON content
- **YAML Parse Errors**: Specific YAML syntax error reporting
- **Schema Validation**: Document-specific schema validation errors

### Document Type Constraints
- **Target Type Validation**: Enforces target type for Command documents only
- **Schema Version Format**: Validates major.minor version pattern
- **Name Format Validation**: Character set and length constraints

### Permission Configuration Errors
- **Account ID Format**: Validates 12-digit AWS account ID format
- **Sharing Requirements**: Enforces account_ids for shared documents
- **Version Constraints**: Validates shared document version format

## Output Reference Structure

```ruby
outputs: {
  name: "${aws_ssm_document.#{name}.name}",
  arn: "${aws_ssm_document.#{name}.arn}",
  created_date: "${aws_ssm_document.#{name}.created_date}",
  default_version: "${aws_ssm_document.#{name}.default_version}",
  description: "${aws_ssm_document.#{name}.description}",
  document_format: "${aws_ssm_document.#{name}.document_format}",
  document_type: "${aws_ssm_document.#{name}.document_type}",
  document_version: "${aws_ssm_document.#{name}.document_version}",
  hash: "${aws_ssm_document.#{name}.hash}",
  hash_type: "${aws_ssm_document.#{name}.hash_type}",
  latest_version: "${aws_ssm_document.#{name}.latest_version}",
  owner: "${aws_ssm_document.#{name}.owner}",
  parameter: "${aws_ssm_document.#{name}.parameter}",
  platform_types: "${aws_ssm_document.#{name}.platform_types}",
  schema_version: "${aws_ssm_document.#{name}.schema_version}",
  status: "${aws_ssm_document.#{name}.status}",
  tags_all: "${aws_ssm_document.#{name}.tags_all}"
}
```

## Best Practices

### Security
1. **IAM Permissions**: Grant minimal required permissions for document execution
2. **Cross-Account Sharing**: Only share with trusted accounts and specific versions
3. **Sensitive Data**: Avoid hardcoding sensitive information in document content
4. **Execution Roles**: Use dedicated roles for automation document execution

### Content Organization
1. **Modular Design**: Break complex operations into smaller, reusable documents
2. **Parameter Usage**: Use parameters for dynamic document behavior
3. **Error Handling**: Include error handling and rollback steps in automation documents
4. **Documentation**: Provide clear descriptions and parameter documentation

### Version Management
1. **Version Control**: Use version names for significant document changes
2. **Dependency Versions**: Specify version constraints for document dependencies
3. **Testing**: Test documents in non-production environments before sharing
4. **Rollback Strategy**: Maintain previous versions for quick rollback

### Performance
1. **Step Optimization**: Minimize number of steps for faster execution
2. **Parallel Execution**: Use parallel steps where possible in automation documents
3. **Timeout Configuration**: Set appropriate timeouts for long-running operations
4. **Resource Cleanup**: Include cleanup steps to prevent resource leaks