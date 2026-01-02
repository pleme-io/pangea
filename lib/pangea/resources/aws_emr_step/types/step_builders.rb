# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Step builder methods for common EMR step types
        module EmrStepBuilders
          def self.spark_step(name, spark_app_path, options = {})
            args = ["spark-submit", "--deploy-mode", options[:deploy_mode] || "cluster"]
            args += ["--driver-memory", options[:driver_memory]] if options[:driver_memory]
            args += ["--driver-cores", options[:driver_cores]] if options[:driver_cores]
            args += ["--executor-memory", options[:executor_memory]] if options[:executor_memory]
            args += ["--executor-cores", options[:executor_cores]] if options[:executor_cores]
            args += ["--num-executors", options[:num_executors]] if options[:num_executors]
            args += ["--conf", options[:spark_conf]] if options[:spark_conf]
            args << spark_app_path
            args += options[:app_args] if options[:app_args]

            { name: name, action_on_failure: options[:action_on_failure] || "CONTINUE", hadoop_jar_step: { jar: "command-runner.jar", args: args } }
          end

          def self.hive_step(name, hive_script_path, options = {})
            args = ["hive-script", "--run-hive-script", "--args", "-f", hive_script_path]
            options[:variables]&.each { |key, value| args += ["-d", "#{key}=#{value}"] }
            { name: name, action_on_failure: options[:action_on_failure] || "CONTINUE", hadoop_jar_step: { jar: "command-runner.jar", args: args } }
          end

          def self.pig_step(name, pig_script_path, options = {})
            args = ["pig-script", "--run-pig-script", "--args", "-f", pig_script_path]
            options[:parameters]&.each { |key, value| args += ["-p", "#{key}=#{value}"] }
            { name: name, action_on_failure: options[:action_on_failure] || "CONTINUE", hadoop_jar_step: { jar: "command-runner.jar", args: args } }
          end

          def self.hadoop_streaming_step(name, mapper, reducer, input_path, output_path, options = {})
            args = ["hadoop-streaming"]
            args += ["-files", options[:files]] if options[:files]
            args += ["-mapper", mapper, "-reducer", reducer, "-input", input_path, "-output", output_path]
            args += options[:additional_args] if options[:additional_args]
            { name: name, action_on_failure: options[:action_on_failure] || "CONTINUE", hadoop_jar_step: { jar: "command-runner.jar", args: args } }
          end

          def self.custom_jar_step(name, jar_path, main_class = nil, options = {})
            step = { name: name, action_on_failure: options[:action_on_failure] || "CONTINUE", hadoop_jar_step: { jar: jar_path } }
            step[:hadoop_jar_step][:main_class] = main_class if main_class
            step[:hadoop_jar_step][:args] = options[:args] if options[:args]
            step[:hadoop_jar_step][:properties] = options[:properties] if options[:properties]
            step
          end

          def self.debug_step(name, options = {})
            { name: name, action_on_failure: options[:action_on_failure] || "CONTINUE", hadoop_jar_step: { jar: "command-runner.jar", args: ["state-pusher-script"] } }
          end

          def self.s3_copy_step(name, source_path, dest_path, options = {})
            args = ["s3-dist-cp", "--src", source_path, "--dest", dest_path]
            args += ["--srcPattern", options[:src_pattern]] if options[:src_pattern]
            args += ["--outputCodec", options[:output_codec]] if options[:output_codec]
            args += ["--groupBy", options[:group_by]] if options[:group_by]
            args += ["--targetSize", options[:target_size]] if options[:target_size]
            { name: name, action_on_failure: options[:action_on_failure] || "CONTINUE", hadoop_jar_step: { jar: "command-runner.jar", args: args } }
          end

          def self.distcp_step(name, source_path, dest_path, options = {})
            args = ["hadoop", "distcp"]
            args += ["-m", options[:num_mappers].to_s] if options[:num_mappers]
            args += ["-bandwidth", options[:bandwidth].to_s] if options[:bandwidth]
            args += ["--overwrite"] if options[:overwrite]
            args += ["--update"] if options[:update]
            args += [source_path, dest_path]
            { name: name, action_on_failure: options[:action_on_failure] || "CONTINUE", hadoop_jar_step: { jar: "command-runner.jar", args: args } }
          end

          def self.common_step_patterns
            {
              etl_processing: { description: "Extract, Transform, Load processing", typical_action: "CONTINUE", complexity: "medium" },
              data_validation: { description: "Data quality and validation checks", typical_action: "CANCEL_AND_WAIT", complexity: "low" },
              model_training: { description: "Machine learning model training", typical_action: "CONTINUE", complexity: "high" },
              batch_analytics: { description: "Large-scale analytics processing", typical_action: "CONTINUE", complexity: "high" },
              data_movement: { description: "Data copying and movement operations", typical_action: "CANCEL_AND_WAIT", complexity: "low" },
              streaming_setup: { description: "Setup streaming processing infrastructure", typical_action: "TERMINATE_CLUSTER", complexity: "medium" }
            }
          end
        end
      end
    end
  end
end
