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
        # Backup configuration attributes for AWS RDS Database Instance
        class BackupAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Backup retention period in days
          attribute :backup_retention_period, Resources::Types::Integer.default(7).constrained(gteq: 0, lteq: 35)

          # Backup window (Format: "hh24:mi-hh24:mi")
          attribute :backup_window, Resources::Types::String.optional

          # Maintenance window (Format: "ddd:hh24:mi-ddd:hh24:mi")
          attribute :maintenance_window, Resources::Types::String.optional
        end
      end
    end
  end
end
