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
        # Workspace access properties
        class WorkspaceAccessPropertiesType < Dry::Struct
          transform_keys(&:to_sym)

          AllowDeny = Resources::Types::String.enum('ALLOW', 'DENY')

          attribute :device_type_windows, AllowDeny.default('ALLOW')
          attribute :device_type_osx, AllowDeny.default('ALLOW')
          attribute :device_type_web, AllowDeny.default('DENY')
          attribute :device_type_ios, AllowDeny.default('ALLOW')
          attribute :device_type_android, AllowDeny.default('ALLOW')
          attribute :device_type_chrome_os, AllowDeny.default('DENY')
          attribute :device_type_zero_client, AllowDeny.default('ALLOW')
          attribute :device_type_linux, AllowDeny.default('DENY')

          def allowed_device_types
            types = []
            types << 'Windows' if device_type_windows == 'ALLOW'
            types << 'macOS' if device_type_osx == 'ALLOW'
            types << 'Web' if device_type_web == 'ALLOW'
            types << 'iOS' if device_type_ios == 'ALLOW'
            types << 'Android' if device_type_android == 'ALLOW'
            types << 'ChromeOS' if device_type_chrome_os == 'ALLOW'
            types << 'ZeroClient' if device_type_zero_client == 'ALLOW'
            types << 'Linux' if device_type_linux == 'ALLOW'
            types
          end

          def mobile_access_allowed?
            device_type_ios == 'ALLOW' || device_type_android == 'ALLOW'
          end

          def web_access_allowed?
            device_type_web == 'ALLOW'
          end

          def desktop_access_allowed?
            device_type_windows == 'ALLOW' ||
              device_type_osx == 'ALLOW' ||
              device_type_linux == 'ALLOW'
          end
        end
      end
    end
  end
end
