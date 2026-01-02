# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module DynamoDbTableInstanceMethods
          def is_pay_per_request?
            billing_mode == "PAY_PER_REQUEST"
          end

          def is_provisioned?
            billing_mode == "PROVISIONED"
          end

          def has_range_key?
            !range_key.nil?
          end

          def has_gsi?
            global_secondary_index.any?
          end

          def has_lsi?
            local_secondary_index.any?
          end

          def has_stream?
            stream_enabled == true
          end

          def has_ttl?
            !ttl.nil?
          end

          def has_encryption?
            !server_side_encryption.nil?
          end

          def has_pitr?
            point_in_time_recovery_enabled
          end

          def is_global_table?
            replica.any?
          end

          def total_indexes
            global_secondary_index.size + local_secondary_index.size
          end

          def estimated_monthly_cost
            return "Variable (Pay per request)" if is_pay_per_request?

            # Calculate based on provisioned capacity
            base_cost = 0.0

            # Table capacity
            if read_capacity && write_capacity
              read_cost = read_capacity * 0.00013 * 730  # $0.00013 per RCU per hour
              write_cost = write_capacity * 0.00065 * 730  # $0.00065 per WCU per hour
              base_cost += read_cost + write_cost
            end

            # GSI capacity
            global_secondary_index.each do |gsi|
              if gsi[:read_capacity] && gsi[:write_capacity]
                gsi_read_cost = gsi[:read_capacity] * 0.00013 * 730
                gsi_write_cost = gsi[:write_capacity] * 0.00065 * 730
                base_cost += gsi_read_cost + gsi_write_cost
              end
            end

            "~$#{base_cost.round(2)}/month (capacity only)"
          end
        end
      end
    end
  end
end
