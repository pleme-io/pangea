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
      # Type-safe attributes for AWS IAM Policy resources
      class IamPolicyAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        # Policy name (required)
        attribute :name, Resources::Types::String

        # Path for the policy (default: "/")
        attribute :path, Resources::Types::String.default("/")

        # Description of the policy
        attribute :description, Resources::Types::String.optional

        # Policy document (required)
        # Can be a Hash representing the policy document structure
        attribute :policy, Resources::Types::Hash.schema(
          Version: Types::String.default("2012-10-17"),
          Statement: Types::Array.of(
            Types::Hash.schema(
              Sid?: Types::String.optional,
              Effect: Types::String.enum("Allow", "Deny"),
              Action: Types::String | Types::Array.of(Types::String),
              Resource: Types::String | Types::Array.of(Types::String),
              Condition?: Types::Hash.optional,
              Principal?: Types::Hash.optional,
              NotAction?: Types::String | Types::Array.of(Types::String),
              NotResource?: Types::String | Types::Array.of(Types::String),
              NotPrincipal?: Types::Hash.optional
            )
          )
        )

        # Tags to apply to the policy
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate policy name meets IAM requirements
          if attrs.name.length > 128
            raise Dry::Struct::Error, "Policy name cannot exceed 128 characters"
          end

          # Validate path format
          unless attrs.path.match?(/\A\/[\w+=,.@-]*\/?\z/)
            raise Dry::Struct::Error, "Path must start and end with '/' and contain only valid characters"
          end

          if attrs.path.length > 512
            raise Dry::Struct::Error, "Path cannot exceed 512 characters"
          end

          # Validate policy document has at least one statement
          if attrs.policy[:Statement].empty?
            raise Dry::Struct::Error, "Policy document must have at least one statement"
          end

          # Check for overly permissive policies
          attrs.validate_policy_security!

          # Validate policy document size (6144 chars for managed policies)
          policy_json = JSON.generate(attrs.policy)
          if policy_json.length > 6144
            raise Dry::Struct::Error, "Policy document cannot exceed 6144 characters"
          end

          attrs
        end

        # Check if policy name uses AWS reserved patterns
        def uses_reserved_name?
          name.start_with?('AWS') || name.include?('Amazon')
        end

        # Extract all actions from policy statements
        def all_actions
          policy[:Statement].flat_map do |statement|
            actions = statement[:Action]
            actions.is_a?(Array) ? actions : [actions]
          end.uniq
        end

        # Extract all resources from policy statements
        def all_resources
          policy[:Statement].flat_map do |statement|
            resources = statement[:Resource]
            resources.is_a?(Array) ? resources : [resources]
          end.uniq
        end

        # Check if policy allows specific action
        def allows_action?(action)
          policy[:Statement].any? do |statement|
            statement[:Effect] == "Allow" &&
              (statement[:Action] == action || 
               (statement[:Action].is_a?(Array) && statement[:Action].include?(action)) ||
               statement[:Action] == "*" ||
               (statement[:Action].is_a?(String) && statement[:Action].end_with?("*") && action.start_with?(statement[:Action][0...-1])))
          end
        end

        # Check if policy has wildcard permissions
        def has_wildcard_permissions?
          policy[:Statement].any? do |statement|
            statement[:Effect] == "Allow" &&
              (statement[:Action] == "*" || statement[:Resource] == "*")
          end
        end

        # Get policy security level
        def security_level
          if has_wildcard_permissions?
            :high_risk
          elsif allows_action?("iam:*") || allows_action?("sts:AssumeRole")
            :medium_risk
          else
            :low_risk
          end
        end

        # Validate policy for security best practices
        def validate_policy_security!
          warnings = []

          # Check for wildcard permissions
          if has_wildcard_permissions?
            warnings << "Policy contains wildcard (*) permissions - consider principle of least privilege"
          end

          # Check for dangerous IAM actions
          dangerous_actions = ["iam:*", "iam:CreateRole", "iam:AttachRolePolicy", "iam:PutRolePolicy"]
          dangerous_actions.each do |action|
            if allows_action?(action)
              warnings << "Policy allows potentially dangerous action: #{action}"
            end
          end

          # Check for root resource access
          if all_resources.any? { |r| r.end_with?(":root") || r == "*" }
            warnings << "Policy grants access to root resources - review necessity"
          end

          # Log warnings but don't fail validation
          unless warnings.empty?
            puts "IAM Policy Security Warnings for '#{name}':"
            warnings.each { |warning| puts "  - #{warning}" }
          end
        end

        # Calculate policy complexity score
        def complexity_score
          statements_count = policy[:Statement].length
          actions_count = all_actions.length
          resources_count = all_resources.length
          conditions_count = policy[:Statement].count { |s| s[:Condition] }
          
          statements_count + actions_count + resources_count + (conditions_count * 2)
        end

        # Check if policy is for a service role
        def service_role_policy?
          all_actions.any? { |action| action.start_with?('sts:AssumeRole') }
        end
      end

      # Common IAM policy document structure
      class IamPolicyDocument < Dry::Struct
        attributeVersion :, Resources::Types::String.default("2012-10-17")
        attributeStatement :, Resources::Types::Array.of(
          Types::Hash.schema(
            Sid?: Types::String.optional,
            Effect: Types::String.enum("Allow", "Deny"),
            Action: Types::String | Types::Array.of(Types::String),
            Resource: Types::String | Types::Array.of(Types::String),
            Condition?: Types::Hash.optional
          )
        )
      end

      # Pre-defined IAM policies for common scenarios
      module PolicyTemplates
        # Read-only S3 access for a specific bucket
        def self.s3_bucket_readonly(bucket_name)
          {
            Version: "2012-10-17",
            Statement: [
              {
                Effect: "Allow",
                Action: ["s3:GetObject", "s3:GetObjectVersion"],
                Resource: "arn:aws:s3:::#{bucket_name}/*"
              },
              {
                Effect: "Allow",
                Action: ["s3:ListBucket"],
                Resource: "arn:aws:s3:::#{bucket_name}"
              }
            ]
          }
        end

        # Full S3 access for a specific bucket
        def self.s3_bucket_fullaccess(bucket_name)
          {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: "s3:*",
              Resource: [
                "arn:aws:s3:::#{bucket_name}",
                "arn:aws:s3:::#{bucket_name}/*"
              ]
            }]
          }
        end

        # CloudWatch logs write access
        def self.cloudwatch_logs_write
          {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams"
              ],
              Resource: "*"
            }]
          }
        end

        # EC2 basic access for instances
        def self.ec2_basic_access
          {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: [
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots"
              ],
              Resource: "*"
            }]
          }
        end

        # RDS read-only access
        def self.rds_readonly
          {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: [
                "rds:DescribeDBInstances",
                "rds:DescribeDBClusters",
                "rds:DescribeDBSnapshots",
                "rds:DescribeDBClusterSnapshots",
                "rds:ListTagsForResource"
              ],
              Resource: "*"
            }]
          }
        end

        # Lambda execution role basic permissions
        def self.lambda_basic_execution
          {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
              ],
              Resource: "arn:aws:logs:*:*:*"
            }]
          }
        end

        # KMS decrypt access for specific key
        def self.kms_decrypt(key_arn)
          {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: [
                "kms:Decrypt",
                "kms:DescribeKey"
              ],
              Resource: key_arn
            }]
          }
        end

        # SSM Parameter Store read access for path
        def self.ssm_parameter_read(parameter_path)
          {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: [
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:GetParametersByPath"
              ],
              Resource: "arn:aws:ssm:*:*:parameter#{parameter_path}*"
            }]
          }
        end

        # Secrets Manager read access for specific secret
        def self.secrets_manager_read(secret_arn)
          {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
              ],
              Resource: secret_arn
            }]
          }
        end
      end
    end
      end
    end
  end
end