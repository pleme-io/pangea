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
        # Core identification and engine attributes for AWS RDS Database Instance
        class CoreAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Database identifier (optional, AWS will generate if not provided)
          attribute :identifier, Resources::Types::String.optional

          # Database identifier prefix (optional, alternative to identifier)
          attribute :identifier_prefix, Resources::Types::String.optional

          # Database engine
          attribute :engine, Resources::Types::String.enum(
            "mysql", "postgres", "mariadb", "oracle-se", "oracle-se1", "oracle-se2",
            "oracle-ee", "sqlserver-ee", "sqlserver-se", "sqlserver-ex", "sqlserver-web",
            "aurora", "aurora-mysql", "aurora-postgresql"
          )

          # Engine version (optional, uses default for engine if not specified)
          attribute :engine_version, Resources::Types::String.optional

          # Instance class (e.g., "db.t3.micro", "db.r5.large")
          attribute :instance_class, Resources::Types::String

          # Database name (optional, not applicable for SQL Server)
          attribute :db_name, Resources::Types::String.optional

          # Master username
          attribute :username, Resources::Types::String.optional

          # Master password (use manage_master_user_password instead for security)
          attribute :password, Resources::Types::String.optional

          # Let AWS manage the master password
          attribute :manage_master_user_password, Resources::Types::Bool.default(true)
        end
      end
    end
  end
end
