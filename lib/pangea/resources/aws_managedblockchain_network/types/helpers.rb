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
        # Helper instance methods for managed blockchain network attributes
        module ManagedBlockchainNetworkHelpers
          def is_hyperledger_fabric?
            framework == 'HYPERLEDGER_FABRIC'
          end

          def is_ethereum?
            framework == 'ETHEREUM'
          end

          def edition
            return nil unless is_hyperledger_fabric?

            framework_configuration&.dig(:network_fabric_configuration, :edition)
          end

          def is_starter_edition?
            edition == 'STARTER'
          end

          def is_standard_edition?
            edition == 'STANDARD'
          end

          def chain_id
            return nil unless is_ethereum?

            framework_configuration&.dig(:network_ethereum_configuration, :chain_id)
          end

          def approval_threshold
            voting_policy&.dig(:approval_threshold_policy, :threshold_percentage)
          end

          def proposal_duration_hours
            voting_policy&.dig(:approval_threshold_policy, :proposal_duration_in_hours)
          end

          def cloudwatch_logging_enabled?
            member_configuration.dig(:log_publishing_configuration, :fabric, :ca_logs, :cloudwatch, :enabled) || false
          end

          def estimated_monthly_cost
            base_cost = calculate_hourly_cost
            # Convert hourly to monthly (730 hours)
            base_cost * 730
          end

          def consensus_mechanism
            case framework
            when 'HYPERLEDGER_FABRIC'
              'RAFT (Ordering Service)'
            when 'ETHEREUM'
              framework_version == 'ETHEREUM_MAINNET' ? 'Proof of Stake (PoS)' : 'Proof of Authority (PoA)'
            end
          end

          def network_type
            case framework
            when 'HYPERLEDGER_FABRIC'
              'Private Permissioned'
            when 'ETHEREUM'
              framework_version.include?('MAINNET') ? 'Public Permissionless' : 'Public Test Network'
            end
          end

          private

          def calculate_hourly_cost
            case framework
            when 'HYPERLEDGER_FABRIC'
              case edition
              when 'STARTER' then 0.45
              when 'STANDARD' then 1.25
              else 0.0
              end
            when 'ETHEREUM'
              0.0
            else
              0.0
            end
          end
        end
      end
    end
  end
end
