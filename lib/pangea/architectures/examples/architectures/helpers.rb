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
    module Examples
      # Helper methods for architecture examples
      module Helpers
        # Helper method for creating architecture-specific resource names
        def composite_resource_name(platform_name, architecture_type, resource_name)
          :"#{platform_name}_#{architecture_type}_#{resource_name}"
        end

        # Helper method for cross-architecture resource sharing
        def share_resources_between_architectures(source_arch, target_arch, shared_resources = [])
          shared_resources.each do |resource_type|
            case resource_type
            when :vpc
              target_arch.network = source_arch.network if source_arch.network
            when :database
              target_arch.database = source_arch.database if source_arch.database
            when :security_groups
              if source_arch.security && target_arch.security
                target_arch.security = target_arch.security.merge(source_arch.security)
              end
            when :monitoring
              target_arch.monitoring = source_arch.monitoring if source_arch.monitoring
            end
          end
        end
      end
    end
  end
end
