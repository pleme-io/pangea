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
require 'pangea/resources/aws_s3_bucket_website_configuration/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Bucket Website Configuration with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_bucket_website_configuration(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::S3BucketWebsiteConfigurationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_bucket_website_configuration, name) do
          # Bucket is required
          bucket attrs.bucket
          
          # Expected bucket owner
          expected_bucket_owner attrs.expected_bucket_owner if attrs.expected_bucket_owner
          
          # Error document configuration
          if attrs.error_document
            error_document do
              key attrs.error_document.key
            end
          end
          
          # Index document configuration
          if attrs.index_document
            index_document do
              suffix attrs.index_document.suffix
            end
          end
          
          # Redirect all requests configuration
          if attrs.redirect_all_requests_to
            redirect_all_requests_to do
              host_name attrs.redirect_all_requests_to.host_name
              protocol attrs.redirect_all_requests_to.protocol if attrs.redirect_all_requests_to.protocol
            end
          end
          
          # Routing rules
          if attrs.routing_rule
            attrs.routing_rule.each do |routing_rule|
              routing_rule do
                # Condition (optional)
                if routing_rule.condition
                  condition do
                    http_error_code_returned_equals routing_rule.condition.http_error_code_returned_equals if routing_rule.condition.http_error_code_returned_equals
                    key_prefix_equals routing_rule.condition.key_prefix_equals if routing_rule.condition.key_prefix_equals
                  end
                end
                
                # Redirect (required)
                redirect do
                  host_name routing_rule.redirect.host_name if routing_rule.redirect.host_name
                  http_redirect_code routing_rule.redirect.http_redirect_code if routing_rule.redirect.http_redirect_code
                  protocol routing_rule.redirect.protocol if routing_rule.redirect.protocol
                  replace_key_prefix_with routing_rule.redirect.replace_key_prefix_with if routing_rule.redirect.replace_key_prefix_with
                  replace_key_with routing_rule.redirect.replace_key_with if routing_rule.redirect.replace_key_with
                end
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_s3_bucket_website_configuration',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_s3_bucket_website_configuration.#{name}.id}",
            bucket: "${aws_s3_bucket_website_configuration.#{name}.bucket}",
            expected_bucket_owner: "${aws_s3_bucket_website_configuration.#{name}.expected_bucket_owner}",
            website_domain: "${aws_s3_bucket_website_configuration.#{name}.website_domain}",
            website_endpoint: "${aws_s3_bucket_website_configuration.#{name}.website_endpoint}"
          },
          computed_properties: {
            hosting_mode: attrs.website_hosting_mode? ? "website_hosting" : "redirect_all",
            has_error_document: attrs.has_error_document?,
            has_routing_rules: attrs.has_routing_rules?,
            routing_rules_count: attrs.routing_rules_count,
            unconditional_rules_count: attrs.unconditional_routing_rules.length,
            error_code_rules_count: attrs.error_code_routing_rules.length,
            prefix_rules_count: attrs.prefix_routing_rules.length,
            permanent_redirect_rules_count: attrs.permanent_redirect_rules.length,
            temporary_redirect_rules_count: attrs.temporary_redirect_rules.length,
            index_document_suffix: attrs.index_document&.suffix,
            error_document_key: attrs.error_document&.key,
            redirect_target_host: attrs.redirect_all_requests_to&.host_name,
            redirect_target_protocol: attrs.redirect_all_requests_to&.protocol
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)