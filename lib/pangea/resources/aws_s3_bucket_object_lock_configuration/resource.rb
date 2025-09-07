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
require 'pangea/resources/aws_s3_bucket_object_lock_configuration/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Bucket Object Lock Configuration with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] S3 bucket object lock configuration attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_bucket_object_lock_configuration(name, attributes = {})
        # Validate attributes using dry-struct
        object_lock_attrs = Types::S3BucketObjectLockConfigurationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_bucket_object_lock_configuration, name) do
          # Set the bucket
          bucket object_lock_attrs.bucket
          
          # Set expected bucket owner if provided
          expected_bucket_owner object_lock_attrs.expected_bucket_owner if object_lock_attrs.expected_bucket_owner
          
          # Set object lock enabled status
          object_lock_enabled object_lock_attrs.object_lock_enabled
          
          # Set token if provided (for update operations)
          token object_lock_attrs.token if object_lock_attrs.token
          
          # Configure default retention rule
          if object_lock_attrs.rule[:default_retention]
            rule do
              default_retention do
                mode object_lock_attrs.rule[:default_retention][:mode]
                
                # Set either days or years (validation ensures only one is specified)
                if object_lock_attrs.rule[:default_retention][:days]
                  days object_lock_attrs.rule[:default_retention][:days]
                elsif object_lock_attrs.rule[:default_retention][:years]
                  years object_lock_attrs.rule[:default_retention][:years]
                end
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_s3_bucket_object_lock_configuration',
          name: name,
          resource_attributes: object_lock_attrs.to_h,
          outputs: {
            id: "${aws_s3_bucket_object_lock_configuration.#{name}.id}",
            bucket: "${aws_s3_bucket_object_lock_configuration.#{name}.bucket}",
            object_lock_enabled: "${aws_s3_bucket_object_lock_configuration.#{name}.object_lock_enabled}"
          },
          computed: {
            has_default_retention: object_lock_attrs.has_default_retention?,
            governance_mode: object_lock_attrs.governance_mode?,
            compliance_mode: object_lock_attrs.compliance_mode?,
            retention_period_in_days: object_lock_attrs.retention_period_in_days,
            retention_period_in_years: object_lock_attrs.retention_period_in_years,
            short_term_retention: object_lock_attrs.short_term_retention?,
            medium_term_retention: object_lock_attrs.medium_term_retention?,
            long_term_retention: object_lock_attrs.long_term_retention?,
            compliance_grade_retention: object_lock_attrs.compliance_grade_retention?,
            allows_privileged_deletion: object_lock_attrs.allows_privileged_deletion?,
            prevents_all_deletion: object_lock_attrs.prevents_all_deletion?,
            estimated_storage_cost_impact: object_lock_attrs.estimated_storage_cost_impact,
            retention_category: object_lock_attrs.retention_category,
            cross_account_scenario: object_lock_attrs.cross_account_scenario?,
            bucket_name_only: object_lock_attrs.bucket_name_only,
            estimated_compliance_level: object_lock_attrs.estimated_compliance_level
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)