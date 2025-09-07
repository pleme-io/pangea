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
require 'pangea/resources/aws_sagemaker_domain/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # SageMaker Domain resource for managing SageMaker Studio domains
      # 
      # SageMaker Studio provides a web-based ML development environment that includes
      # Jupyter notebooks, code editors, ML workflows, and model deployment capabilities.
      # A domain defines the VPC, subnets, and default user settings for Studio.
      #
      # @example Basic SageMaker Studio domain
      #   aws_sagemaker_domain(:ml_platform, {
      #     domain_name: "ml-development-platform",
      #     auth_mode: "SSO",
      #     vpc_id: vpc_ref.id,
      #     subnet_ids: [subnet_a_ref.id, subnet_b_ref.id],
      #     default_user_settings: {
      #       execution_role: execution_role_ref.arn
      #     }
      #   })
      #
      # @example Enterprise SageMaker domain with VPC-only access
      #   aws_sagemaker_domain(:enterprise_ml, {
      #     domain_name: "enterprise-ml-platform",
      #     auth_mode: "SSO", 
      #     vpc_id: vpc_ref.id,
      #     subnet_ids: private_subnet_refs.map(&:id),
      #     app_network_access_type: "VpcOnly",
      #     app_security_group_management: "Customer",
      #     kms_key_id: kms_key_ref.arn,
      #     default_user_settings: {
      #       execution_role: execution_role_ref.arn,
      #       security_groups: [ml_security_group_ref.id],
      #       sharing_settings: {
      #         notebook_output_option: "Disabled"
      #       },
      #       jupyter_server_app_settings: {
      #         default_resource_spec: {
      #           instance_type: "ml.t3.medium"
      #         }
      #       }
      #     },
      #     domain_settings: {
      #       security_group_ids: [domain_security_group_ref.id],
      #       execution_role_identity_config: "USER_PROFILE_NAME"
      #     }
      #   })
      #
      # @example Data science platform with Canvas and R Studio
      #   aws_sagemaker_domain(:data_science_platform, {
      #     domain_name: "data-science-platform",
      #     auth_mode: "SSO",
      #     vpc_id: vpc_ref.id, 
      #     subnet_ids: [subnet_a_ref.id, subnet_b_ref.id, subnet_c_ref.id],
      #     kms_key_id: kms_key_ref.arn,
      #     default_user_settings: {
      #       execution_role: execution_role_ref.arn,
      #       canvas_app_settings: {
      #         time_series_forecasting_settings: {
      #           status: "ENABLED",
      #           amazon_forecast_role_arn: forecast_role_ref.arn
      #         },
      #         workspace_settings: {
      #           s3_artifact_path: "s3://#{artifacts_bucket_ref.bucket}/canvas-artifacts/",
      #           s3_kms_key_id: kms_key_ref.arn
      #         }
      #       }
      #     },
      #     domain_settings: {
      #       r_studio_server_pro_domain_settings: {
      #         domain_execution_role_arn: r_studio_role_ref.arn,
      #         default_resource_spec: {
      #           instance_type: "ml.t3.medium"
      #         }
      #       }
      #     },
      #     tags: {
      #       Environment: "production",
      #       Team: "data-science",
      #       CostCenter: "ml-ops"
      #     }
      #   })
      class SageMakerDomain < Base
        def self.resource_type
          'aws_sagemaker_domain'
        end
        
        def self.attribute_struct
          Types::SageMakerDomainAttributes
        end
      end
      
      # Resource function for aws_sagemaker_domain
      # 
      # @param name [Symbol] The resource name
      # @param attributes [Hash] The resource attributes
      # @return [ResourceReference] Reference to the created resource
      def aws_sagemaker_domain(name, attributes)
        resource = SageMakerDomain.new(
          name: name,
          attributes: attributes
        )
        
        add_resource(resource)
        
        # Return resource reference with computed attributes
        ResourceReference.new(
          name: name,
          type: :aws_sagemaker_domain,
          attributes: {
            # Direct attributes
            id: "${aws_sagemaker_domain.#{name}.id}",
            arn: "${aws_sagemaker_domain.#{name}.arn}",
            domain_name: "${aws_sagemaker_domain.#{name}.domain_name}",
            auth_mode: "${aws_sagemaker_domain.#{name}.auth_mode}",
            vpc_id: "${aws_sagemaker_domain.#{name}.vpc_id}",
            subnet_ids: "${aws_sagemaker_domain.#{name}.subnet_ids}",
            kms_key_id: "${aws_sagemaker_domain.#{name}.kms_key_id}",
            app_network_access_type: "${aws_sagemaker_domain.#{name}.app_network_access_type}",
            
            # Computed attributes
            domain_id: "${aws_sagemaker_domain.#{name}.id}",
            home_efs_file_system_id: "${aws_sagemaker_domain.#{name}.home_efs_file_system_id}",
            security_group_id_for_domain_boundary: "${aws_sagemaker_domain.#{name}.security_group_id_for_domain_boundary}",
            single_sign_on_managed_application_instance_id: "${aws_sagemaker_domain.#{name}.single_sign_on_managed_application_instance_id}",
            url: "${aws_sagemaker_domain.#{name}.url}",
            
            # Helper attributes for referencing
            studio_url: "${aws_sagemaker_domain.#{name}.url}",
            execution_role: attributes[:default_user_settings][:execution_role],
            is_vpc_only: attributes[:app_network_access_type] == 'VpcOnly',
            uses_sso: attributes[:auth_mode] == 'SSO'
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)