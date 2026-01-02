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
  module Resources
    module AWS
      module Types
        # Custom validation module for AWS RDS Database Instance attributes
        module DbInstanceValidations
          # Validates the attributes and raises errors for invalid configurations
          def self.validate!(attrs)
            validate_identifier!(attrs)
            validate_iops!(attrs)
            validate_password!(attrs)
            validate_aurora!(attrs)
            validate_sqlserver!(attrs)
          end

          private

          # Cannot specify both identifier and identifier_prefix
          def self.validate_identifier!(attrs)
            if attrs.identifier && attrs.identifier_prefix
              raise Dry::Struct::Error, "Cannot specify both 'identifier' and 'identifier_prefix'"
            end
          end

          # IOPS only valid for io1/io2 storage types
          def self.validate_iops!(attrs)
            if attrs.iops && !%w[io1 io2].include?(attrs.storage_type)
              raise Dry::Struct::Error, "IOPS can only be specified for io1 or io2 storage types"
            end
          end

          # Password security validation
          def self.validate_password!(attrs)
            if attrs.password && attrs.manage_master_user_password
              raise Dry::Struct::Error, "Cannot specify both 'password' and 'manage_master_user_password'"
            end
          end

          # Aurora engine validations
          def self.validate_aurora!(attrs)
            return unless attrs.engine.start_with?("aurora")

            if attrs.allocated_storage
              raise Dry::Struct::Error, "Aurora engines do not support 'allocated_storage' - use cluster configuration instead"
            end
            if attrs.multi_az
              raise Dry::Struct::Error, "Aurora engines handle multi-AZ at the cluster level, not instance level"
            end
          end

          # Non-Aurora engines require allocated_storage
          def self.validate_non_aurora!(attrs)
            return if attrs.engine.start_with?("aurora")

            if attrs.allocated_storage.nil?
              raise Dry::Struct::Error, "Non-Aurora engines require 'allocated_storage' to be specified"
            end
          end

          # SQL Server doesn't support db_name
          def self.validate_sqlserver!(attrs)
            if attrs.engine.start_with?("sqlserver") && attrs.db_name
              raise Dry::Struct::Error, "SQL Server engines do not support 'db_name' parameter"
            end
          end
        end
      end
    end
  end
end
