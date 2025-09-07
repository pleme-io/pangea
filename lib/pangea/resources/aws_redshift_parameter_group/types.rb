# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Redshift Parameter Group resources
      class RedshiftParameterGroupAttributes < Dry::Struct
        # Parameter group name (required)
        attribute :name, Resources::Types::String
        
        # Parameter group family (required)
        attribute :family, Resources::Types::String.default("redshift-1.0")
        
        # Description
        attribute :description, Resources::Types::String.optional
        
        # Parameters
        attribute :parameters, Resources::Types::Array.of(
          Types::Hash.schema(
            name: Types::String,
            value: Types::String
          )
        ).default([].freeze)
        
        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate parameter group name format
          unless attrs.name =~ /\A[a-z][a-z0-9\-]*\z/
            raise Dry::Struct::Error, "Parameter group name must start with lowercase letter and contain only lowercase letters, numbers, and hyphens"
          end
          
          # Validate parameter group name length
          if attrs.name.length > 255
            raise Dry::Struct::Error, "Parameter group name must be 255 characters or less"
          end
          
          # Validate parameter names
          attrs.parameters.each do |param|
            unless param[:name] =~ /\A[a-z_]+\z/
              raise Dry::Struct::Error, "Parameter name '#{param[:name]}' must contain only lowercase letters and underscores"
            end
          end

          attrs
        end

        # Get parameter by name
        def parameter_value(name)
          param = parameters.find { |p| p[:name] == name }
          param ? param[:value] : nil
        end

        # Check if parameter exists
        def has_parameter?(name)
          parameters.any? { |p| p[:name] == name }
        end

        # Check if WLM is configured
        def has_wlm_configuration?
          has_parameter?("wlm_json_configuration")
        end

        # Check if query monitoring is enabled
        def query_monitoring_enabled?
          parameter_value("enable_user_activity_logging") == "true"
        end

        # Check if result caching is enabled
        def result_caching_enabled?
          parameter_value("enable_result_cache_for_session") != "false"
        end

        # Check if concurrency scaling is enabled
        def concurrency_scaling_enabled?
          max_clusters = parameter_value("max_concurrency_scaling_clusters")
          max_clusters && max_clusters.to_i > 0
        end

        # Get concurrency scaling limit
        def concurrency_scaling_limit
          max_clusters = parameter_value("max_concurrency_scaling_clusters")
          max_clusters ? max_clusters.to_i : 0
        end

        # Check if auto analyze is enabled
        def auto_analyze_enabled?
          parameter_value("auto_analyze") != "false"
        end

        # Generate description if not provided
        def generated_description
          description || "Redshift parameter group for #{name}"
        end

        # Estimate performance impact of parameters
        def performance_impact_score
          score = 1.0
          
          # Positive impacts
          score *= 1.2 if result_caching_enabled?
          score *= 1.3 if concurrency_scaling_enabled?
          score *= 1.1 if auto_analyze_enabled?
          
          # Check for performance-related parameters
          if has_parameter?("statement_timeout")
            timeout = parameter_value("statement_timeout").to_i
            score *= 0.9 if timeout > 0 && timeout < 300000 # Less than 5 minutes
          end
          
          score.round(2)
        end

        # Common parameter sets for different workloads
        def self.parameters_for_workload(workload)
          case workload.to_s
          when "etl"
            [
              { name: "max_concurrency_scaling_clusters", value: "1" },
              { name: "enable_user_activity_logging", value: "true" },
              { name: "statement_timeout", value: "0" }, # No timeout for ETL
              { name: "query_group", value: "etl" },
              { name: "enable_result_cache_for_session", value: "true" },
              { name: "auto_analyze", value: "true" },
              { name: "datestyle", value: "ISO, MDY" },
              { name: "extra_float_digits", value: "0" }
            ]
          when "analytics"
            [
              { name: "max_concurrency_scaling_clusters", value: "3" },
              { name: "enable_user_activity_logging", value: "true" },
              { name: "statement_timeout", value: "600000" }, # 10 minutes
              { name: "query_group", value: "analytics" },
              { name: "enable_result_cache_for_session", value: "true" },
              { name: "search_path", value: "analytics,public" },
              { name: "require_ssl", value: "true" }
            ]
          when "reporting"
            [
              { name: "max_concurrency_scaling_clusters", value: "2" },
              { name: "enable_user_activity_logging", value: "true" },
              { name: "statement_timeout", value: "300000" }, # 5 minutes
              { name: "query_group", value: "reporting" },
              { name: "enable_result_cache_for_session", value: "true" },
              { name: "use_fips_ssl", value: "true" }
            ]
          when "mixed"
            [
              { name: "max_concurrency_scaling_clusters", value: "2" },
              { name: "enable_user_activity_logging", value: "true" },
              { name: "auto_analyze", value: "true" },
              { name: "enable_result_cache_for_session", value: "true" }
            ]
          else
            []
          end
        end

        # WLM configuration helper
        def self.wlm_configuration(queues)
          config = queues.map do |queue|
            {
              query_group: queue[:name],
              memory_percent_to_use: queue[:memory_percent] || 25,
              max_execution_time: queue[:timeout_ms] || 0,
              user_group: queue[:user_group] || [],
              query_group_wild_card: queue[:wildcard] || 0,
              priority: queue[:priority] || "normal"
            }
          end
          
          { name: "wlm_json_configuration", value: JSON.generate(config) }
        end

        # Query monitoring rules helper
        def self.query_monitoring_rules(rules)
          config = rules.map do |rule|
            {
              rule_name: rule[:name],
              predicate: rule[:conditions],
              action: rule[:action] || "log",
              priority: rule[:priority] || 1
            }
          end
          
          { name: "query_monitoring_rules", value: JSON.generate(config) }
        end
      end
    end
      end
    end
  end
end