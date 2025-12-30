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
  module Resources
    module AWS
      module Types
        # Compute type configuration
        class ComputeTypeConfigurationType < Dry::Struct
          transform_keys(&:to_sym)

          attribute :name, Resources::Types::String.enum(
            'VALUE', 'STANDARD', 'PERFORMANCE', 'POWER', 'POWERPRO', 'GRAPHICS', 'GRAPHICSPRO'
          )

          def vcpus
            case name
            when 'VALUE' then 1
            when 'STANDARD' then 2
            when 'PERFORMANCE' then 2
            when 'POWER' then 4
            when 'POWERPRO' then 8
            when 'GRAPHICS' then 8
            when 'GRAPHICSPRO' then 16
            end
          end

          def memory_gb
            case name
            when 'VALUE' then 2
            when 'STANDARD' then 4
            when 'PERFORMANCE' then 8
            when 'POWER' then 16
            when 'POWERPRO' then 32
            when 'GRAPHICS' then 15
            when 'GRAPHICSPRO' then 60
            end
          end

          def gpu_enabled?
            %w[GRAPHICS GRAPHICSPRO].include?(name)
          end

          def gpu_memory_gb
            case name
            when 'GRAPHICS' then 1
            when 'GRAPHICSPRO' then 8
            else 0
            end
          end
        end
      end
    end
  end
end
