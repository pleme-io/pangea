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
      # Type-safe attributes for AWS EMR Cluster resources
      class EmrClusterAttributes < Dry::Struct
        # Cluster name (required)
        attribute :name, Resources::Types::String
        
        # Release label (required) 
        attribute :release_label, Resources::Types::String
        
        # Applications to install
        attribute :applications, Resources::Types::Array.of(
          Types::String.enum(
            "Hadoop", "Spark", "Hive", "Presto", "Trino", "HBase", "Phoenix", "Pig", 
            "Sqoop", "Oozie", "ZooKeeper", "Tez", "Ganglia", "Flume", "MXNet", 
            "TensorFlow", "JupyterHub", "Livy", "Zeppelin"
          )
        ).default(["Hadoop", "Spark"].freeze)
        
        # Service role (required)
        attribute :service_role, Resources::Types::String
        
        # EMR release configurations
        attribute :configurations, Resources::Types::Array.of(
          Types::Hash.schema(
            classification: Types::String,
            configurations?: Types::Array.of(Types::Hash).optional,
            properties?: Types::Hash.map(Types::String, Types::String).optional
          )
        ).default([].freeze)
        
        # EC2 attributes
        attributeec2_attribute :s, Resources::Types::Hash.schema(
          key_name?: Types::String.optional,
          instance_profile: Types::String,
          emr_managed_master_security_group?: Types::String.optional,
          emr_managed_slave_security_group?: Types::String.optional,
          service_access_security_group?: Types::String.optional,
          additional_master_security_groups?: Types::Array.of(Types::String).optional,
          additional_slave_security_groups?: Types::Array.of(Types::String).optional,
          subnet_id?: Types::String.optional,
          subnet_ids?: Types::Array.of(Types::String).optional
        )
        
        # Master instance group
        attribute :master_instance_group, Resources::Types::Hash.schema(
          instance_type: Types::String,
          instance_count?: Types::Integer.constrained(eql: 1).optional
        )
        
        # Core instance group
        attribute :core_instance_group, Resources::Types::Hash.schema(
          instance_type: Types::String,
          instance_count?: Types::Integer.constrained(gteq: 1).optional,
          bid_price?: Types::String.optional,
          ebs_config?: Types::Hash.schema(
            ebs_block_device_config?: Types::Array.of(
              Types::Hash.schema(
                volume_specification: Types::Hash.schema(
                  volume_type: Types::String.enum("gp2", "gp3", "io1", "io2", "st1", "sc1"),
                  size_in_gb: Types::Integer,
                  iops?: Types::Integer.optional
                ),
                volumes_per_instance?: Types::Integer.optional
              )
            ).optional,
            ebs_optimized?: Types::Bool.optional
          ).optional
        ).optional
        
        # Task instance groups
        attribute :task_instance_groups, Resources::Types::Array.of(
          Types::Hash.schema(
            name?: Types::String.optional,
            instance_role: Types::String.enum("TASK"),
            instance_type: Types::String,
            instance_count: Types::Integer.constrained(gteq: 0),
            bid_price?: Types::String.optional,
            ebs_config?: Types::Hash.schema(
              ebs_block_device_config?: Types::Array.of(
                Types::Hash.schema(
                  volume_specification: Types::Hash.schema(
                    volume_type: Types::String.enum("gp2", "gp3", "io1", "io2", "st1", "sc1"),
                    size_in_gb: Types::Integer,
                    iops?: Types::Integer.optional
                  ),
                  volumes_per_instance?: Types::Integer.optional
                )
              ).optional,
              ebs_optimized?: Types::Bool.optional
            ).optional,
            auto_scaling_policy?: Types::Hash.schema(
              constraints: Types::Hash.schema(
                min_capacity: Types::Integer,
                max_capacity: Types::Integer
              ),
              rules: Types::Array.of(
                Types::Hash.schema(
                  name: Types::String,
                  description?: Types::String.optional,
                  action: Types::Hash.schema(
                    market?: Types::String.enum("ON_DEMAND", "SPOT").optional,
                    simple_scaling_policy_configuration: Types::Hash.schema(
                      adjustment_type?: Types::String.enum("CHANGE_IN_CAPACITY", "PERCENT_CHANGE_IN_CAPACITY", "EXACT_CAPACITY").optional,
                      scaling_adjustment: Types::Integer,
                      cool_down?: Types::Integer.optional
                    )
                  ),
                  trigger: Types::Hash.schema(
                    cloud_watch_alarm_definition: Types::Hash.schema(
                      comparison_operator: Types::String.enum("GREATER_THAN_OR_EQUAL", "GREATER_THAN", "LESS_THAN", "LESS_THAN_OR_EQUAL"),
                      evaluation_periods: Types::Integer,
                      metric_name: Types::String,
                      namespace: Types::String,
                      period: Types::Integer,
                      statistic?: Types::String.enum("SAMPLE_COUNT", "AVERAGE", "SUM", "MINIMUM", "MAXIMUM").optional,
                      threshold: Types::Float,
                      unit?: Types::String.optional,
                      dimensions?: Types::Hash.map(Types::String, Types::String).optional
                    )
                  )
                )
              )
            ).optional
          )
        ).default([].freeze)
        
        # Bootstrap actions
        attribute :bootstrap_action, Resources::Types::Array.of(
          Types::Hash.schema(
            path: Types::String,
            name: Types::String,
            args?: Types::Array.of(Types::String).optional
          )
        ).default([].freeze)
        
        # Logging configuration
        attribute :log_uri, Resources::Types::String.optional
        attribute :log_encryption_kms_key_id, Resources::Types::String.optional
        
        # Termination protection
        attribute :termination_protection, Resources::Types::Bool.default(false)
        
        # Keep job flow alive
        attribute :keep_job_flow_alive_when_no_steps, Resources::Types::Bool.default(true)
        
        # Visible to all users
        attribute :visible_to_all_users, Resources::Types::Bool.default(true)
        
        # Auto-terminate after idle
        attribute :auto_termination_policy, Resources::Types::Hash.schema(
          idle_timeout?: Types::Integer.optional
        ).optional
        
        # Custom AMI
        attribute :custom_ami_id, Resources::Types::String.optional
        
        # EBS root volume configuration
        attribute :ebs_root_volume_size, Resources::Types::Integer.optional
        
        # Kerberos attributes
        attribute :kerberos_attributes, Resources::Types::Hash.schema(
          kdc_admin_password: Types::String,
          realm: Types::String,
          ad_domain_join_password?: Types::String.optional,
          ad_domain_join_user?: Types::String.optional,
          cross_realm_trust_principal_password?: Types::String.optional
        ).optional
        
        # Step concurrency level
        attribute :step_concurrency_level, Resources::Types::Integer.constrained(gteq: 1, lteq: 256).optional
        
        # Placement group configs
        attribute :placement_group_configs, Resources::Types::Array.of(
          Types::Hash.schema(
            instance_role: Types::String.enum("MASTER", "CORE", "TASK"),
            placement_strategy?: Types::String.enum("SPREAD", "PARTITION", "CLUSTER").optional
          )
        ).default([].freeze)
        
        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate cluster name format
          unless attrs.name =~ /\A[a-zA-Z_][a-zA-Z0-9_-]*\z/
            raise Dry::Struct::Error, "Cluster name must start with letter or underscore and contain only alphanumeric characters, underscores, and hyphens"
          end
          
          # Validate cluster name length
          if attrs.name.length > 256
            raise Dry::Struct::Error, "Cluster name must be 256 characters or less"
          end
          
          # Validate release label format
          unless attrs.release_label =~ /\Aemr-\d+\.\d+\.\d+\z/
            raise Dry::Struct::Error, "Release label must be in format emr-x.x.x"
          end
          
          # Validate service role format
          unless attrs.service_role.match(/\A(arn:aws:iam::\d{12}:role\/|EMR_DefaultRole)/i)
            raise Dry::Struct::Error, "Service role must be an IAM role ARN or EMR_DefaultRole"
          end
          
          # Validate instance profile format
          unless attrs.ec2_attributes[:instance_profile].match(/\A(arn:aws:iam::\d{12}:instance-profile\/|EMR_EC2_DefaultRole)/i)
            raise Dry::Struct::Error, "Instance profile must be an IAM instance profile ARN or EMR_EC2_DefaultRole"
          end
          
          # Validate log URI format if specified
          if attrs.log_uri && !attrs.log_uri.match(/\As3:\/\//)
            raise Dry::Struct::Error, "Log URI must be an S3 URL (s3://bucket/path)"
          end
          
          # Validate subnet configuration
          ec2_attrs = attrs.ec2_attributes
          if ec2_attrs[:subnet_id] && ec2_attrs[:subnet_ids]
            raise Dry::Struct::Error, "Cannot specify both subnet_id and subnet_ids"
          end

          attrs
        end

        # Check if cluster uses Spark
        def uses_spark?
          applications.include?("Spark")
        end

        # Check if cluster uses Hive
        def uses_hive?
          applications.include?("Hive")
        end

        # Check if cluster uses Presto/Trino
        def uses_presto?
          applications.include?("Presto") || applications.include?("Trino")
        end

        # Check if cluster uses machine learning frameworks
        def uses_ml_frameworks?
          (applications & ["MXNet", "TensorFlow"]).any?
        end

        # Check if cluster uses notebooks
        def uses_notebooks?
          (applications & ["JupyterHub", "Zeppelin"]).any?
        end

        # Check if cluster is multi-AZ
        def is_multi_az?
          ec2_attributes[:subnet_ids]&.size.to_i > 1
        end

        # Check if cluster uses spot instances
        def uses_spot_instances?
          return true if core_instance_group&.dig(:bid_price)
          return true if task_instance_groups.any? { |group| group[:bid_price] }
          false
        end

        # Check if auto scaling is configured
        def has_auto_scaling?
          task_instance_groups.any? { |group| group[:auto_scaling_policy] }
        end

        # Get total core instances
        def total_core_instances
          core_instance_group&.dig(:instance_count) || 0
        end

        # Get total task instances
        def total_task_instances
          task_instance_groups.sum { |group| group[:instance_count] }
        end

        # Get total cluster instances
        def total_cluster_instances
          1 + total_core_instances + total_task_instances # 1 for master
        end

        # Estimate hourly cost based on instance types and counts
        def estimated_hourly_cost_usd
          # Simplified cost estimation
          base_costs = {
            "m5.xlarge" => 0.192,
            "m5.2xlarge" => 0.384,
            "m5.4xlarge" => 0.768,
            "m5.12xlarge" => 2.304,
            "c5.xlarge" => 0.17,
            "c5.2xlarge" => 0.34,
            "c5.4xlarge" => 0.68,
            "r5.xlarge" => 0.252,
            "r5.2xlarge" => 0.504,
            "r5.4xlarge" => 1.008
          }
          
          total_cost = 0.0
          
          # Master instance cost
          master_type = master_instance_group[:instance_type]
          total_cost += base_costs[master_type] || 0.20
          
          # Core instance cost
          if core_instance_group
            core_type = core_instance_group[:instance_type]
            core_count = core_instance_group[:instance_count] || 1
            core_cost = base_costs[core_type] || 0.20
            total_cost += core_cost * core_count
          end
          
          # Task instance cost
          task_instance_groups.each do |group|
            task_type = group[:instance_type]
            task_count = group[:instance_count]
            task_cost = base_costs[task_type] || 0.20
            total_cost += task_cost * task_count
          end
          
          # Apply spot pricing discount if using spot instances
          if uses_spot_instances?
            total_cost *= 0.3 # Approximate 70% discount
          end
          
          total_cost.round(4)
        end

        # Get configuration warnings
        def configuration_warnings
          warnings = []
          
          if total_cluster_instances > 1000
            warnings << "Very large cluster (>1000 instances) may face resource limits"
          end
          
          unless uses_spark?
            warnings << "Consider adding Spark for better performance on most workloads"
          end
          
          if !log_uri
            warnings << "Consider enabling cluster logging for troubleshooting"
          end
          
          if !termination_protection && !uses_spot_instances?
            warnings << "Consider enabling termination protection for production clusters"
          end
          
          if task_instance_groups.any? && !has_auto_scaling?
            warnings << "Consider configuring auto scaling for task instance groups"
          end
          
          if uses_notebooks? && !is_multi_az?
            warnings << "Consider multi-AZ deployment for notebook high availability"
          end
          
          warnings
        end

        # Helper to generate common configurations
        def self.spark_configuration(options = {})
          {
            classification: "spark-defaults",
            properties: {
              "spark.dynamicAllocation.enabled" => "true",
              "spark.dynamicAllocation.minExecutors" => options[:min_executors]&.to_s || "1",
              "spark.dynamicAllocation.maxExecutors" => options[:max_executors]&.to_s || "8",
              "spark.sql.adaptive.enabled" => "true",
              "spark.sql.adaptive.coalescePartitions.enabled" => "true",
              "spark.serializer" => "org.apache.spark.serializer.KryoSerializer"
            }.merge(options[:additional_properties] || {})
          }
        end

        def self.hadoop_configuration(options = {})
          {
            classification: "hadoop-env",
            configurations: [
              {
                classification: "export",
                properties: {
                  "HADOOP_DATANODE_HEAPSIZE" => options[:datanode_heap] || "2048",
                  "HADOOP_NAMENODE_HEAPSIZE" => options[:namenode_heap] || "2048"
                }
              }
            ]
          }
        end

        def self.hive_configuration(options = {})
          {
            classification: "hive-site",
            properties: {
              "javax.jdo.option.ConnectionURL" => options[:connection_url] || "glue_catalog",
              "hive.metastore.client.factory.class" => "com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory",
              "hive.exec.dynamic.partition" => "true",
              "hive.exec.dynamic.partition.mode" => "nonstrict"
            }.merge(options[:additional_properties] || {})
          }
        end

        # Helper to generate instance group configurations
        def self.instance_group_config(role, instance_type, count, options = {})
          config = {
            instance_role: role.upcase,
            instance_type: instance_type,
            instance_count: count
          }
          
          config[:bid_price] = options[:spot_price] if options[:spot_price]
          config[:ebs_config] = options[:ebs_config] if options[:ebs_config]
          config[:auto_scaling_policy] = options[:auto_scaling_policy] if options[:auto_scaling_policy]
          config[:name] = options[:name] if options[:name]
          
          config
        end

        # Helper to generate bootstrap actions
        def self.bootstrap_action(name, script_path, args = [])
          {
            name: name,
            path: script_path,
            args: Array(args)
          }
        end

        # Common cluster configurations for different workloads
        def self.workload_configurations
          {
            spark_analytics: {
              applications: ["Hadoop", "Spark", "Hive", "Livy"],
              configurations: [
                spark_configuration(min_executors: 2, max_executors: 20),
                hive_configuration
              ]
            },
            machine_learning: {
              applications: ["Hadoop", "Spark", "JupyterHub", "MXNet", "TensorFlow"],
              configurations: [
                spark_configuration(min_executors: 1, max_executors: 10, additional_properties: {
                  "spark.dynamicAllocation.schedulerBacklogTimeout" => "1s",
                  "spark.dynamicAllocation.sustainedSchedulerBacklogTimeout" => "5s"
                })
              ]
            },
            data_engineering: {
              applications: ["Hadoop", "Spark", "Hive", "Pig", "Sqoop", "Oozie"],
              configurations: [
                spark_configuration(min_executors: 4, max_executors: 50),
                hive_configuration,
                hadoop_configuration
              ]
            },
            interactive_analytics: {
              applications: ["Hadoop", "Spark", "Presto", "Hive", "JupyterHub", "Zeppelin"],
              configurations: [
                spark_configuration(min_executors: 2, max_executors: 15),
                hive_configuration,
                {
                  classification: "presto-config",
                  properties: {
                    "query.max-memory" => "50GB",
                    "query.max-memory-per-node" => "8GB"
                  }
                }
              ]
            }
          }
        end
      end
    end
      end
    end
  end
end