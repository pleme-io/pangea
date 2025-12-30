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
      module EksNodeGroup
        # Builds Terraform DSL for EKS node group resources
        module DslBuilder
          module_function

          def build_resource(context, attrs)
            build_required_attributes(context, attrs)
            build_scaling_config(context, attrs.scaling_config)
            build_update_config(context, attrs.update_config) if attrs.update_config
            build_instance_config(context, attrs)
            build_version_info(context, attrs)
            build_remote_access(context, attrs.remote_access) if attrs.remote_access
            build_launch_template(context, attrs.launch_template) if attrs.launch_template
            build_kubernetes_config(context, attrs)
          end

          def build_required_attributes(context, attrs)
            context.cluster_name attrs.cluster_name
            context.node_role_arn attrs.node_role_arn
            context.subnet_ids attrs.subnet_ids
            context.node_group_name attrs.node_group_name if attrs.node_group_name
          end

          def build_scaling_config(context, scaling_config)
            context.scaling_config do
              desired_size scaling_config.desired_size
              max_size scaling_config.max_size
              min_size scaling_config.min_size
            end
          end

          def build_update_config(context, update_config)
            context.update_config do
              if update_config.max_unavailable
                max_unavailable update_config.max_unavailable
              elsif update_config.max_unavailable_percentage
                max_unavailable_percentage update_config.max_unavailable_percentage
              end
            end
          end

          def build_instance_config(context, attrs)
            context.instance_types attrs.instance_types
            context.capacity_type attrs.capacity_type
            context.ami_type attrs.ami_type
            context.disk_size attrs.disk_size
          end

          def build_version_info(context, attrs)
            context.release_version attrs.release_version if attrs.release_version
            context.version attrs.version if attrs.version
            context.force_update_version attrs.force_update_version if attrs.force_update_version
          end

          def build_remote_access(context, remote_access)
            context.remote_access do
              ec2_ssh_key remote_access.ec2_ssh_key if remote_access.ec2_ssh_key
              source_security_group_ids remote_access.source_security_group_ids if remote_access.source_security_group_ids.any?
            end
          end

          def build_launch_template(context, launch_template)
            context.launch_template do
              id launch_template.id if launch_template.id
              __send__(:name, launch_template.name) if launch_template.name
              version launch_template.version if launch_template.version
            end
          end

          def build_kubernetes_config(context, attrs)
            context.labels attrs.labels if attrs.labels.any?
            build_taints(context, attrs.taints) if attrs.taints.any?
            context.tags attrs.tags if attrs.tags.any?
          end

          def build_taints(context, taints)
            taints.each do |taint_config|
              context.taint do
                key taint_config.key
                value taint_config.value if taint_config.value
                effect taint_config.effect
              end
            end
          end
        end
      end
    end
  end
end
