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
      module EmrCluster
        class DSLBuilder
          # Cluster settings building methods for EMR clusters
          module ClusterSettings
            def build_bootstrap_actions(ctx)
              attrs.bootstrap_action.each do |bootstrap|
                ctx.bootstrap_action do
                  name bootstrap[:name]
                  path bootstrap[:path]
                  args bootstrap[:args] if bootstrap[:args]&.any?
                end
              end
            end

            def build_logging(ctx)
              ctx.log_uri attrs.log_uri if attrs.log_uri
              return unless attrs.log_encryption_kms_key_id

              ctx.log_encryption_kms_key_id attrs.log_encryption_kms_key_id
            end

            def build_cluster_behavior(ctx)
              ctx.termination_protection attrs.termination_protection
              ctx.keep_job_flow_alive_when_no_steps attrs.keep_job_flow_alive_when_no_steps
              ctx.visible_to_all_users attrs.visible_to_all_users
            end

            def build_auto_termination_policy(ctx)
              return unless attrs.auto_termination_policy

              atp = attrs.auto_termination_policy
              ctx.auto_termination_policy do
                idle_timeout atp[:idle_timeout] if atp[:idle_timeout]
              end
            end

            def build_custom_ami(ctx)
              ctx.custom_ami_id attrs.custom_ami_id if attrs.custom_ami_id
            end

            def build_ebs_root_volume(ctx)
              ctx.ebs_root_volume_size attrs.ebs_root_volume_size if attrs.ebs_root_volume_size
            end

            def build_kerberos_attributes(ctx)
              return unless attrs.kerberos_attributes

              ka = attrs.kerberos_attributes
              ctx.kerberos_attributes do
                kdc_admin_password ka[:kdc_admin_password]
                realm ka[:realm]
                ad_domain_join_password ka[:ad_domain_join_password] if ka[:ad_domain_join_password]
                ad_domain_join_user ka[:ad_domain_join_user] if ka[:ad_domain_join_user]
                if ka[:cross_realm_trust_principal_password]
                  cross_realm_trust_principal_password ka[:cross_realm_trust_principal_password]
                end
              end
            end

            def build_step_concurrency(ctx)
              return unless attrs.step_concurrency_level

              ctx.step_concurrency_level attrs.step_concurrency_level
            end

            def build_placement_group_configs(ctx)
              attrs.placement_group_configs.each do |placement_config|
                ctx.placement_group_configs do
                  instance_role placement_config[:instance_role]
                  placement_strategy placement_config[:placement_strategy] if placement_config[:placement_strategy]
                end
              end
            end

            def build_tags(ctx)
              return unless attrs.tags.any?

              ctx.tags do
                attrs.tags.each { |key, value| public_send(key, value) }
              end
            end
          end
        end
      end
    end
  end
end
