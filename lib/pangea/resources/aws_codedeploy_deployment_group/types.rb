# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS CodeDeploy Deployment Group resources
      class CodeDeployDeploymentGroupAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Application name (required)
        attribute :app_name, Resources::Types::String

        # Deployment group name (required)
        attribute :deployment_group_name, Resources::Types::String.constrained(
          format: /\A[a-zA-Z0-9._-]+\z/,
          min_size: 1,
          max_size: 100
        )

        # Service role ARN (required)
        attribute :service_role_arn, Resources::Types::String

        # Deployment configuration name
        attribute :deployment_config_name, Resources::Types::String.default('CodeDeployDefault.OneAtATime')

        # EC2 tag filters (for EC2/Server platform)
        attribute :ec2_tag_filters, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            type?: Resources::Types::String.enum('KEY_ONLY', 'VALUE_ONLY', 'KEY_AND_VALUE').optional,
            key?: Resources::Types::String.optional,
            value?: Resources::Types::String.optional
          )
        ).default([])

        # On-premises instance tag filters
        attribute :on_premises_instance_tag_filters, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            type?: Resources::Types::String.enum('KEY_ONLY', 'VALUE_ONLY', 'KEY_AND_VALUE').optional,
            key?: Resources::Types::String.optional,
            value?: Resources::Types::String.optional
          )
        ).default([])

        # Auto Scaling Groups
        attribute :auto_scaling_groups, Resources::Types::Array.of(Resources::Types::String).default([])

        # Trigger configurations
        attribute :trigger_configurations, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            trigger_name: Resources::Types::String,
            trigger_target_arn: Resources::Types::String,
            trigger_events: Resources::Types::Array.of(
              Resources::Types::String.enum(
                'DeploymentStart', 'DeploymentSuccess', 'DeploymentFailure',
                'DeploymentStop', 'DeploymentRollback', 'DeploymentReady',
                'InstanceStart', 'InstanceSuccess', 'InstanceFailure',
                'InstanceReady'
              )
            )
          )
        ).default([])

        # Auto rollback configuration
        attribute :auto_rollback_configuration, Resources::Types::Hash.schema(
          enabled?: Resources::Types::Bool.optional,
          events?: Resources::Types::Array.of(
            Resources::Types::String.enum('DEPLOYMENT_FAILURE', 'DEPLOYMENT_STOP_ON_ALARM', 'DEPLOYMENT_STOP_ON_REQUEST')
          ).optional
        ).default({})

        # Alarm configuration
        attribute :alarm_configuration, Resources::Types::Hash.schema(
          alarms?: Resources::Types::Array.of(Resources::Types::String).optional,
          enabled?: Resources::Types::Bool.optional,
          ignore_poll_alarm_failure?: Resources::Types::Bool.optional
        ).default({})

        # Blue-green deployment configuration
        attribute :blue_green_deployment_config, Resources::Types::Hash.schema(
          terminate_blue_instances_on_deployment_success?: Resources::Types::Hash.schema(
            action?: Resources::Types::String.enum('TERMINATE', 'KEEP_ALIVE').optional,
            termination_wait_time_in_minutes?: Resources::Types::Integer.constrained(gteq: 0, lteq: 2880).optional
          ).optional,
          deployment_ready_option?: Resources::Types::Hash.schema(
            action_on_timeout?: Resources::Types::String.enum('CONTINUE_DEPLOYMENT', 'STOP_DEPLOYMENT').optional
          ).optional,
          green_fleet_provisioning_option?: Resources::Types::Hash.schema(
            action?: Resources::Types::String.enum('DISCOVER_EXISTING', 'COPY_AUTO_SCALING_GROUP').optional
          ).optional
        ).default({})

        # Load balancer info
        attribute :load_balancer_info, Resources::Types::Hash.schema(
          elb_info?: Resources::Types::Array.of(
            Resources::Types::Hash.schema(name?: Resources::Types::String.optional)
          ).optional,
          target_group_info?: Resources::Types::Array.of(
            Resources::Types::Hash.schema(name?: Resources::Types::String.optional)
          ).optional,
          target_group_pair_info?: Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              prod_traffic_route?: Resources::Types::Hash.schema(
                listener_arns?: Resources::Types::Array.of(Resources::Types::String).optional
              ).optional,
              test_traffic_route?: Resources::Types::Hash.schema(
                listener_arns?: Resources::Types::Array.of(Resources::Types::String).optional
              ).optional,
              target_groups?: Resources::Types::Array.of(
                Resources::Types::Hash.schema(name?: Resources::Types::String.optional)
              ).optional
            )
          ).optional
        ).default({})

        # ECS service configuration
        attribute :ecs_service, Resources::Types::Hash.schema(
          cluster_name?: Resources::Types::String.optional,
          service_name?: Resources::Types::String.optional
        ).default({})

        # Deployment style
        attribute :deployment_style, Resources::Types::Hash.schema(
          deployment_type?: Resources::Types::String.enum('IN_PLACE', 'BLUE_GREEN').optional,
          deployment_option?: Resources::Types::String.enum('WITH_TRAFFIC_CONTROL', 'WITHOUT_TRAFFIC_CONTROL').optional
        ).default({})

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate EC2 tag filters
          attrs.ec2_tag_filters.each do |filter|
            case filter[:type]
            when 'KEY_ONLY'
              raise Dry::Struct::Error, "KEY_ONLY filter requires 'key' to be specified" unless filter[:key]
            when 'VALUE_ONLY'
              raise Dry::Struct::Error, "VALUE_ONLY filter requires 'value' to be specified" unless filter[:value]
            when 'KEY_AND_VALUE'
              raise Dry::Struct::Error, "KEY_AND_VALUE filter requires both 'key' and 'value'" unless filter[:key] && filter[:value]
            end
          end

          # Validate blue-green configuration
          if attrs.deployment_style[:deployment_type] == 'BLUE_GREEN' && attrs.blue_green_deployment_config.empty?
            raise Dry::Struct::Error, "Blue-green deployment requires blue_green_deployment_config"
          end

          # Validate load balancer configuration for blue-green
          if attrs.deployment_style[:deployment_type] == 'BLUE_GREEN'
            unless attrs.load_balancer_info[:elb_info] || attrs.load_balancer_info[:target_group_info] || attrs.load_balancer_info[:target_group_pair_info]
              raise Dry::Struct::Error, "Blue-green deployment requires load balancer configuration"
            end
          end

          # Validate ECS service configuration
          if attrs.ecs_service[:cluster_name] && !attrs.ecs_service[:service_name]
            raise Dry::Struct::Error, "ECS service configuration requires both cluster_name and service_name"
          end

          attrs
        end

        # Helper methods
        def uses_ec2_tags?
          ec2_tag_filters.any?
        end

        def uses_on_premises_tags?
          on_premises_instance_tag_filters.any?
        end

        def uses_auto_scaling?
          auto_scaling_groups.any?
        end

        def has_triggers?
          trigger_configurations.any?
        end

        def auto_rollback_enabled?
          auto_rollback_configuration[:enabled] == true
        end

        def uses_alarms?
          alarm_configuration[:enabled] == true && alarm_configuration[:alarms]&.any?
        end

        def blue_green_deployment?
          deployment_style[:deployment_type] == 'BLUE_GREEN'
        end

        def in_place_deployment?
          deployment_style[:deployment_type] == 'IN_PLACE' || deployment_style[:deployment_type].nil?
        end

        def uses_load_balancer?
          load_balancer_info[:elb_info]&.any? || 
          load_balancer_info[:target_group_info]&.any? ||
          load_balancer_info[:target_group_pair_info]&.any?
        end

        def ecs_deployment?
          ecs_service[:cluster_name].present?
        end

        def traffic_control_enabled?
          deployment_style[:deployment_option] == 'WITH_TRAFFIC_CONTROL'
        end

        def deployment_target_type
          if uses_ec2_tags?
            'EC2 instances (tag-based)'
          elsif uses_auto_scaling?
            'Auto Scaling groups'
          elsif uses_on_premises_tags?
            'On-premises instances'
          elsif ecs_deployment?
            'ECS service'
          else
            'Unknown'
          end
        end
      end
    end
      end
    end
  end
end