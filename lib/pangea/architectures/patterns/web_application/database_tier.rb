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
  module Architectures
    module Patterns
      module WebApplication
        # Database tier creation for web application
        module DatabaseTier
          private

          def create_database_tier(name, arch_ref, arch_attrs, base_tags)
            database_resources = {}

            database_resources[:subnet_group] = create_db_subnet_group(name, arch_ref, base_tags)
            database_resources[:instance] = create_db_instance(name, arch_ref, arch_attrs,
                                                               database_resources[:subnet_group], base_tags)

            database_resources
          end

          def create_db_subnet_group(name, arch_ref, base_tags)
            aws_db_subnet_group(
              architecture_resource_name(name, :db_subnet_group),
              name: "#{name}-db-subnet-group",
              subnet_ids: arch_ref.network.private_subnet_ids,
              tags: base_tags.merge(Tier: 'database', Component: 'subnet-group')
            )
          end

          def create_db_instance(name, arch_ref, arch_attrs, subnet_group, base_tags)
            aws_db_instance(
              architecture_resource_name(name, :database),
              identifier: "#{name}-#{arch_attrs.environment}-db",
              engine: arch_attrs.database_engine,
              engine_version: arch_attrs.database_engine == 'postgres' ? '14.9' : '8.0.35',
              instance_class: arch_attrs.database_instance_class,
              allocated_storage: arch_attrs.database_allocated_storage,
              storage_type: 'gp2',
              storage_encrypted: arch_attrs.environment == 'production',

              db_name: name.to_s.gsub(/[^a-zA-Z0-9]/, ''),
              username: 'admin',
              manage_master_user_password: true,

              vpc_security_group_ids: [arch_ref.security[:db_sg].id],
              db_subnet_group_name: subnet_group.id,

              backup_retention_period: arch_attrs.database_backup_retention,
              backup_window: '03:00-04:00',
              maintenance_window: 'sun:04:00-sun:05:00',

              deletion_protection: arch_attrs.environment == 'production',
              skip_final_snapshot: arch_attrs.environment != 'production',

              tags: base_tags.merge(Tier: 'database', Component: 'primary')
            )
          end
        end
      end
    end
  end
end
