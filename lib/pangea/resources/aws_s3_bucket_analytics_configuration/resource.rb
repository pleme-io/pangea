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
require 'pangea/resources/aws_s3_bucket_analytics_configuration/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Bucket Analytics Configuration with type-safe attributes
      #
      # S3 Analytics configurations provide storage class analysis and data export
      # capabilities to help you understand storage access patterns and optimize
      # costs by transitioning objects to appropriate storage classes.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] S3 bucket analytics configuration attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_bucket_analytics_configuration(name, attributes = {})
        # Validate attributes using dry-struct
        analytics_attrs = S3BucketAnalyticsConfiguration::Types::S3BucketAnalyticsConfigurationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_bucket_analytics_configuration, name) do
          # Required attributes
          bucket analytics_attrs.bucket
          name analytics_attrs.name
          
          # Optional filter configuration
          if analytics_attrs.filter
            filter do
              prefix analytics_attrs.filter[:prefix] if analytics_attrs.filter[:prefix]
              
              if analytics_attrs.filter[:tags]
                analytics_attrs.filter[:tags].each do |key, value|
                  tag do
                    key key
                    value value
                  end
                end
              end
            end
          end
          
          # Optional storage class analysis configuration
          if analytics_attrs.storage_class_analysis
            storage_class_analysis do
              data_export do
                output_schema_version analytics_attrs.storage_class_analysis[:data_export][:output_schema_version]
                
                destination do
                  s3_bucket_destination do
                    bucket_destination = analytics_attrs.storage_class_analysis[:data_export][:destination][:s3_bucket_destination]
                    
                    bucket_arn bucket_destination[:bucket_arn]
                    bucket_account_id bucket_destination[:bucket_account_id] if bucket_destination[:bucket_account_id]
                    format bucket_destination[:format]
                    prefix bucket_destination[:prefix] if bucket_destination[:prefix]
                  end
                end
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_s3_bucket_analytics_configuration',
          name: name,
          resource_attributes: analytics_attrs.to_h,
          outputs: {
            id: "${aws_s3_bucket_analytics_configuration.#{name}.id}",
            bucket: "${aws_s3_bucket_analytics_configuration.#{name}.bucket}",
            name: "${aws_s3_bucket_analytics_configuration.#{name}.name}"
          },
          computed: {
            has_filter: analytics_attrs.has_filter?,
            has_storage_class_analysis: analytics_attrs.has_storage_class_analysis?,
            exports_data: analytics_attrs.exports_data?,
            filter_by_prefix: analytics_attrs.filter_by_prefix?,
            filter_by_tags: analytics_attrs.filter_by_tags?,
            export_bucket_arn: analytics_attrs.export_bucket_arn,
            export_bucket_name: analytics_attrs.export_bucket_name,
            cross_account_export: analytics_attrs.cross_account_export?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)