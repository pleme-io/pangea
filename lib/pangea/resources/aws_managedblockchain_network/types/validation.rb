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
        # Validation methods for managed blockchain network attributes
        module ManagedBlockchainNetworkValidation
          def self.validate_name(name)
            unless name.match?(/\A[a-zA-Z][a-zA-Z0-9]*\z/)
              raise Dry::Struct::Error, 'name must start with a letter and contain only alphanumeric characters'
            end

            return if name.length >= 1 && name.length <= 64

            raise Dry::Struct::Error, 'name must be between 1 and 64 characters'
          end

          def self.validate_member_name(member_name)
            return if member_name.match?(/\A[a-zA-Z][a-zA-Z0-9]*\z/)

            raise Dry::Struct::Error,
                  'member name must start with a letter and contain only alphanumeric characters'
          end

          def self.validate_fabric_configuration(attrs)
            if attrs.framework_configuration.nil? || attrs.framework_configuration[:network_fabric_configuration].nil?
              raise Dry::Struct::Error, 'network_fabric_configuration is required for Hyperledger Fabric networks'
            end

            raise Dry::Struct::Error, 'voting_policy is required for Hyperledger Fabric networks' if attrs.voting_policy.nil?

            valid_fabric_versions = %w[1.2 1.4 2.2 2.5]
            unless valid_fabric_versions.include?(attrs.framework_version)
              raise Dry::Struct::Error,
                    "framework_version must be one of: #{valid_fabric_versions.join(', ')} for Hyperledger Fabric"
            end

            validate_fabric_member_configuration(attrs)
          end

          def self.validate_fabric_member_configuration(attrs)
            member_fabric_config = attrs.member_configuration[:framework_configuration][:member_fabric_configuration]
            if member_fabric_config.nil?
              raise Dry::Struct::Error, 'member_fabric_configuration is required for Hyperledger Fabric members'
            end

            admin_username = member_fabric_config[:admin_username]
            admin_password = member_fabric_config[:admin_password]

            unless admin_username.match?(/\A[a-zA-Z0-9]+\z/)
              raise Dry::Struct::Error, 'admin_username must contain only alphanumeric characters'
            end

            return unless admin_password.length < 8

            raise Dry::Struct::Error, 'admin_password must be at least 8 characters long'
          end

          def self.validate_ethereum_configuration(attrs)
            if attrs.framework_configuration.nil? || attrs.framework_configuration[:network_ethereum_configuration].nil?
              raise Dry::Struct::Error, 'network_ethereum_configuration is required for Ethereum networks'
            end

            unless attrs.framework_version.match?(/\A(ETHEREUM_MAINNET|ETHEREUM_GOERLI|ETHEREUM_ROPSTEN|ETHEREUM_RINKEBY)\z/)
              raise Dry::Struct::Error, 'framework_version must be a valid Ethereum network identifier'
            end

            return unless attrs.voting_policy

            raise Dry::Struct::Error, 'voting_policy is not supported for Ethereum networks'
          end
        end
      end
    end
  end
end
