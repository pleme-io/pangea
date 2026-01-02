# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Pre-defined IAM policies for common scenarios
        module PolicyTemplates
          def self.s3_bucket_readonly(bucket_name)
            {
              Version: '2012-10-17',
              Statement: [
                { Effect: 'Allow', Action: %w[s3:GetObject s3:GetObjectVersion], Resource: "arn:aws:s3:::#{bucket_name}/*" },
                { Effect: 'Allow', Action: ['s3:ListBucket'], Resource: "arn:aws:s3:::#{bucket_name}" }
              ]
            }
          end

          def self.s3_bucket_fullaccess(bucket_name)
            { Version: '2012-10-17', Statement: [{ Effect: 'Allow', Action: 's3:*', Resource: ["arn:aws:s3:::#{bucket_name}", "arn:aws:s3:::#{bucket_name}/*"] }] }
          end

          def self.cloudwatch_logs_write
            { Version: '2012-10-17', Statement: [{ Effect: 'Allow', Action: %w[logs:CreateLogGroup logs:CreateLogStream logs:PutLogEvents logs:DescribeLogGroups logs:DescribeLogStreams], Resource: '*' }] }
          end

          def self.ec2_basic_access
            { Version: '2012-10-17', Statement: [{ Effect: 'Allow', Action: %w[ec2:DescribeInstances ec2:DescribeInstanceStatus ec2:DescribeVolumes ec2:DescribeSnapshots], Resource: '*' }] }
          end

          def self.rds_readonly
            { Version: '2012-10-17', Statement: [{ Effect: 'Allow', Action: %w[rds:DescribeDBInstances rds:DescribeDBClusters rds:DescribeDBSnapshots rds:DescribeDBClusterSnapshots rds:ListTagsForResource], Resource: '*' }] }
          end

          def self.lambda_basic_execution
            { Version: '2012-10-17', Statement: [{ Effect: 'Allow', Action: %w[logs:CreateLogGroup logs:CreateLogStream logs:PutLogEvents], Resource: 'arn:aws:logs:*:*:*' }] }
          end

          def self.kms_decrypt(key_arn)
            { Version: '2012-10-17', Statement: [{ Effect: 'Allow', Action: %w[kms:Decrypt kms:DescribeKey], Resource: key_arn }] }
          end

          def self.ssm_parameter_read(parameter_path)
            { Version: '2012-10-17', Statement: [{ Effect: 'Allow', Action: %w[ssm:GetParameter ssm:GetParameters ssm:GetParametersByPath], Resource: "arn:aws:ssm:*:*:parameter#{parameter_path}*" }] }
          end

          def self.secrets_manager_read(secret_arn)
            { Version: '2012-10-17', Statement: [{ Effect: 'Allow', Action: %w[secretsmanager:GetSecretValue secretsmanager:DescribeSecret], Resource: secret_arn }] }
          end
        end
      end
    end
  end
end
