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
        # Instance type helper methods for ManagedBlockchainNode
        module ManagedBlockchainNodeInstanceMethods
          def instance_family
            node_configuration[:instance_type].split('.')[1]
          end

          def instance_size
            node_configuration[:instance_type].split('.')[2]
          end

          def is_burstable?
            instance_family == 't3'
          end

          def is_compute_optimized?
            instance_family == 'c5'
          end

          def is_general_purpose?
            instance_family == 'm5'
          end

          def uses_couchdb?
            node_configuration[:state_db] == 'CouchDB'
          end

          def uses_leveldb?
            node_configuration[:state_db] == 'LevelDB' || node_configuration[:state_db].nil?
          end

          def chaincode_logging_enabled?
            node_configuration.dig(:log_publishing_configuration, :fabric, :chaincode_logs, :cloudwatch, :enabled) || false
          end

          def peer_logging_enabled?
            node_configuration.dig(:log_publishing_configuration, :fabric, :peer_logs, :cloudwatch, :enabled) || false
          end

          def any_logging_enabled?
            chaincode_logging_enabled? || peer_logging_enabled?
          end

          def performance_tier
            case instance_size
            when 'small', 'medium'
              :development
            when 'large'
              :standard
            when 'xlarge'
              :performance
            when '2xlarge', '4xlarge'
              :high_performance
            else
              :unknown
            end
          end

          def max_chaincode_connections
            case performance_tier
            when :development
              50
            when :standard
              200
            when :performance
              500
            when :high_performance
              1000
            else
              0
            end
          end
        end
      end
    end
  end
end
