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
        # Self-service permissions configuration
        class SelfServicePermissionsType < Dry::Struct
          transform_keys(&:to_sym)

          EnabledDisabled = Resources::Types::String.enum('ENABLED', 'DISABLED')

          attribute :restart_workspace, EnabledDisabled.default('ENABLED')
          attribute :increase_volume_size, EnabledDisabled.default('DISABLED')
          attribute :change_compute_type, EnabledDisabled.default('DISABLED')
          attribute :switch_running_mode, EnabledDisabled.default('DISABLED')
          attribute :rebuild_workspace, EnabledDisabled.default('DISABLED')

          def all_enabled?
            restart_workspace == 'ENABLED' &&
              increase_volume_size == 'ENABLED' &&
              change_compute_type == 'ENABLED' &&
              switch_running_mode == 'ENABLED' &&
              rebuild_workspace == 'ENABLED'
          end

          def all_disabled?
            restart_workspace == 'DISABLED' &&
              increase_volume_size == 'DISABLED' &&
              change_compute_type == 'DISABLED' &&
              switch_running_mode == 'DISABLED' &&
              rebuild_workspace == 'DISABLED'
          end
        end
      end
    end
  end
end
