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
require 'pangea/resources/aws_sagemaker_user_profile/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # SageMaker User Profile resource for managing individual user configurations within a SageMaker Studio domain
      # 
      # User profiles define user-specific settings that override domain defaults, including execution roles,
      # application settings, storage configurations, and security settings for individual data scientists
      # and ML engineers.
      #
      # @example Basic user profile with custom execution role
      #   aws_sagemaker_user_profile(:data_scientist, {
      #     domain_id: domain_ref.id,
      #     user_profile_name: "data-scientist-profile",
      #     user_settings: {
      #       execution_role: data_scientist_role_ref.arn
      #     }
      #   })
      #
      # @example Enterprise user profile with comprehensive security settings
      #   aws_sagemaker_user_profile(:senior_ml_engineer, {
      #     domain_id: domain_ref.id,
      #     user_profile_name: "senior-ml-engineer",
      #     single_sign_on_user_identifier: "UserName",
      #     single_sign_on_user_value: "john.doe@company.com",
      #     user_settings: {
      #       execution_role: ml_engineer_role_ref.arn,
      #       security_groups: [ml_security_group_ref.id],
      #       sharing_settings: {
      #         notebook_output_option: "Disabled"
      #       },
      #       jupyter_server_app_settings: {
      #         default_resource_spec: {
      #           instance_type: "ml.t3.medium",
      #           lifecycle_config_arn: jupyter_lifecycle_ref.arn
      #         },
      #         code_repositories: [
      #           {
      #             repository_url: "https://github.com/company/ml-templates",
      #             default_branch: "main"
      #           }
      #         ]
      #       },
      #       space_storage_settings: {
      #         default_ebs_storage_settings: {
      #           default_ebs_volume_size_in_gb: 50,
      #           maximum_ebs_volume_size_in_gb: 500
      #         }
      #       }
      #     }
      #   })
      #
      # @example Canvas and R Studio enabled user profile
      #   aws_sagemaker_user_profile(:business_analyst, {
      #     domain_id: domain_ref.id,
      #     user_profile_name: "business-analyst",
      #     user_settings: {
      #       execution_role: analyst_role_ref.arn,
      #       canvas_app_settings: {
      #         time_series_forecasting_settings: {
      #           status: "ENABLED",
      #           amazon_forecast_role_arn: forecast_role_ref.arn
      #         },
      #         model_register_settings: {
      #           status: "ENABLED"
      #         },
      #         workspace_settings: {
      #           s3_artifact_path: "s3://#{canvas_bucket_ref.bucket}/user-artifacts/#{user_name}/",
      #           s3_kms_key_id: kms_key_ref.arn
      #         },
      #         direct_deploy_settings: {
      #           status: "ENABLED"
      #         },
      #         generative_ai_settings: {
      #           amazon_bedrock_role_arn: bedrock_role_ref.arn
      #         }
      #       },
      #       r_studio_server_pro_app_settings: {
      #         access_status: "ENABLED",
      #         user_group: "R_STUDIO_USER"
      #       }
      #     },
      #     tags: {
      #       Team: "business-intelligence",
      #       UserType: "analyst",
      #       CostCenter: "analytics"
      #     }
      #   })
      #
      # @example Advanced user with custom POSIX configuration and EFS integration
      #   aws_sagemaker_user_profile(:ml_researcher, {
      #     domain_id: domain_ref.id,
      #     user_profile_name: "ml-researcher",
      #     user_settings: {
      #       execution_role: researcher_role_ref.arn,
      #       custom_posix_user_config: {
      #         uid: 2001,
      #         gid: 2001
      #       },
      #       custom_file_system_configs: [
      #         {
      #           efs_file_system_config: {
      #             file_system_id: shared_efs_ref.id,
      #             file_system_path: "/research-data"
      #           }
      #         }
      #       ],
      #       kernel_gateway_app_settings: {
      #         default_resource_spec: {
      #           instance_type: "ml.m5.xlarge"
      #         },
      #         custom_images: [
      #           {
      #             app_image_config_name: "pytorch-research-config",
      #             image_name: "pytorch-research-environment",
      #             image_version_number: 1
      #           }
      #         ]
      #       }
      #     }
      #   })
      class SageMakerUserProfile < Base
        def self.resource_type
          'aws_sagemaker_user_profile'
        end
        
        def self.attribute_struct
          Types::SageMakerUserProfileAttributes
        end
      end
      
      # Resource function for aws_sagemaker_user_profile
      # 
      # @param name [Symbol] The resource name
      # @param attributes [Hash] The resource attributes
      # @return [ResourceReference] Reference to the created resource
      def aws_sagemaker_user_profile(name, attributes)
        resource = SageMakerUserProfile.new(
          name: name,
          attributes: attributes
        )
        
        add_resource(resource)
        
        # Return resource reference with computed attributes
        ResourceReference.new(
          name: name,
          type: :aws_sagemaker_user_profile,
          attributes: {
            # Direct attributes
            id: "${aws_sagemaker_user_profile.#{name}.id}",
            arn: "${aws_sagemaker_user_profile.#{name}.arn}",
            user_profile_name: "${aws_sagemaker_user_profile.#{name}.user_profile_name}",
            domain_id: "${aws_sagemaker_user_profile.#{name}.domain_id}",
            
            # Computed attributes
            home_efs_file_system_uid: "${aws_sagemaker_user_profile.#{name}.home_efs_file_system_uid}",
            
            # Helper attributes for integration
            profile_name: "${aws_sagemaker_user_profile.#{name}.user_profile_name}",
            has_sso: !attributes[:single_sign_on_user_identifier].nil?,
            has_custom_role: attributes.dig(:user_settings, :execution_role) != nil,
            canvas_enabled: attributes.dig(:user_settings, :canvas_app_settings) != nil,
            r_studio_enabled: attributes.dig(:user_settings, :r_studio_server_pro_app_settings) != nil,
            storage_size_gb: attributes.dig(:user_settings, :space_storage_settings, :default_ebs_storage_settings, :default_ebs_volume_size_in_gb) || 5,
            
            # Security attributes
            notebook_sharing_disabled: attributes.dig(:user_settings, :sharing_settings, :notebook_output_option) == 'Disabled',
            uses_custom_posix: attributes.dig(:user_settings, :custom_posix_user_config) != nil,
            has_efs_mounts: attributes.dig(:user_settings, :custom_file_system_configs)&.any? { |c| c[:efs_file_system_config] } || false
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)