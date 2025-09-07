#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'erb'
require 'optparse'

# Resource generator for Pangea AWS resources
class ResourceGenerator
  attr_reader :resource_name, :service_name, :options

  def initialize(resource_name, options = {})
    @resource_name = resource_name.downcase
    @service_name = extract_service_name(resource_name)
    @options = options
    @base_path = File.expand_path('../../lib/pangea/resources', __FILE__)
  end

  def generate!
    validate_resource_name!
    create_directory_structure
    generate_types_file
    generate_resource_file
    generate_claude_md
    generate_readme
    update_aws_resources_loader
    
    puts "✅ Successfully generated resource: #{resource_name}"
    puts "📁 Location: #{resource_dir}"
    puts "\nNext steps:"
    puts "1. Review and customize the generated files"
    puts "2. Add resource-specific validations in types.rb"
    puts "3. Implement computed properties in resource.rb"
    puts "4. Update examples in README.md"
    puts "5. Run tests to ensure everything works"
  end

  private

  def validate_resource_name!
    unless resource_name.start_with?('aws_')
      raise ArgumentError, "Resource name must start with 'aws_' (got: #{resource_name})"
    end
  end

  def extract_service_name(name)
    parts = name.split('_')[1..-1]
    parts.map(&:capitalize).join(' ')
  end

  def resource_dir
    File.join(@base_path, resource_name)
  end

  def create_directory_structure
    FileUtils.mkdir_p(resource_dir)
  end

  def class_name
    resource_name.split('_').map(&:capitalize).join
  end

  def attributes_class_name
    "#{class_name.gsub('Aws', '')}Attributes"
  end

  def generate_types_file
    template = <<~RUBY
      # frozen_string_literal: true

      require 'pangea/resources/types'

      module Pangea
        module Resources
          module AWS
            # Type-safe attributes for #{class_name} resources
            class #{attributes_class_name} < Dry::Struct
              <%= attribute_definitions %>
              
              # Tags to apply to the resource
              attribute :tags, Types::AwsTags.default({})

              # Custom validation
              def self.new(attributes = {})
                attrs = super(attributes)
                
                # TODO: Add custom validations here
                # Example:
                # if attrs.some_attribute && attrs.conflicting_attribute
                #   raise Dry::Struct::Error, "Cannot specify both 'some_attribute' and 'conflicting_attribute'"
                # end
                
                attrs
              end

              # TODO: Add computed properties as methods
              # Example:
              # def is_public?
              #   some_attribute == "public"
              # end
            end
          end
        end
      end
    RUBY

    File.write(File.join(resource_dir, 'types.rb'), erb_result(template))
  end

  def generate_resource_file
    template = <<~RUBY
      # frozen_string_literal: true

      require 'pangea/resources/base'
      require 'pangea/resources/reference'
      require 'pangea/resources/#{resource_name}/types'

      module Pangea
        module Resources
          module AWS
            # Create an #{class_name} with type-safe attributes
            #
            # @param name [Symbol] The resource name
            # @param attributes [Hash] Resource attributes
            # @return [ResourceReference] Reference object with outputs and computed properties
            def #{resource_name}(name, attributes = {})
              # Validate attributes using dry-struct
              attrs = #{attributes_class_name}.new(attributes)
              
              # Generate terraform resource block via terraform-synthesizer
              resource(:#{resource_name}, name) do
                <%= resource_attributes %>
                
                # Apply tags if present
                if attrs.tags.any?
                  tags do
                    attrs.tags.each do |key, value|
                      public_send(key, value)
                    end
                  end
                end
              end
              
              # Return resource reference with available outputs
              ResourceReference.new(
                type: '#{resource_name}',
                name: name,
                resource_attributes: attrs.to_h,
                outputs: {
                  <%= resource_outputs %>
                },
                computed_properties: {
                  # TODO: Add computed properties
                  # Example:
                  # is_public: attrs.is_public?
                }
              )
            end
          end
        end
      end
    RUBY

    File.write(File.join(resource_dir, 'resource.rb'), erb_result(template))
  end

  def generate_claude_md
    template = <<~MARKDOWN
      # #{class_name} Implementation Documentation

      ## Overview

      This directory contains the implementation for the `#{resource_name}` resource function, providing type-safe creation and management of #{service_name} resources through terraform-synthesizer integration.

      ## Implementation Architecture

      ### Core Components

      #### 1. Resource Function (`resource.rb`)
      The main `#{resource_name}` function that:
      - Accepts a symbol name and attributes hash
      - Validates attributes using dry-struct types
      - Generates terraform resource blocks via terraform-synthesizer
      - Returns ResourceReference with computed outputs and properties

      #### 2. Type Definitions (`types.rb`)
      #{attributes_class_name} dry-struct defining:
      - Required attributes: TODO: List required attributes
      - Optional attributes: TODO: List optional attributes
      - Custom validations for business logic
      - Computed properties for convenience

      #### 3. Documentation
      - **CLAUDE.md** (this file): Implementation details for developers
      - **README.md**: User-facing documentation with examples

      ## Technical Implementation Details

      ### TODO: Add technical details
      - Describe the AWS service
      - Key features and constraints
      - Integration patterns

      ### Type Validation Logic

      ```ruby
      class #{attributes_class_name} < Dry::Struct
        # TODO: Document validation logic
      end
      ```

      ### Terraform Synthesis

      The resource function generates terraform JSON through terraform-synthesizer:

      ```ruby
      resource(:#{resource_name}, name) do
        # TODO: Document synthesis process
      end
      ```

      ### ResourceReference Return Value

      The function returns a ResourceReference providing:

      #### Terraform Outputs
      TODO: List available outputs

      #### Computed Properties
      TODO: List computed properties

      ## Integration Patterns

      ### 1. Basic Usage
      ```ruby
      template :example do
        # TODO: Add basic usage example
      end
      ```

      ## Error Handling and Validation

      ### Common Validation Errors

      TODO: Document common errors and solutions

      ## Testing Strategy

      ### Unit Tests
      ```ruby
      RSpec.describe Pangea::Resources::AWS do
        describe "##{resource_name}" do
          # TODO: Add test examples
        end
      end
      ```

      ## Security Best Practices

      TODO: Add security considerations

      ## Future Enhancements

      TODO: List potential improvements
    MARKDOWN

    File.write(File.join(resource_dir, 'CLAUDE.md'), template)
  end

  def generate_readme
    template = <<~MARKDOWN
      # #{service_name} Resource

      Create type-safe #{service_name} resources with automatic validation and terraform-synthesizer integration.

      ## Quick Start

      ```ruby
      template :example do
        # Create #{service_name.downcase}
        my_resource = #{resource_name}(:example, {
          # TODO: Add required attributes
          tags: {
            Name: "my-#{resource_name.gsub('_', '-')}",
            Environment: "production"
          }
        })
      end
      ```

      ## Parameters

      | Parameter | Type | Required | Default | Description |
      |-----------|------|----------|---------|-------------|
      | TODO | | | | |
      | `tags` | Hash | No | `{}` | Key-value pairs of tags |

      ## Usage Examples

      ### Basic Configuration

      ```ruby
      template :basic_example do
        # TODO: Add basic example
      end
      ```

      ### Advanced Configuration

      ```ruby
      template :advanced_example do
        # TODO: Add advanced example
      end
      ```

      ## Resource Outputs

      The `#{resource_name}` function returns a resource reference with these outputs:

      ```ruby
      resource_ref = #{resource_name}(:example, { ... })

      # Terraform references
      # TODO: List available outputs
      resource_ref.id                      # Resource ID

      # Computed properties
      # TODO: List computed properties
      ```

      ## Best Practices

      ### 1. Security
      - TODO: Add security best practices

      ### 2. Cost Optimization
      - TODO: Add cost optimization tips

      ### 3. Performance
      - TODO: Add performance considerations

      ## Related Resources

      - TODO: List related AWS resources

      ## Troubleshooting

      ### Common Issues

      TODO: Document common issues and solutions

      ### Validation Errors

      ```ruby
      # TODO: Add validation error examples
      ```

      This #{service_name} resource provides a type-safe way to create and manage #{service_name} resources within your Pangea infrastructure templates.
    MARKDOWN

    File.write(File.join(resource_dir, 'README.md'), template)
  end

  def update_aws_resources_loader
    loader_path = File.join(@base_path, 'aws_resources.rb')
    content = File.read(loader_path)
    
    # Find the TODO comment line
    if content.include?("# TODO: Add more resources")
      # Add the new require before the TODO comment
      new_require = "require 'pangea/resources/#{resource_name}/resource'"
      
      unless content.include?(new_require)
        content.sub!(
          /# TODO: Add more resources/,
          "#{new_require}\n# TODO: Add more resources"
        )
        
        File.write(loader_path, content)
        puts "✅ Updated aws_resources.rb"
      end
    else
      puts "⚠️  Could not update aws_resources.rb - please add manually:"
      puts "    require 'pangea/resources/#{resource_name}/resource'"
    end
  end

  def erb_result(template)
    ERB.new(template, trim_mode: '<>').result(binding)
  end

  def attribute_definitions
    # Generate common attribute patterns based on resource type
    case resource_name
    when /instance/, /server/
      <<~RUBY
        # Instance configuration
        attribute? :instance_type, Types::String.optional
        attribute? :availability_zone, Types::String.optional
      RUBY
    when /bucket/, /storage/
      <<~RUBY
        # Storage configuration
        attribute? :storage_class, Types::String.optional
        attribute? :encryption, Types::Hash.optional
      RUBY
    when /network/, /vpc/
      <<~RUBY
        # Network configuration
        attribute? :cidr_block, Types::String.optional
        attribute? :vpc_id, Types::String.optional
      RUBY
    else
      <<~RUBY
        # TODO: Define resource-specific attributes
        # attribute :required_attribute, Types::String
        # attribute? :optional_attribute, Types::String.optional
      RUBY
    end
  end

  def resource_attributes
    # Generate common resource attribute patterns
    case resource_name
    when /instance/, /server/
      <<~RUBY
        # Instance attributes
                instance_type attrs.instance_type if attrs.instance_type
                availability_zone attrs.availability_zone if attrs.availability_zone
      RUBY
    when /bucket/, /storage/
      <<~RUBY
        # Storage attributes
                storage_class attrs.storage_class if attrs.storage_class
                
                if attrs.encryption
                  server_side_encryption_configuration do
                    rule do
                      apply_server_side_encryption_by_default do
                        sse_algorithm attrs.encryption[:sse_algorithm] || "AES256"
                      end
                    end
                  end
                end
      RUBY
    else
      <<~RUBY
        # TODO: Map attributes to terraform resource
                # attribute_name attrs.attribute_name if attrs.attribute_name
      RUBY
    end
  end

  def resource_outputs
    # Common outputs based on resource type
    base_outputs = [
      'id: "${' + resource_name + '.#{name}.id}"',
      'arn: "${' + resource_name + '.#{name}.arn}"'
    ]
    
    case resource_name
    when /instance/
      base_outputs += [
        'public_ip: "${' + resource_name + '.#{name}.public_ip}"',
        'private_ip: "${' + resource_name + '.#{name}.private_ip}"'
      ]
    when /bucket/
      base_outputs += [
        'bucket: "${' + resource_name + '.#{name}.bucket}"',
        'bucket_domain_name: "${' + resource_name + '.#{name}.bucket_domain_name}"'
      ]
    when /role/
      base_outputs += [
        'name: "${' + resource_name + '.#{name}.name}"',
        'unique_id: "${' + resource_name + '.#{name}.unique_id}"'
      ]
    end
    
    base_outputs.join(",\n                  ")
  end
end

# CLI Interface
if __FILE__ == $0
  options = {}
  
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: generate_resource.rb RESOURCE_NAME [options]"
    
    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit
    end
    
    opts.on("-f", "--force", "Overwrite existing files") do
      options[:force] = true
    end
  end
  
  parser.parse!
  
  if ARGV.empty?
    puts parser
    exit 1
  end
  
  resource_name = ARGV[0]
  
  begin
    generator = ResourceGenerator.new(resource_name, options)
    generator.generate!
  rescue => e
    puts "❌ Error: #{e.message}"
    exit 1
  end
end