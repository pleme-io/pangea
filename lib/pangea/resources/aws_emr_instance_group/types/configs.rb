# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module EmrInstanceGroupConfigs
          def self.create_scale_out_rule(name, metric_name, threshold, scaling_adjustment = 2, options = {})
            { name: name, description: options[:description] || "Scale out based on #{metric_name}",
              action: { market: options[:market] || 'ON_DEMAND',
                        simple_scaling_policy_configuration: { adjustment_type: options[:adjustment_type] || 'CHANGE_IN_CAPACITY',
                                                               scaling_adjustment: scaling_adjustment, cool_down: options[:cool_down] || 300 } },
              trigger: { cloud_watch_alarm_definition: { comparison_operator: 'GREATER_THAN', evaluation_periods: options[:evaluation_periods] || 2,
                                                          metric_name: metric_name, namespace: options[:namespace] || 'AWS/ElasticMapReduce',
                                                          period: options[:period] || 300, statistic: options[:statistic] || 'AVERAGE',
                                                          threshold: threshold.to_f, unit: options[:unit], dimensions: options[:dimensions] || {} } } }
          end

          def self.create_scale_in_rule(name, metric_name, threshold, scaling_adjustment = -1, options = {})
            { name: name, description: options[:description] || "Scale in based on #{metric_name}",
              action: { simple_scaling_policy_configuration: { adjustment_type: options[:adjustment_type] || 'CHANGE_IN_CAPACITY',
                                                               scaling_adjustment: scaling_adjustment, cool_down: options[:cool_down] || 600 } },
              trigger: { cloud_watch_alarm_definition: { comparison_operator: 'LESS_THAN', evaluation_periods: options[:evaluation_periods] || 3,
                                                          metric_name: metric_name, namespace: options[:namespace] || 'AWS/ElasticMapReduce',
                                                          period: options[:period] || 300, statistic: options[:statistic] || 'AVERAGE',
                                                          threshold: threshold.to_f, unit: options[:unit], dimensions: options[:dimensions] || {} } } }
          end

          def self.create_ebs_config(volume_type, size_gb, options = {})
            vol_spec = { volume_type: volume_type, size_in_gb: size_gb }
            vol_spec[:iops] = options[:iops] if options[:iops]
            { ebs_optimized: options[:ebs_optimized].nil? ? true : options[:ebs_optimized],
              ebs_block_device_config: [{ volume_specification: vol_spec, volumes_per_instance: options[:volumes_per_instance] || 1 }] }
          end

          def self.common_auto_scaling_configs
            {
              cpu_scaling: { constraints: { min_capacity: 1, max_capacity: 10 },
                             rules: [create_scale_out_rule('ScaleOutOnHighCPU', 'CPUUtilization', 75, 2),
                                     create_scale_in_rule('ScaleInOnLowCPU', 'CPUUtilization', 25, -1)] },
              memory_scaling: { constraints: { min_capacity: 2, max_capacity: 20 },
                                rules: [create_scale_out_rule('ScaleOutOnHighMemory', 'MemoryPercentage', 80, 3),
                                        create_scale_in_rule('ScaleInOnLowMemory', 'MemoryPercentage', 30, -2)] },
              yarn_scaling: { constraints: { min_capacity: 1, max_capacity: 50 },
                              rules: [create_scale_out_rule('ScaleOutOnPendingContainers', 'ContainerPendingRatio', 0.3, 4),
                                      create_scale_in_rule('ScaleInOnAvailableCapacity', 'YARNMemoryAvailablePercentage', 75, -2)] }
            }
          end

          def self.common_ebs_configs
            { standard_ssd: create_ebs_config('gp3', 100, ebs_optimized: true),
              large_ssd: create_ebs_config('gp3', 500, ebs_optimized: true, volumes_per_instance: 2),
              high_iops: create_ebs_config('io2', 200, iops: 10_000, ebs_optimized: true),
              throughput_optimized: create_ebs_config('st1', 1000, ebs_optimized: true),
              cold_storage: create_ebs_config('sc1', 2000, ebs_optimized: false) }
          end
        end
      end
    end
  end
end
