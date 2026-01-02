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
      # Backup and recovery infrastructure
      module Backup
        def create_backup_infrastructure(name, attrs, primary_resources, tags)
          backup_resources = {}

          backup_resources[:backup_vault] = create_backup_vault(name, attrs, tags)

          if attrs.critical_data.cross_region_backup
            backup_resources[:dr_vault] = create_dr_backup_vault(name, attrs, tags)
          end

          backup_resources[:backup_plan] = create_backup_plan(
            name, attrs, backup_resources, tags
          )

          backup_resources[:backup_selection] = create_backup_selection(
            name, backup_resources[:backup_plan]
          )

          backup_resources
        end

        private

        def create_backup_vault(name, attrs, tags)
          aws_backup_vault(
            component_resource_name(name, :backup_vault),
            {
              name: "#{name}-backup-vault",
              encryption_key_arn: attrs.compliance.encryption_required ? "alias/aws/backup" : nil,
              tags: tags.merge(Purpose: "DR-Backup")
            }.compact
          )
        end

        def create_dr_backup_vault(name, attrs, tags)
          aws_backup_vault(
            component_resource_name(name, :dr_backup_vault),
            {
              name: "#{name}-dr-backup-vault",
              encryption_key_arn: attrs.compliance.encryption_required ? "alias/aws/backup" : nil,
              tags: tags.merge(
                Purpose: "DR-Backup",
                Region: attrs.dr_region.region
              )
            }.compact
          )
        end

        def create_backup_plan(name, attrs, backup_resources, tags)
          aws_backup_plan(
            component_resource_name(name, :backup_plan),
            {
              name: "#{name}-dr-backup-plan",
              rule: [build_backup_rule(attrs, backup_resources)],
              tags: tags
            }
          )
        end

        def build_backup_rule(attrs, backup_resources)
          rule = {
            rule_name: "DailyBackup",
            target_vault_name: backup_resources[:backup_vault].name,
            schedule: attrs.primary_region.backup_schedule,
            start_window: 60,
            completion_window: 120,
            lifecycle: build_lifecycle_config(attrs)
          }

          if attrs.critical_data.cross_region_backup && backup_resources[:dr_vault]
            rule[:copy_action] = [{
              destination_vault_arn: backup_resources[:dr_vault].arn,
              lifecycle: {
                delete_after: attrs.critical_data.backup_retention_days
              }
            }]
          end

          rule.compact
        end

        def build_lifecycle_config(attrs)
          lifecycle = {
            delete_after: attrs.critical_data.backup_retention_days
          }

          if attrs.cost_optimization.data_lifecycle_policies
            lifecycle[:cold_storage_after] = 7
          end

          lifecycle.compact
        end

        def create_backup_selection(name, backup_plan)
          aws_backup_selection(
            component_resource_name(name, :backup_selection),
            {
              name: "#{name}-dr-backup-selection",
              plan_id: backup_plan.id,
              iam_role_arn: "arn:aws:iam::ACCOUNT:role/service-role/AWSBackupDefaultServiceRole",
              selection_tag: [{
                type: "STRINGEQUALS",
                key: "Backup",
                value: "true"
              }],
              resources: []
            }
          )
        end
      end
    end
  end
end
