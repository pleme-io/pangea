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
require 'pangea/resources/aws_cloudfront_distribution/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudFront Distribution with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudFront distribution attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cloudfront_distribution(name, attributes = {})
        # Validate attributes using dry-struct
        distribution_attrs = AWS::Types::Types::CloudFrontDistributionAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudfront_distribution, name) do
          # Configure origins
          distribution_attrs.origin.each do |origin_config|
            origin do
              domain_name origin_config[:domain_name]
              origin_id origin_config[:origin_id]
              origin_path origin_config[:origin_path] if origin_config[:origin_path]
              connection_attempts origin_config[:connection_attempts] if origin_config[:connection_attempts]
              connection_timeout origin_config[:connection_timeout] if origin_config[:connection_timeout]
              
              # Configure S3 origin
              if origin_config[:s3_origin_config]
                s3_origin_config do
                  origin_access_identity origin_config[:s3_origin_config][:origin_access_identity] if origin_config[:s3_origin_config][:origin_access_identity]
                  origin_access_control_id origin_config[:s3_origin_config][:origin_access_control_id] if origin_config[:s3_origin_config][:origin_access_control_id]
                end
              end
              
              # Configure custom origin
              if origin_config[:custom_origin_config]
                custom_origin_config do
                  http_port origin_config[:custom_origin_config][:http_port]
                  https_port origin_config[:custom_origin_config][:https_port] 
                  origin_protocol_policy origin_config[:custom_origin_config][:origin_protocol_policy]
                  origin_ssl_protocols origin_config[:custom_origin_config][:origin_ssl_protocols] if origin_config[:custom_origin_config][:origin_ssl_protocols]
                  origin_keepalive_timeout origin_config[:custom_origin_config][:origin_keepalive_timeout] if origin_config[:custom_origin_config][:origin_keepalive_timeout]
                  origin_read_timeout origin_config[:custom_origin_config][:origin_read_timeout] if origin_config[:custom_origin_config][:origin_read_timeout]
                end
              end
              
              # Configure origin shield
              if origin_config[:origin_shield]
                origin_shield do
                  enabled origin_config[:origin_shield][:enabled]
                  origin_shield_region origin_config[:origin_shield][:origin_shield_region] if origin_config[:origin_shield][:origin_shield_region]
                end
              end
              
              # Configure custom headers
              origin_config[:custom_header].each do |header|
                custom_header do
                  name header[:name]
                  value header[:value]
                end
              end
            end
          end
          
          # Configure default cache behavior
          default_cache_behavior do
            target_origin_id distribution_attrs.default_cache_behavior[:target_origin_id]
            viewer_protocol_policy distribution_attrs.default_cache_behavior[:viewer_protocol_policy]
            allowed_methods distribution_attrs.default_cache_behavior[:allowed_methods] if distribution_attrs.default_cache_behavior[:allowed_methods]
            cached_methods distribution_attrs.default_cache_behavior[:cached_methods] if distribution_attrs.default_cache_behavior[:cached_methods]
            cache_policy_id distribution_attrs.default_cache_behavior[:cache_policy_id] if distribution_attrs.default_cache_behavior[:cache_policy_id]
            origin_request_policy_id distribution_attrs.default_cache_behavior[:origin_request_policy_id] if distribution_attrs.default_cache_behavior[:origin_request_policy_id]
            response_headers_policy_id distribution_attrs.default_cache_behavior[:response_headers_policy_id] if distribution_attrs.default_cache_behavior[:response_headers_policy_id]
            realtime_log_config_arn distribution_attrs.default_cache_behavior[:realtime_log_config_arn] if distribution_attrs.default_cache_behavior[:realtime_log_config_arn]
            smooth_streaming distribution_attrs.default_cache_behavior[:smooth_streaming] if distribution_attrs.default_cache_behavior[:smooth_streaming]
            trusted_signers distribution_attrs.default_cache_behavior[:trusted_signers] if distribution_attrs.default_cache_behavior[:trusted_signers].any?
            trusted_key_groups distribution_attrs.default_cache_behavior[:trusted_key_groups] if distribution_attrs.default_cache_behavior[:trusted_key_groups].any?
            compress distribution_attrs.default_cache_behavior[:compress] if distribution_attrs.default_cache_behavior.key?(:compress)
            field_level_encryption_id distribution_attrs.default_cache_behavior[:field_level_encryption_id] if distribution_attrs.default_cache_behavior[:field_level_encryption_id]
            
            # Function associations
            distribution_attrs.default_cache_behavior[:function_association].each do |func_assoc|
              function_association do
                event_type func_assoc[:event_type]
                function_arn func_assoc[:function_arn]
              end
            end
            
            # Lambda@Edge associations
            distribution_attrs.default_cache_behavior[:lambda_function_association].each do |lambda_assoc|
              lambda_function_association do
                event_type lambda_assoc[:event_type]
                lambda_arn lambda_assoc[:lambda_arn]
                include_body lambda_assoc[:include_body] if lambda_assoc.key?(:include_body)
              end
            end
          end
          
          # Configure ordered cache behaviors
          distribution_attrs.ordered_cache_behavior.each do |behavior|
            ordered_cache_behavior do
              path_pattern behavior[:path_pattern]
              target_origin_id behavior[:target_origin_id]
              viewer_protocol_policy behavior[:viewer_protocol_policy]
              allowed_methods behavior[:allowed_methods] if behavior[:allowed_methods]
              cached_methods behavior[:cached_methods] if behavior[:cached_methods]
              cache_policy_id behavior[:cache_policy_id] if behavior[:cache_policy_id]
              origin_request_policy_id behavior[:origin_request_policy_id] if behavior[:origin_request_policy_id]
              response_headers_policy_id behavior[:response_headers_policy_id] if behavior[:response_headers_policy_id]
              smooth_streaming behavior[:smooth_streaming] if behavior[:smooth_streaming]
              trusted_signers behavior[:trusted_signers] if behavior[:trusted_signers].any?
              trusted_key_groups behavior[:trusted_key_groups] if behavior[:trusted_key_groups].any?
              compress behavior[:compress] if behavior.key?(:compress)
              field_level_encryption_id behavior[:field_level_encryption_id] if behavior[:field_level_encryption_id]
              
              # Function associations
              behavior[:function_association].each do |func_assoc|
                function_association do
                  event_type func_assoc[:event_type]
                  function_arn func_assoc[:function_arn]
                end
              end
              
              # Lambda@Edge associations  
              behavior[:lambda_function_association].each do |lambda_assoc|
                lambda_function_association do
                  event_type lambda_assoc[:event_type]
                  lambda_arn lambda_assoc[:lambda_arn]
                  include_body lambda_assoc[:include_body] if lambda_assoc.key?(:include_body)
                end
              end
            end
          end
          
          # Basic distribution settings
          comment distribution_attrs.comment
          default_root_object distribution_attrs.default_root_object if distribution_attrs.default_root_object
          enabled distribution_attrs.enabled
          http_version distribution_attrs.http_version
          is_ipv6_enabled distribution_attrs.is_ipv6_enabled
          price_class distribution_attrs.price_class
          
          # Custom error responses
          distribution_attrs.custom_error_response.each do |error_response|
            custom_error_response do
              error_code error_response[:error_code]
              response_code error_response[:response_code] if error_response[:response_code]
              response_page_path error_response[:response_page_path] if error_response[:response_page_path]
              error_caching_min_ttl error_response[:error_caching_min_ttl] if error_response[:error_caching_min_ttl]
            end
          end
          
          # Geographic restrictions
          restrictions do
            geo_restriction do
              restriction_type distribution_attrs.restrictions[:geo_restriction][:restriction_type]
              locations distribution_attrs.restrictions[:geo_restriction][:locations] if distribution_attrs.restrictions[:geo_restriction][:locations].any?
            end
          end
          
          # Viewer certificate configuration
          viewer_certificate do
            acm_certificate_arn distribution_attrs.viewer_certificate[:acm_certificate_arn] if distribution_attrs.viewer_certificate[:acm_certificate_arn]
            iam_certificate_id distribution_attrs.viewer_certificate[:iam_certificate_id] if distribution_attrs.viewer_certificate[:iam_certificate_id]
            cloudfront_default_certificate distribution_attrs.viewer_certificate[:cloudfront_default_certificate] if distribution_attrs.viewer_certificate.key?(:cloudfront_default_certificate)
            ssl_support_method distribution_attrs.viewer_certificate[:ssl_support_method] if distribution_attrs.viewer_certificate[:ssl_support_method]
            minimum_protocol_version distribution_attrs.viewer_certificate[:minimum_protocol_version] if distribution_attrs.viewer_certificate[:minimum_protocol_version]
          end
          
          # Aliases
          aliases distribution_attrs.aliases if distribution_attrs.aliases.any?
          
          # Web ACL
          web_acl_id distribution_attrs.web_acl_id if distribution_attrs.web_acl_id
          
          # Management settings
          retain_on_delete distribution_attrs.retain_on_delete
          wait_for_deployment distribution_attrs.wait_for_deployment
          
          # Tags
          if distribution_attrs.tags.any?
            tags do
              distribution_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Create resource reference
        ref = ResourceReference.new(
          type: 'aws_cloudfront_distribution',
          name: name,
          resource_attributes: distribution_attrs.to_h,
          outputs: {
            id: "${aws_cloudfront_distribution.#{name}.id}",
            arn: "${aws_cloudfront_distribution.#{name}.arn}",
            domain_name: "${aws_cloudfront_distribution.#{name}.domain_name}",
            hosted_zone_id: "${aws_cloudfront_distribution.#{name}.hosted_zone_id}",
            etag: "${aws_cloudfront_distribution.#{name}.etag}",
            status: "${aws_cloudfront_distribution.#{name}.status}",
            trusted_signers: "${aws_cloudfront_distribution.#{name}.trusted_signers}",
            trusted_key_groups: "${aws_cloudfront_distribution.#{name}.trusted_key_groups}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:total_origins_count) { distribution_attrs.total_origins_count }
        ref.define_singleton_method(:total_behaviors_count) { distribution_attrs.total_behaviors_count }
        ref.define_singleton_method(:has_custom_ssl?) { distribution_attrs.has_custom_ssl? }
        ref.define_singleton_method(:uses_cloudfront_ssl?) { distribution_attrs.uses_cloudfront_ssl? }
        ref.define_singleton_method(:has_custom_domain?) { distribution_attrs.has_custom_domain? }
        ref.define_singleton_method(:has_geographic_restrictions?) { distribution_attrs.has_geographic_restrictions? }
        ref.define_singleton_method(:has_custom_error_pages?) { distribution_attrs.has_custom_error_pages? }
        ref.define_singleton_method(:has_origin_shield?) { distribution_attrs.has_origin_shield? }
        ref.define_singleton_method(:has_lambda_at_edge?) { distribution_attrs.has_lambda_at_edge? }
        ref.define_singleton_method(:has_cloudfront_functions?) { distribution_attrs.has_cloudfront_functions? }
        ref.define_singleton_method(:supports_http2?) { distribution_attrs.supports_http2? }
        ref.define_singleton_method(:ipv6_enabled?) { distribution_attrs.ipv6_enabled? }
        ref.define_singleton_method(:estimated_cost_tier) { distribution_attrs.estimated_cost_tier }
        ref.define_singleton_method(:s3_origins_count) { distribution_attrs.s3_origins_count }
        ref.define_singleton_method(:custom_origins_count) { distribution_attrs.custom_origins_count }
        ref.define_singleton_method(:primary_domain) { distribution_attrs.primary_domain }
        ref.define_singleton_method(:security_profile) { distribution_attrs.security_profile }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)