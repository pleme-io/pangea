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
      # Type-safe attributes for AWS EMR Instance Group resources
      class EmrInstanceGroupAttributes < Dry::Struct
        # Instance group name
        attribute :name, Resources::Types::String.optional
        
        # Cluster ID (required)
        attribute :cluster_id, Resources::Types::String
        
        # Instance role (required)
        attribute :instance_role, Resources::Types::String.enum("MASTER", "CORE", "TASK")
        
        # Instance type (required)
        attribute :instance_type, Resources::Types::String
        
        # Instance count
        attribute :instance_count, Resources::Types::Integer.constrained(gteq: 1).default(1)
        
        # Bid price for spot instances
        attribute :bid_price, Resources::Types::String.optional
        
        # EBS configuration
        attribute :ebs_config, Resources::Types::Hash.schema(
          ebs_block_device_config?: Types::Array.of(
            Types::Hash.schema(
              volume_specification: Types::Hash.schema(
                volume_type: Types::String.enum("gp2", "gp3", "io1", "io2", "st1", "sc1"),
                size_in_gb: Types::Integer.constrained(gteq: 1),
                iops?: Types::Integer.constrained(gteq: 100).optional
              ),
              volumes_per_instance?: Types::Integer.constrained(gteq: 1, lteq: 23).optional
            )
          ).optional,
          ebs_optimized?: Types::Bool.optional
        ).optional
        
        # Auto scaling policy
        attribute :auto_scaling_policy, Resources::Types::Hash.schema(
          constraints: Types::Hash.schema(
            min_capacity: Types::Integer.constrained(gteq: 0),
            max_capacity: Types::Integer.constrained(gteq: 1)
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
                  cool_down?: Types::Integer.constrained(gteq: 0).optional
                )
              ),
              trigger: Types::Hash.schema(
                cloud_watch_alarm_definition: Types::Hash.schema(
                  comparison_operator: Types::String.enum("GREATER_THAN_OR_EQUAL", "GREATER_THAN", "LESS_THAN", "LESS_THAN_OR_EQUAL"),
                  evaluation_periods: Types::Integer.constrained(gteq: 1),
                  metric_name: Types::String,
                  namespace: Types::String,
                  period: Types::Integer.constrained(gteq: 60),
                  statistic?: Types::String.enum("SAMPLE_COUNT", "AVERAGE", "SUM", "MINIMUM", "MAXIMUM").optional,
                  threshold: Types::Float,
                  unit?: Types::String.optional,
                  dimensions?: Types::Hash.map(Types::String, Types::String).optional
                )
              )
            )
          ).default([].freeze)
        ).optional
        
        # Configurations for this instance group
        attribute :configurations, Resources::Types::Array.of(
          Types::Hash.schema(
            classification: Types::String,
            configurations?: Types::Array.of(Types::Hash).optional,
            properties?: Types::Hash.map(Types::String, Types::String).optional
          )
        ).default([].freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate cluster ID format
          unless attrs.cluster_id =~ /\Aj-[A-Z0-9]{8,}\z/
            raise Dry::Struct::Error, "Cluster ID must be in format j-XXXXXXXXX"
          end
          
          # Validate instance count for master role
          if attrs.instance_role == "MASTER" && attrs.instance_count != 1
            raise Dry::Struct::Error, "Master instance group must have exactly 1 instance"
          end
          
          # Validate auto scaling constraints
          if attrs.auto_scaling_policy
            constraints = attrs.auto_scaling_policy[:constraints]
            if constraints[:min_capacity] > constraints[:max_capacity]
              raise Dry::Struct::Error, "min_capacity cannot be greater than max_capacity"
            end
            
            # Task instances can scale to zero, but core cannot
            if attrs.instance_role == "CORE" && constraints[:min_capacity] < 1
              raise Dry::Struct::Error, "Core instance group min_capacity must be at least 1"
            end
          end
          
          # Validate EBS configuration
          if attrs.ebs_config&.dig(:ebs_block_device_config)
            attrs.ebs_config[:ebs_block_device_config].each do |device_config|
              vol_spec = device_config[:volume_specification]
              
              # Validate IOPS for io1/io2 volumes
              if %w[io1 io2].include?(vol_spec[:volume_type]) && !vol_spec[:iops]
                raise Dry::Struct::Error, "IOPS must be specified for io1 and io2 volume types"
              end
              
              if vol_spec[:iops] && !%w[io1 io2 gp3].include?(vol_spec[:volume_type])
                raise Dry::Struct::Error, "IOPS can only be specified for io1, io2, and gp3 volume types"
              end
              
              # Validate volume size constraints
              case vol_spec[:volume_type]
              when "gp2", "gp3"
                if vol_spec[:size_in_gb] < 1 || vol_spec[:size_in_gb] > 16384
                  raise Dry::Struct::Error, "GP2/GP3 volume size must be between 1 and 16384 GB"
                end
              when "io1", "io2"
                if vol_spec[:size_in_gb] < 4 || vol_spec[:size_in_gb] > 16384
                  raise Dry::Struct::Error, "IO1/IO2 volume size must be between 4 and 16384 GB"
                end
              end
            end
          end

          attrs
        end

        # Check if instance group is master
        def is_master?
          instance_role == "MASTER"
        end

        # Check if instance group is core
        def is_core?
          instance_role == "CORE"
        end

        # Check if instance group is task
        def is_task?
          instance_role == "TASK"
        end

        # Check if using spot instances
        def uses_spot_instances?
          !bid_price.nil?
        end

        # Check if auto scaling is enabled
        def has_auto_scaling?
          auto_scaling_policy && auto_scaling_policy[:rules].any?
        end

        # Check if EBS optimized
        def is_ebs_optimized?
          ebs_config&.dig(:ebs_optimized) || false
        end

        # Get total EBS storage per instance
        def total_ebs_storage_gb_per_instance
          return 0 unless ebs_config&.dig(:ebs_block_device_config)
          
          ebs_config[:ebs_block_device_config].sum do |device_config|
            vol_spec = device_config[:volume_specification]
            volumes_per_instance = device_config[:volumes_per_instance] || 1
            vol_spec[:size_in_gb] * volumes_per_instance
          end
        end

        # Get scaling capacity range
        def scaling_capacity_range
          return { min: instance_count, max: instance_count } unless has_auto_scaling?
          
          constraints = auto_scaling_policy[:constraints]
          { min: constraints[:min_capacity], max: constraints[:max_capacity] }
        end

        # Get scaling rules summary
        def scaling_rules_summary
          return {} unless has_auto_scaling?
          
          rules = auto_scaling_policy[:rules]
          {
            total_rules: rules.size,
            scale_out_rules: rules.count { |r| r[:action][:simple_scaling_policy_configuration][:scaling_adjustment] > 0 },
            scale_in_rules: rules.count { |r| r[:action][:simple_scaling_policy_configuration][:scaling_adjustment] < 0 },
            metrics_used: rules.map { |r| r[:trigger][:cloud_watch_alarm_definition][:metric_name] }.uniq
          }
        end

        # Estimate hourly cost for this instance group
        def estimated_hourly_cost_usd
          # Simplified cost estimation
          base_costs = {
            "m5.large" => 0.096,
            "m5.xlarge" => 0.192,
            "m5.2xlarge" => 0.384,
            "m5.4xlarge" => 0.768,
            "m5.12xlarge" => 2.304,
            "c5.large" => 0.085,
            "c5.xlarge" => 0.17,
            "c5.2xlarge" => 0.34,
            "c5.4xlarge" => 0.68,
            "r5.large" => 0.126,
            "r5.xlarge" => 0.252,
            "r5.2xlarge" => 0.504,
            "r5.4xlarge" => 1.008,
            "i3.large" => 0.156,
            "i3.xlarge" => 0.312,
            "i3.2xlarge" => 0.624
          }
          
          base_cost = base_costs[instance_type] || 0.20
          total_cost = base_cost * instance_count
          
          # Apply spot pricing discount
          if uses_spot_instances?
            total_cost *= 0.3 # Approximate 70% discount
          end
          
          # Add EBS costs
          ebs_cost_per_gb_hour = 0.0001 # Approximate GP3 cost
          ebs_cost = total_ebs_storage_gb_per_instance * instance_count * ebs_cost_per_gb_hour
          
          (total_cost + ebs_cost).round(4)
        end

        # Get configuration warnings
        def configuration_warnings
          warnings = []
          
          if is_master? && uses_spot_instances?
            warnings << "Using spot instances for master node is not recommended for production"
          end
          
          if is_core? && uses_spot_instances?
            warnings << "Using spot instances for core nodes may cause data loss"
          end
          
          if has_auto_scaling? && !is_task?
            warnings << "Auto scaling should typically only be used with task instance groups"
          end
          
          if instance_count > 1000
            warnings << "Very large instance group (>1000) may face AWS service limits"
          end
          
          if total_ebs_storage_gb_per_instance > 60000
            warnings << "Very large EBS storage (>60TB) per instance may impact performance"
          end
          
          if ebs_config&.dig(:ebs_block_device_config)&.size.to_i > 10
            warnings << "Large number of EBS volumes may impact instance performance"
          end
          
          warnings
        end

        # Helper method to create auto scaling rules
        def self.create_scale_out_rule(name, metric_name, threshold, scaling_adjustment = 2, options = {})
          {
            name: name,
            description: options[:description] || "Scale out based on #{metric_name}",
            action: {
              market: options[:market] || "ON_DEMAND",
              simple_scaling_policy_configuration: {
                adjustment_type: options[:adjustment_type] || "CHANGE_IN_CAPACITY",
                scaling_adjustment: scaling_adjustment,
                cool_down: options[:cool_down] || 300
              }
            },
            trigger: {
              cloud_watch_alarm_definition: {
                comparison_operator: "GREATER_THAN",
                evaluation_periods: options[:evaluation_periods] || 2,
                metric_name: metric_name,
                namespace: options[:namespace] || "AWS/ElasticMapReduce",
                period: options[:period] || 300,
                statistic: options[:statistic] || "AVERAGE",
                threshold: threshold.to_f,
                unit: options[:unit],
                dimensions: options[:dimensions] || {}
              }
            }
          }
        end

        def self.create_scale_in_rule(name, metric_name, threshold, scaling_adjustment = -1, options = {})
          {
            name: name,
            description: options[:description] || "Scale in based on #{metric_name}",
            action: {
              simple_scaling_policy_configuration: {
                adjustment_type: options[:adjustment_type] || "CHANGE_IN_CAPACITY",
                scaling_adjustment: scaling_adjustment,
                cool_down: options[:cool_down] || 600
              }
            },
            trigger: {
              cloud_watch_alarm_definition: {
                comparison_operator: "LESS_THAN",
                evaluation_periods: options[:evaluation_periods] || 3,
                metric_name: metric_name,
                namespace: options[:namespace] || "AWS/ElasticMapReduce",
                period: options[:period] || 300,
                statistic: options[:statistic] || "AVERAGE", 
                threshold: threshold.to_f,
                unit: options[:unit],
                dimensions: options[:dimensions] || {}
              }
            }
          }
        end

        # Helper method to create EBS configurations
        def self.create_ebs_config(volume_type, size_gb, options = {})
          volume_spec = {
            volume_type: volume_type,
            size_in_gb: size_gb
          }
          
          volume_spec[:iops] = options[:iops] if options[:iops]
          
          {
            ebs_optimized: options[:ebs_optimized].nil? ? true : options[:ebs_optimized],
            ebs_block_device_config: [
              {
                volume_specification: volume_spec,
                volumes_per_instance: options[:volumes_per_instance] || 1
              }
            ]
          }
        end

        # Common auto scaling configurations
        def self.common_auto_scaling_configs
          {
            # CPU-based scaling
            cpu_scaling: {
              constraints: { min_capacity: 1, max_capacity: 10 },
              rules: [
                create_scale_out_rule("ScaleOutOnHighCPU", "CPUUtilization", 75, 2),
                create_scale_in_rule("ScaleInOnLowCPU", "CPUUtilization", 25, -1)
              ]
            },
            
            # Memory-based scaling
            memory_scaling: {
              constraints: { min_capacity: 2, max_capacity: 20 },
              rules: [
                create_scale_out_rule("ScaleOutOnHighMemory", "MemoryPercentage", 80, 3),
                create_scale_in_rule("ScaleInOnLowMemory", "MemoryPercentage", 30, -2)
              ]
            },
            
            # YARN container-based scaling
            yarn_scaling: {
              constraints: { min_capacity: 1, max_capacity: 50 },
              rules: [
                create_scale_out_rule("ScaleOutOnPendingContainers", "ContainerPendingRatio", 0.3, 4),
                create_scale_in_rule("ScaleInOnAvailableCapacity", "YARNMemoryAvailablePercentage", 75, -2)
              ]
            }
          }
        end

        # Common EBS configurations
        def self.common_ebs_configs
          {
            # General purpose SSD
            standard_ssd: create_ebs_config("gp3", 100, { ebs_optimized: true }),
            large_ssd: create_ebs_config("gp3", 500, { ebs_optimized: true, volumes_per_instance: 2 }),
            
            # High IOPS storage
            high_iops: create_ebs_config("io2", 200, { iops: 10000, ebs_optimized: true }),
            
            # Throughput optimized
            throughput_optimized: create_ebs_config("st1", 1000, { ebs_optimized: true }),
            
            # Cold storage
            cold_storage: create_ebs_config("sc1", 2000, { ebs_optimized: false })
          }
        end
      end
    end
      end
    end
  end
end