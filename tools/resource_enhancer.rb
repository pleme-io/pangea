#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'yaml'

# Enhanced resource implementation based on AWS documentation
class ResourceEnhancer
  # AWS Resource documentation data (manually curated from Terraform docs)
  RESOURCE_DATA = {
    'aws_eip_association' => {
      description: 'Provides an AWS EIP Association as a top level resource, to associate and disassociate Elastic IPs from AWS Instances and Network Interfaces.',
      arguments: {
        'allocation_id' => { type: 'String', required: false, description: 'The allocation ID. This is required for EC2-VPC.' },
        'allow_reassociation' => { type: 'Boolean', required: false, description: 'Whether to allow an Elastic IP to be re-associated. Defaults to true in VPC contexts.' },
        'instance_id' => { type: 'String', required: false, description: 'The ID of the instance. This is required for EC2-Classic. For EC2-VPC, you can specify either the instance ID or the network interface ID, but not both.' },
        'network_interface_id' => { type: 'String', required: false, description: 'The ID of the network interface. If the instance has more than one network interface, you must specify a network interface ID.' },
        'private_ip_address' => { type: 'String', required: false, description: 'The primary or secondary private IP address to associate with the Elastic IP address.' },
        'public_ip' => { type: 'String', required: false, description: 'The Elastic IP address. This is required for EC2-Classic.' }
      },
      attributes: {
        'id' => 'The ID that represents the association of the Elastic IP address with an instance.',
        'allocation_id' => 'The allocation ID.',
        'instance_id' => 'The ID of the instance.',
        'network_interface_id' => 'The ID of the network interface.',
        'private_ip_address' => 'The private IP address.',
        'public_ip' => 'The Elastic IP address.'
      },
      validations: [
        'Either allocation_id or public_ip must be specified',
        'Cannot specify both instance_id and network_interface_id',
        'private_ip_address requires network_interface_id'
      ]
    },
    
    'aws_network_acl' => {
      description: 'Provides an network ACL resource. You might set up network ACLs with rules similar to your security groups in order to add an additional layer of security to your VPC.',
      arguments: {
        'vpc_id' => { type: 'String', required: true, description: 'The ID of the associated VPC.' },
        'subnet_ids' => { type: 'Array[String]', required: false, description: 'A list of Subnet IDs to apply the ACL to' },
        'ingress' => { type: 'Array[Hash]', required: false, description: 'Specifies an ingress rule.' },
        'egress' => { type: 'Array[Hash]', required: false, description: 'Specifies an egress rule.' },
        'tags' => { type: 'Hash', required: false, description: 'A map of tags to assign to the resource.' }
      },
      attributes: {
        'id' => 'The ID of the network ACL',
        'arn' => 'The ARN of the network ACL',
        'owner_id' => 'The ID of the AWS account that owns the network ACL',
        'vpc_id' => 'The ID of the associated VPC',
        'subnet_ids' => 'A list of Subnet IDs the ACL is applied to',
        'ingress' => 'The ingress rules',
        'egress' => 'The egress rules'
      },
      rule_schema: {
        'rule_number' => 'Rule number',
        'protocol' => 'Protocol (-1 for all)',
        'action' => 'allow or deny',
        'cidr_block' => 'CIDR block',
        'ipv6_cidr_block' => 'IPv6 CIDR block',
        'from_port' => 'From port',
        'to_port' => 'To port',
        'icmp_type' => 'ICMP type',
        'icmp_code' => 'ICMP code'
      }
    },
    
    'aws_route' => {
      description: 'Provides a resource to create a routing table entry (a route) in a VPC routing table.',
      arguments: {
        'route_table_id' => { type: 'String', required: true, description: 'The ID of the routing table.' },
        'destination_cidr_block' => { type: 'String', required: false, description: 'The destination CIDR block.' },
        'destination_ipv6_cidr_block' => { type: 'String', required: false, description: 'The destination IPv6 CIDR block.' },
        'destination_prefix_list_id' => { type: 'String', required: false, description: 'The ID of a managed prefix list destination.' },
        'carrier_gateway_id' => { type: 'String', required: false, description: 'Identifier of a carrier gateway.' },
        'core_network_arn' => { type: 'String', required: false, description: 'The Amazon Resource Name (ARN) of a core network.' },
        'egress_only_gateway_id' => { type: 'String', required: false, description: 'Identifier of a VPC Egress Only Internet Gateway.' },
        'gateway_id' => { type: 'String', required: false, description: 'Identifier of a VPC internet gateway or a virtual private gateway.' },
        'nat_gateway_id' => { type: 'String', required: false, description: 'Identifier of a VPC NAT gateway.' },
        'local_gateway_id' => { type: 'String', required: false, description: 'Identifier of a Outpost local gateway.' },
        'network_interface_id' => { type: 'String', required: false, description: 'Identifier of an EC2 network interface.' },
        'transit_gateway_id' => { type: 'String', required: false, description: 'Identifier of an EC2 Transit Gateway.' },
        'vpc_endpoint_id' => { type: 'String', required: false, description: 'Identifier of a VPC Endpoint.' },
        'vpc_peering_connection_id' => { type: 'String', required: false, description: 'Identifier of a VPC peering connection.' }
      },
      attributes: {
        'id' => 'Route Table identifier and destination',
        'instance_id' => 'Identifier of an EC2 instance',
        'instance_owner_id' => 'The AWS account ID of the owner of the EC2 instance',
        'network_interface_id' => 'Identifier of an EC2 network interface',
        'origin' => 'How the route was created',
        'state' => 'The state of the route'
      },
      validations: [
        'One of destination_cidr_block, destination_ipv6_cidr_block or destination_prefix_list_id must be specified',
        'Only one target can be specified (gateway_id, nat_gateway_id, instance_id, etc.)'
      ]
    }
  }

  attr_reader :resource_name, :resource_dir

  def initialize(resource_name)
    @resource_name = resource_name
    @resource_dir = File.join(
      File.expand_path('../../lib/pangea/resources', __FILE__),
      resource_name
    )
  end

  def enhance!
    data = RESOURCE_DATA[resource_name]
    
    unless data
      puts "❌ No enhancement data available for #{resource_name}"
      puts "Available resources: #{RESOURCE_DATA.keys.join(', ')}"
      return false
    end

    puts "🔧 Enhancing #{resource_name}..."
    
    enhance_types(data)
    enhance_resource(data)
    enhance_documentation(data)
    
    puts "✅ Successfully enhanced #{resource_name}"
    true
  end

  private

  def enhance_types(data)
    types_file = File.join(resource_dir, 'types.rb')
    
    # Generate attribute definitions
    attributes = data[:arguments].map do |name, info|
      type_def = convert_type(info[:type])
      if info[:required]
        "attribute :#{name}, #{type_def}"
      else
        "attribute? :#{name}, #{type_def}.optional"
      end
    end.join("\n        ")
    
    # Generate validation logic
    validations = data[:validations]&.map do |validation|
      "# #{validation}"
    end&.join("\n          ") || ""
    
    content = <<~RUBY
      # frozen_string_literal: true

      require 'pangea/resources/types'

      module Pangea
        module Resources
          module AWS
            # Type-safe attributes for #{class_name} resources
            # #{data[:description]}
            class #{attributes_class_name} < Dry::Struct
              #{attributes}
              
              # Tags to apply to the resource
              attribute :tags, Types::AwsTags.default({})

              # Custom validation
              def self.new(attributes = {})
                attrs = super(attributes)
                
                #{validations}
                #{generate_custom_validations(data)}
                
                attrs
              end
              
              #{generate_computed_properties(data)}
            end
          end
        end
      end
    RUBY
    
    File.write(types_file, content)
    puts "  ✓ Enhanced types.rb"
  end

  def enhance_resource(data)
    resource_file = File.join(resource_dir, 'resource.rb')
    
    # Generate attribute mappings
    mappings = data[:arguments].keys.map do |attr|
      "#{attr} attrs.#{attr} if attrs.#{attr}"
    end.join("\n          ")
    
    # Generate outputs
    outputs = data[:attributes].keys.map do |attr|
      "#{attr}: \"${#{resource_name}.\#{name}.#{attr}}\""
    end.join(",\n            ")
    
    content = <<~RUBY
      # frozen_string_literal: true

      require 'pangea/resources/base'
      require 'pangea/resources/reference'
      require 'pangea/resources/#{resource_name}/types'

      module Pangea
        module Resources
          module AWS
            # #{data[:description]}
            #
            # @param name [Symbol] The resource name
            # @param attributes [Hash] Resource attributes
            # @return [ResourceReference] Reference object with outputs and computed properties
            def #{resource_name}(name, attributes = {})
              # Validate attributes using dry-struct
              attrs = #{attributes_class_name}.new(attributes)
              
              # Generate terraform resource block via terraform-synthesizer
              resource(:#{resource_name}, name) do
                #{mappings}
                
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
                  #{outputs}
                },
                computed_properties: {
                  # Computed properties from type definitions
                }
              )
            end
          end
        end
      end
    RUBY
    
    File.write(resource_file, content)
    puts "  ✓ Enhanced resource.rb"
  end

  def enhance_documentation(data)
    readme_file = File.join(resource_dir, 'README.md')
    
    # Generate parameter table
    param_rows = data[:arguments].map do |name, info|
      req = info[:required] ? '**Yes**' : 'No'
      desc = info[:description].gsub('|', '\\|')
      "| `#{name}` | #{info[:type]} | #{req} | - | #{desc} |"
    end.join("\n")
    
    content = <<~MARKDOWN
      # #{resource_name.split('_').map(&:capitalize).join(' ')} Resource

      #{data[:description]}

      ## Quick Start

      ```ruby
      template :example do
        my_resource = #{resource_name}(:example, {
          #{data[:arguments].select { |_, v| v[:required] }.keys.map { |k| "#{k}: \"value\"" }.join(",\n      ")}
        })
      end
      ```

      ## Parameters

      | Parameter | Type | Required | Default | Description |
      |-----------|------|----------|---------|-------------|
      #{param_rows}
      | `tags` | Hash | No | `{}` | Resource tags |

      ## Resource Outputs

      The `#{resource_name}` function returns a resource reference with these outputs:

      ```ruby
      resource_ref = #{resource_name}(:example, { ... })

      # Terraform references
      #{data[:attributes].map { |k, v| "resource_ref.#{k} # #{v}" }.join("\n  ")}
      ```

      ## Related Resources

      - See other networking resources in the [AWS documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
    MARKDOWN
    
    File.write(readme_file, content)
    puts "  ✓ Enhanced README.md"
  end

  def class_name
    resource_name.split('_').map(&:capitalize).join
  end

  def attributes_class_name
    "#{class_name.gsub('Aws', '')}Attributes"
  end

  def convert_type(type_string)
    case type_string
    when 'String'
      'Types::String'
    when 'Boolean'
      'Types::Bool'
    when 'Integer'
      'Types::Integer'
    when 'Array[String]'
      'Types::Array.of(Types::String).default([].freeze)'
    when 'Array[Hash]'
      'Types::Array.of(Types::Hash).default([].freeze)'
    when 'Hash'
      'Types::Hash.default({})'
    else
      'Types::String'
    end
  end

  def generate_custom_validations(data)
    case resource_name
    when 'aws_eip_association'
      <<~RUBY
        # Either allocation_id or public_ip must be specified
        if !attrs.allocation_id && !attrs.public_ip
          raise Dry::Struct::Error, "Either 'allocation_id' or 'public_ip' must be specified"
        end
        
        # Cannot specify both instance_id and network_interface_id
        if attrs.instance_id && attrs.network_interface_id
          raise Dry::Struct::Error, "Cannot specify both 'instance_id' and 'network_interface_id'"
        end
        
        # private_ip_address requires network_interface_id
        if attrs.private_ip_address && !attrs.network_interface_id
          raise Dry::Struct::Error, "'private_ip_address' requires 'network_interface_id'"
        end
      RUBY
    when 'aws_route'
      <<~RUBY
        # Must specify one destination
        destinations = [attrs.destination_cidr_block, attrs.destination_ipv6_cidr_block, attrs.destination_prefix_list_id].compact
        if destinations.empty?
          raise Dry::Struct::Error, "One of 'destination_cidr_block', 'destination_ipv6_cidr_block', or 'destination_prefix_list_id' must be specified"
        end
        if destinations.size > 1
          raise Dry::Struct::Error, "Only one destination can be specified"
        end
        
        # Must specify exactly one target
        targets = [
          attrs.carrier_gateway_id, attrs.core_network_arn, attrs.egress_only_gateway_id,
          attrs.gateway_id, attrs.nat_gateway_id, attrs.local_gateway_id,
          attrs.network_interface_id, attrs.transit_gateway_id, attrs.vpc_endpoint_id,
          attrs.vpc_peering_connection_id
        ].compact
        
        if targets.empty?
          raise Dry::Struct::Error, "Must specify one target (gateway_id, nat_gateway_id, etc.)"
        end
        if targets.size > 1
          raise Dry::Struct::Error, "Only one target can be specified"
        end
      RUBY
    else
      ""
    end
  end

  def generate_computed_properties(data)
    case resource_name
    when 'aws_eip_association'
      <<~RUBY
        # Check if using VPC allocation
        def vpc_allocation?
          !allocation_id.nil?
        end
        
        # Check if using EC2-Classic
        def ec2_classic?
          !public_ip.nil? && allocation_id.nil?
        end
        
        # Determine association target
        def target_type
          if instance_id
            :instance
          elsif network_interface_id
            :network_interface
          else
            :none
          end
        end
      RUBY
    when 'aws_network_acl'
      <<~RUBY
        # Count ingress rules
        def ingress_rule_count
          ingress.size
        end
        
        # Count egress rules
        def egress_rule_count
          egress.size
        end
        
        # Check if default deny-all
        def is_restrictive?
          ingress.empty? && egress.empty?
        end
      RUBY
    when 'aws_route'
      <<~RUBY
        # Determine destination type
        def destination_type
          if destination_cidr_block
            :ipv4
          elsif destination_ipv6_cidr_block
            :ipv6
          elsif destination_prefix_list_id
            :prefix_list
          else
            :unknown
          end
        end
        
        # Determine target type
        def target_type
          if gateway_id
            :internet_gateway
          elsif nat_gateway_id
            :nat_gateway
          elsif network_interface_id
            :network_interface
          elsif transit_gateway_id
            :transit_gateway
          elsif vpc_peering_connection_id
            :vpc_peering
          elsif vpc_endpoint_id
            :vpc_endpoint
          elsif egress_only_gateway_id
            :egress_only_gateway
          elsif local_gateway_id
            :local_gateway
          elsif carrier_gateway_id
            :carrier_gateway
          elsif core_network_arn
            :core_network
          else
            :unknown
          end
        end
      RUBY
    else
      <<~RUBY
        # TODO: Add computed properties specific to #{resource_name}
      RUBY
    end
  end
end

# CLI Interface
if __FILE__ == $0
  require 'optparse'
  
  options = {}
  
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: resource_enhancer.rb RESOURCE_NAME [options]"
    
    opts.on("-l", "--list", "List available resources with enhancement data") do
      options[:list] = true
    end
    
    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit
    end
  end
  
  parser.parse!
  
  if options[:list]
    puts "📋 Resources with enhancement data:\n\n"
    ResourceEnhancer::RESOURCE_DATA.each do |name, data|
      puts "#{name}:"
      puts "  #{data[:description]}"
      puts
    end
    exit
  end
  
  if ARGV.empty?
    puts parser
    exit 1
  end
  
  resource_name = ARGV[0]
  enhancer = ResourceEnhancer.new(resource_name)
  
  unless enhancer.enhance!
    exit 1
  end
end