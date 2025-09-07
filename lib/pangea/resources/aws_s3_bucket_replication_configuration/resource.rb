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
require 'pangea/resources/aws_s3_bucket_replication_configuration/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Bucket Replication Configuration with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] S3 bucket replication configuration attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_bucket_replication_configuration(name, attributes = {})
        # Validate attributes using dry-struct
        replication_attrs = Types::S3BucketReplicationConfigurationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_bucket_replication_configuration, name) do
          # Set the bucket
          bucket replication_attrs.bucket
          
          # Set the IAM role
          role replication_attrs.role
          
          # Configure replication rules
          replication_attrs.rule.each_with_index do |rule_config, index|
            rule do
              # Set rule ID
              id rule_config[:id] || "rule-#{index}"
              
              # Set priority if specified (required for multiple rules)
              priority rule_config[:priority] if rule_config[:priority]
              
              # Set rule status
              status rule_config[:status]
              
              # Configure filter if specified
              if rule_config[:filter]
                filter do
                  if rule_config[:filter][:and]
                    # Complex filter with multiple conditions
                    and do
                      prefix rule_config[:filter][:and][:prefix] if rule_config[:filter][:and][:prefix]
                      
                      if rule_config[:filter][:and][:tags]
                        rule_config[:filter][:and][:tags].each do |tag_key, tag_value|
                          tag do
                            key tag_key
                            value tag_value
                          end
                        end
                      end
                    end
                  else
                    # Simple filter conditions
                    prefix rule_config[:filter][:prefix] if rule_config[:filter][:prefix]
                    
                    if rule_config[:filter][:tag]
                      tag do
                        key rule_config[:filter][:tag][:key]
                        value rule_config[:filter][:tag][:value]
                      end
                    end
                  end
                end
              end
              
              # Configure destination
              destination do
                bucket rule_config[:destination][:bucket]
                storage_class rule_config[:destination][:storage_class] if rule_config[:destination][:storage_class]
                account_id rule_config[:destination][:account_id] if rule_config[:destination][:account_id]
                
                # Access control translation for cross-account replication
                if rule_config[:destination][:access_control_translation]
                  access_control_translation do
                    owner rule_config[:destination][:access_control_translation][:owner]
                  end
                end
                
                # Encryption configuration
                if rule_config[:destination][:encryption_configuration]
                  encryption_configuration do
                    replica_kms_key_id rule_config[:destination][:encryption_configuration][:replica_kms_key_id]
                  end
                end
                
                # Metrics configuration
                if rule_config[:destination][:metrics]
                  metrics do
                    status rule_config[:destination][:metrics][:status]
                    
                    if rule_config[:destination][:metrics][:event_threshold]
                      event_threshold do
                        minutes rule_config[:destination][:metrics][:event_threshold][:minutes]
                      end
                    end
                  end
                end
                
                # Replication time control
                if rule_config[:destination][:replication_time]
                  replication_time do
                    status rule_config[:destination][:replication_time][:status]
                    
                    if rule_config[:destination][:replication_time][:time]
                      time do
                        minutes rule_config[:destination][:replication_time][:time][:minutes]
                      end
                    end
                  end
                end
              end
              
              # Delete marker replication
              if rule_config[:delete_marker_replication]
                delete_marker_replication do
                  status rule_config[:delete_marker_replication][:status]
                end
              end
              
              # Existing object replication
              if rule_config[:existing_object_replication]
                existing_object_replication do
                  status rule_config[:existing_object_replication][:status]
                end
              end
              
              # Source selection criteria
              if rule_config[:source_selection_criteria]
                source_selection_criteria do
                  if rule_config[:source_selection_criteria][:replica_modifications]
                    replica_modifications do
                      status rule_config[:source_selection_criteria][:replica_modifications][:status]
                    end
                  end
                  
                  if rule_config[:source_selection_criteria][:sse_kms_encrypted_objects]
                    sse_kms_encrypted_objects do
                      status rule_config[:source_selection_criteria][:sse_kms_encrypted_objects][:status]
                    end
                  end
                end
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_s3_bucket_replication_configuration',
          name: name,
          resource_attributes: replication_attrs.to_h,
          outputs: {
            id: "${aws_s3_bucket_replication_configuration.#{name}.id}",
            bucket: "${aws_s3_bucket_replication_configuration.#{name}.bucket}",
            role: "${aws_s3_bucket_replication_configuration.#{name}.role}"
          },
          computed: {
            total_rules_count: replication_attrs.total_rules_count,
            enabled_rules_count: replication_attrs.enabled_rules_count,
            disabled_rules_count: replication_attrs.disabled_rules_count,
            cross_region_rules_count: replication_attrs.cross_region_rules_count,
            cross_account_rules_count: replication_attrs.cross_account_rules_count,
            has_delete_marker_replication: replication_attrs.has_delete_marker_replication?,
            has_existing_object_replication: replication_attrs.has_existing_object_replication?,
            has_rtc_enabled: replication_attrs.has_rtc_enabled?,
            has_metrics_enabled: replication_attrs.has_metrics_enabled?,
            has_encryption_in_transit: replication_attrs.has_encryption_in_transit?,
            has_kms_replication: replication_attrs.has_kms_replication?,
            replicates_to_storage_classes: replication_attrs.replicates_to_storage_classes,
            has_filtered_replication: replication_attrs.has_filtered_replication?,
            max_rtc_minutes: replication_attrs.max_rtc_minutes,
            estimated_replication_cost_category: replication_attrs.estimated_replication_cost_category
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)