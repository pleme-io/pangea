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
  module Components
    module MultiRegionActiveActive
      # Aurora global cluster and regional cluster resources
      module Aurora
        def create_aurora_global_cluster(name, attrs, tags)
          aws_rds_global_cluster(
            component_resource_name(name, :aurora_global),
            {
              global_cluster_identifier: "#{name}-global-cluster",
              engine: attrs.global_database.engine,
              engine_version: attrs.global_database.engine_version,
              database_name: "#{name.to_s.gsub(/[^a-zA-Z0-9]/, '')}db",
              storage_encrypted: attrs.global_database.storage_encrypted,
              deletion_protection: true
            }
          )
        end

        def create_regional_aurora_cluster(name, region_config, attrs, global_cluster, subnets, tags)
          db_subnet_group = create_db_subnet_group(name, region_config, subnets, tags)
          cluster = create_aurora_cluster(name, region_config, attrs, global_cluster, db_subnet_group, tags)
          instances = create_aurora_instances(name, region_config, attrs, cluster, tags)

          {
            subnet_group: db_subnet_group,
            cluster: cluster,
            instances: instances
          }
        end

        private

        def create_db_subnet_group(name, region_config, subnets, tags)
          private_subnet_ids = subnets.select { |k, _| k.to_s.start_with?('private_') }.values.map(&:id)

          aws_db_subnet_group(
            component_resource_name(name, :db_subnet_group, region_config.region.to_sym),
            {
              name: "#{name}-#{region_config.region}-subnet-group",
              description: "Subnet group for Aurora cluster in #{region_config.region}",
              subnet_ids: private_subnet_ids,
              tags: tags.merge(Region: region_config.region)
            }
          )
        end

        def create_aurora_cluster(name, region_config, attrs, global_cluster, db_subnet_group, tags)
          cluster_config = build_aurora_cluster_config(name, region_config, attrs, global_cluster, db_subnet_group, tags)

          aws_rds_cluster(
            component_resource_name(name, :aurora_cluster, region_config.region.to_sym),
            cluster_config.compact
          )
        end

        def build_aurora_cluster_config(name, region_config, attrs, global_cluster, db_subnet_group, tags)
          {
            cluster_identifier: "#{name}-#{region_config.region}-cluster",
            engine: attrs.global_database.engine,
            engine_version: attrs.global_database.engine_version,
            global_cluster_identifier: global_cluster.id,
            database_name: region_config.is_primary ? "#{name.to_s.gsub(/[^a-zA-Z0-9]/, '')}db" : nil,
            db_subnet_group_name: db_subnet_group.name,
            backup_retention_period: attrs.global_database.backup_retention_days,
            preferred_backup_window: '03:00-04:00',
            preferred_maintenance_window: 'sun:04:00-sun:05:00',
            storage_encrypted: attrs.global_database.storage_encrypted,
            kms_key_id: attrs.global_database.kms_key_ref&.arn,
            enabled_cloudwatch_logs_exports: ['postgresql'] || ['mysql'],
            tags: tags.merge(Region: region_config.region, IsPrimary: region_config.is_primary.to_s)
          }
        end

        def create_aurora_instances(name, region_config, attrs, cluster, tags)
          instance_count = region_config.is_primary ? 2 : 1
          instances = {}

          (1..instance_count).each do |i|
            instance_ref = aws_rds_cluster_instance(
              component_resource_name(name, :aurora_instance, "#{region_config.region}_#{i}".to_sym),
              build_aurora_instance_config(name, region_config, attrs, cluster, i, tags)
            )
            instances["instance_#{i}".to_sym] = instance_ref
          end

          instances
        end

        def build_aurora_instance_config(name, region_config, attrs, cluster, index, tags)
          {
            identifier: "#{name}-#{region_config.region}-instance-#{index}",
            cluster_identifier: cluster.id,
            instance_class: attrs.global_database.instance_class,
            engine: attrs.global_database.engine,
            engine_version: attrs.global_database.engine_version,
            performance_insights_enabled: true,
            monitoring_interval: 60,
            promotion_tier: index,
            tags: tags.merge(Region: region_config.region)
          }
        end
      end
    end
  end
end
