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
require 'pangea/resources/aws_iot_topic_rule/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      def aws_iot_topic_rule(name, attributes = {})
        rule_attrs = Types::IotTopicRuleAttributes.new(attributes)
        
        resource(:aws_iot_topic_rule, name) do
          name rule_attrs.name
          enabled rule_attrs.enabled
          sql rule_attrs.sql
          sql_version rule_attrs.sql_version
          aws_iot_sql_version rule_attrs.aws_iot_sql_version if rule_attrs.aws_iot_sql_version
          description rule_attrs.description if rule_attrs.description
          
          rule_attrs.actions.each_with_index do |action, index|
            action_type = action.keys.first
            action_config = action[action_type]
            
            public_send(action_type) do
              action_config.each { |k, v| public_send(k, v) }
            end
          end
          
          if rule_attrs.error_action
            error_action do
              rule_attrs.error_action.each { |k, v| public_send(k, v) }
            end
          end
          
          if rule_attrs.tags.any?
            tags do
              rule_attrs.tags.each { |k, v| public_send(k, v) }
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_iot_topic_rule',
          name: name,
          resource_attributes: rule_attrs.to_h,
          outputs: {
            name: "${aws_iot_topic_rule.#{name}.name}",
            arn: "${aws_iot_topic_rule.#{name}.arn}",
            sql: "${aws_iot_topic_rule.#{name}.sql}",
            enabled: "${aws_iot_topic_rule.#{name}.enabled}",
            tags_all: "${aws_iot_topic_rule.#{name}.tags_all}"
          },
          computed_properties: {
            action_types: rule_attrs.action_types,
            has_error_handling: rule_attrs.has_error_handling?,
            sql_complexity_score: rule_attrs.sql_complexity_score
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)