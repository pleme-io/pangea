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
require 'pangea/resources/aws_config_remediation_configuration/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Config Remediation Configuration with type-safe attributes
      def aws_config_remediation_configuration(name, attributes = {})
        remediation_attrs = Types::Types::ConfigRemediationConfigurationAttributes.new(attributes)
        
        resource(:aws_config_remediation_configuration, name) do
          config_rule_name remediation_attrs.config_rule_name
          resource_type remediation_attrs.resource_type
          target_type remediation_attrs.target_type
          target_id remediation_attrs.target_id
          target_version remediation_attrs.target_version
          automatic remediation_attrs.automatic
          
          maximum_automatic_attempts remediation_attrs.maximum_automatic_attempts if remediation_attrs.has_max_attempts?
          
          if remediation_attrs.has_parameters?
            parameters do
              remediation_attrs.parameters.each do |key, value|
                public_send(key, value)
              end
            end
          end
          
          if remediation_attrs.tags.any?
            tags do
              remediation_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_config_remediation_configuration',
          name: name,
          resource_attributes: remediation_attrs.to_h,
          outputs: {
            arn: "${aws_config_remediation_configuration.#{name}.arn}",
            config_rule_name: "${aws_config_remediation_configuration.#{name}.config_rule_name}",
            tags_all: "${aws_config_remediation_configuration.#{name}.tags_all}"
          },
          computed_properties: {
            has_parameters: remediation_attrs.has_parameters?,
            is_automatic: remediation_attrs.is_automatic?,
            estimated_monthly_cost_usd: remediation_attrs.estimated_monthly_cost_usd
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)