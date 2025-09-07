# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Components
    module AutoScalingWebServers
      # Block device mapping for EBS volumes
      class BlockDeviceMapping < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :device_name, Types::String.default("/dev/xvda")
        attribute :volume_type, Types::EbsVolumeType.default("gp3")
        attribute :volume_size, Types::Integer.default(20).constrained(gteq: 8, lteq: 16384)
        attribute :iops, Types::Integer.optional.constrained(gteq: 100, lteq: 16000)
        attribute :throughput, Types::Integer.optional.constrained(gteq: 125, lteq: 1000)
        attribute :encrypted, Types::Bool.default(true)
        attribute :delete_on_termination, Types::Bool.default(true)
      end
      
      # Scaling policy configuration
      class ScalingPolicyConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :policy_type, Types::String.default("TargetTrackingScaling").enum('StepScaling', 'TargetTrackingScaling', 'SimpleScaling')
        attribute :target_value, Types::Coercible::Float.optional.constrained(gt: 0)
        attribute :metric_type, Types::String.default("ASGAverageCPUUtilization").enum('ASGAverageCPUUtilization', 'ASGAverageNetworkIn', 'ASGAverageNetworkOut', 'ALBRequestCountPerTarget')
        attribute :scale_out_cooldown, Types::Integer.default(300).constrained(gteq: 0, lteq: 3600)
        attribute :scale_in_cooldown, Types::Integer.default(300).constrained(gteq: 0, lteq: 3600)
        attribute :disable_scale_in, Types::Bool.default(false)
        
        # For ALB request count per target metric
        attribute :target_group_arn, Types::String.optional
        
        # For step scaling policies
        attribute :adjustment_type, Types::String.optional.enum('ChangeInCapacity', 'ExactCapacity', 'PercentChangeInCapacity')
        attribute :step_adjustments, Types::Array.optional.default([].freeze)
        attribute :min_adjustment_magnitude, Types::Integer.optional
        
        # For simple scaling policies
        attribute :scaling_adjustment, Types::Integer.optional
      end
      
      # Monitoring configuration
      class MonitoringConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :granularity, Types::String.default("1Minute").enum('1Minute')
        attribute :enabled_metrics, Types::Array.of(Types::String).default([
          "GroupMinSize",
          "GroupMaxSize", 
          "GroupDesiredCapacity",
          "GroupInServiceInstances",
          "GroupTotalInstances",
          "GroupPendingInstances",
          "GroupStandbyInstances",
          "GroupTerminatingInstances"
        ].freeze)
      end
      
      # Main Auto Scaling Web Servers component attributes
      class AutoScalingWebServersAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        # Network configuration
        attribute :vpc_ref, Types.Instance(Object)  # ResourceReference to VPC
        attribute :subnet_refs, Types::Array.of(Types.Instance(Object)).constrained(min_size: 1)  # ResourceReferences to subnets
        attribute :security_group_refs, Types::Array.of(Types.Instance(Object)).default([].freeze)  # ResourceReferences to security groups
        
        # Instance configuration
        attribute :ami_id, Types::String.constrained(format: /\Aami-[a-f0-9]{8,17}\z/)
        attribute :instance_type, Types::Ec2InstanceType.default("t3.micro")
        attribute :key_name, Types::String.optional
        attribute :iam_instance_profile, Types::String.optional
        
        # User data script for instance initialization
        attribute :user_data, Types::String.optional
        attribute :user_data_base64, Types::String.optional
        
        # Auto Scaling configuration
        attribute :min_size, Types::Integer.default(1).constrained(gteq: 0, lteq: 1000)
        attribute :max_size, Types::Integer.default(3).constrained(gteq: 1, lteq: 1000)
        attribute :desired_capacity, Types::Integer.optional.constrained(gteq: 0, lteq: 1000)
        attribute :default_cooldown, Types::Integer.default(300).constrained(gteq: 0, lteq: 7200)
        
        # Health check configuration
        attribute :health_check_type, Types::String.default("EC2").enum('EC2', 'ELB')
        attribute :health_check_grace_period, Types::Integer.default(300).constrained(gteq: 0, lteq: 7200)
        
        # Load balancer integration
        attribute :target_group_refs, Types::Array.of(Types.Instance(Object)).default([].freeze)  # ResourceReferences to target groups
        attribute :load_balancer_names, Types::Array.of(Types::String).default([].freeze)  # Classic ELB names
        
        # Storage configuration
        attribute :block_device_mappings, Types::Array.of(BlockDeviceMapping).default([
          BlockDeviceMapping.new(device_name: "/dev/xvda")
        ].freeze)
        
        # Scaling policies
        attribute :enable_cpu_scaling, Types::Bool.default(true)
        attribute :cpu_target_value, Types::Coercible::Float.default(70.0).constrained(gteq: 1.0, lteq: 100.0)
        attribute :scaling_policies, Types::Array.of(ScalingPolicyConfig).default([].freeze)
        
        # Instance placement
        attribute :availability_zones, Types::Array.of(Types::String).optional
        attribute :placement_group, Types::String.optional
        
        # Termination policies
        attribute :termination_policies, Types::Array.of(Types::String).default([
          "Default"
        ].freeze).constructor { |value|
          valid_policies = [
            "Default", "OldestInstance", "NewestInstance", "OldestLaunchConfiguration",
            "OldestLaunchTemplate", "ClosestToNextInstanceHour", "AllocationStrategy"
          ]
          invalid_policies = value - valid_policies
          unless invalid_policies.empty?
            raise Dry::Types::ConstraintError, "Invalid termination policies: #{invalid_policies.join(', ')}"
          end
          value
        }
        
        # Instance protection
        attribute :protect_from_scale_in, Types::Bool.default(false)
        
        # Monitoring
        attribute :monitoring, MonitoringConfig.default({})
        
        # Tags
        attribute :tags, Types::AwsTags.default({}.freeze)
        
        # Auto Scaling group tags (different from resource tags)
        attribute :asg_tags, Types::Hash.default({}.freeze)
        attribute :propagate_at_launch, Types::Bool.default(true)
        
        # Instance metadata service configuration
        attribute :metadata_options, Types::Hash.default({
          http_endpoint: "enabled",
          http_tokens: "required",
          http_put_response_hop_limit: 1,
          instance_metadata_tags: "enabled"
        }.freeze)
        
        # Mixed instances policy for cost optimization
        attribute :enable_mixed_instances, Types::Bool.default(false)
        attribute :mixed_instances_policy, Types::Hash.optional
        
        # Warm pool configuration
        attribute :enable_warm_pool, Types::Bool.default(false)
        attribute :warm_pool_config, Types::Hash.optional
        
        # Service-linked role
        attribute :service_linked_role_arn, Types::String.optional.constrained(format: /\Aarn:aws:iam::\d{12}:role\/aws-service-role\/autoscaling\.amazonaws\.com\/AWSServiceRoleForAutoScaling/)
        
        # Lifecycle hooks
        attribute :lifecycle_hooks, Types::Array.default([].freeze)
      end
    end
  end
end