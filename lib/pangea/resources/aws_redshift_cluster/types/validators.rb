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
        # Validation logic for RedshiftClusterAttributes
        module RedshiftClusterValidators
          def self.validate!(attrs)
            validate_cluster_identifier!(attrs)
            validate_cluster_type!(attrs)
            validate_encryption!(attrs)
            validate_snapshot_config!(attrs)
            validate_logging_config!(attrs)
          end

          def self.validate_cluster_identifier!(attrs)
            unless attrs.cluster_identifier =~ /\A[a-z][a-z0-9\-]*\z/
              raise Dry::Struct::Error,
                    'Cluster identifier must start with lowercase letter and contain only lowercase letters, numbers, and hyphens'
            end

            return unless attrs.cluster_identifier.length > 63

            raise Dry::Struct::Error, 'Cluster identifier must be 63 characters or less'
          end

          def self.validate_cluster_type!(attrs)
            if attrs.cluster_type == 'multi-node' && attrs.number_of_nodes < 2
              raise Dry::Struct::Error, 'Multi-node clusters must have at least 2 nodes'
            end

            return unless attrs.cluster_type == 'single-node' && attrs.number_of_nodes != 1

            raise Dry::Struct::Error, 'Single-node clusters must have exactly 1 node'
          end

          def self.validate_encryption!(attrs)
            return unless attrs.encrypted && attrs.kms_key_id.nil?

            raise Dry::Struct::Error, 'KMS key ID must be provided when encryption is enabled'
          end

          def self.validate_snapshot_config!(attrs)
            return unless !attrs.skip_final_snapshot && attrs.final_snapshot_identifier.nil?

            raise Dry::Struct::Error, 'Final snapshot identifier must be provided when skip_final_snapshot is false'
          end

          def self.validate_logging_config!(attrs)
            return unless attrs.logging && attrs.logging[:enable] && attrs.logging[:bucket_name].nil?

            raise Dry::Struct::Error, 'Bucket name must be provided when logging is enabled'
          end
        end
      end
    end
  end
end
