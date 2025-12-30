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
        module EmrClusterClassMethods
          def spark_configuration(options = {})
            {
              classification: 'spark-defaults',
              properties: {
                'spark.dynamicAllocation.enabled' => 'true',
                'spark.dynamicAllocation.minExecutors' => options[:min_executors]&.to_s || '1',
                'spark.dynamicAllocation.maxExecutors' => options[:max_executors]&.to_s || '8',
                'spark.sql.adaptive.enabled' => 'true',
                'spark.sql.adaptive.coalescePartitions.enabled' => 'true',
                'spark.serializer' => 'org.apache.spark.serializer.KryoSerializer'
              }.merge(options[:additional_properties] || {})
            }
          end

          def hadoop_configuration(options = {})
            {
              classification: 'hadoop-env',
              configurations: [{
                classification: 'export',
                properties: {
                  'HADOOP_DATANODE_HEAPSIZE' => options[:datanode_heap] || '2048',
                  'HADOOP_NAMENODE_HEAPSIZE' => options[:namenode_heap] || '2048'
                }
              }]
            }
          end

          def hive_configuration(options = {})
            {
              classification: 'hive-site',
              properties: {
                'javax.jdo.option.ConnectionURL' => options[:connection_url] || 'glue_catalog',
                'hive.metastore.client.factory.class' => 'com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory',
                'hive.exec.dynamic.partition' => 'true',
                'hive.exec.dynamic.partition.mode' => 'nonstrict'
              }.merge(options[:additional_properties] || {})
            }
          end

          def instance_group_config(role, instance_type, count, options = {})
            config = { instance_role: role.upcase, instance_type: instance_type, instance_count: count }
            config[:bid_price] = options[:spot_price] if options[:spot_price]
            config[:ebs_config] = options[:ebs_config] if options[:ebs_config]
            config[:auto_scaling_policy] = options[:auto_scaling_policy] if options[:auto_scaling_policy]
            config[:name] = options[:name] if options[:name]
            config
          end

          def bootstrap_action(name, script_path, args = [])
            { name: name, path: script_path, args: Array(args) }
          end

          def workload_configurations
            {
              spark_analytics: spark_analytics_config,
              machine_learning: machine_learning_config,
              data_engineering: data_engineering_config,
              interactive_analytics: interactive_analytics_config
            }
          end

          private

          def spark_analytics_config
            { applications: %w[Hadoop Spark Hive Livy], configurations: [spark_configuration(min_executors: 2, max_executors: 20), hive_configuration] }
          end

          def machine_learning_config
            {
              applications: %w[Hadoop Spark JupyterHub MXNet TensorFlow],
              configurations: [spark_configuration(min_executors: 1, max_executors: 10, additional_properties: {
                'spark.dynamicAllocation.schedulerBacklogTimeout' => '1s',
                'spark.dynamicAllocation.sustainedSchedulerBacklogTimeout' => '5s'
              })]
            }
          end

          def data_engineering_config
            { applications: %w[Hadoop Spark Hive Pig Sqoop Oozie], configurations: [spark_configuration(min_executors: 4, max_executors: 50), hive_configuration, hadoop_configuration] }
          end

          def interactive_analytics_config
            {
              applications: %w[Hadoop Spark Presto Hive JupyterHub Zeppelin],
              configurations: [spark_configuration(min_executors: 2, max_executors: 15), hive_configuration,
                               { classification: 'presto-config', properties: { 'query.max-memory' => '50GB', 'query.max-memory-per-node' => '8GB' } }]
            }
          end
        end
      end
    end
  end
end
