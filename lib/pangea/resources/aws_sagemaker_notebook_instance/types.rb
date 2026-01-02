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

require 'dry-struct'
require 'pangea/resources/types'
require_relative 'types/validators'
require_relative 'types/pricing'
require_relative 'types/helpers'
require_relative 'types/security'

module Pangea
  module Resources
    module AWS
      module Types
        # SageMaker Notebook Instance types
        SageMakerNotebookInstanceType = String.enum(
          'ml.t2.medium', 'ml.t2.large', 'ml.t2.xlarge', 'ml.t2.2xlarge',
          'ml.t3.medium', 'ml.t3.large', 'ml.t3.xlarge', 'ml.t3.2xlarge',
          'ml.m4.xlarge', 'ml.m4.2xlarge', 'ml.m4.4xlarge', 'ml.m4.10xlarge', 'ml.m4.16xlarge',
          'ml.m5.xlarge', 'ml.m5.2xlarge', 'ml.m5.4xlarge', 'ml.m5.8xlarge', 'ml.m5.12xlarge', 'ml.m5.24xlarge',
          'ml.c4.xlarge', 'ml.c4.2xlarge', 'ml.c4.4xlarge', 'ml.c4.8xlarge',
          'ml.c5.xlarge', 'ml.c5.2xlarge', 'ml.c5.4xlarge', 'ml.c5.9xlarge', 'ml.c5.18xlarge',
          'ml.c5d.xlarge', 'ml.c5d.2xlarge', 'ml.c5d.4xlarge', 'ml.c5d.9xlarge', 'ml.c5d.18xlarge',
          'ml.r4.xlarge', 'ml.r4.2xlarge', 'ml.r4.4xlarge', 'ml.r4.8xlarge', 'ml.r4.16xlarge',
          'ml.r5.xlarge', 'ml.r5.2xlarge', 'ml.r5.4xlarge', 'ml.r5.8xlarge', 'ml.r5.12xlarge', 'ml.r5.24xlarge',
          'ml.p2.xlarge', 'ml.p2.8xlarge', 'ml.p2.16xlarge',
          'ml.p3.2xlarge', 'ml.p3.8xlarge', 'ml.p3.16xlarge'
        )

        # SageMaker Notebook Instance volume types
        SageMakerNotebookVolumeType = String.enum('gp2', 'gp3', 'io1', 'io2')

        # SageMaker Notebook Instance platform identifier
        SageMakerNotebookPlatformIdentifier = String.enum('notebook-al1-v1', 'notebook-al2-v1', 'notebook-al2-v2')

        # SageMaker Notebook Instance root access
        SageMakerNotebookRootAccess = String.enum('Enabled', 'Disabled').default('Enabled')

        # SageMaker Notebook Instance status
        SageMakerNotebookInstanceStatus = String.enum(
          'Pending', 'InService', 'Stopping', 'Stopped', 'Failed', 'Deleting', 'Updating'
        )

        # Accelerator types enum
        SageMakerAcceleratorType = String.enum(
          'ml.eia1.medium', 'ml.eia1.large', 'ml.eia1.xlarge',
          'ml.eia2.medium', 'ml.eia2.large', 'ml.eia2.xlarge'
        )

        # SageMaker Notebook Instance attributes with comprehensive validation
        class SageMakerNotebookInstanceAttributes < Dry::Struct
          include SageMakerNotebookInstance::Pricing
          include SageMakerNotebookInstance::Helpers
          include SageMakerNotebookInstance::Security

          transform_keys(&:to_sym)

          # Required attributes
          attribute :instance_name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 63,
            format: /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/
          )
          attribute :instance_type, SageMakerNotebookInstanceType
          attribute :role_arn, Resources::Types::String.constrained(
            format: /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9_+=,.@-]+\z/
          )

          # Optional attributes
          attribute :subnet_id, Resources::Types::String.optional
          attribute :security_group_ids, Resources::Types::Array.of(String).optional
          attribute :kms_key_id, Resources::Types::String.optional
          attribute :lifecycle_config_name, Resources::Types::String.optional
          attribute :direct_internet_access, String.enum('Enabled', 'Disabled').default('Enabled')
          attribute :volume_size_in_gb, Integer.constrained(gteq: 5, lteq: 16384).default(20)
          attribute :volume_type, SageMakerNotebookVolumeType.default('gp2')
          attribute :accelerator_types, Resources::Types::Array.of(SageMakerAcceleratorType).optional
          attribute :default_code_repository, Resources::Types::String.optional
          attribute :additional_code_repositories, Resources::Types::Array.of(String).optional
          attribute :root_access, SageMakerNotebookRootAccess
          attribute :platform_identifier, SageMakerNotebookPlatformIdentifier.optional
          attribute :instance_metadata_service_configuration, Resources::Types::Hash.schema(
            minimum_instance_metadata_service_version: String.enum('1', '2').default('1')
          ).optional
          attribute :tags, Resources::Types::AwsTags

          # Custom validation for SageMaker Notebook Instance
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            SageMakerNotebookInstance::Validators.validate!(attrs)
            super(attrs)
          end
        end
      end
    end
  end
end
