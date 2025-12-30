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

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # SageMaker Domain execution role policy validation
        SageMakerDomainExecutionRole = String.constrained(
          format: /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9_+=,.@-]+\z/
        )

        # SageMaker Domain auth modes
        SageMakerDomainAuthMode = String.enum('SSO', 'IAM')

        # SageMaker Domain VPC-only mode
        SageMakerDomainVpcOnly = String.enum('Enabled', 'Disabled').default('Disabled')

        # SageMaker Domain app network access type
        SageMakerDomainAppNetworkAccessType = String.enum('PublicInternetOnly', 'VpcOnly').default('PublicInternetOnly')

        # SageMaker Domain app security group override
        SageMakerDomainAppSecurityGroupManagement = String.enum('Service', 'Customer').default('Service')

        # SageMaker Domain instance types for Studio
        SageMakerDomainInstanceType = String.enum(
          # System instances (for JupyterServer apps)
          'system',
          # ML instances
          'ml.t3.micro', 'ml.t3.small', 'ml.t3.medium', 'ml.t3.large', 'ml.t3.xlarge', 'ml.t3.2xlarge',
          'ml.m5.large', 'ml.m5.xlarge', 'ml.m5.2xlarge', 'ml.m5.4xlarge', 'ml.m5.8xlarge', 'ml.m5.12xlarge', 'ml.m5.16xlarge', 'ml.m5.24xlarge',
          'ml.c5.large', 'ml.c5.xlarge', 'ml.c5.2xlarge', 'ml.c5.4xlarge', 'ml.c5.9xlarge', 'ml.c5.18xlarge',
          'ml.r5.large', 'ml.r5.xlarge', 'ml.r5.2xlarge', 'ml.r5.4xlarge', 'ml.r5.8xlarge', 'ml.r5.12xlarge', 'ml.r5.16xlarge', 'ml.r5.24xlarge',
          'ml.g4dn.xlarge', 'ml.g4dn.2xlarge', 'ml.g4dn.4xlarge', 'ml.g4dn.8xlarge', 'ml.g4dn.12xlarge', 'ml.g4dn.16xlarge',
          'ml.p3.2xlarge', 'ml.p3.8xlarge', 'ml.p3.16xlarge',
          'ml.p4d.24xlarge'
        )
      end
    end
  end
end
