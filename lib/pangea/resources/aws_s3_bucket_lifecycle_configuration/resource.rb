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
require 'pangea/resources/aws_s3_bucket_lifecycle_configuration/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Bucket Lifecycle Configuration with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_bucket_lifecycle_configuration(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::S3BucketLifecycleConfigurationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_bucket_lifecycle_configuration, name) do
          # Bucket is required
          bucket attrs.bucket
          
          # Expected bucket owner
          expected_bucket_owner attrs.expected_bucket_owner if attrs.expected_bucket_owner
          
          # Lifecycle rules
          attrs.rule.each_with_index do |lifecycle_rule, index|
            rule do
              id lifecycle_rule.id
              status lifecycle_rule.status
              
              # Filter configuration
              if lifecycle_rule.filter
                filter do
                  if lifecycle_rule.filter.and_condition
                    and_condition do
                      object_size_greater_than lifecycle_rule.filter.and_condition.object_size_greater_than if lifecycle_rule.filter.and_condition.object_size_greater_than
                      object_size_less_than lifecycle_rule.filter.and_condition.object_size_less_than if lifecycle_rule.filter.and_condition.object_size_less_than
                      prefix lifecycle_rule.filter.and_condition.prefix if lifecycle_rule.filter.and_condition.prefix
                      
                      if lifecycle_rule.filter.and_condition.tags
                        lifecycle_rule.filter.and_condition.tags.each do |filter_tag|
                          tag do
                            key filter_tag.key
                            value filter_tag.value
                          end
                        end
                      end
                    end
                  else
                    object_size_greater_than lifecycle_rule.filter.object_size_greater_than if lifecycle_rule.filter.object_size_greater_than
                    object_size_less_than lifecycle_rule.filter.object_size_less_than if lifecycle_rule.filter.object_size_less_than
                    prefix lifecycle_rule.filter.prefix if lifecycle_rule.filter.prefix
                    
                    if lifecycle_rule.filter.tag
                      tag do
                        key lifecycle_rule.filter.tag.key
                        value lifecycle_rule.filter.tag.value
                      end
                    end
                  end
                end
              elsif lifecycle_rule.prefix
                # Legacy prefix support
                prefix lifecycle_rule.prefix
              end
              
              # Abort incomplete multipart uploads
              if lifecycle_rule.abort_incomplete_multipart_upload
                abort_incomplete_multipart_upload do
                  days_after_initiation lifecycle_rule.abort_incomplete_multipart_upload.days_after_initiation
                end
              end
              
              # Expiration configuration
              if lifecycle_rule.expiration
                expiration do
                  date lifecycle_rule.expiration.date if lifecycle_rule.expiration.date
                  days lifecycle_rule.expiration.days if lifecycle_rule.expiration.days
                  expired_object_delete_marker lifecycle_rule.expiration.expired_object_delete_marker if lifecycle_rule.expiration.expired_object_delete_marker
                end
              end
              
              # Noncurrent version expiration
              if lifecycle_rule.noncurrent_version_expiration
                noncurrent_version_expiration do
                  noncurrent_days lifecycle_rule.noncurrent_version_expiration.noncurrent_days if lifecycle_rule.noncurrent_version_expiration.noncurrent_days
                  newer_noncurrent_versions lifecycle_rule.noncurrent_version_expiration.newer_noncurrent_versions if lifecycle_rule.noncurrent_version_expiration.newer_noncurrent_versions
                end
              end
              
              # Transitions
              if lifecycle_rule.transition
                lifecycle_rule.transition.each do |trans|
                  transition do
                    date trans.date if trans.date
                    days trans.days if trans.days
                    storage_class trans.storage_class
                  end
                end
              end
              
              # Noncurrent version transitions
              if lifecycle_rule.noncurrent_version_transition
                lifecycle_rule.noncurrent_version_transition.each do |nv_trans|
                  noncurrent_version_transition do
                    noncurrent_days nv_trans.noncurrent_days if nv_trans.noncurrent_days
                    newer_noncurrent_versions nv_trans.newer_noncurrent_versions if nv_trans.newer_noncurrent_versions
                    storage_class nv_trans.storage_class
                  end
                end
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_s3_bucket_lifecycle_configuration',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_s3_bucket_lifecycle_configuration.#{name}.id}",
            bucket: "${aws_s3_bucket_lifecycle_configuration.#{name}.bucket}",
            expected_bucket_owner: "${aws_s3_bucket_lifecycle_configuration.#{name}.expected_bucket_owner}",
            rule: "${aws_s3_bucket_lifecycle_configuration.#{name}.rule}"
          },
          computed_properties: {
            total_rules_count: attrs.total_rules_count,
            enabled_rules_count: attrs.enabled_rules.length,
            disabled_rules_count: attrs.disabled_rules.length,
            rules_with_expiration_count: attrs.rules_with_expiration.length,
            rules_with_transitions_count: attrs.rules_with_transitions.length
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)