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
      module DynamoDBTableExport
        # Common types for DynamoDB Table Export configurations
        class Types < Dry::Types::Module
          include Dry.Types()

          # DynamoDB Table ARN constraint
          TableArn = String.constrained(
            format: /\Aarn:aws:dynamodb:[a-z0-9\-]*:[0-9]{12}:table\/[a-zA-Z0-9_.-]+\z/
          )
          
          # S3 Bucket ARN constraint
          S3BucketArn = String.constrained(
            format: /\Aarn:aws:s3:::[a-zA-Z0-9.\-_]+\z/
          )
          
          # KMS Key ARN constraint
          KmsKeyArn = String.constrained(
            format: /\Aarn:aws:kms:[a-z0-9\-]*:[0-9]{12}:key\/[a-f0-9\-]+\z/
          )
          
          # Export format
          ExportFormat = String.enum('DYNAMODB_JSON', 'ION')
          
          # Export type
          ExportType = String.enum('FULL_EXPORT', 'INCREMENTAL_EXPORT')
        end

        # DynamoDB Table Export attributes with comprehensive validation
        class DynamoDBTableExportAttributes < Dry::Struct
          include Types[self]
          
          # Required attributes
          attribute :s3_bucket, S3BucketArn
          attribute :table_arn, TableArn
          
          # Optional attributes
          attribute? :export_format, ExportFormat.default('DYNAMODB_JSON')
          attribute? :export_type, ExportType.default('FULL_EXPORT')
          attribute? :export_time, Time.optional
          attribute? :s3_bucket_owner, String.constrained(format: /\A\d{12}\z/).optional
          attribute? :s3_prefix, String.optional
          attribute? :s3_sse_algorithm, String.enum('AES256', 'KMS').optional
          attribute? :s3_sse_kms_key_id, KmsKeyArn.optional
          
          # Computed properties
          def table_name
            table_arn.split('/')[-1]
          end
          
          def bucket_name
            s3_bucket.split(':')[-1]
          end
          
          def uses_kms_encryption?
            s3_sse_algorithm == 'KMS'
          end
          
          def uses_aes_encryption?
            s3_sse_algorithm == 'AES256'
          end
          
          def cross_account_bucket?
            !s3_bucket_owner.nil?
          end
          
          def incremental_export?
            export_type == 'INCREMENTAL_EXPORT'
          end
          
          def full_export?
            export_type == 'FULL_EXPORT'
          end
        end
      end
    end
  end
end