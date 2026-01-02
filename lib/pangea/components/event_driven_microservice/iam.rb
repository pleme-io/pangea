# frozen_string_literal: true

require 'json'

module Pangea
  module Components
    module EventDrivenMicroservice
      # IAM roles and policies
      module Iam
        def create_lambda_role(name, component_tag_set)
          aws_iam_role(component_resource_name(name, :lambda_role), {
            name: "#{name}-lambda-role",
            assume_role_policy: JSON.generate({
              Version: '2012-10-17',
              Statement: [{
                Action: 'sts:AssumeRole',
                Effect: 'Allow',
                Principal: { Service: 'lambda.amazonaws.com' }
              }]
            }),
            tags: component_tag_set
          })
        end

        def attach_lambda_policies(name, lambda_role_ref, component_attrs)
          resources = {}

          resources[:lambda_basic_policy] = aws_iam_role_policy_attachment(
            component_resource_name(name, :lambda_basic_policy),
            {
              role: lambda_role_ref.name,
              policy_arn: 'arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole'
            }
          )

          if component_attrs.vpc_ref
            resources[:lambda_vpc_policy] = aws_iam_role_policy_attachment(
              component_resource_name(name, :lambda_vpc_policy),
              {
                role: lambda_role_ref.name,
                policy_arn: 'arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole'
              }
            )
          end

          resources
        end

        def create_lambda_access_policy(name, lambda_role_ref, resources, component_attrs)
          aws_iam_role_policy(component_resource_name(name, :lambda_policy), {
            name: "#{name}-lambda-policy",
            role: lambda_role_ref.id,
            policy: JSON.generate(lambda_policy_document(resources, component_attrs))
          })
        end

        private

        def lambda_policy_document(resources, component_attrs)
          {
            Version: '2012-10-17',
            Statement: [
              dynamodb_statement(resources, component_attrs),
              eventbridge_statement,
              sqs_statement(resources, component_attrs),
              xray_statement
            ]
          }
        end

        def dynamodb_statement(resources, component_attrs)
          table_resources = [
            resources[:event_store].arn,
            "#{resources[:event_store].arn}/index/*",
            "#{resources[:event_store].arn}/stream/*"
          ]

          if component_attrs.cqrs&.enabled
            table_resources += [
              resources[:command_table].arn,
              "#{resources[:command_table].arn}/index/*",
              resources[:query_table].arn,
              "#{resources[:query_table].arn}/index/*"
            ]
          end

          {
            Effect: 'Allow',
            Action: %w[
              dynamodb:GetItem dynamodb:PutItem dynamodb:UpdateItem
              dynamodb:Query dynamodb:Scan dynamodb:BatchGetItem
              dynamodb:BatchWriteItem dynamodb:DescribeStream
              dynamodb:GetRecords dynamodb:GetShardIterator dynamodb:ListStreams
            ],
            Resource: table_resources
          }
        end

        def eventbridge_statement
          { Effect: 'Allow', Action: ['events:PutEvents'], Resource: '*' }
        end

        def sqs_statement(resources, component_attrs)
          {
            Effect: 'Allow',
            Action: %w[sqs:SendMessage sqs:ReceiveMessage sqs:DeleteMessage sqs:GetQueueAttributes],
            Resource: component_attrs.dead_letter_queue_enabled ? [resources[:dead_letter_queue].arn] : []
          }
        end

        def xray_statement
          { Effect: 'Allow', Action: %w[xray:PutTraceSegments xray:PutTelemetryRecords], Resource: '*' }
        end
      end
    end
  end
end
