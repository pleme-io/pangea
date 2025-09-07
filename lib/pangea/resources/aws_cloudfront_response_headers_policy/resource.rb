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
require 'pangea/resources/aws_cloudfront_response_headers_policy/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudFront Response Headers Policy with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudFront response headers policy attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cloudfront_response_headers_policy(name, attributes = {})
        # Validate attributes using dry-struct
        headers_policy_attrs = Types::CloudFrontResponseHeadersPolicyAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudfront_response_headers_policy, name) do
          name headers_policy_attrs.name
          comment headers_policy_attrs.comment if headers_policy_attrs.comment
          
          # Configure CORS if specified
          if headers_policy_attrs.cors_config
            cors_config do
              access_control_allow_credentials headers_policy_attrs.cors_config[:access_control_allow_credentials]
              origin_override headers_policy_attrs.cors_config[:origin_override]
              
              if headers_policy_attrs.cors_config[:access_control_allow_headers]
                access_control_allow_headers do
                  items headers_policy_attrs.cors_config[:access_control_allow_headers][:items]
                end
              end
              
              access_control_allow_methods do
                items headers_policy_attrs.cors_config[:access_control_allow_methods][:items]
              end
              
              access_control_allow_origins do
                items headers_policy_attrs.cors_config[:access_control_allow_origins][:items]
              end
              
              if headers_policy_attrs.cors_config[:access_control_expose_headers]
                access_control_expose_headers do
                  items headers_policy_attrs.cors_config[:access_control_expose_headers][:items]
                end
              end
              
              access_control_max_age_sec headers_policy_attrs.cors_config[:access_control_max_age_sec] if headers_policy_attrs.cors_config[:access_control_max_age_sec]
            end
          end
          
          # Configure custom headers if specified
          if headers_policy_attrs.custom_headers_config&.dig(:items)
            custom_headers_config do
              headers_policy_attrs.custom_headers_config[:items].each do |header_config|
                items do
                  header header_config[:header]
                  value header_config[:value]
                  override header_config[:override]
                end
              end
            end
          end
          
          # Configure remove headers if specified
          if headers_policy_attrs.remove_headers_config
            remove_headers_config do
              headers_policy_attrs.remove_headers_config[:items].each do |header_config|
                items do
                  header header_config[:header]
                end
              end
            end
          end
          
          # Configure security headers if specified
          if headers_policy_attrs.security_headers_config
            security_headers_config do
              if headers_policy_attrs.security_headers_config[:content_type_options]
                content_type_options do
                  override headers_policy_attrs.security_headers_config[:content_type_options][:override]
                end
              end
              
              if headers_policy_attrs.security_headers_config[:frame_options]
                frame_options do
                  frame_option headers_policy_attrs.security_headers_config[:frame_options][:frame_option]
                  override headers_policy_attrs.security_headers_config[:frame_options][:override]
                end
              end
              
              if headers_policy_attrs.security_headers_config[:referrer_policy]
                referrer_policy do
                  referrer_policy headers_policy_attrs.security_headers_config[:referrer_policy][:referrer_policy]
                  override headers_policy_attrs.security_headers_config[:referrer_policy][:override]
                end
              end
              
              if headers_policy_attrs.security_headers_config[:strict_transport_security]
                strict_transport_security do
                  access_control_max_age_sec headers_policy_attrs.security_headers_config[:strict_transport_security][:access_control_max_age_sec]
                  include_subdomains headers_policy_attrs.security_headers_config[:strict_transport_security][:include_subdomains] if headers_policy_attrs.security_headers_config[:strict_transport_security][:include_subdomains]
                  override headers_policy_attrs.security_headers_config[:strict_transport_security][:override]
                  preload headers_policy_attrs.security_headers_config[:strict_transport_security][:preload] if headers_policy_attrs.security_headers_config[:strict_transport_security][:preload]
                end
              end
            end
          end
          
          # Configure server timing headers if specified
          if headers_policy_attrs.server_timing_headers_config
            server_timing_headers_config do
              enabled headers_policy_attrs.server_timing_headers_config[:enabled]
              sampling_rate headers_policy_attrs.server_timing_headers_config[:sampling_rate] if headers_policy_attrs.server_timing_headers_config[:sampling_rate]
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cloudfront_response_headers_policy',
          name: name,
          resource_attributes: headers_policy_attrs.to_h,
          outputs: {
            id: "${aws_cloudfront_response_headers_policy.#{name}.id}",
            etag: "${aws_cloudfront_response_headers_policy.#{name}.etag}",
            name: "${aws_cloudfront_response_headers_policy.#{name}.name}",
            comment: "${aws_cloudfront_response_headers_policy.#{name}.comment}",
            cors_config: "${aws_cloudfront_response_headers_policy.#{name}.cors_config}",
            custom_headers_config: "${aws_cloudfront_response_headers_policy.#{name}.custom_headers_config}",
            remove_headers_config: "${aws_cloudfront_response_headers_policy.#{name}.remove_headers_config}",
            security_headers_config: "${aws_cloudfront_response_headers_policy.#{name}.security_headers_config}",
            server_timing_headers_config: "${aws_cloudfront_response_headers_policy.#{name}.server_timing_headers_config}"
          },
          computed_properties: {
            has_cors: headers_policy_attrs.has_cors?,
            has_security_headers: headers_policy_attrs.has_security_headers?,
            has_custom_headers: headers_policy_attrs.has_custom_headers?,
            has_remove_headers: headers_policy_attrs.has_remove_headers?,
            cors_allows_credentials: headers_policy_attrs.cors_allows_credentials?,
            cors_allows_all_origins: headers_policy_attrs.cors_allows_all_origins?,
            hsts_enabled: headers_policy_attrs.hsts_enabled?,
            frame_options_enabled: headers_policy_attrs.frame_options_enabled?,
            security_level: headers_policy_attrs.security_level,
            complexity_level: headers_policy_attrs.complexity_level,
            production_ready: headers_policy_attrs.production_ready?,
            primary_purpose: headers_policy_attrs.primary_purpose,
            configuration_warnings: headers_policy_attrs.validate_configuration,
            estimated_monthly_cost: headers_policy_attrs.estimated_monthly_cost
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)