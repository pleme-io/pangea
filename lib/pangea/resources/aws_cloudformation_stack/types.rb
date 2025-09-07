# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS CloudFormation Stack resources
      class CloudFormationStackAttributes < Dry::Struct
        # Stack name (required)
        attribute :name, Resources::Types::String

        # Template body or URL
        attribute :template_body, Resources::Types::String.optional
        attribute :template_url, Resources::Types::String.optional

        # Stack parameters
        attribute :parameters, Resources::Types::Hash.map(Types::String, Types::String).default({})

        # Stack capabilities (for IAM resources)
        attribute :capabilities, Resources::Types::Array.of(
          Types::String.enum(
            "CAPABILITY_IAM", 
            "CAPABILITY_NAMED_IAM", 
            "CAPABILITY_AUTO_EXPAND"
          )
        ).default([].freeze)

        # Stack notification topics
        attribute :notification_arns, Resources::Types::Array.of(Types::String).default([].freeze)

        # Stack policy (JSON document)
        attribute :policy_body, Resources::Types::String.optional
        attribute :policy_url, Resources::Types::String.optional

        # Stack timeout (in minutes)
        attribute :timeout_in_minutes, Resources::Types::Integer.optional.constrained(gteq: 1)

        # Disable rollback on failure
        attribute :disable_rollback, Resources::Types::Bool.default(false)

        # Enable termination protection
        attribute :enable_termination_protection, Resources::Types::Bool.default(false)

        # IAM role for CloudFormation service
        attribute :iam_role_arn, Resources::Types::String.optional

        # Stack creation options
        attribute :on_failure, Resources::Types::String.enum("DO_NOTHING", "ROLLBACK", "DELETE").default("ROLLBACK")

        # Stack tags
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

          # Validate policy source consistency
          if attrs.policy_body && attrs.policy_url
            raise Dry::Struct::Error, "Cannot specify both policy_body and policy_url"
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

          # Validate policy body JSON
          if attrs.policy_body
            begin
              JSON.parse(attrs.policy_body)
            rescue JSON::ParserError
              raise Dry::Struct::Error, "policy_body must be valid JSON"
            end
          end

          # Validate URLs
          if attrs.template_url && !attrs.template_url.match?(/\Ahttps?:\/\//)
            raise Dry::Struct::Error, "template_url must be a valid HTTP/HTTPS URL"
          end

          if attrs.policy_url && !attrs.policy_url.match?(/\Ahttps?:\/\//)
            raise Dry::Struct::Error, "policy_url must be a valid HTTP/HTTPS URL"
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

        def has_notifications?
          notification_arns.any?
        end

        def has_policy?
          !policy_body.nil? || !policy_url.nil?
        end

        def has_timeout?
          !timeout_in_minutes.nil?
        end

        def has_iam_role?
          !iam_role_arn.nil?
        end

        def rollback_disabled?
          disable_rollback
        end

        def termination_protected?
          enable_termination_protection
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

      # Common CloudFormation Stack configurations
      module CloudFormationStackConfigs
        # Simple stack with inline template
        def self.simple_stack(name, template_body)
          {
            name: name,
            template_body: template_body,
            on_failure: "ROLLBACK"
          }
        end

        # Stack from S3 template URL
        def self.s3_template_stack(name, template_url, parameters: {})
          {
            name: name,
            template_url: template_url,
            parameters: parameters,
            on_failure: "ROLLBACK"
          }
        end

        # IAM-enabled stack
        def self.iam_stack(name, template_body, iam_role_arn: nil)
          {
            name: name,
            template_body: template_body,
            capabilities: ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"],
            iam_role_arn: iam_role_arn,
            enable_termination_protection: true
          }
        end

        # Stack with notification
        def self.monitored_stack(name, template_body, notification_arns)
          {
            name: name,
            template_body: template_body,
            notification_arns: notification_arns,
            on_failure: "ROLLBACK",
            timeout_in_minutes: 30
          }
        end

        # Production stack with full protection
        def self.production_stack(name, template_url, parameters: {})
          {
            name: name,
            template_url: template_url,
            parameters: parameters,
            capabilities: ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"],
            enable_termination_protection: true,
            disable_rollback: false,
            timeout_in_minutes: 60
          }
        end

        # Stack with policy protection
        def self.protected_stack(name, template_body, policy_body)
          {
            name: name,
            template_body: template_body,
            policy_body: policy_body,
            capabilities: ["CAPABILITY_IAM"],
            enable_termination_protection: true
          }
        end
      end
    end
      end
    end
  end
end