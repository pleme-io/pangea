# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module CloudFormation
        module Types
          # CloudFormation Stack Set attributes with validation
          class CloudFormationStackSetAttributes < Dry::Struct
            transform_keys(&:to_sym)
            
            # Required attributes
            attribute :name, Resources::Types::String
            
            # Template source (mutually exclusive)
            attribute :template_body, Resources::Types::String.optional.default(nil)
            attribute :template_url, Resources::Types::String.optional.default(nil)
            
            # Optional attributes
            attribute :parameters, Resources::Types::Hash.default({}.freeze)
            attribute :capabilities, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
            attribute :description, Resources::Types::String.optional.default(nil)
            attribute :execution_role_name, Resources::Types::String.optional.default(nil)
            attribute :administration_role_arn, Resources::Types::String.optional.default(nil)
            attribute :permission_model, Resources::Types::String.optional.default(nil)
            attribute :call_as, Resources::Types::String.optional.default(nil)
            attribute :auto_deployment, Resources::Types::Hash.optional.default(nil)
            attribute :managed_execution, Resources::Types::Hash.optional.default(nil)
            attribute :operation_preferences, Resources::Types::Hash.optional.default(nil)
            attribute :tags, Resources::Types::Hash.default({}.freeze)
            
            def self.new(attributes)
              attrs = attributes.is_a?(Hash) ? attributes : {}
              
              # Validate template source
              template_sources = [attrs[:template_body], attrs[:template_url]].compact
              if template_sources.empty?
                raise Dry::Struct::Error, "Must specify either template_body or template_url"
              elsif template_sources.length > 1
                raise Dry::Struct::Error, "Can only specify one of: template_body or template_url"
              end
              
              # Validate permission model
              if attrs[:permission_model] && !%w[SERVICE_MANAGED SELF_MANAGED].include?(attrs[:permission_model])
                raise Dry::Struct::Error, "permission_model must be SERVICE_MANAGED or SELF_MANAGED"
              end
              
              # Validate call_as
              if attrs[:call_as] && !%w[DELEGATED_ADMIN SELF].include?(attrs[:call_as])
                raise Dry::Struct::Error, "call_as must be DELEGATED_ADMIN or SELF"
              end
              
              # Validate capabilities
              valid_capabilities = %w[
                CAPABILITY_IAM
                CAPABILITY_NAMED_IAM
                CAPABILITY_AUTO_EXPAND
              ]
              if attrs[:capabilities]
                invalid_caps = attrs[:capabilities] - valid_capabilities
                unless invalid_caps.empty?
                  raise Dry::Struct::Error, "Invalid capabilities: #{invalid_caps.join(', ')}"
                end
              end
              
              super(attrs)
            end
            
            def organization_managed?
              permission_model == 'SERVICE_MANAGED'
            end
            
            def has_auto_deployment?
              !auto_deployment.nil?
            end
            
            def has_managed_execution?
              !managed_execution.nil?
            end
            
            def template_source
              return :body if template_body
              return :url if template_url
              :none
            end
            
            def requires_capabilities?
              capabilities.any?
            end
            
            def to_h
              hash = { name: name }
              hash[:template_body] = template_body if template_body
              hash[:template_url] = template_url if template_url
              hash[:parameters] = parameters if parameters.any?
              hash[:capabilities] = capabilities if capabilities.any?
              hash[:description] = description if description
              hash[:execution_role_name] = execution_role_name if execution_role_name
              hash[:administration_role_arn] = administration_role_arn if administration_role_arn
              hash[:permission_model] = permission_model if permission_model
              hash[:call_as] = call_as if call_as
              hash[:auto_deployment] = auto_deployment if auto_deployment
              hash[:managed_execution] = managed_execution if managed_execution
              hash[:operation_preferences] = operation_preferences if operation_preferences
              hash[:tags] = tags if tags.any?
              hash.compact
            end
          end
          
          # CloudFormation Stack Set Instance attributes
          class CloudFormationStackSetInstanceAttributes < Dry::Struct
            transform_keys(&:to_sym)
            
            # Required attributes
            attribute :stack_set_name, Resources::Types::String
            
            # Target specification (for SELF_MANAGED)
            attribute :account_id, Resources::Types::String.optional.default(nil)
            attribute :region, Resources::Types::String.optional.default(nil)
            
            # Organizational Units (for SERVICE_MANAGED)
            attribute :deployment_targets, Resources::Types::Hash.optional.default(nil)
            
            # Optional attributes
            attribute :parameter_overrides, Resources::Types::Hash.default({}.freeze)
            attribute :retain_stack, Resources::Types::Bool.default(false)
            attribute :operation_preferences, Resources::Types::Hash.optional.default(nil)
            attribute :call_as, Resources::Types::String.optional.default(nil)
            
            def self.new(attributes)
              attrs = attributes.is_a?(Hash) ? attributes : {}
              
              # Validate deployment target specification
              has_account_region = attrs[:account_id] && attrs[:region]
              has_deployment_targets = attrs[:deployment_targets]
              
              unless has_account_region || has_deployment_targets
                raise Dry::Struct::Error, "Must specify either account_id+region or deployment_targets"
              end
              
              if has_account_region && has_deployment_targets
                raise Dry::Struct::Error, "Cannot specify both account_id+region and deployment_targets"
              end
              
              super(attrs)
            end
            
            def organization_deployment?
              !deployment_targets.nil?
            end
            
            def account_deployment?
              account_id && region
            end
            
            def to_h
              hash = { stack_set_name: stack_set_name }
              hash[:account_id] = account_id if account_id
              hash[:region] = region if region
              hash[:deployment_targets] = deployment_targets if deployment_targets
              hash[:parameter_overrides] = parameter_overrides if parameter_overrides.any?
              hash[:retain_stack] = retain_stack
              hash[:operation_preferences] = operation_preferences if operation_preferences
              hash[:call_as] = call_as if call_as
              hash.compact
            end
          end
          
          # CloudFormation Stack Instances attributes
          class CloudFormationStackInstancesAttributes < Dry::Struct
            transform_keys(&:to_sym)
            
            # Required attributes
            attribute :stack_set_name, Resources::Types::String
            
            # Deployment configuration
            attribute :deployment_targets, Resources::Types::Hash.optional.default(nil)
            attribute :regions, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
            
            # Optional attributes
            attribute :parameter_overrides, Resources::Types::Hash.default({}.freeze)
            attribute :operation_preferences, Resources::Types::Hash.optional.default(nil)
            attribute :call_as, Resources::Types::String.optional.default(nil)
            attribute :operation_id, Resources::Types::String.optional.default(nil)
            
            def self.new(attributes)
              attrs = attributes.is_a?(Hash) ? attributes : {}
              
              # Validate deployment targets or regions are specified
              if (!attrs[:deployment_targets] || attrs[:deployment_targets].empty?) && 
                 (!attrs[:regions] || attrs[:regions].empty?)
                raise Dry::Struct::Error, "Must specify either deployment_targets or regions"
              end
              
              super(attrs)
            end
            
            def deployment_scope
              return 'organization' if deployment_targets&.key?(:organizational_unit_ids)
              return 'accounts' if deployment_targets&.key?(:accounts)
              'regions'
            end
            
            def multi_region?
              regions.length > 1
            end
            
            def to_h
              hash = { stack_set_name: stack_set_name }
              hash[:deployment_targets] = deployment_targets if deployment_targets
              hash[:regions] = regions if regions.any?
              hash[:parameter_overrides] = parameter_overrides if parameter_overrides.any?
              hash[:operation_preferences] = operation_preferences if operation_preferences
              hash[:call_as] = call_as if call_as
              hash[:operation_id] = operation_id if operation_id
              hash.compact
            end
          end
          
          # CloudFormation Type attributes
          class CloudFormationTypeAttributes < Dry::Struct
            transform_keys(&:to_sym)
            
            # Required attributes
            attribute :type, Resources::Types::String
            attribute :type_name, Resources::Types::String
            
            # Schema and configuration
            attribute :schema, Resources::Types::String.optional.default(nil)
            attribute :schema_handler_package, Resources::Types::String.optional.default(nil)
            attribute :source_url, Resources::Types::String.optional.default(nil)
            attribute :documentation_url, Resources::Types::String.optional.default(nil)
            attribute :execution_role_arn, Resources::Types::String.optional.default(nil)
            attribute :logging_config, Resources::Types::Hash.optional.default(nil)
            attribute :client_request_token, Resources::Types::String.optional.default(nil)
            
            def self.new(attributes)
              attrs = attributes.is_a?(Hash) ? attributes : {}
              
              # Validate type
              unless %w[RESOURCE HOOK].include?(attrs[:type])
                raise Dry::Struct::Error, "type must be RESOURCE or HOOK"
              end
              
              # Validate type_name format
              if attrs[:type_name] && !attrs[:type_name].match?(/^[A-Za-z0-9]{2,64}::[A-Za-z0-9]{2,64}::[A-Za-z0-9]{2,64}$/)
                raise Dry::Struct::Error, "type_name must follow format Namespace::Type::Resource"
              end
              
              super(attrs)
            end
            
            def resource_type?
              type == 'RESOURCE'
            end
            
            def hook_type?
              type == 'HOOK'
            end
            
            def has_logging?
              !logging_config.nil?
            end
            
            def to_h
              hash = {
                type: type,
                type_name: type_name
              }
              hash[:schema] = schema if schema
              hash[:schema_handler_package] = schema_handler_package if schema_handler_package
              hash[:source_url] = source_url if source_url
              hash[:documentation_url] = documentation_url if documentation_url
              hash[:execution_role_arn] = execution_role_arn if execution_role_arn
              hash[:logging_config] = logging_config if logging_config
              hash[:client_request_token] = client_request_token if client_request_token
              hash.compact
            end
          end
        end
      end
    end
  end
end