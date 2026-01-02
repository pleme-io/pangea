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

module Pangea
  module Components
    module SustainableMLTraining
      # Storage resources: S3 buckets, FSx filesystem
      module Storage
        def create_s3_bucket(input)
          aws_s3_bucket(:"#{input.name}-training-data", {
            bucket: input.s3_bucket_name,
            versioning: {
              status: "Enabled"
            },
            lifecycle_rule: [{
              id: "expire-old-checkpoints",
              status: "Enabled",
              prefix: "checkpoints/",
              expiration: {
                days: 30
              }
            }],
            server_side_encryption_configuration: {
              rule: [{
                apply_server_side_encryption_by_default: {
                  sse_algorithm: "AES256"
                }
              }]
            },
            tags: input.tags.merge(
              "Component" => "sustainable-ml-training",
              "Purpose" => "training-data"
            )
          })
        end

        def create_fsx_filesystem(input, s3_bucket)
          aws_fsx_lustre_file_system(:"#{input.name}-fsx", {
            storage_capacity: calculate_fsx_capacity(input.dataset_size_gb),
            subnet_ids: ["subnet-12345"], # Would be provided via input
            deployment_type: "SCRATCH_2",
            data_compression_type: "LZ4",
            import_path: "s3://#{s3_bucket.bucket}/data",
            export_path: "s3://#{s3_bucket.bucket}/output",
            auto_import_policy: "NEW_CHANGED",
            tags: input.tags.merge(
              "Component" => "sustainable-ml-training",
              "Purpose" => "high-performance-storage"
            )
          })
        end

        def create_model_cache_bucket(input)
          aws_s3_bucket(:"#{input.name}-model-cache", {
            bucket: "#{input.s3_bucket_name}-model-cache",
            lifecycle_rule: [{
              id: "intelligent-tiering",
              status: "Enabled",
              transition: [{
                days: 0,
                storage_class: "INTELLIGENT_TIERING"
              }]
            }],
            tags: input.tags.merge(
              "Component" => "sustainable-ml-training",
              "Purpose" => "model-cache"
            )
          })
        end
      end
    end
  end
end
