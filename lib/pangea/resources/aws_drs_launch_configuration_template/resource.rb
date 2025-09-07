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

module Pangea
  module Resources
    module AWS
      # Type-safe resource function for AWS DRS Launch Configuration Template
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes following AWS provider schema
      # @return [Pangea::Resources::Reference] Resource reference for chaining
      # 
      # @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/drs_launch_configuration_template
      #
      # @example Production launch configuration template
      #   aws_drs_launch_configuration_template(:production_launch, {
      #     copy_private_ip: false,
      #     copy_tags: true,
      #     launch_disposition: "STARTED",
      #     licensing: {
      #       os_byol: false
      #     },
      #     target_instance_type_right_sizing_method: "BASIC",
      #     post_launch_enabled: true,
      #     post_launch_actions: {
      #       deployment: "TEST_AND_CUTOVER",
      #       s3_log_bucket: log_bucket.bucket,
      #       s3_output_key_prefix: "drs-launch-logs/",
      #       cloud_watch_log_group_name: log_group.name,
      #       ssm_documents: [
      #         {
      #           action_name: "configure-application",
      #           ssm_document_name: "ConfigureApplication",
      #           timeout_seconds: 1800,
      #           must_succeed_for_cutover: true,
      #           parameters: {
      #             "EnvironmentType" => "production"
      #           }
      #         }
      #       ]
      #     },
      #     tags: {
      #       "Template" => "production-launch",
      #       "Purpose" => "disaster-recovery"
      #     }
      #   })
      def aws_drs_launch_configuration_template(name, attributes)
        transformed = Base.transform_attributes(attributes, {
          copy_private_ip: {
            description: "Whether to copy private IP address",
            type: :boolean,
            default: false
          },
          copy_tags: {
            description: "Whether to copy tags from source",
            type: :boolean,
            default: true
          },
          launch_disposition: {
            description: "Launch disposition (STOPPED or STARTED)",
            type: :string,
            default: "STOPPED",
            enum: ["STOPPED", "STARTED"]
          },
          licensing: {
            description: "Licensing configuration",
            type: :hash,
            properties: {
              os_byol: {
                description: "Whether to use BYOL licensing",
                type: :boolean,
                default: true
              }
            }
          },
          target_instance_type_right_sizing_method: {
            description: "Right-sizing method for target instances",
            type: :string,
            default: "BASIC",
            enum: ["BASIC", "IN_AWS"]
          },
          post_launch_enabled: {
            description: "Whether post-launch actions are enabled",
            type: :boolean,
            default: false
          },
          post_launch_actions: {
            description: "Configuration for post-launch actions",
            type: :hash,
            properties: {
              deployment: {
                description: "Deployment type",
                type: :string,
                enum: ["TEST_AND_CUTOVER", "CUTOVER_ONLY", "TEST_ONLY"]
              },
              s3_log_bucket: {
                description: "S3 bucket for post-launch action logs",
                type: :string
              },
              s3_output_key_prefix: {
                description: "S3 key prefix for logs",
                type: :string
              },
              cloud_watch_log_group_name: {
                description: "CloudWatch log group name",
                type: :string
              },
              ssm_documents: {
                description: "List of SSM documents to execute",
                type: :array,
                items: {
                  type: :hash,
                  properties: {
                    action_name: {
                      description: "Name of the action",
                      type: :string,
                      required: true
                    },
                    ssm_document_name: {
                      description: "Name of SSM document",
                      type: :string,
                      required: true
                    },
                    timeout_seconds: {
                      description: "Timeout for the action",
                      type: :integer
                    },
                    must_succeed_for_cutover: {
                      description: "Whether action must succeed for cutover",
                      type: :boolean,
                      default: false
                    },
                    parameters: {
                      description: "Parameters for the SSM document",
                      type: :map
                    }
                  }
                }
              }
            }
          },
          tags: {
            description: "Resource tags",
            type: :map
          }
        })

        resource_block = resource(:aws_drs_launch_configuration_template, name, transformed)
        
        Reference.new(
          type: :aws_drs_launch_configuration_template,
          name: name,
          attributes: {
            arn: "#{resource_block}.arn",
            id: "#{resource_block}.id",
            template_id: "#{resource_block}.template_id",
            tags_all: "#{resource_block}.tags_all"
          },
          resource: resource_block
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)