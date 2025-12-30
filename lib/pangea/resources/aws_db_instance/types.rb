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
require_relative 'types/core_attributes'
require_relative 'types/storage_attributes'
require_relative 'types/network_attributes'
require_relative 'types/backup_attributes'
require_relative 'types/monitoring_attributes'
require_relative 'types/options_attributes'
require_relative 'types/validations'
require_relative 'types/helpers'
require_relative 'types/engine_configs'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS RDS Database Instance resources
        # Composed from modular attribute structs for maintainability
        class DbInstanceAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Compose attributes from modular structs
          attributes_from CoreAttributes
          attributes_from StorageAttributes
          attributes_from NetworkAttributes
          attributes_from BackupAttributes
          attributes_from MonitoringAttributes
          attributes_from OptionsAttributes

          # Include helper methods
          include DbInstanceHelpers

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            # Run all validations
            DbInstanceValidations.validate!(attrs)
            validate_non_aurora!(attrs)

            attrs
          end

          # Non-Aurora engines require allocated_storage (kept here for self.new context)
          def self.validate_non_aurora!(attrs)
            return if attrs.engine.start_with?("aurora")

            if attrs.allocated_storage.nil?
              raise Dry::Struct::Error, "Non-Aurora engines require 'allocated_storage' to be specified"
            end
          end
        end
      end
    end
  end
end
