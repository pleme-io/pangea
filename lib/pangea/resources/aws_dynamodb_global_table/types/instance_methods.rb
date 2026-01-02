# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Instance methods for DynamoDbGlobalTableAttributes
        module DynamoDbGlobalTableInstanceMethods
          def is_pay_per_request?
            billing_mode == "PAY_PER_REQUEST"
          end

          def is_provisioned?
            billing_mode == "PROVISIONED"
          end

          def has_stream?
            stream_enabled == true
          end

          def has_encryption?
            !server_side_encryption.nil?
          end

          def has_pitr?
            point_in_time_recovery && point_in_time_recovery[:enabled]
          end

          def region_count
            replica.size
          end

          def regions
            replica.map { |r| r[:region_name] }
          end

          def has_gsi?
            replica.any? { |r| r[:global_secondary_index] && r[:global_secondary_index].any? }
          end

          def total_gsi_count
            replica.sum { |r| (r[:global_secondary_index] || []).size }
          end

          def estimated_monthly_cost
            cost_multiplier = region_count
            base_cost = is_pay_per_request? ? "Variable per region" : "~$50"

            "#{base_cost} x #{cost_multiplier} regions (#{total_gsi_count} total GSIs)"
          end

          def multi_region_strategy
            case region_count
            when 2
              "Active-Active (2 regions)"
            when 3
              "Multi-region Active (3 regions)"
            else
              "Global Active-Active (#{region_count} regions)"
            end
          end
        end
      end
    end
  end
end
