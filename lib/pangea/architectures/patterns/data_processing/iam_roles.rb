# frozen_string_literal: true

module Pangea
  module Architectures
    module Patterns
      module DataProcessing
        # IAM roles for data processing
        module IamRoles
          def create_firehose_role(name, arch_ref, base_tags)
            aws_iam_role(
              architecture_resource_name(name, :firehose_role),
              name: "#{name}-firehose-role",
              assume_role_policy: firehose_assume_role_policy,
              inline_policies: [firehose_s3_policy(arch_ref)],
              tags: base_tags.merge(Tier: 'security', Component: 'firehose-role')
            )
          end

          def create_glue_role(name, _arch_ref, base_tags)
            aws_iam_role(
              architecture_resource_name(name, :glue_role),
              name: "#{name}-glue-role",
              assume_role_policy: glue_assume_role_policy,
              tags: base_tags.merge(Tier: 'security', Component: 'glue-role')
            )
          end

          def create_lambda_role(name, _arch_ref, base_tags)
            aws_iam_role(
              architecture_resource_name(name, :lambda_role),
              name: "#{name}-lambda-role",
              assume_role_policy: lambda_assume_role_policy,
              tags: base_tags.merge(Tier: 'security', Component: 'lambda-role')
            )
          end

          def create_emr_service_role(name, base_tags)
            aws_iam_role(
              architecture_resource_name(name, :emr_service_role),
              name: "#{name}-emr-service-role",
              assume_role_policy: emr_assume_role_policy,
              tags: base_tags.merge(Tier: 'security', Component: 'emr-service-role')
            )
          end

          def create_emr_instance_profile(name, base_tags)
            role = aws_iam_role(
              architecture_resource_name(name, :emr_instance_role),
              name: "#{name}-emr-instance-role",
              assume_role_policy: ec2_assume_role_policy,
              tags: base_tags.merge(Tier: 'security', Component: 'emr-instance-role')
            )

            aws_iam_instance_profile(
              architecture_resource_name(name, :emr_instance_profile),
              name: "#{name}-emr-instance-profile",
              role: role.name
            )
          end

          def create_kinesis_analytics_role(name, base_tags)
            aws_iam_role(
              architecture_resource_name(name, :kinesis_analytics_role),
              name: "#{name}-kinesis-analytics-role",
              assume_role_policy: kinesis_analytics_assume_role_policy,
              tags: base_tags.merge(Tier: 'security', Component: 'kinesis-analytics-role')
            )
          end

          private

          def firehose_assume_role_policy
            jsonencode({
              Version: '2012-10-17',
              Statement: [{ Action: 'sts:AssumeRole', Effect: 'Allow', Principal: { Service: 'firehose.amazonaws.com' } }]
            })
          end

          def firehose_s3_policy(arch_ref)
            {
              name: 'FirehoseS3Access',
              policy: jsonencode({
                Version: '2012-10-17',
                Statement: [{
                  Effect: 'Allow',
                  Action: %w[s3:PutObject s3:GetObject s3:ListBucket],
                  Resource: ["#{arch_ref.storage[:raw_bucket].arn}/*", arch_ref.storage[:raw_bucket].arn]
                }]
              })
            }
          end

          def glue_assume_role_policy
            jsonencode({
              Version: '2012-10-17',
              Statement: [{ Action: 'sts:AssumeRole', Effect: 'Allow', Principal: { Service: 'glue.amazonaws.com' } }]
            })
          end

          def lambda_assume_role_policy
            jsonencode({
              Version: '2012-10-17',
              Statement: [{ Action: 'sts:AssumeRole', Effect: 'Allow', Principal: { Service: 'lambda.amazonaws.com' } }]
            })
          end

          def emr_assume_role_policy
            jsonencode({
              Version: '2012-10-17',
              Statement: [{ Action: 'sts:AssumeRole', Effect: 'Allow', Principal: { Service: 'elasticmapreduce.amazonaws.com' } }]
            })
          end

          def ec2_assume_role_policy
            jsonencode({
              Version: '2012-10-17',
              Statement: [{ Action: 'sts:AssumeRole', Effect: 'Allow', Principal: { Service: 'ec2.amazonaws.com' } }]
            })
          end

          def kinesis_analytics_assume_role_policy
            jsonencode({
              Version: '2012-10-17',
              Statement: [{ Action: 'sts:AssumeRole', Effect: 'Allow', Principal: { Service: 'kinesisanalytics.amazonaws.com' } }]
            })
          end
        end
      end
    end
  end
end
