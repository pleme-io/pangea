# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS CloudFormation Stack Set resources
      class CloudFormationStackSetAttributes < Dry::Struct
        # Stack set name (required)
        attribute :name, Resources::Types::String

        # Template body or URL
        attribute :template_body, Resources::Types::String.optional
        attribute :template_url, Resources::Types::String.optional

        # Stack set description
        attribute :description, Resources::Types::String.optional

        # Stack set parameters
        attribute :parameters, Resources::Types::Hash.map(Types::String, Types::String).default({})

        # Stack set capabilities (for IAM resources)
        attribute :capabilities, Resources::Types::Array.of(
          Types::String.enum(
            "CAPABILITY_IAM", 
            "CAPABILITY_NAMED_IAM", 
            "CAPABILITY_AUTO_EXPAND"
          )
        ).default([].freeze)

        # Permission model
        attribute :permission_model, Resources::Types::String.enum("SERVICE_MANAGED", "SELF_MANAGED")

        # Auto deployment configuration (for SERVICE_MANAGED)
        attribute :auto_deployment, Resources::Types::Hash.schema(
          enabled?: Types::Bool.default(false),
          retain_stacks_on_account_removal?: Types::Bool.default(false)
        ).optional

        # Administration role ARN (for SELF_MANAGED)
        attribute :administration_role_arn, Resources::Types::String.optional

        # Execution role name (for SELF_MANAGED)
        attribute :execution_role_name, Resources::Types::String.optional

        # Operation preferences
        attribute :operation_preferences, Resources::Types::Hash.schema(
          region_concurrency_type?: Types::String.enum("SEQUENTIAL", "PARALLEL").optional,
          max_concurrent_percentage?: Types::Integer.optional.constrained(gteq: 1, lteq: 100),
          max_concurrent_count?: Types::Integer.optional.constrained(gteq: 1),
          failure_tolerance_percentage?: Types::Integer.optional.constrained(gteq: 0, lteq: 100),
          failure_tolerance_count?: Types::Integer.optional.constrained(gteq: 0)
        ).optional

        # Call as operation (immediate deployment)
        attribute :call_as, Resources::Types::String.enum("SELF", "DELEGATED_ADMIN").default("SELF")

        # Stack set tags
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate template source
          if !attrs.template_body && !attrs.template_url
            raise Dry::Struct::Error, "Either template_body or template_url must be specified"
          end
          
          if attrs.template_body && attrs.template_url
            raise Dry::Struct::Error, "Cannot specify both template_body and template_url"
          end

          # Validate permission model requirements
          if attrs.permission_model == "SELF_MANAGED"
            unless attrs.administration_role_arn
              raise Dry::Struct::Error, "administration_role_arn is required for SELF_MANAGED permission model"
            end
            
            unless attrs.execution_role_name
              raise Dry::Struct::Error, "execution_role_name is required for SELF_MANAGED permission model"
            end
            
            if attrs.auto_deployment
              raise Dry::Struct::Error, "auto_deployment is not supported for SELF_MANAGED permission model"
            end
          elsif attrs.permission_model == "SERVICE_MANAGED"
            if attrs.administration_role_arn
              raise Dry::Struct::Error, "administration_role_arn is not supported for SERVICE_MANAGED permission model"
            end
            
            if attrs.execution_role_name
              raise Dry::Struct::Error, "execution_role_name is not supported for SERVICE_MANAGED permission model"
            end
          end

          # Validate template body JSON/YAML
          if attrs.template_body
            begin
              JSON.parse(attrs.template_body)
            rescue JSON::ParserError
              begin
                YAML.safe_load(attrs.template_body)
              rescue Psych::SyntaxError
                raise Dry::Struct::Error, "template_body must be valid JSON or YAML"
              end
            end
          end

          # Validate operation preferences
          if attrs.operation_preferences
            prefs = attrs.operation_preferences
            
            # Cannot specify both max_concurrent_percentage and max_concurrent_count
            if prefs[:max_concurrent_percentage] && prefs[:max_concurrent_count]
              raise Dry::Struct::Error, "Cannot specify both max_concurrent_percentage and max_concurrent_count"
            end
            
            # Cannot specify both failure_tolerance_percentage and failure_tolerance_count
            if prefs[:failure_tolerance_percentage] && prefs[:failure_tolerance_count]
              raise Dry::Struct::Error, "Cannot specify both failure_tolerance_percentage and failure_tolerance_count"
            end
          end

          # Validate URLs
          if attrs.template_url && !attrs.template_url.match?(/\Ahttps?:\/\//)
            raise Dry::Struct::Error, "template_url must be a valid HTTP/HTTPS URL"
          end

          attrs
        end

        # Helper methods
        def uses_template_body?
          !template_body.nil?
        end

        def uses_template_url?
          !template_url.nil?
        end

        def has_parameters?
          parameters.any?
        end

        def has_capabilities?
          capabilities.any?
        end

        def has_description?
          !description.nil?
        end

        def is_service_managed?
          permission_model == "SERVICE_MANAGED"
        end

        def is_self_managed?
          permission_model == "SELF_MANAGED"
        end

        def has_auto_deployment?
          !auto_deployment.nil?
        end

        def auto_deployment_enabled?
          auto_deployment&.dig(:enabled) == true
        end

        def retains_stacks_on_removal?
          auto_deployment&.dig(:retain_stacks_on_account_removal) == true
        end

        def has_operation_preferences?
          !operation_preferences.nil?
        end

        def uses_parallel_deployment?
          operation_preferences&.dig(:region_concurrency_type) == "PARALLEL"
        end

        def uses_sequential_deployment?
          operation_preferences&.dig(:region_concurrency_type) == "SEQUENTIAL"
        end

        def requires_iam_capabilities?
          capabilities.any? { |cap| cap.include?("IAM") }
        end

        def template_source
          return :body if template_body
          return :url if template_url
          :none
        end
      end

      # Common CloudFormation Stack Set configurations
      module CloudFormationStackSetConfigs
        # Service-managed stack set (Organizations)
        def self.service_managed_stack_set(name, template_body)
          {
            name: name,
            template_body: template_body,
            permission_model: "SERVICE_MANAGED",
            auto_deployment: {
              enabled: true,
              retain_stacks_on_account_removal: false
            },
            call_as: "DELEGATED_ADMIN"
          }
        end

        # Self-managed stack set
        def self.self_managed_stack_set(name, template_body, admin_role_arn, exec_role_name)
          {
            name: name,
            template_body: template_body,
            permission_model: "SELF_MANAGED",
            administration_role_arn: admin_role_arn,
            execution_role_name: exec_role_name,
            call_as: "SELF"
          }
        end

        # Stack set with parallel deployment
        def self.parallel_deployment_stack_set(name, template_url)
          {
            name: name,
            template_url: template_url,
            permission_model: "SERVICE_MANAGED",
            auto_deployment: {
              enabled: true,
              retain_stacks_on_account_removal: false
            },
            operation_preferences: {
              region_concurrency_type: "PARALLEL",
              max_concurrent_percentage: 100,
              failure_tolerance_percentage: 10
            }
          }
        end

        # Stack set with conservative deployment
        def self.conservative_deployment_stack_set(name, template_body)
          {
            name: name,
            template_body: template_body,
            permission_model: "SERVICE_MANAGED",
            auto_deployment: {
              enabled: false,
              retain_stacks_on_account_removal: true
            },
            operation_preferences: {
              region_concurrency_type: "SEQUENTIAL",
              max_concurrent_count: 1,
              failure_tolerance_count: 0
            }
          }
        end

        # IAM-enabled stack set
        def self.iam_stack_set(name, template_body, admin_role_arn, exec_role_name)
          {
            name: name,
            template_body: template_body,
            permission_model: "SELF_MANAGED",
            administration_role_arn: admin_role_arn,
            execution_role_name: exec_role_name,
            capabilities: ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
          }
        end

        # Stack set with custom operation preferences
        def self.custom_operation_stack_set(name, template_url, max_concurrent: 50, failure_tolerance: 5)
          {
            name: name,
            template_url: template_url,
            permission_model: "SERVICE_MANAGED",
            auto_deployment: {
              enabled: true,
              retain_stacks_on_account_removal: false
            },
            operation_preferences: {
              region_concurrency_type: "PARALLEL",
              max_concurrent_percentage: max_concurrent,
              failure_tolerance_percentage: failure_tolerance
            }
          }
        end
      end
    end
      end
    end
  end
end