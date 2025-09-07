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
      # Type-safe attributes for AWS EMR Step resources
      class EmrStepAttributes < Dry::Struct
        # Step name (required)
        attribute :name, Resources::Types::String
        
        # Cluster ID (required)
        attribute :cluster_id, Resources::Types::String
        
        # Action on failure (required)
        attribute :action_on_failure, Resources::Types::String.enum("TERMINATE_JOB_FLOW", "TERMINATE_CLUSTER", "CANCEL_AND_WAIT", "CONTINUE")
        
        # Hadoop JAR step configuration (required)
        attribute :hadoop_jar_step, Resources::Types::Hash.schema(
          jar: Types::String,
          main_class?: Types::String.optional,
          args?: Types::Array.of(Types::String).optional,
          properties?: Types::Hash.map(Types::String, Types::String).optional
        )
        
        # Step description
        attribute :description, Resources::Types::String.optional
        
        # Step concurrency level override
        attribute :step_concurrency_level, Resources::Types::Integer.constrained(gteq: 1, lteq: 256).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate step name format
          unless attrs.name =~ /\A[a-zA-Z_][a-zA-Z0-9_\s-]*\z/
            raise Dry::Struct::Error, "Step name must start with letter or underscore and contain only alphanumeric characters, spaces, underscores, and hyphens"
          end
          
          # Validate step name length
          if attrs.name.length > 256
            raise Dry::Struct::Error, "Step name must be 256 characters or less"
          end
          
          # Validate cluster ID format
          unless attrs.cluster_id =~ /\Aj-[A-Z0-9]{8,}\z/
            raise Dry::Struct::Error, "Cluster ID must be in format j-XXXXXXXXX"
          end
          
          # Validate JAR path format
          jar_path = attrs.hadoop_jar_step[:jar]
          unless jar_path.match(/\A(s3:\/\/|command-runner\.jar|\/|hdfs:\/\/)/)
            raise Dry::Struct::Error, "JAR path must be S3 URL, command-runner.jar, local path, or HDFS path"
          end
          
          # Validate arguments are strings if provided
          if attrs.hadoop_jar_step[:args]
            attrs.hadoop_jar_step[:args].each_with_index do |arg, index|
              unless arg.is_a?(String)
                raise Dry::Struct::Error, "Argument #{index} must be a string"
              end
            end
          end

          attrs
        end

        # Check if step uses command runner
        def uses_command_runner?
          hadoop_jar_step[:jar] == "command-runner.jar"
        end

        # Check if step uses S3 JAR
        def uses_s3_jar?
          hadoop_jar_step[:jar].start_with?("s3://")
        end

        # Check if step has custom main class
        def has_custom_main_class?
          !hadoop_jar_step[:main_class].nil?
        end

        # Get step type based on configuration
        def step_type
          jar = hadoop_jar_step[:jar]
          args = hadoop_jar_step[:args] || []
          
          case jar
          when "command-runner.jar"
            if args.first&.include?("spark-submit")
              "spark"
            elsif args.first&.include?("hadoop")
              "hadoop"
            elsif args.first&.include?("hive")
              "hive"
            elsif args.first&.include?("pig")
              "pig"
            else
              "command_runner"
            end
          when /spark/i
            "spark"
          when /hadoop/i
            "hadoop"
          when /hive/i
            "hive"
          when /pig/i
            "pig"
          else
            "custom_jar"
          end
        end

        # Get argument count
        def argument_count
          hadoop_jar_step[:args]&.size || 0
        end

        # Get property count
        def property_count
          hadoop_jar_step[:properties]&.size || 0
        end

        # Check if step is likely long-running
        def is_likely_long_running?
          step_type_indicators = %w[spark hive pig]
          step_type_indicators.include?(step_type) || 
            (hadoop_jar_step[:args] || []).any? { |arg| arg.match?(/-D.*streaming|--streaming/) }
        end

        # Estimate step complexity based on configuration
        def complexity_score
          score = 1
          score += argument_count * 0.1
          score += property_count * 0.2
          score += 2 if has_custom_main_class?
          score += 1 if uses_s3_jar?
          score += 3 if is_likely_long_running?
          
          score.round(1)
        end

        # Generate configuration warnings
        def configuration_warnings
          warnings = []
          
          if action_on_failure == "TERMINATE_CLUSTER" && !is_likely_long_running?
            warnings << "TERMINATE_CLUSTER action may be too aggressive for short-running steps"
          end
          
          if action_on_failure == "CONTINUE" && is_likely_long_running?
            warnings << "CONTINUE action may allow long-running failed steps to waste resources"
          end
          
          if argument_count > 50
            warnings << "Large number of arguments (>50) may indicate overly complex step"
          end
          
          if uses_s3_jar? && !hadoop_jar_step[:jar].match?(/\.jar$/)
            warnings << "S3 JAR path should end with .jar extension"
          end
          
          if step_type == "spark" && !(hadoop_jar_step[:args] || []).any? { |arg| arg.match?(/--driver-memory|--executor-memory/) }
            warnings << "Spark steps should specify memory configuration for optimal performance"
          end
          
          warnings
        end

        # Helper methods to create common step configurations
        def self.spark_step(name, spark_app_path, options = {})
          args = ["spark-submit"]
          
          # Spark configuration
          args += ["--deploy-mode", options[:deploy_mode] || "cluster"]
          args += ["--driver-memory", options[:driver_memory]] if options[:driver_memory]
          args += ["--driver-cores", options[:driver_cores]] if options[:driver_cores]
          args += ["--executor-memory", options[:executor_memory]] if options[:executor_memory]
          args += ["--executor-cores", options[:executor_cores]] if options[:executor_cores]
          args += ["--num-executors", options[:num_executors]] if options[:num_executors]
          args += ["--conf", options[:spark_conf]] if options[:spark_conf]
          
          # Application and arguments
          args << spark_app_path
          args += options[:app_args] if options[:app_args]
          
          {
            name: name,
            action_on_failure: options[:action_on_failure] || "CONTINUE",
            hadoop_jar_step: {
              jar: "command-runner.jar",
              args: args
            }
          }
        end

        def self.hive_step(name, hive_script_path, options = {})
          args = ["hive-script"]
          args += ["--run-hive-script", "--args"]
          args += ["-f", hive_script_path]
          
          # Add variables
          if options[:variables]
            options[:variables].each do |key, value|
              args += ["-d", "#{key}=#{value}"]
            end
          end
          
          {
            name: name,
            action_on_failure: options[:action_on_failure] || "CONTINUE",
            hadoop_jar_step: {
              jar: "command-runner.jar",
              args: args
            }
          }
        end

        def self.pig_step(name, pig_script_path, options = {})
          args = ["pig-script"]
          args += ["--run-pig-script", "--args"]
          args += ["-f", pig_script_path]
          
          # Add parameters
          if options[:parameters]
            options[:parameters].each do |key, value|
              args += ["-p", "#{key}=#{value}"]
            end
          end
          
          {
            name: name,
            action_on_failure: options[:action_on_failure] || "CONTINUE",
            hadoop_jar_step: {
              jar: "command-runner.jar",
              args: args
            }
          }
        end

        def self.hadoop_streaming_step(name, mapper, reducer, input_path, output_path, options = {})
          args = ["hadoop-streaming"]
          args += ["-files", options[:files]] if options[:files]
          args += ["-mapper", mapper]
          args += ["-reducer", reducer]
          args += ["-input", input_path]
          args += ["-output", output_path]
          
          # Add additional arguments
          args += options[:additional_args] if options[:additional_args]
          
          {
            name: name,
            action_on_failure: options[:action_on_failure] || "CONTINUE",
            hadoop_jar_step: {
              jar: "command-runner.jar",
              args: args
            }
          }
        end

        def self.custom_jar_step(name, jar_path, main_class = nil, options = {})
          step_config = {
            name: name,
            action_on_failure: options[:action_on_failure] || "CONTINUE",
            hadoop_jar_step: {
              jar: jar_path
            }
          }
          
          step_config[:hadoop_jar_step][:main_class] = main_class if main_class
          step_config[:hadoop_jar_step][:args] = options[:args] if options[:args]
          step_config[:hadoop_jar_step][:properties] = options[:properties] if options[:properties]
          
          step_config
        end

        def self.debug_step(name, options = {})
          {
            name: name,
            action_on_failure: options[:action_on_failure] || "CONTINUE",
            hadoop_jar_step: {
              jar: "command-runner.jar",
              args: ["state-pusher-script"]
            }
          }
        end

        def self.s3_copy_step(name, source_path, dest_path, options = {})
          args = ["s3-dist-cp"]
          args += ["--src", source_path]
          args += ["--dest", dest_path]
          args += ["--srcPattern", options[:src_pattern]] if options[:src_pattern]
          args += ["--outputCodec", options[:output_codec]] if options[:output_codec]
          args += ["--groupBy", options[:group_by]] if options[:group_by]
          args += ["--targetSize", options[:target_size]] if options[:target_size]
          
          {
            name: name,
            action_on_failure: options[:action_on_failure] || "CONTINUE",
            hadoop_jar_step: {
              jar: "command-runner.jar",
              args: args
            }
          }
        end

        def self.distcp_step(name, source_path, dest_path, options = {})
          args = ["hadoop", "distcp"]
          args += ["-m", options[:num_mappers].to_s] if options[:num_mappers]
          args += ["-bandwidth", options[:bandwidth].to_s] if options[:bandwidth]
          args += ["--overwrite"] if options[:overwrite]
          args += ["--update"] if options[:update]
          args += [source_path, dest_path]
          
          {
            name: name,
            action_on_failure: options[:action_on_failure] || "CONTINUE", 
            hadoop_jar_step: {
              jar: "command-runner.jar",
              args: args
            }
          }
        end

        # Common step patterns
        def self.common_step_patterns
          {
            # Data processing patterns
            etl_processing: {
              description: "Extract, Transform, Load processing",
              typical_action: "CONTINUE",
              complexity: "medium"
            },
            
            data_validation: {
              description: "Data quality and validation checks", 
              typical_action: "CANCEL_AND_WAIT",
              complexity: "low"
            },
            
            model_training: {
              description: "Machine learning model training",
              typical_action: "CONTINUE",
              complexity: "high"
            },
            
            batch_analytics: {
              description: "Large-scale analytics processing",
              typical_action: "CONTINUE",
              complexity: "high"
            },
            
            data_movement: {
              description: "Data copying and movement operations",
              typical_action: "CANCEL_AND_WAIT",
              complexity: "low"
            },
            
            streaming_setup: {
              description: "Setup streaming processing infrastructure",
              typical_action: "TERMINATE_CLUSTER",
              complexity: "medium"
            }
          }
        end
      end
    end
      end
    end
  end
end