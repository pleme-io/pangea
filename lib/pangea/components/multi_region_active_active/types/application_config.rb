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
require 'pangea/resources/types'

module Pangea
  module Components
    module MultiRegionActiveActive
      # Application configuration
      class ApplicationConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String
        attribute :port, Types::Integer.default(443)
        attribute :protocol, Types::String.enum('HTTP', 'HTTPS', 'TCP').default('HTTPS')
        attribute :health_check_path, Types::String.default('/health')
        attribute :container_image, Types::String.optional
        attribute :task_cpu, Types::Integer.default(256)
        attribute :task_memory, Types::Integer.default(512)
        attribute :desired_count, Types::Integer.default(3)
      end
    end
  end
end
