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
require 'pangea/resources/aws_sagemaker_notebook_instance/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # SageMaker Notebook Instance resource for managed Jupyter notebook environments
      # 
      # Notebook instances provide fully managed Jupyter notebook servers for data exploration,
      # model development, and machine learning experimentation. They offer persistent storage,
      # pre-installed ML frameworks, and integration with other SageMaker services.
      #
      # @example Basic notebook instance for development
      #   aws_sagemaker_notebook_instance(:ml_notebook, {
      #     instance_name: "ml-development-notebook",
      #     instance_type: "ml.t3.medium",
      #     role_arn: notebook_role_ref.arn
      #   })
      #
      # @example Secure notebook instance in VPC with custom configuration
      #   aws_sagemaker_notebook_instance(:secure_notebook, {
      #     instance_name: "secure-ml-notebook",
      #     instance_type: "ml.m5.xlarge",
      #     role_arn: notebook_role_ref.arn,
      #     subnet_id: private_subnet_ref.id,
      #     security_group_ids: [notebook_sg_ref.id],
      #     direct_internet_access: "Disabled",
      #     kms_key_id: kms_key_ref.arn,
      #     volume_size_in_gb: 100,
      #     volume_type: "gp3",
      #     root_access: "Disabled",
      #     platform_identifier: "notebook-al2-v2",
      #     instance_metadata_service_configuration: {
      #       minimum_instance_metadata_service_version: "2"
      #     }
      #   })
      #
      # @example GPU-enabled notebook with accelerators and code repositories
      #   aws_sagemaker_notebook_instance(:gpu_notebook, {
      #     instance_name: "gpu-ml-notebook",
      #     instance_type: "ml.p3.2xlarge",
      #     role_arn: notebook_role_ref.arn,
      #     accelerator_types: ["ml.eia2.medium"],
      #     volume_size_in_gb: 200,
      #     volume_type: "gp3",
      #     lifecycle_config_name: gpu_lifecycle_config_ref.name,
      #     default_code_repository: "https://github.com/company/ml-experiments",
      #     additional_code_repositories: [
      #       "https://github.com/company/ml-utils",
      #       "https://github.com/company/datasets"
      #     ],
      #     tags: {
      #       Environment: "development",
      #       Team: "ml-research",
      #       CostCenter: "r-and-d",
      #       GPU: "enabled"
      #     }
      #   })
      class SageMakerNotebookInstance < Base
        def self.resource_type
          'aws_sagemaker_notebook_instance'
        end
        
        def self.attribute_struct
          Types::SageMakerNotebookInstanceAttributes
        end
      end
      
      # Resource function for aws_sagemaker_notebook_instance
      # 
      # @param name [Symbol] The resource name
      # @param attributes [Hash] The resource attributes
      # @return [ResourceReference] Reference to the created resource
      def aws_sagemaker_notebook_instance(name, attributes)
        resource = SageMakerNotebookInstance.new(
          name: name,
          attributes: attributes
        )
        
        add_resource(resource)
        
        # Return resource reference with computed attributes
        ResourceReference.new(
          name: name,
          type: :aws_sagemaker_notebook_instance,
          attributes: {
            # Direct attributes
            id: "${aws_sagemaker_notebook_instance.#{name}.id}",
            arn: "${aws_sagemaker_notebook_instance.#{name}.arn}",
            name: "${aws_sagemaker_notebook_instance.#{name}.name}",
            instance_name: "${aws_sagemaker_notebook_instance.#{name}.instance_name}",
            instance_type: "${aws_sagemaker_notebook_instance.#{name}.instance_type}",
            role_arn: "${aws_sagemaker_notebook_instance.#{name}.role_arn}",
            
            # Computed attributes
            url: "${aws_sagemaker_notebook_instance.#{name}.url}",
            network_interface_id: "${aws_sagemaker_notebook_instance.#{name}.network_interface_id}",
            security_groups: "${aws_sagemaker_notebook_instance.#{name}.security_groups}",
            
            # Helper attributes for integration
            notebook_instance_name: "${aws_sagemaker_notebook_instance.#{name}.instance_name}",
            jupyter_url: "${aws_sagemaker_notebook_instance.#{name}.url}",
            is_gpu_instance: attributes[:instance_type]&.start_with?('ml.p') || false,
            has_accelerators: attributes[:accelerator_types]&.any? || false,
            has_vpc_config: !attributes[:subnet_id].nil?,
            has_internet_access: attributes[:direct_internet_access] != 'Disabled',
            storage_size_gb: attributes[:volume_size_in_gb] || 20,
            uses_kms_encryption: !attributes[:kms_key_id].nil?,
            
            # Security attributes
            root_access_disabled: attributes[:root_access] == 'Disabled',
            uses_latest_platform: attributes[:platform_identifier] == 'notebook-al2-v2',
            imdsv2_enforced: attributes.dig(:instance_metadata_service_configuration, :minimum_instance_metadata_service_version) == '2'
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)