# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS IAM Role Policy Attachment resources
      class IamRolePolicyAttachmentAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        # Role name or ARN (required)
        attribute :role, Resources::Types::String

        # Policy ARN (required)
        attribute :policy_arn, Resources::Types::String

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate policy ARN format
          unless attrs.policy_arn.match?(/\Aarn:aws:iam::[0-9]{12}:policy\/.*\z/) || 
                 attrs.policy_arn.match?(/\Aarn:aws:iam::aws:policy\/.*\z/)
            raise Dry::Struct::Error, "policy_arn must be a valid IAM policy ARN"
          end

          # Validate role name/ARN format
          unless attrs.role.match?(/\A[a-zA-Z0-9+=,.@_-]+\z/) || # Role name format
                 attrs.role.match?(/\Aarn:aws:iam::[0-9]{12}:role\/.*\z/) # Role ARN format
            raise Dry::Struct::Error, "role must be a valid IAM role name or ARN"
          end

          attrs
        end

        # Check if policy is AWS managed
        def aws_managed_policy?
          policy_arn.include?("arn:aws:iam::aws:policy/")
        end

        # Check if policy is customer managed
        def customer_managed_policy?
          policy_arn.match?(/\Aarn:aws:iam::[0-9]{12}:policy\//)
        end

        # Extract policy name from ARN
        def policy_name
          policy_arn.split('/').last
        end

        # Extract account ID from policy ARN (for customer managed policies)
        def policy_account_id
          if customer_managed_policy?
            policy_arn.match(/arn:aws:iam::([0-9]{12}):policy\//)[1]
          else
            nil
          end
        end

        # Check if role is specified by name or ARN
        def role_specified_by_arn?
          role.start_with?('arn:aws:iam::')
        end

        # Extract role name from ARN if provided as ARN
        def role_name
          if role_specified_by_arn?
            role.split('/').last
          else
            role
          end
        end

        # Generate a unique attachment identifier
        def attachment_id
          "#{role_name}-#{policy_name}"
        end

        # Check for potentially dangerous policy attachments
        def potentially_dangerous?
          dangerous_policies = [
            "AdministratorAccess",
            "PowerUserAccess", 
            "IAMFullAccess",
            "AWSAccountManagementFullAccess",
            "SecurityAudit" # Can be risky if misused
          ]

          dangerous_policies.any? { |dangerous| policy_name.include?(dangerous) }
        end

        # Categorize policy type for better organization
        def policy_category
          case policy_name
          when /Admin/, /FullAccess/
            :administrative
          when /ReadOnly/, /ViewOnly/
            :read_only
          when /PowerUser/
            :power_user
          when /Service/
            :service_linked
          when /Lambda/, /EC2/, /S3/, /RDS/
            :service_specific
          else
            :custom
          end
        end

        # Security risk assessment
        def security_risk_level
          if potentially_dangerous?
            :high
          elsif policy_category == :administrative
            :high
          elsif policy_category == :power_user
            :medium
          elsif aws_managed_policy? && policy_category == :read_only
            :low
          elsif customer_managed_policy?
            :medium # Requires manual review
          else
            :low
          end
        end
      end

      # Common AWS managed policies for different use cases
      module AwsManagedPolicies
        # Administrative access
        ADMINISTRATOR_ACCESS = "arn:aws:iam::aws:policy/AdministratorAccess"
        POWER_USER_ACCESS = "arn:aws:iam::aws:policy/PowerUserAccess"
        IAM_FULL_ACCESS = "arn:aws:iam::aws:policy/IAMFullAccess"

        # Read-only access
        READ_ONLY_ACCESS = "arn:aws:iam::aws:policy/ReadOnlyAccess"
        SECURITY_AUDIT = "arn:aws:iam::aws:policy/SecurityAudit"

        # Service-specific policies
        module S3
          FULL_ACCESS = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
          READ_ONLY = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
        end

        module EC2
          FULL_ACCESS = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
          READ_ONLY = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
        end

        module RDS
          FULL_ACCESS = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
          READ_ONLY = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
        end

        module Lambda
          FULL_ACCESS = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
          READ_ONLY = "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
          BASIC_EXECUTION_ROLE = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
          VPC_ACCESS_EXECUTION_ROLE = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
        end

        module CloudWatch
          FULL_ACCESS = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
          READ_ONLY = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
          AGENT_SERVER_POLICY = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
        end

        module ECS
          TASK_EXECUTION_ROLE = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
          SERVICE_ROLE = "arn:aws:iam::aws:policy/service-role/AmazonECSServiceRolePolicy"
        end

        # Helper methods for policy organization
        def self.all_policies
          constants.map { |const| const_get(const) }.select { |val| val.is_a?(String) }
        end

        def self.service_policies
          {
            s3: S3,
            ec2: EC2,
            rds: RDS,
            lambda: Lambda,
            cloudwatch: CloudWatch,
            ecs: ECS
          }
        end

        def self.administrative_policies
          [ADMINISTRATOR_ACCESS, POWER_USER_ACCESS, IAM_FULL_ACCESS]
        end

        def self.read_only_policies
          [READ_ONLY_ACCESS, SECURITY_AUDIT]
        end
      end

      # Policy attachment patterns for common scenarios
      module AttachmentPatterns
        # Lambda execution role attachments
        def self.lambda_execution_role_policies
          [
            AwsManagedPolicies::Lambda::BASIC_EXECUTION_ROLE
          ]
        end

        # Lambda VPC execution role attachments
        def self.lambda_vpc_execution_role_policies
          [
            AwsManagedPolicies::Lambda::BASIC_EXECUTION_ROLE,
            AwsManagedPolicies::Lambda::VPC_ACCESS_EXECUTION_ROLE
          ]
        end

        # EC2 instance role attachments for basic functionality
        def self.ec2_instance_basic_policies
          [
            AwsManagedPolicies::CloudWatch::AGENT_SERVER_POLICY
          ]
        end

        # ECS task execution role attachments
        def self.ecs_task_execution_policies
          [
            AwsManagedPolicies::ECS::TASK_EXECUTION_ROLE
          ]
        end

        # Development environment policies (more permissive)
        def self.development_policies
          [
            AwsManagedPolicies::S3::FULL_ACCESS,
            AwsManagedPolicies::CloudWatch::FULL_ACCESS,
            AwsManagedPolicies::Lambda::FULL_ACCESS
          ]
        end

        # Production environment policies (more restrictive)
        def self.production_read_only_policies
          [
            AwsManagedPolicies::S3::READ_ONLY,
            AwsManagedPolicies::CloudWatch::READ_ONLY,
            AwsManagedPolicies::EC2::READ_ONLY
          ]
        end
      end
    end
      end
    end
  end
end