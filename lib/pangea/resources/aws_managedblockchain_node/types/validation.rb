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
        # Validation methods for ManagedBlockchainNode attributes
        module ManagedBlockchainNodeValidation
          def validate_network_id(network_id)
            return if network_id.match?(/\An-[A-Z0-9]{26}\z/)

            raise Dry::Struct::Error, "network_id must be in format 'n-XXXXXXXXXXXXXXXXXXXXXXXXXXXX'"
          end

          def validate_member_id(member_id)
            return if member_id.nil?
            return if member_id.match?(/\Am-[A-Z0-9]{26}\z/)

            raise Dry::Struct::Error, "member_id must be in format 'm-XXXXXXXXXXXXXXXXXXXXXXXXXXXX'"
          end

          def validate_availability_zone(availability_zone)
            return if availability_zone.match?(/\A[a-z]{2}-[a-z]+-\d[a-z]\z/)

            raise Dry::Struct::Error, 'availability_zone must be a valid AWS availability zone (e.g., us-east-1a)'
          end

          def validate_instance_type_for_workload(attrs)
            instance_type = attrs.node_configuration[:instance_type]

            return unless attrs.node_configuration[:state_db] == 'CouchDB'

            small_instances = ['bc.t3.small', 'bc.t3.medium']
            return unless small_instances.include?(instance_type)

            raise Dry::Struct::Error, 'CouchDB requires at least bc.t3.large instance type for adequate performance'
          end
        end
      end
    end
  end
end
