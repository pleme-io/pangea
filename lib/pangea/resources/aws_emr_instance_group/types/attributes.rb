# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        class EmrInstanceGroupAttributes < Dry::Struct
          attribute :name, Resources::Types::String.optional
          attribute :cluster_id, Resources::Types::String
          attribute :instance_role, Resources::Types::String.enum('MASTER', 'CORE', 'TASK')
          attribute :instance_type, Resources::Types::String
          attribute :instance_count, Resources::Types::Integer.constrained(gteq: 1).default(1)
          attribute :bid_price, Resources::Types::String.optional
          attribute :ebs_config, Resources::Types::Hash.optional
          attribute :auto_scaling_policy, Resources::Types::Hash.optional
          attribute :configurations, Resources::Types::Array.of(Resources::Types::Hash).default([].freeze)

          def self.new(attributes = {})
            attrs = super(attributes)
            raise Dry::Struct::Error, 'Cluster ID must be in format j-XXXXXXXXX' unless attrs.cluster_id =~ /\Aj-[A-Z0-9]{8,}\z/
            raise Dry::Struct::Error, 'Master instance group must have exactly 1 instance' if attrs.instance_role == 'MASTER' && attrs.instance_count != 1
            validate_auto_scaling(attrs) if attrs.auto_scaling_policy
            validate_ebs_config(attrs) if attrs.ebs_config&.dig(:ebs_block_device_config)
            attrs
          end

          def self.validate_auto_scaling(attrs)
            constraints = attrs.auto_scaling_policy[:constraints]
            raise Dry::Struct::Error, 'min_capacity cannot be greater than max_capacity' if constraints[:min_capacity] > constraints[:max_capacity]
            raise Dry::Struct::Error, 'Core instance group min_capacity must be at least 1' if attrs.instance_role == 'CORE' && constraints[:min_capacity] < 1
          end

          def self.validate_ebs_config(attrs)
            attrs.ebs_config[:ebs_block_device_config].each do |device_config|
              vol_spec = device_config[:volume_specification]
              raise Dry::Struct::Error, 'IOPS must be specified for io1 and io2 volume types' if %w[io1 io2].include?(vol_spec[:volume_type]) && !vol_spec[:iops]
              raise Dry::Struct::Error, 'IOPS can only be specified for io1, io2, and gp3 volume types' if vol_spec[:iops] && !%w[io1 io2 gp3].include?(vol_spec[:volume_type])
            end
          end

          def is_master? = instance_role == 'MASTER'
          def is_core? = instance_role == 'CORE'
          def is_task? = instance_role == 'TASK'
          def uses_spot_instances? = !bid_price.nil?
          def has_auto_scaling? = auto_scaling_policy && auto_scaling_policy[:rules]&.any?
          def is_ebs_optimized? = ebs_config&.dig(:ebs_optimized) || false

          def total_ebs_storage_gb_per_instance
            return 0 unless ebs_config&.dig(:ebs_block_device_config)
            ebs_config[:ebs_block_device_config].sum do |dc|
              dc[:volume_specification][:size_in_gb] * (dc[:volumes_per_instance] || 1)
            end
          end

          def scaling_capacity_range
            return { min: instance_count, max: instance_count } unless has_auto_scaling?
            c = auto_scaling_policy[:constraints]
            { min: c[:min_capacity], max: c[:max_capacity] }
          end

          def scaling_rules_summary
            return {} unless has_auto_scaling?
            rules = auto_scaling_policy[:rules]
            { total_rules: rules.size,
              scale_out_rules: rules.count { |r| r[:action][:simple_scaling_policy_configuration][:scaling_adjustment].positive? },
              scale_in_rules: rules.count { |r| r[:action][:simple_scaling_policy_configuration][:scaling_adjustment].negative? },
              metrics_used: rules.map { |r| r[:trigger][:cloud_watch_alarm_definition][:metric_name] }.uniq }
          end

          INSTANCE_COSTS = { 'm5.large' => 0.096, 'm5.xlarge' => 0.192, 'm5.2xlarge' => 0.384, 'c5.large' => 0.085, 'r5.large' => 0.126 }.freeze
          def estimated_hourly_cost_usd
            base = INSTANCE_COSTS[instance_type] || 0.20
            total = base * instance_count * (uses_spot_instances? ? 0.3 : 1)
            (total + total_ebs_storage_gb_per_instance * instance_count * 0.0001).round(4)
          end

          def configuration_warnings
            warnings = []
            warnings << 'Using spot instances for master node is not recommended for production' if is_master? && uses_spot_instances?
            warnings << 'Using spot instances for core nodes may cause data loss' if is_core? && uses_spot_instances?
            warnings << 'Auto scaling should typically only be used with task instance groups' if has_auto_scaling? && !is_task?
            warnings
          end
        end
      end
    end
  end
end
