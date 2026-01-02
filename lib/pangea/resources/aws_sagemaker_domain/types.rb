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
require_relative 'types/user_settings_types'

module Pangea
  module Resources
    module AWS
      module Types
        # SageMaker Domain attributes with extensive ML-specific validation
        class SageMakerDomainAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :domain_name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 63,
            format: /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/
          )
          attribute :auth_mode, SageMakerDomainAuthMode
          attribute :default_user_settings, SageMakerDomainDefaultUserSettings
          attribute :subnet_ids, Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1, max_size: 16)
          attribute :vpc_id, Resources::Types::String

          # Optional attributes
          attribute :app_network_access_type, SageMakerDomainAppNetworkAccessType
          attribute :app_security_group_management, SageMakerDomainAppSecurityGroupManagement
          attribute :domain_settings, Resources::Types::Hash.schema(
            security_group_ids?: Resources::Types::Array.of(Resources::Types::String).optional,
            r_studio_server_pro_domain_settings?: Resources::Types::Hash.schema(
              domain_execution_role_arn: Resources::Types::String,
              r_studio_connect_url?: Resources::Types::String.optional,
              r_studio_package_manager_url?: Resources::Types::String.optional,
              default_resource_spec?: Resources::Types::Hash.schema(
                instance_type?: Resources::Types::String.optional,
                lifecycle_config_arn?: Resources::Types::String.optional,
                sage_maker_image_arn?: Resources::Types::String.optional,
                sage_maker_image_version_arn?: Resources::Types::String.optional
              ).optional
            ).optional,
            execution_role_identity_config?: Resources::Types::String.enum(
              'USER_PROFILE_NAME', 'DISABLED'
            ).optional
          ).optional
          attribute :kms_key_id, Resources::Types::String.optional
          attribute :tags, Resources::Types::AwsTags
          attribute :default_space_settings, Resources::Types::Hash.schema(
            execution_role?: Resources::Types::String.optional,
            security_groups?: Resources::Types::Array.of(Resources::Types::String).optional,
            jupyter_server_app_settings?: SageMakerDomainJupyterServerAppSettings.optional,
            kernel_gateway_app_settings?: SageMakerDomainKernelGatewayAppSettings.optional
          ).optional
          attribute :retention_policy, SageMakerDomainRetentionPolicy.optional

          # Custom validation for SageMaker Domain
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            validate_vpc_configuration(attrs)
            validate_auth_mode_requirements(attrs)
            validate_app_network_access(attrs)
            validate_kms_key_format(attrs)
            validate_execution_role(attrs)

            super(attrs)
          end

          def self.validate_vpc_configuration(attrs)
            return unless attrs[:vpc_id] && attrs[:subnet_ids]

            subnet_ids = attrs[:subnet_ids]
            return unless subnet_ids.size < 2

            raise Dry::Struct::Error, 'SageMaker Domain requires at least 2 subnets in different Availability Zones'
          end

          def self.validate_auth_mode_requirements(attrs)
            return unless attrs[:auth_mode] == 'SSO'
            return unless attrs[:domain_settings]&.dig(:execution_role_identity_config) == 'DISABLED'

            raise Dry::Struct::Error, 'execution_role_identity_config cannot be DISABLED when auth_mode is SSO'
          end

          def self.validate_app_network_access(attrs)
            return unless attrs[:app_network_access_type] == 'VpcOnly'
            return unless attrs[:vpc_id].nil? || attrs[:subnet_ids].nil?

            raise Dry::Struct::Error, 'vpc_id and subnet_ids are required when app_network_access_type is VpcOnly'
          end

          def self.validate_kms_key_format(attrs)
            return unless attrs[:kms_key_id]
            return if attrs[:kms_key_id] =~ /\A(arn:aws:kms:|alias\/|[a-f0-9-]{36})/

            raise Dry::Struct::Error, 'kms_key_id must be a valid KMS key ARN, alias, or key ID'
          end

          def self.validate_execution_role(attrs)
            execution_role = attrs.dig(:default_user_settings, :execution_role)
            return unless execution_role
            return if execution_role =~ /\Aarn:aws:iam::\d{12}:role\//

            raise Dry::Struct::Error, 'execution_role must be a valid IAM role ARN'
          end

          # Computed properties
          def estimated_monthly_cost
            base_cost = 0.0 # SageMaker Studio domain itself is free
            notebook_cost = 50.0  # Estimated for ml.t3.medium instances
            storage_cost = 10.0   # EFS storage for user directories
            base_cost + notebook_cost + storage_cost
          end

          def supports_vpc_only?
            app_network_access_type == 'VpcOnly'
          end

          def uses_sso_auth?
            auth_mode == 'SSO'
          end

          def uses_custom_kms_key?
            !kms_key_id.nil?
          end

          def has_custom_security_groups?
            domain_settings&.dig(:security_group_ids)&.any? || false
          end

          def supports_r_studio?
            !domain_settings&.dig(:r_studio_server_pro_domain_settings).nil?
          end

          def subnet_count
            subnet_ids.size
          end

          # Security and compliance checks
          def security_score
            score = 0
            score += 20 if supports_vpc_only?
            score += 15 if uses_custom_kms_key?
            score += 10 if has_custom_security_groups?
            score += 15 if uses_sso_auth?
            score += 10 if subnet_count >= 3 # Multi-AZ redundancy
            [score, 100].min
          end

          def compliance_status
            issues = []
            issues << 'No VPC-only access configured' unless supports_vpc_only?
            issues << 'No custom KMS key for encryption' unless uses_custom_kms_key?
            issues << 'Using IAM auth instead of SSO' unless uses_sso_auth?
            issues << 'Insufficient subnet redundancy' if subnet_count < 2

            {
              status: issues.empty? ? 'compliant' : 'needs_attention',
              issues: issues
            }
          end
        end
      end
    end
  end
end
