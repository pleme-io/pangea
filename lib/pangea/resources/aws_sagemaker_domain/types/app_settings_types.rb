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

require_relative 'base_types'

module Pangea
  module Resources
    module AWS
      module Types
        # SageMaker Domain Jupyter Server app settings
        SageMakerDomainJupyterServerAppSettings = Resources::Types::Hash.schema(
          default_resource_spec?: Resources::Types::Hash.schema(
            instance_type?: SageMakerDomainInstanceType.optional,
            lifecycle_config_arn?: Resources::Types::String.optional,
            sage_maker_image_arn?: Resources::Types::String.optional,
            sage_maker_image_version_arn?: Resources::Types::String.optional
          ).optional,
          lifecycle_config_arns?: Resources::Types::Array.of(Resources::Types::String).optional,
          code_repositories?: Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              repository_url: Resources::Types::String.constrained(format: /\Ahttps:\/\/github\.com\//),
              default_branch?: Resources::Types::String.default('main')
            )
          ).optional
        )

        # SageMaker Domain Kernel Gateway app settings
        SageMakerDomainKernelGatewayAppSettings = Resources::Types::Hash.schema(
          default_resource_spec?: Resources::Types::Hash.schema(
            instance_type?: SageMakerDomainInstanceType.optional,
            lifecycle_config_arn?: Resources::Types::String.optional,
            sage_maker_image_arn?: Resources::Types::String.optional,
            sage_maker_image_version_arn?: Resources::Types::String.optional
          ).optional,
          lifecycle_config_arns?: Resources::Types::Array.of(Resources::Types::String).optional,
          custom_images?: Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              app_image_config_name: Resources::Types::String,
              image_name: Resources::Types::String,
              image_version_number?: Resources::Types::Integer.optional
            )
          ).optional
        )

        # SageMaker Domain Tensor Board app settings
        SageMakerDomainTensorBoardAppSettings = Resources::Types::Hash.schema(
          default_resource_spec?: Resources::Types::Hash.schema(
            instance_type?: SageMakerDomainInstanceType.optional,
            lifecycle_config_arn?: Resources::Types::String.optional,
            sage_maker_image_arn?: Resources::Types::String.optional,
            sage_maker_image_version_arn?: Resources::Types::String.optional
          ).optional
        )

        # SageMaker Domain RStudio Server Pro app settings
        SageMakerDomainRStudioServerProAppSettings = Resources::Types::Hash.schema(
          access_status?: Resources::Types::String.enum('ENABLED', 'DISABLED').optional,
          user_group?: Resources::Types::String.enum('R_STUDIO_ADMIN', 'R_STUDIO_USER').optional
        )

        # SageMaker Domain Canvas app settings
        SageMakerDomainCanvasAppSettings = Resources::Types::Hash.schema(
          time_series_forecasting_settings?: Resources::Types::Hash.schema(
            status?: Resources::Types::String.enum('ENABLED', 'DISABLED').optional,
            amazon_forecast_role_arn?: Resources::Types::String.optional
          ).optional,
          model_register_settings?: Resources::Types::Hash.schema(
            status?: Resources::Types::String.enum('ENABLED', 'DISABLED').optional,
            cross_account_model_register_role_arn?: Resources::Types::String.optional
          ).optional,
          workspace_settings?: Resources::Types::Hash.schema(
            s3_artifact_path?: Resources::Types::String.optional,
            s3_kms_key_id?: Resources::Types::String.optional
          ).optional
        )
      end
    end
  end
end
