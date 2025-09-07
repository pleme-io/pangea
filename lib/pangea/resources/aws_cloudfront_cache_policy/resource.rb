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
require 'pangea/resources/aws_cloudfront_cache_policy/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      def aws_cloudfront_cache_policy(name, attributes = {})
        cache_policy_attrs = Types::CloudFrontCachePolicyAttributes.new(attributes)
        
        resource(:aws_cloudfront_cache_policy, name) do
          name cache_policy_attrs.name
          comment cache_policy_attrs.comment if cache_policy_attrs.comment.present?
          default_ttl cache_policy_attrs.default_ttl
          max_ttl cache_policy_attrs.max_ttl
          min_ttl cache_policy_attrs.min_ttl
          
          parameters_in_cache_key_and_forwarded_to_origin do
            enable_accept_encoding_brotli cache_policy_attrs.parameters_in_cache_key_and_forwarded_to_origin[:enable_accept_encoding_brotli]
            enable_accept_encoding_gzip cache_policy_attrs.parameters_in_cache_key_and_forwarded_to_origin[:enable_accept_encoding_gzip]
            
            headers_config do
              header_behavior cache_policy_attrs.parameters_in_cache_key_and_forwarded_to_origin[:headers_config][:header_behavior]
              if cache_policy_attrs.parameters_in_cache_key_and_forwarded_to_origin[:headers_config][:headers]
                headers do
                  items cache_policy_attrs.parameters_in_cache_key_and_forwarded_to_origin[:headers_config][:headers][:items] if cache_policy_attrs.parameters_in_cache_key_and_forwarded_to_origin[:headers_config][:headers][:items]
                end
              end
            end
            
            query_strings_config do
              query_string_behavior cache_policy_attrs.parameters_in_cache_key_and_forwarded_to_origin[:query_strings_config][:query_string_behavior]
              if cache_policy_attrs.parameters_in_cache_key_and_forwarded_to_origin[:query_strings_config][:query_strings]
                query_strings do
                  items cache_policy_attrs.parameters_in_cache_key_and_forwarded_to_origin[:query_strings_config][:query_strings][:items] if cache_policy_attrs.parameters_in_cache_key_and_forwarded_to_origin[:query_strings_config][:query_strings][:items]
                end
              end
            end
            
            cookies_config do
              cookie_behavior cache_policy_attrs.parameters_in_cache_key_and_forwarded_to_origin[:cookies_config][:cookie_behavior]
              if cache_policy_attrs.parameters_in_cache_key_and_forwarded_to_origin[:cookies_config][:cookies]
                cookies do
                  items cache_policy_attrs.parameters_in_cache_key_and_forwarded_to_origin[:cookies_config][:cookies][:items] if cache_policy_attrs.parameters_in_cache_key_and_forwarded_to_origin[:cookies_config][:cookies][:items]
                end
              end
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_cloudfront_cache_policy',
          name: name,
          resource_attributes: cache_policy_attrs.to_h,
          outputs: {
            id: "${aws_cloudfront_cache_policy.#{name}.id}",
            etag: "${aws_cloudfront_cache_policy.#{name}.etag}"
          },
          computed: {}
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)