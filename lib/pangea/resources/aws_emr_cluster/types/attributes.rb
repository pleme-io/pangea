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
      module Types
        # Type-safe attributes for AWS EMR Cluster resources
        class EmrClusterAttributes < Dry::Struct
          extend EmrClusterClassMethods
          include EmrClusterInstanceMethods
          extend EmrClusterValidation

          attribute :name, Resources::Types::String
          attribute :release_label, Resources::Types::String
          attribute :applications, Resources::Types::Array.of(
            Types::String.enum('Hadoop', 'Spark', 'Hive', 'Presto', 'Trino', 'HBase', 'Phoenix', 'Pig',
                               'Sqoop', 'Oozie', 'ZooKeeper', 'Tez', 'Ganglia', 'Flume', 'MXNet',
                               'TensorFlow', 'JupyterHub', 'Livy', 'Zeppelin')
          ).default(%w[Hadoop Spark].freeze)
          attribute :service_role, Resources::Types::String
          attribute :configurations, Resources::Types::Array.of(
            Types::Hash.schema(classification: Types::String, configurations?: Types::Array.of(Types::Hash).optional,
                               properties?: Types::Hash.map(Types::String, Types::String).optional)
          ).default([].freeze)

          # EC2 attributes
          attribute :ec2_attributes, Resources::Types::Hash.schema(
            key_name?: Types::String.optional, instance_profile: Types::String,
            emr_managed_master_security_group?: Types::String.optional, emr_managed_slave_security_group?: Types::String.optional,
            service_access_security_group?: Types::String.optional, additional_master_security_groups?: Types::Array.of(Types::String).optional,
            additional_slave_security_groups?: Types::Array.of(Types::String).optional, subnet_id?: Types::String.optional,
            subnet_ids?: Types::Array.of(Types::String).optional
          )

          # Instance groups
          attribute :master_instance_group, Resources::Types::Hash.schema(instance_type: Types::String, instance_count?: Types::Integer.constrained(eql: 1).optional)
          attribute :core_instance_group, Resources::Types::Hash.schema(
            instance_type: Types::String, instance_count?: Types::Integer.constrained(gteq: 1).optional, bid_price?: Types::String.optional,
            ebs_config?: Types::Hash.schema(ebs_block_device_config?: Types::Array.of(Types::Hash).optional, ebs_optimized?: Types::Bool.optional).optional
          ).optional
          attribute :task_instance_groups, Resources::Types::Array.of(Types::Hash).default([].freeze)

          # Bootstrap and logging
          attribute :bootstrap_action, Resources::Types::Array.of(
            Types::Hash.schema(path: Types::String, name: Types::String, args?: Types::Array.of(Types::String).optional)
          ).default([].freeze)
          attribute :log_uri, Resources::Types::String.optional
          attribute :log_encryption_kms_key_id, Resources::Types::String.optional

          # Cluster behavior
          attribute :termination_protection, Resources::Types::Bool.default(false)
          attribute :keep_job_flow_alive_when_no_steps, Resources::Types::Bool.default(true)
          attribute :visible_to_all_users, Resources::Types::Bool.default(true)
          attribute :auto_termination_policy, Resources::Types::Hash.schema(idle_timeout?: Types::Integer.optional).optional
          attribute :custom_ami_id, Resources::Types::String.optional
          attribute :ebs_root_volume_size, Resources::Types::Integer.optional

          # Kerberos and advanced settings
          attribute :kerberos_attributes, Resources::Types::Hash.schema(
            kdc_admin_password: Types::String, realm: Types::String, ad_domain_join_password?: Types::String.optional,
            ad_domain_join_user?: Types::String.optional, cross_realm_trust_principal_password?: Types::String.optional
          ).optional
          attribute :step_concurrency_level, Resources::Types::Integer.constrained(gteq: 1, lteq: 256).optional
          attribute :placement_group_configs, Resources::Types::Array.of(
            Types::Hash.schema(instance_role: Types::String.enum('MASTER', 'CORE', 'TASK'), placement_strategy?: Types::String.enum('SPREAD', 'PARTITION', 'CLUSTER').optional)
          ).default([].freeze)
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          def self.new(attributes = {})
            attrs = super(attributes)
            validate_cluster_name(attrs.name)
            validate_release_label(attrs.release_label)
            validate_service_role(attrs.service_role)
            validate_instance_profile(attrs.ec2_attributes[:instance_profile])
            validate_log_uri(attrs.log_uri)
            validate_subnet_config(attrs.ec2_attributes)
            attrs
          end
        end
      end
    end
  end
end
