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
        SageMakerDomainJupyterServerAppSettings = Hash.schema(
          default_resource_spec?: Hash.schema(
            instance_type?: SageMakerDomainInstanceType.optional,
            lifecycle_config_arn?: String.optional,
            sage_maker_image_arn?: String.optional,
            sage_maker_image_version_arn?: String.optional
          ).optional,
          lifecycle_config_arns?: Array.of(String).optional,
          code_repositories?: Array.of(
            Hash.schema(
              repository_url: String.constrained(format: /\Ahttps:\/\/github\.com\//),
              default_branch?: String.default('main')
            )
          ).optional
        )

        # SageMaker Domain Kernel Gateway app settings
        SageMakerDomainKernelGatewayAppSettings = Hash.schema(
          default_resource_spec?: Hash.schema(
            instance_type?: SageMakerDomainInstanceType.optional,
            lifecycle_config_arn?: String.optional,
            sage_maker_image_arn?: String.optional,
            sage_maker_image_version_arn?: String.optional
          ).optional,
          lifecycle_config_arns?: Array.of(String).optional,
          custom_images?: Array.of(
            Hash.schema(
              app_image_config_name: String,
              image_name: String,
              image_version_number?: Integer.optional
            )
          ).optional
        )

        # SageMaker Domain Tensor Board app settings
        SageMakerDomainTensorBoardAppSettings = Hash.schema(
          default_resource_spec?: Hash.schema(
            instance_type?: SageMakerDomainInstanceType.optional,
            lifecycle_config_arn?: String.optional,
            sage_maker_image_arn?: String.optional,
            sage_maker_image_version_arn?: String.optional
          ).optional
        )

        # SageMaker Domain RStudio Server Pro app settings
        SageMakerDomainRStudioServerProAppSettings = Hash.schema(
          access_status?: String.enum('ENABLED', 'DISABLED').optional,
          user_group?: String.enum('R_STUDIO_ADMIN', 'R_STUDIO_USER').optional
        )

        # SageMaker Domain Canvas app settings
        SageMakerDomainCanvasAppSettings = Hash.schema(
          time_series_forecasting_settings?: Hash.schema(
            status?: String.enum('ENABLED', 'DISABLED').optional,
            amazon_forecast_role_arn?: String.optional
          ).optional,
          model_register_settings?: Hash.schema(
            status?: String.enum('ENABLED', 'DISABLED').optional,
            cross_account_model_register_role_arn?: String.optional
          ).optional,
          workspace_settings?: Hash.schema(
            s3_artifact_path?: String.optional,
            s3_kms_key_id?: String.optional
          ).optional
        )
      end
    end
  end
end
