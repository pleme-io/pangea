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

require_relative 'app_settings_types'

module Pangea
  module Resources
    module AWS
      module Types
        # SageMaker Domain default user settings
        SageMakerDomainDefaultUserSettings = Resources::Types::Hash.schema(
          execution_role: SageMakerDomainExecutionRole,
          security_groups?: Resources::Types::Array.of(Resources::Types::String).optional,
          sharing_settings?: Resources::Types::Hash.schema(
            notebook_output_option?: Resources::Types::String.enum('Allowed', 'Disabled').optional,
            s3_output_path?: Resources::Types::String.optional,
            s3_kms_key_id?: Resources::Types::String.optional
          ).optional,
          jupyter_server_app_settings?: SageMakerDomainJupyterServerAppSettings.optional,
          kernel_gateway_app_settings?: SageMakerDomainKernelGatewayAppSettings.optional,
          tensor_board_app_settings?: SageMakerDomainTensorBoardAppSettings.optional,
          r_studio_server_pro_app_settings?: SageMakerDomainRStudioServerProAppSettings.optional,
          canvas_app_settings?: SageMakerDomainCanvasAppSettings.optional
        )

        # SageMaker Domain retention policy
        SageMakerDomainRetentionPolicy = Resources::Types::Hash.schema(
          home_efs_file_system?: Resources::Types::String.default('Retain').enum('Retain', 'Delete')
        )
      end
    end
  end
end
