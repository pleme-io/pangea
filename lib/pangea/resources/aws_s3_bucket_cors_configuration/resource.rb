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
require 'pangea/resources/aws_s3_bucket_cors_configuration/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Bucket CORS Configuration with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_bucket_cors_configuration(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::S3BucketCorsConfigurationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_bucket_cors_configuration, name) do
          # Bucket is required
          bucket attrs.bucket
          
          # Expected bucket owner
          expected_bucket_owner attrs.expected_bucket_owner if attrs.expected_bucket_owner
          
          # CORS rules
          attrs.cors_rule.each do |cors_rule|
            cors_rule do
              # Rule ID (optional)
              id cors_rule.id if cors_rule.id
              
              # Allowed methods (required)
              allowed_methods cors_rule.allowed_methods
              
              # Allowed origins (required)  
              allowed_origins cors_rule.allowed_origins
              
              # Allowed headers (optional)
              allowed_headers cors_rule.allowed_headers if cors_rule.allowed_headers
              
              # Expose headers (optional)
              expose_headers cors_rule.expose_headers if cors_rule.expose_headers
              
              # Max age seconds (optional)
              max_age_seconds cors_rule.max_age_seconds if cors_rule.max_age_seconds
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_s3_bucket_cors_configuration',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_s3_bucket_cors_configuration.#{name}.id}",
            bucket: "${aws_s3_bucket_cors_configuration.#{name}.bucket}",
            expected_bucket_owner: "${aws_s3_bucket_cors_configuration.#{name}.expected_bucket_owner}",
            cors_rule: "${aws_s3_bucket_cors_configuration.#{name}.cors_rule}"
          },
          computed_properties: {
            total_rules_count: attrs.total_rules_count,
            wildcard_rules_count: attrs.rules_with_wildcards.length,
            rules_with_max_age_count: attrs.rules_with_max_age.length,
            rules_exposing_headers_count: attrs.rules_exposing_headers.length,
            max_max_age_seconds: attrs.max_max_age,
            all_allowed_methods: attrs.all_allowed_methods,
            all_allowed_origins: attrs.all_allowed_origins,
            allows_get: attrs.rules_allowing_method("GET").any?,
            allows_post: attrs.rules_allowing_method("POST").any?,
            allows_put: attrs.rules_allowing_method("PUT").any?,
            allows_delete: attrs.rules_allowing_method("DELETE").any?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)