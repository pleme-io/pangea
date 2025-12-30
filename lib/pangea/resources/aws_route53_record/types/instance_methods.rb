# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module Route53RecordInstanceMethods
          def is_alias_record?
            !self.alias.nil?
          end

          def is_simple_record?
            routing_policies_count == 0 && !multivalue_answer
          end

          def routing_policies_count
            [
              weighted_routing_policy,
              latency_routing_policy,
              failover_routing_policy,
              geolocation_routing_policy,
              geoproximity_routing_policy
            ].compact.length
          end

          def has_routing_policy?
            routing_policies_count > 0
          end

          def routing_policy_type
            return "weighted" if weighted_routing_policy
            return "latency" if latency_routing_policy
            return "failover" if failover_routing_policy
            return "geolocation" if geolocation_routing_policy
            return "geoproximity" if geoproximity_routing_policy
            return "multivalue" if multivalue_answer
            "simple"
          end

          def is_wildcard_record?
            name.start_with?('*.')
          end

          def record_count
            records.length
          end

          # Get the domain part of the record name
          def domain_name
            # Remove the trailing dot if present
            clean_name = name.end_with?('.') ? name[0..-2] : name

            # For wildcard records, remove the *. prefix
            if is_wildcard_record?
              clean_name[2..-1]
            else
              clean_name
            end
          end

          # Estimate DNS query cost impact
          def estimated_query_cost_per_million
            base_cost = 0.40  # $0.40 per million queries for standard

            case routing_policy_type
            when "weighted", "latency", "failover", "geolocation"
              base_cost * 2  # 2x cost for routing policies
            when "geoproximity"
              base_cost * 3  # 3x cost for geoproximity
            else
              base_cost
            end
          end
        end
      end
    end
  end
end
