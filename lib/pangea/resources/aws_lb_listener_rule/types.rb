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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Load Balancer Listener Rule resources
      class LoadBalancerListenerRuleAttributes < Dry::Struct
        # The ARN of the listener to attach the rule to
        attribute :listener_arn, Resources::Types::String
        
        # The priority for the rule (1-50000, lower numbers have higher priority)
        attribute :priority, Resources::Types::Integer.constrained(gteq: 1, lteq: 50000)
        
        # Actions to take when the rule conditions are met
        attribute :action, Resources::Types::Array.of(
          Types::Hash.schema(
            type: Types::ListenerActionType,
            target_group_arn?: Types::String.optional,
            forward?: Types::ListenerForwardAction.optional,
            redirect?: Types::ListenerRedirectAction.optional,
            fixed_response?: Types::ListenerFixedResponseAction.optional,
            authenticate_cognito?: Types::ListenerAuthenticateCognitoAction.optional,
            authenticate_oidc?: Types::ListenerAuthenticateOidcAction.optional,
            order?: Types::Integer.constrained(gteq: 1, lteq: 50000).optional
          )
        ).constrained(min_size: 1)
        
        # Conditions that must be met for the rule to apply
        attribute :condition, Resources::Types::Array.of(
          Types::Hash.schema(
            field?: Types::String.optional, # Legacy field name
            values?: Types::Array.of(Types::String).optional, # Legacy values
            host_header?: Types::ListenerConditionHostHeader.optional,
            path_pattern?: Types::ListenerConditionPathPattern.optional,
            http_method?: Types::ListenerConditionHttpMethod.optional,
            query_string?: Types::ListenerConditionQueryString.optional,
            http_header?: Types::ListenerConditionHttpHeader.optional,
            source_ip?: Types::ListenerConditionSourceIp.optional
          )
        ).constrained(min_size: 1)
        
        # Tags to apply to the listener rule
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation for condition and action completeness
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate that each condition has proper configuration
          attrs.condition.each_with_index do |condition, index|
            condition_types = []
            
            # Check legacy condition format first
            if condition[:field] && condition[:values]
              condition_types << 'legacy'
            end
            
            # Check modern condition types
            condition_types << 'host-header' if condition[:host_header]
            condition_types << 'path-pattern' if condition[:path_pattern]
            condition_types << 'http-method' if condition[:http_method]
            condition_types << 'query-string' if condition[:query_string]
            condition_types << 'http-header' if condition[:http_header]
            condition_types << 'source-ip' if condition[:source_ip]
            
            if condition_types.empty?
              raise Dry::Struct::Error, "Condition #{index + 1} must specify at least one condition type"
            elsif condition_types.length > 1
              raise Dry::Struct::Error, "Condition #{index + 1} can only specify one condition type, found: #{condition_types.join(', ')}"
            end
          end
          
          # Validate actions
          attrs.action.each_with_index do |action, index|
            case action[:type]
            when 'forward'
              unless action[:target_group_arn] || action[:forward]
                raise Dry::Struct::Error, "Forward action #{index + 1} requires either target_group_arn or forward configuration"
              end
            when 'redirect'
              unless action[:redirect]
                raise Dry::Struct::Error, "Redirect action #{index + 1} requires redirect configuration"
              end
            when 'fixed-response'
              unless action[:fixed_response]
                raise Dry::Struct::Error, "Fixed-response action #{index + 1} requires fixed_response configuration"
              end
            when 'authenticate-cognito'
              unless action[:authenticate_cognito]
                raise Dry::Struct::Error, "Authenticate-cognito action #{index + 1} requires authenticate_cognito configuration"
              end
            when 'authenticate-oidc'
              unless action[:authenticate_oidc]
                raise Dry::Struct::Error, "Authenticate-oidc action #{index + 1} requires authenticate_oidc configuration"
              end
            end
          end

          attrs
        end
      end
    end
      end
    end
  end
end