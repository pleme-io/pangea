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
        # Workspace creation properties
        class WorkspaceCreationPropertiesType < Dry::Struct
          transform_keys(&:to_sym)

          attribute :custom_security_group_id, Resources::Types::String.optional
          attribute :default_ou, Resources::Types::String.optional
          attribute :enable_internet_access, Resources::Types::Bool.default(true)
          attribute :enable_maintenance_mode, Resources::Types::Bool.default(false)
          attribute :user_enabled_as_local_administrator, Resources::Types::Bool.default(false)

          # Validation for OU format
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            if attrs[:default_ou] && !attrs[:default_ou].match?(/\AOU=[^,]+/)
              raise Dry::Struct::Error, "default_ou must be in format 'OU=WorkSpaces,DC=example,DC=com'"
            end

            super(attrs)
          end

          # Security assessment
          def security_level
            score = 0
            score += 2 if custom_security_group_id  # Using custom security group
            score += 1 unless enable_internet_access  # Internet access disabled
            score += 2 unless user_enabled_as_local_administrator  # No local admin

            case score
            when 4..5 then :high
            when 2..3 then :medium
            else :low
            end
          end
        end
      end
    end
  end
end
