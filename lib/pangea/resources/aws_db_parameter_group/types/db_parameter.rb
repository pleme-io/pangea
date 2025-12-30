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

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Individual parameter definition for DB parameter groups
        class DbParameter < Dry::Struct
          # Parameter name
          attribute :name, Resources::Types::String

          # Parameter value
          attribute :value, Resources::Types::String

          # Apply method for parameter application
          attribute :apply_method, Resources::Types::String.enum("immediate", "pending-reboot").optional

          def self.new(attributes = {})
            attrs = super(attributes)

            # Validate parameter name format
            unless attrs.name.match?(/^[a-zA-Z][a-zA-Z0-9_.-]*$/)
              raise Dry::Struct::Error, "Invalid parameter name format: #{attrs.name}"
            end

            attrs
          end

          # Check if parameter requires reboot
          def requires_reboot?
            apply_method == "pending-reboot"
          end

          # Check if parameter applies immediately
          def applies_immediately?
            apply_method == "immediate" || apply_method.nil?
          end
        end
      end
    end
  end
end
