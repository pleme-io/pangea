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
    module GreenDataLifecycle
      # S3 inventory configuration for Green Data Lifecycle component
      module Inventory
        private

        def create_inventory_configuration(input, bucket)
          aws_s3_bucket_inventory(:"#{input.name}-inventory", {
            bucket: bucket.id,
            name: "#{input.name}-inventory",
            included_object_versions: "All",
            optional_fields: inventory_optional_fields,
            schedule: { frequency: "Daily" },
            destination: inventory_destination(bucket)
          })
        end

        def inventory_optional_fields
          [
            "Size",
            "LastModifiedDate",
            "StorageClass",
            "IntelligentTieringAccessTier",
            "ObjectAccessControlList",
            "ObjectOwner"
          ]
        end

        def inventory_destination(bucket)
          {
            bucket: {
              format: "Parquet",
              bucket_arn: bucket.arn,
              prefix: "inventory/"
            }
          }
        end
      end
    end
  end
end
