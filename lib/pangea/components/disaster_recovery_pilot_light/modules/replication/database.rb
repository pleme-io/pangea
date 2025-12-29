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
    module DisasterRecoveryPilotLight
      module Replication
        # Database replication resources
        module Database
          def create_database_replicas(name, attrs, dr_resources, tags)
            db_replicas = {}

            attrs.critical_data.databases.each_with_index do |db, index|
              next unless db[:engine].start_with?('aurora')

              db_replicas.merge!(
                create_aurora_replica(name, attrs, db, dr_resources, index, tags)
              )
            end

            db_replicas
          end

          def create_dms_instance(name, dr_resources, tags)
            aws_dms_replication_instance(
              component_resource_name(name, :dms_instance),
              {
                replication_instance_id: "#{name}-dms-instance",
                replication_instance_class: "dms.t3.small",
                vpc_security_group_ids: [],
                replication_subnet_group_id: dr_resources[:db_subnet_group].name,
                multi_az: false,
                tags: tags.merge(State: "PilotLight")
              }
            )
          end

          private

          def create_aurora_replica(name, attrs, db, dr_resources, index, tags)
            cluster_ref = create_replica_cluster(name, attrs, db, dr_resources, index, tags)
            instance_ref = create_replica_instance(name, attrs, db, cluster_ref, index, tags)

            {
              "cluster_#{index}".to_sym => cluster_ref,
              "instance_#{index}".to_sym => instance_ref
            }
          end

          def create_replica_cluster(name, attrs, db, dr_resources, index, tags)
            aws_rds_cluster(
              component_resource_name(name, :dr_db_cluster, "db#{index}".to_sym),
              {
                cluster_identifier: "#{name}-dr-cluster-#{index}",
                engine: db[:engine],
                engine_version: db[:engine_version],
                replication_source_identifier: build_cluster_arn(attrs, db),
                db_subnet_group_name: dr_resources[:db_subnet_group].name,
                backup_retention_period: attrs.critical_data.backup_retention_days,
                storage_encrypted: attrs.compliance.encryption_required,
                tags: tags.merge(
                  Region: attrs.dr_region.region,
                  State: "PilotLight",
                  Role: "ReadReplica"
                )
              }
            )
          end

          def create_replica_instance(name, attrs, db, cluster_ref, index, tags)
            aws_rds_cluster_instance(
              component_resource_name(name, :dr_db_instance, "db#{index}".to_sym),
              {
                identifier: "#{name}-dr-instance-#{index}",
                cluster_identifier: cluster_ref.id,
                instance_class: "db.t3.small",
                engine: db[:engine],
                performance_insights_enabled: attrs.monitoring.dr_region_monitoring,
                tags: tags.merge(State: "PilotLight")
              }
            )
          end

          def build_cluster_arn(attrs, db)
            "arn:aws:rds:#{attrs.primary_region.region}:ACCOUNT:cluster:#{db[:identifier]}"
          end
        end
      end
    end
  end
end
