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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws/cloudformation/types'

module Pangea
  module Resources
    module AWS
      module CloudFormation
        # AWS CloudFormation Type resource
        # Registers custom resource types and hooks in the CloudFormation registry.
        # This enables the creation and management of custom CloudFormation resources
        # with defined schemas, handlers, and lifecycle hooks.
        #
        # @see https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/custom-resource.html
        module Type
          # Creates an AWS CloudFormation Type registration
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the type
          # @option attributes [String] :type Type of registration (RESOURCE or HOOK) (required)
          # @option attributes [String] :type_name Unique name for the type (required)
          # @option attributes [String] :schema JSON schema defining the type
          # @option attributes [String] :schema_handler_package S3 location of handler package
          # @option attributes [String] :source_url URL to source code repository
          # @option attributes [String] :documentation_url URL to documentation
          # @option attributes [String] :execution_role_arn IAM role for type execution
          # @option attributes [Hash] :logging_config CloudWatch Logs configuration
          # @option attributes [String] :client_request_token Unique request token
          #
          # @example Custom S3 bucket resource type
          #   custom_s3_type = aws_cloudformation_type(:secure_s3_bucket, {
          #     type: "RESOURCE",
          #     type_name: "Company::S3::SecureBucket",
          #     schema_handler_package: "s3://cf-types-bucket/secure-s3-bucket.zip",
          #     documentation_url: "https://docs.company.com/cloudformation/s3-secure-bucket",
          #     source_url: "https://github.com/company/cf-types/s3-secure-bucket",
          #     execution_role_arn: ref(:aws_iam_role, :cf_type_execution, :arn),
          #     logging_config: {
          #       log_group_name: "CloudFormationTypes",
          #       log_role_arn: ref(:aws_iam_role, :cf_logging, :arn)
          #     },
          #     schema: JSON.generate({
          #       "typeName" => "Company::S3::SecureBucket",
          #       "description" => "S3 bucket with security defaults",
          #       "properties" => {
          #         "BucketName" => {
          #           "type" => "string",
          #           "description" => "Name of the S3 bucket"
          #         },
          #         "EncryptionEnabled" => {
          #           "type" => "boolean",
          #           "default" => true
          #         }
          #       },
          #       "required" => ["BucketName"],
          #       "handlers" => {
          #         "create" => { "permissions" => ["s3:CreateBucket", "s3:PutEncryptionConfiguration"] },
          #         "read" => { "permissions" => ["s3:GetBucketEncryption"] },
          #         "delete" => { "permissions" => ["s3:DeleteBucket"] }
          #       }
          #     })
          #   })
          #
          # @example Pre-deployment validation hook
          #   validation_hook = aws_cloudformation_type(:deployment_validator, {
          #     type: "HOOK",
          #     type_name: "Company::Security::DeploymentValidator",
          #     schema_handler_package: "s3://cf-hooks-bucket/deployment-validator.zip",
          #     documentation_url: "https://docs.company.com/cloudformation/hooks/validator",
          #     execution_role_arn: ref(:aws_iam_role, :hook_execution, :arn),
          #     logging_config: {
          #       log_group_name: "CloudFormationHooks",
          #       log_role_arn: ref(:aws_iam_role, :cf_logging, :arn)
          #     },
          #     schema: JSON.generate({
          #       "typeName" => "Company::Security::DeploymentValidator",
          #       "description" => "Validates deployments against security policies",
          #       "properties" => {
          #         "PolicyArn" => {
          #           "type" => "string",
          #           "description" => "ARN of the security policy to validate against"
          #         }
          #       },
          #       "handlers" => {
          #         "preCreate" => { "permissions" => ["iam:GetPolicy", "iam:SimulatePrincipalPolicy"] },
          #         "preUpdate" => { "permissions" => ["iam:GetPolicy", "iam:SimulatePrincipalPolicy"] }
          #       }
          #     })
          #   })
          #
          # @return [ResourceReference] The CloudFormation type resource reference
          def aws_cloudformation_type(name, attributes = {})
            # Validate attributes using dry-struct
            type_attrs = Types::CloudFormationTypeAttributes.new(attributes)
            
            # Generate terraform resource block
            resource(:aws_cloudformation_type, name) do
              type type_attrs.type
              type_name type_attrs.type_name
              
              # Optional configurations
              schema type_attrs.schema if type_attrs.schema
              schema_handler_package type_attrs.schema_handler_package if type_attrs.schema_handler_package
              source_url type_attrs.source_url if type_attrs.source_url
              documentation_url type_attrs.documentation_url if type_attrs.documentation_url
              execution_role_arn type_attrs.execution_role_arn if type_attrs.execution_role_arn
              client_request_token type_attrs.client_request_token if type_attrs.client_request_token
              
              # Logging configuration
              if type_attrs.logging_config
                logging_config do
                  log_group_name type_attrs.logging_config[:log_group_name] if type_attrs.logging_config[:log_group_name]
                  log_role_arn type_attrs.logging_config[:log_role_arn] if type_attrs.logging_config[:log_role_arn]
                end
              end
            end
            
            # Return resource reference
            ResourceReference.new(
              type: 'aws_cloudformation_type',
              name: name,
              resource_attributes: type_attrs.to_h,
              outputs: {
                id: "${aws_cloudformation_type.#{name}.id}",
                arn: "${aws_cloudformation_type.#{name}.arn}",
                version_id: "${aws_cloudformation_type.#{name}.version_id}",
                provisioning_type: "${aws_cloudformation_type.#{name}.provisioning_type}",
                schema: "${aws_cloudformation_type.#{name}.schema}",
                source_url: "${aws_cloudformation_type.#{name}.source_url}",
                documentation_url: "${aws_cloudformation_type.#{name}.documentation_url}",
                last_updated: "${aws_cloudformation_type.#{name}.last_updated}",
                default_version_id: "${aws_cloudformation_type.#{name}.default_version_id}",
                deprecated_status: "${aws_cloudformation_type.#{name}.deprecated_status}",
                is_default_version: "${aws_cloudformation_type.#{name}.is_default_version}",
                visibility: "${aws_cloudformation_type.#{name}.visibility}"
              },
              computed_properties: {
                is_resource_type: type_attrs.resource_type?,
                is_hook_type: type_attrs.hook_type?,
                has_logging: type_attrs.has_logging?,
                namespace: type_attrs.type_name.split('::').first,
                service: type_attrs.type_name.split('::').second,
                resource_name: type_attrs.type_name.split('::').last
              }
            )
          end
        end
      end
    end
  end
end