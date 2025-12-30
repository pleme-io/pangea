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
  module Architectures
    module Patterns
      module WebApplication
        # Storage tier creation for web application
        module StorageTier
          private

          def create_storage_tier(name, _arch_ref, arch_attrs, base_tags)
            storage_resources = {}

            storage_resources[:assets_bucket] = create_assets_bucket(name, arch_attrs, base_tags)
            storage_resources[:logs_bucket] = create_logs_bucket(name, arch_attrs, base_tags)

            storage_resources
          end

          def create_assets_bucket(name, arch_attrs, base_tags)
            aws_s3_bucket(
              architecture_resource_name(name, :assets),
              bucket_name: "#{name.to_s.gsub('_', '-')}-#{arch_attrs.environment}-assets-#{Time.now.to_i}",
              versioning: arch_attrs.environment == 'production' ? 'Enabled' : 'Disabled',
              tags: base_tags.merge(Tier: 'storage', Component: 'assets')
            )
          end

          def create_logs_bucket(name, arch_attrs, base_tags)
            aws_s3_bucket(
              architecture_resource_name(name, :logs),
              bucket_name: "#{name.to_s.gsub('_', '-')}-#{arch_attrs.environment}-logs-#{Time.now.to_i}",
              lifecycle_rules: [
                { id: 'delete_old_logs', status: 'Enabled',
                  expiration: { days: arch_attrs.log_retention_days } }
              ],
              tags: base_tags.merge(Tier: 'storage', Component: 'logs')
            )
          end
        end
      end
    end
  end
end
