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


require 'dry-struct'

module Pangea
  module Resources
    module AWS
      module S3BucketAnalyticsConfiguration
        # Common types for S3 Bucket Analytics Configuration
        class Types < Dry::Types::Module
          include Dry.Types()

          # Analytics Configuration Name constraint
          ConfigurationName = String.constrained(
            min_size: 1,
            max_size: 64,
            format: /\A[a-zA-Z0-9\-_.]+\z/
          )
          
          # S3 Bucket Name constraint
          BucketName = String.constrained(
            min_size: 3,
            max_size: 63,
            format: /\A[a-z0-9\-\.]+\z/
          )
          
          # Storage Class Analysis configuration
          StorageClassAnalysis = Hash.schema({
            data_export: Hash.schema({
              output_schema_version: String.enum('V_1'),
              destination: Hash.schema({
                s3_bucket_destination: Hash.schema({
                  bucket_arn: String.constrained(format: /\Aarn:aws:s3:::[a-zA-Z0-9.\-_]+\z/),
                  bucket_account_id?: String.constrained(format: /\A\d{12}\z/).optional,
                  format: String.enum('CSV'),
                  prefix?: String.optional
                })
              })
            })
          })
          
          # Filter for analytics configuration
          AnalyticsFilter = Hash.schema({
            prefix?: String.optional,
            tags?: Hash.map(String, String).optional
          })
        end

        # S3 Bucket Analytics Configuration attributes
        class S3BucketAnalyticsConfigurationAttributes < Dry::Struct
          include Types[self]
          
          # Required attributes
          attribute :bucket, BucketName
          attribute :name, ConfigurationName
          
          # Optional attributes
          attribute? :filter, AnalyticsFilter.optional
          attribute? :storage_class_analysis, StorageClassAnalysis.optional
          
          # Computed properties
          def has_filter?
            !filter.nil?
          end
          
          def has_storage_class_analysis?
            !storage_class_analysis.nil?
          end
          
          def exports_data?
            has_storage_class_analysis?
          end
          
          def filter_by_prefix?
            has_filter? && filter[:prefix]
          end
          
          def filter_by_tags?
            has_filter? && filter[:tags]
          end
          
          def export_bucket_arn
            return nil unless exports_data?
            storage_class_analysis[:data_export][:destination][:s3_bucket_destination][:bucket_arn]
          end
          
          def export_bucket_name
            return nil unless export_bucket_arn
            export_bucket_arn.split(':')[-1]
          end
          
          def cross_account_export?
            return false unless exports_data?
            destination = storage_class_analysis[:data_export][:destination][:s3_bucket_destination]
            destination[:bucket_account_id] != nil
          end
        end
      end
    end
  end
end