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
        # Computed properties for Kinesis Firehose Delivery Stream attributes
        module FirehoseComputedProperties
          BACKUP_ENABLED_VALUES = %w[Enabled AllDocuments AllEvents AllData].freeze

          def has_data_transformation?
            config = destination_config
            config&.dig(:processing_configuration, :enabled) == true
          end

          def has_format_conversion?
            destination == 'extended_s3' &&
              extended_s3_configuration&.dig(:data_format_conversion_configuration, :enabled) == true
          end

          def backup_enabled?
            backup_mode = destination_config&.dig(:s3_backup_mode)
            BACKUP_ENABLED_VALUES.include?(backup_mode)
          end

          def is_encrypted?
            server_side_encryption&.dig(:enabled) == true
          end

          def uses_customer_managed_key?
            is_encrypted? && server_side_encryption&.dig(:key_type) == 'CUSTOMER_MANAGED_CMK'
          end

          def has_kinesis_source?
            !kinesis_source_configuration.nil?
          end

          def estimated_monthly_cost_usd
            'Variable - depends on data volume and destination'
          end

          private

          def destination_config
            config_method = "#{destination}_configuration"
            public_send(config_method.to_sym) if respond_to?(config_method)
          end
        end
      end
    end
  end
end
