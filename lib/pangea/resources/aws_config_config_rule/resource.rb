# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_config_config_rule/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Config Config Rule with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Config Rule attributes
      # @option attributes [String] :name The name of the config rule
      # @option attributes [Hash] :source The source configuration for the rule
      # @option attributes [String] :description The description of the config rule
      # @option attributes [String] :input_parameters A string in JSON format for input parameters
      # @option attributes [String] :maximum_execution_frequency The maximum frequency for rule evaluations
      # @option attributes [Hash] :scope The scope of the config rule
      # @option attributes [Array] :depends_on Resources this rule depends on
      # @option attributes [Hash] :tags A map of tags to assign to the resource
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example AWS managed rule
      #   root_mfa_rule = aws_config_config_rule(:root_mfa_enabled, {
      #     name: "root-mfa-enabled",
      #     description: "Checks whether MFA is enabled for the root user",
      #     source: {
      #       owner: "AWS",
      #       source_identifier: "ROOT_MFA_ENABLED"
      #     },
      #     tags: {
      #       Environment: "production",
      #       Compliance: "required"
      #     }
      #   })
      #
      # @example Custom Lambda rule with scope
      #   custom_compliance_rule = aws_config_config_rule(:custom_compliance, {
      #     name: "custom-security-compliance",
      #     description: "Custom security compliance validation",
      #     source: {
      #       owner: "CUSTOM_LAMBDA",
      #       source_identifier: compliance_lambda.arn
      #     },
      #     scope: {
      #       compliance_resource_types: [
      #         "AWS::EC2::Instance",
      #         "AWS::S3::Bucket"
      #       ]
      #     },
      #     input_parameters: {
      #       requiredTags: "Environment,Owner",
      #       allowedInstanceTypes: "t3.micro,t3.small"
      #     }.to_json,
      #     tags: {
      #       Environment: "production",
      #       Type: "security",
      #       Custom: "true"
      #     }
      #   })
      #
      # @example Periodic evaluation rule
      #   periodic_rule = aws_config_config_rule(:periodic_check, {
      #     name: "periodic-compliance-check",
      #     description: "Periodic compliance validation",
      #     source: {
      #       owner: "AWS",
      #       source_identifier: "S3_BUCKET_PUBLIC_READ_PROHIBITED"
      #     },
      #     maximum_execution_frequency: "Six_Hours",
      #     tags: {
      #       Environment: "production",
      #       Schedule: "periodic"
      #     }
      #   })
      def aws_config_config_rule(name, attributes = {})
        # Validate attributes using dry-struct
        rule_attrs = Types::Types::ConfigConfigRuleAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_config_config_rule, name) do
          name rule_attrs.name
          description rule_attrs.description if rule_attrs.description
          
          # Source configuration
          source do
            owner rule_attrs.source[:owner]
            source_identifier rule_attrs.source[:source_identifier] if rule_attrs.source[:source_identifier]
            
            # Source detail for custom policy rules
            if rule_attrs.source[:source_detail].is_a?(Array)
              rule_attrs.source[:source_detail].each do |detail|
                source_detail do
                  event_source detail[:event_source] if detail[:event_source]
                  message_type detail[:message_type] if detail[:message_type]
                  maximum_execution_frequency detail[:maximum_execution_frequency] if detail[:maximum_execution_frequency]
                end
              end
            end
          end
          
          # Input parameters as JSON string
          input_parameters rule_attrs.input_parameters if rule_attrs.input_parameters
          
          # Maximum execution frequency for periodic rules
          maximum_execution_frequency rule_attrs.maximum_execution_frequency if rule_attrs.has_periodic_execution?
          
          # Scope configuration
          if rule_attrs.has_scope?
            scope do
              if rule_attrs.scope[:compliance_resource_types]
                compliance_resource_types rule_attrs.scope[:compliance_resource_types]
              end
              
              if rule_attrs.scope[:tag_key]
                tag_key rule_attrs.scope[:tag_key]
              end
              
              if rule_attrs.scope[:tag_value] 
                tag_value rule_attrs.scope[:tag_value]
              end
              
              if rule_attrs.scope[:compliance_resource_id]
                compliance_resource_id rule_attrs.scope[:compliance_resource_id]
              end
            end
          end
          
          # Dependencies
          if rule_attrs.depends_on.any?
            depends_on rule_attrs.depends_on
          end
          
          # Apply tags if present
          if rule_attrs.tags.any?
            tags do
              rule_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_config_config_rule',
          name: name,
          resource_attributes: rule_attrs.to_h,
          outputs: {
            arn: "${aws_config_config_rule.#{name}.arn}",
            name: "${aws_config_config_rule.#{name}.name}",
            rule_id: "${aws_config_config_rule.#{name}.rule_id}",
            source: "${aws_config_config_rule.#{name}.source}",
            scope: "${aws_config_config_rule.#{name}.scope}",
            tags_all: "${aws_config_config_rule.#{name}.tags_all}"
          },
          computed_properties: {
            is_aws_managed: rule_attrs.is_aws_managed?,
            is_custom_lambda: rule_attrs.is_custom_lambda?,
            is_custom_policy: rule_attrs.is_custom_policy?,
            has_scope: rule_attrs.has_scope?,
            has_resource_type_scope: rule_attrs.has_resource_type_scope?,
            has_tag_scope: rule_attrs.has_tag_scope?,
            has_periodic_execution: rule_attrs.has_periodic_execution?,
            estimated_monthly_cost_usd: rule_attrs.estimated_monthly_cost_usd
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)