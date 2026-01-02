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

module Pangea
  module Resources
    module AWS
      module SageMakerNotebookInstance
        # Validation logic for SageMaker Notebook Instance attributes
        module Validators
          RESERVED_NAMES = %w[sagemaker aws amazon].freeze
          INCOMPATIBLE_ACCELERATOR_PREFIXES = %w[ml.t ml.m4 ml.c4].freeze
          REPO_URL_PATTERN = /\A(https:\/\/github\.com\/|https:\/\/git-codecommit\.[a-z0-9-]+\.amazonaws\.com\/|arn:aws:sagemaker:)/.freeze
          KMS_KEY_PATTERN = /\A(arn:aws:kms:|alias\/|[a-f0-9-]{36})/.freeze

          def self.validate!(attrs)
            validate_instance_name(attrs[:instance_name])
            validate_vpc_configuration(attrs[:subnet_id], attrs[:direct_internet_access])
            validate_security_groups(attrs[:security_group_ids], attrs[:subnet_id])
            validate_kms_key(attrs[:kms_key_id])
            validate_accelerator_compatibility(attrs[:accelerator_types], attrs[:instance_type])
            validate_code_repositories(attrs[:default_code_repository], attrs[:additional_code_repositories])
            validate_volume_configuration(attrs[:volume_type], attrs[:volume_size_in_gb])
          end

          def self.validate_instance_name(name)
            return unless name

            if RESERVED_NAMES.any? { |reserved| name.downcase.include?(reserved) }
              raise Dry::Struct::Error, "Instance name cannot contain reserved words: #{RESERVED_NAMES.join(', ')}"
            end
          end

          def self.validate_vpc_configuration(subnet_id, direct_internet_access)
            if subnet_id.nil? && direct_internet_access == 'Disabled'
              raise Dry::Struct::Error, 'direct_internet_access cannot be Disabled without specifying subnet_id'
            end
          end

          def self.validate_security_groups(security_group_ids, subnet_id)
            if security_group_ids&.any? && subnet_id.nil?
              raise Dry::Struct::Error, 'security_group_ids can only be specified when subnet_id is provided'
            end
          end

          def self.validate_kms_key(kms_key_id)
            return unless kms_key_id
            return if kms_key_id.match?(KMS_KEY_PATTERN)

            raise Dry::Struct::Error, 'kms_key_id must be a valid KMS key ARN, alias, or key ID'
          end

          def self.validate_accelerator_compatibility(accelerator_types, instance_type)
            return unless accelerator_types&.any?

            if INCOMPATIBLE_ACCELERATOR_PREFIXES.any? { |prefix| instance_type&.start_with?(prefix) }
              raise Dry::Struct::Error, "Elastic Inference accelerators are not compatible with #{instance_type}"
            end
          end

          def self.validate_code_repositories(default_repo, additional_repos)
            all_repos = []
            all_repos << default_repo if default_repo
            all_repos.concat(additional_repos || [])

            all_repos.each do |repo|
              next if repo.match?(REPO_URL_PATTERN)

              raise Dry::Struct::Error, 'Code repository must be a GitHub URL, CodeCommit URL, or SageMaker Git repo ARN'
            end
          end

          def self.validate_volume_configuration(volume_type, volume_size)
            return unless %w[io1 io2].include?(volume_type)

            volume_size ||= 20
            return unless volume_size < 10

            raise Dry::Struct::Error, "Volume size must be at least 10GB for #{volume_type} volume type"
          end
        end
      end
    end
  end
end
