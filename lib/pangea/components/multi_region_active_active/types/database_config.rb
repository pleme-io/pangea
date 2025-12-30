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
      # Global database configuration
      class GlobalDatabaseConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :engine, Types::String.enum('aurora-mysql', 'aurora-postgresql', 'dynamodb').default('aurora-postgresql')
        attribute :engine_version, Types::String.optional
        attribute :instance_class, Types::String.default('db.r5.large')
        attribute :backup_retention_days, Types::Integer.default(7)
        attribute :enable_global_write_forwarding, Types::Bool.default(true)
        attribute :storage_encrypted, Types::Bool.default(true)
        attribute :kms_key_ref, Types::ResourceReference.optional
      end
    end
  end
end
