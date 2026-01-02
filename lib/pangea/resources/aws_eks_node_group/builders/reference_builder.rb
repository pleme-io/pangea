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
        # Builds resource references for EKS node groups
        module ReferenceBuilder
          TERRAFORM_OUTPUTS = %i[
            id arn cluster_name node_group_name node_role_arn subnet_ids status
            capacity_type instance_types disk_size remote_access scaling_config
            update_config launch_template version release_version resources tags_all
          ].freeze

          COMPUTED_PROPERTIES = %i[
            spot_instances? custom_ami? has_remote_access? has_taints? has_labels?
          ].freeze

          DELEGATED_ATTRIBUTES = %i[ami_type].freeze

          module_function

          def build_reference(name, node_group_attrs)
            ref = ResourceReference.new(
              type: 'aws_eks_node_group',
              name: name,
              resource_attributes: node_group_attrs.to_h,
              outputs: build_outputs(name)
            )

            add_computed_properties(ref, node_group_attrs)
            add_delegated_attributes(ref, node_group_attrs)
            add_desired_size_method(ref, node_group_attrs)
            ref
          end

          def build_outputs(name)
            TERRAFORM_OUTPUTS.each_with_object({}) do |output, hash|
              hash[output] = "${aws_eks_node_group.#{name}.#{output}}"
            end
          end

          def add_computed_properties(ref, node_group_attrs)
            COMPUTED_PROPERTIES.each do |prop|
              ref.define_singleton_method(prop) { node_group_attrs.public_send(prop) }
            end
          end

          def add_delegated_attributes(ref, node_group_attrs)
            DELEGATED_ATTRIBUTES.each do |attr|
              ref.define_singleton_method(attr) { node_group_attrs.public_send(attr) }
            end
          end

          def add_desired_size_method(ref, node_group_attrs)
            ref.define_singleton_method(:desired_size) { node_group_attrs.scaling_config.desired_size }
          end
        end
      end
    end
  end
end
