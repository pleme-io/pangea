# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS EMR Step resources
        class EmrStepAttributes < Dry::Struct
          attribute :name, Resources::Types::String
          attribute :cluster_id, Resources::Types::String
          attribute :action_on_failure, Resources::Types::String.enum("TERMINATE_JOB_FLOW", "TERMINATE_CLUSTER", "CANCEL_AND_WAIT", "CONTINUE")
          attribute :hadoop_jar_step, Resources::Types::Hash.schema(
            jar: Types::String,
            main_class?: Types::String.optional,
            args?: Types::Array.of(Types::String).optional,
            properties?: Types::Hash.map(Types::String, Types::String).optional
          )
          attribute :description, Resources::Types::String.optional
          attribute :step_concurrency_level, Resources::Types::Integer.constrained(gteq: 1, lteq: 256).optional

          def self.new(attributes = {})
            attrs = super(attributes)

            unless attrs.name =~ /\A[a-zA-Z_][a-zA-Z0-9_\s-]*\z/
              raise Dry::Struct::Error, "Step name must start with letter or underscore and contain only alphanumeric characters, spaces, underscores, and hyphens"
            end

            raise Dry::Struct::Error, "Step name must be 256 characters or less" if attrs.name.length > 256
            raise Dry::Struct::Error, "Cluster ID must be in format j-XXXXXXXXX" unless attrs.cluster_id =~ /\Aj-[A-Z0-9]{8,}\z/

            jar_path = attrs.hadoop_jar_step[:jar]
            unless jar_path.match(/\A(s3:\/\/|command-runner\.jar|\/|hdfs:\/\/)/)
              raise Dry::Struct::Error, "JAR path must be S3 URL, command-runner.jar, local path, or HDFS path"
            end

            attrs
          end

          def uses_command_runner? = hadoop_jar_step[:jar] == "command-runner.jar"
          def uses_s3_jar? = hadoop_jar_step[:jar].start_with?("s3://")
          def has_custom_main_class? = !hadoop_jar_step[:main_class].nil?
          def argument_count = hadoop_jar_step[:args]&.size || 0
          def property_count = hadoop_jar_step[:properties]&.size || 0

          def step_type
            jar = hadoop_jar_step[:jar]
            args = hadoop_jar_step[:args] || []

            case jar
            when "command-runner.jar"
              return "spark" if args.first&.include?("spark-submit")
              return "hadoop" if args.first&.include?("hadoop")
              return "hive" if args.first&.include?("hive")
              return "pig" if args.first&.include?("pig")
              "command_runner"
            when /spark/i then "spark"
            when /hadoop/i then "hadoop"
            when /hive/i then "hive"
            when /pig/i then "pig"
            else "custom_jar"
            end
          end

          def is_likely_long_running?
            %w[spark hive pig].include?(step_type) ||
              (hadoop_jar_step[:args] || []).any? { |arg| arg.match?(/-D.*streaming|--streaming/) }
          end

          def complexity_score
            score = 1 + argument_count * 0.1 + property_count * 0.2
            score += 2 if has_custom_main_class?
            score += 1 if uses_s3_jar?
            score += 3 if is_likely_long_running?
            score.round(1)
          end

          def configuration_warnings
            warnings = []
            warnings << "TERMINATE_CLUSTER action may be too aggressive for short-running steps" if action_on_failure == "TERMINATE_CLUSTER" && !is_likely_long_running?
            warnings << "CONTINUE action may allow long-running failed steps to waste resources" if action_on_failure == "CONTINUE" && is_likely_long_running?
            warnings << "Large number of arguments (>50) may indicate overly complex step" if argument_count > 50
            warnings << "S3 JAR path should end with .jar extension" if uses_s3_jar? && !hadoop_jar_step[:jar].match?(/\.jar$/)
            warnings << "Spark steps should specify memory configuration for optimal performance" if step_type == "spark" && !(hadoop_jar_step[:args] || []).any? { |arg| arg.match?(/--driver-memory|--executor-memory/) }
            warnings
          end
        end
      end
    end
  end
end
