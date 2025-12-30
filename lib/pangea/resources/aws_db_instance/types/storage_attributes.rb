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
        # Storage-related attributes for AWS RDS Database Instance
        class StorageAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Allocated storage in GB (not used for Aurora)
          attribute :allocated_storage, Resources::Types::Integer.optional.constrained(gteq: 20, lteq: 65536)

          # Storage type
          attribute :storage_type, Resources::Types::String.default("gp3").enum("standard", "gp2", "gp3", "io1", "io2")

          # Storage encryption
          attribute :storage_encrypted, Resources::Types::Bool.default(true)

          # KMS key for encryption
          attribute :kms_key_id, Resources::Types::String.optional

          # IOPS (only for io1/io2 storage types)
          attribute :iops, Resources::Types::Integer.optional.constrained(gteq: 1000, lteq: 256000)
        end
      end
    end
  end
end
