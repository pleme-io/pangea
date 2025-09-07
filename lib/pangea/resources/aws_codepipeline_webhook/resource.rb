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
require 'pangea/resources/aws_codepipeline_webhook/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CodePipeline Webhook with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CodePipeline webhook attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_codepipeline_webhook(name, attributes = {})
        # Validate attributes using dry-struct
        webhook_attrs = Types::CodePipelineWebhookAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_codepipeline_webhook, name) do
          # Basic configuration
          name webhook_attrs.name
          target_pipeline webhook_attrs.target_pipeline
          target_action webhook_attrs.target_action
          authentication webhook_attrs.authentication
          
          # Authentication configuration
          if webhook_attrs.authentication_configuration.any?
            authentication_configuration do
              secret_token webhook_attrs.authentication_configuration[:secret_token] if webhook_attrs.authentication_configuration[:secret_token]
              allowed_ip_range webhook_attrs.authentication_configuration[:allowed_ip_range] if webhook_attrs.authentication_configuration[:allowed_ip_range]
            end
          end
          
          # Filters
          webhook_attrs.filters.each do |filter_config|
            filter do
              json_path filter_config[:json_path]
              match_equals filter_config[:match_equals] if filter_config[:match_equals]
            end
          end
          
          # Apply tags
          if webhook_attrs.tags.any?
            tags do
              webhook_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_codepipeline_webhook',
          name: name,
          resource_attributes: webhook_attrs.to_h,
          outputs: {
            id: "${aws_codepipeline_webhook.#{name}.id}",
            arn: "${aws_codepipeline_webhook.#{name}.arn}",
            url: "${aws_codepipeline_webhook.#{name}.url}"
          },
          computed: {
            github_authentication: webhook_attrs.github_authentication?,
            ip_authentication: webhook_attrs.ip_authentication?,
            unauthenticated: webhook_attrs.unauthenticated?,
            filter_count: webhook_attrs.filter_count,
            has_secret: webhook_attrs.has_secret?,
            filter_descriptions: webhook_attrs.filter_descriptions,
            security_level: webhook_attrs.security_level
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)