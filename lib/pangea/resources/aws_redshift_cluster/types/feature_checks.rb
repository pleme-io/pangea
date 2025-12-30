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
        # Feature check methods for Redshift clusters
        module RedshiftFeatureChecks
          # Check if cluster has high availability features
          def high_availability?
            multi_node? && automated_snapshot_retention_period.positive?
          end

          # Check if cluster has audit logging enabled
          def audit_logging_enabled?
            logging && logging[:enable] == true
          end

          # Check if cluster has cross-region snapshot copy
          def cross_region_backup?
            !snapshot_copy.nil?
          end

          # Generate connection string
          def jdbc_connection_string
            "jdbc:redshift://#{cluster_identifier}.region.redshift.amazonaws.com:#{port}/#{database_name}"
          end
        end
      end
    end
  end
end
