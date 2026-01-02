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
      module Types
        module ManagedBlockchainMemberInstanceMethods
          def member_name
            member_configuration[:name]
          end

          def member_description
            member_configuration[:description]
          end

          def is_fabric_member?
            member_configuration[:framework_configuration][:member_fabric_configuration].present?
          end

          def admin_username
            member_configuration.dig(:framework_configuration, :member_fabric_configuration, :admin_username)
          end

          def ca_logging_enabled?
            member_configuration.dig(:log_publishing_configuration, :fabric, :ca_logs, :cloudwatch, :enabled) || false
          end

          def is_joining_existing_network?
            !invitation_id.nil?
          end

          def is_founding_member?
            invitation_id.nil?
          end

          def member_type
            is_founding_member? ? :founding_member : :invited_member
          end

          def estimated_monthly_cost
            base_cost = is_fabric_member? ? 0.10 : 0.00
            base_cost += 0.01 if ca_logging_enabled?
            base_cost * 730
          end

          def member_capabilities
            capabilities = []

            if is_fabric_member?
              capabilities << :certificate_authority
              capabilities << :peer_node_creation
              capabilities << :chaincode_deployment
              capabilities << :channel_creation
            end

            capabilities << :ca_audit_logging if ca_logging_enabled?
            capabilities
          end

          def security_features
            features = []

            if is_fabric_member?
              features << :x509_certificates
              features << :msp_identity_management
              features << :tls_encryption
            end

            features << :admin_credentials if admin_username
            features
          end

          def compliance_features
            features = []

            if ca_logging_enabled?
              features << :audit_trail
              features << :cloudwatch_integration
            end

            features << :resource_tagging if member_configuration[:tags]
            features
          end
        end
      end
    end
  end
end
