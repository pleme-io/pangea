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

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_emr_cluster/types'
require 'pangea/resource_registry'
require_relative 'resource/dsl_builder'

module Pangea
  module Resources
    module AWS
      # Create an AWS EMR Cluster with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] EMR Cluster attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_emr_cluster(name, attributes = {})
        cluster_attrs = Types::EmrClusterAttributes.new(attributes)
        builder = EmrCluster::DSLBuilder.new(cluster_attrs)

        resource(:aws_emr_cluster, name) do
          release_label cluster_attrs.release_label
          service_role cluster_attrs.service_role

          builder.build_applications(self)
          builder.build_configurations(self)
          builder.build_ec2_attributes(self)
          builder.build_master_instance_group(self)
          builder.build_core_instance_group(self)
          builder.build_task_instance_groups(self)
          builder.build_bootstrap_actions(self)
          builder.build_logging(self)
          builder.build_cluster_behavior(self)
          builder.build_auto_termination_policy(self)
          builder.build_custom_ami(self)
          builder.build_ebs_root_volume(self)
          builder.build_kerberos_attributes(self)
          builder.build_step_concurrency(self)
          builder.build_placement_group_configs(self)
          builder.build_tags(self)
        end

        build_resource_reference(name, cluster_attrs)
      end

      private

      def build_resource_reference(name, cluster_attrs)
        ResourceReference.new(
          type: 'aws_emr_cluster',
          name: name,
          resource_attributes: cluster_attrs.to_h,
          outputs: emr_outputs(name),
          computed_properties: emr_computed_properties(cluster_attrs)
        )
      end

      def emr_outputs(name)
        {
          id: "${aws_emr_cluster.#{name}.id}",
          name: "${aws_emr_cluster.#{name}.name}",
          arn: "${aws_emr_cluster.#{name}.arn}",
          cluster_state: "${aws_emr_cluster.#{name}.cluster_state}",
          master_instance_group_id: "${aws_emr_cluster.#{name}.master_instance_group[0].id}",
          core_instance_group_id: "${aws_emr_cluster.#{name}.core_instance_group[0].id}",
          master_public_dns: "${aws_emr_cluster.#{name}.master_public_dns}",
          log_uri: "${aws_emr_cluster.#{name}.log_uri}",
          applications: "${aws_emr_cluster.#{name}.applications}"
        }
      end

      def emr_computed_properties(cluster_attrs)
        {
          uses_spark: cluster_attrs.uses_spark?,
          uses_hive: cluster_attrs.uses_hive?,
          uses_presto: cluster_attrs.uses_presto?,
          uses_ml_frameworks: cluster_attrs.uses_ml_frameworks?,
          uses_notebooks: cluster_attrs.uses_notebooks?,
          is_multi_az: cluster_attrs.is_multi_az?,
          uses_spot_instances: cluster_attrs.uses_spot_instances?,
          has_auto_scaling: cluster_attrs.has_auto_scaling?,
          total_core_instances: cluster_attrs.total_core_instances,
          total_task_instances: cluster_attrs.total_task_instances,
          total_cluster_instances: cluster_attrs.total_cluster_instances,
          estimated_hourly_cost_usd: cluster_attrs.estimated_hourly_cost_usd,
          configuration_warnings: cluster_attrs.configuration_warnings
        }
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)
