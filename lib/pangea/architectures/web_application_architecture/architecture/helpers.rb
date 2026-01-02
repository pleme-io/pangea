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
    module WebApplicationArchitecture
      class Architecture
        # Helper methods for architecture
        module Helpers
          def architecture_tags(attributes)
            { Architecture: 'WebApplication', Environment: attributes[:environment], ManagedBy: 'Pangea' }.merge(attributes[:tags] || {})
          end

          def has_high_availability?(components)
            network = components[:network]
            return false unless network

            network.respond_to?(:availability_zones) ? network.availability_zones.size >= 2 : true
          end

          def has_auto_scaling?(components)
            components[:web_servers] &&
              components[:web_servers][:auto_scaling_group_name] &&
              components[:web_servers][:max_size] > components[:web_servers][:min_size]
          end

          def has_backup_strategy?(components)
            database = components[:database]
            return false unless database

            database.respond_to?(:backup_retention_days) ? database.backup_retention_days.positive? : true
          end
        end
      end
    end
  end
end
