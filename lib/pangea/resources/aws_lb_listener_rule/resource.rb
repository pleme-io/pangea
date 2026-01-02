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
require 'pangea/resources/aws_lb_listener_rule/types'
require_relative 'action_builders'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Load Balancer Listener Rule with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Listener rule attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_lb_listener_rule(name, attributes = {})
        # Validate attributes using dry-struct
        rule_attrs = Types::LoadBalancerListenerRuleAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_lb_listener_rule, name) do
          listener_arn rule_attrs.listener_arn
          priority rule_attrs.priority
          
          # Actions configuration
          rule_attrs.action.each do |act|
            LbListenerRuleActionBuilders.apply_action(self, act)
          end
          
          # Conditions configuration
          rule_attrs.condition.each_with_index do |condition, index|
            condition do
              # Legacy condition format (deprecated but supported)
              if condition[:field] && condition[:values]
                field condition[:field]
                values condition[:values]
              end
              
              # Modern condition types
              if condition[:host_header]
                host_header do
                  values condition[:host_header][:values]
                end
              end
              
              if condition[:path_pattern]
                path_pattern do
                  values condition[:path_pattern][:values]
                end
              end
              
              if condition[:http_method]
                http_method do
                  values condition[:http_method][:values]
                end
              end
              
              if condition[:query_string]
                condition[:query_string][:values].each do |qs|
                  query_string do
                    key qs[:key] if qs[:key]
                    value qs[:value]
                  end
                end
              end
              
              if condition[:http_header]
                http_header do
                  http_header_name condition[:http_header][:http_header_name]
                  values condition[:http_header][:values]
                end
              end
              
              if condition[:source_ip]
                source_ip do
                  values condition[:source_ip][:values]
                end
              end
            end
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
          type: 'aws_lb_listener_rule',
          name: name,
          resource_attributes: rule_attrs.to_h,
          outputs: {
            id: "${aws_lb_listener_rule.#{name}.id}",
            arn: "${aws_lb_listener_rule.#{name}.arn}",
            listener_arn: "${aws_lb_listener_rule.#{name}.listener_arn}",
            priority: "${aws_lb_listener_rule.#{name}.priority}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)