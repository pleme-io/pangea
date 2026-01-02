# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Common Route53 record configurations
        module Route53RecordConfigs
          # Simple A record
          def self.a_record(zone_id, name, ip_addresses, ttl: 300)
            {
              zone_id: zone_id,
              name: name,
              type: "A",
              ttl: ttl,
              records: Array(ip_addresses)
            }
          end

          # Simple AAAA record
          def self.aaaa_record(zone_id, name, ipv6_addresses, ttl: 300)
            {
              zone_id: zone_id,
              name: name,
              type: "AAAA",
              ttl: ttl,
              records: Array(ipv6_addresses)
            }
          end

          # CNAME record
          def self.cname_record(zone_id, name, target, ttl: 300)
            {
              zone_id: zone_id,
              name: name,
              type: "CNAME",
              ttl: ttl,
              records: [target]
            }
          end

          # MX record
          def self.mx_record(zone_id, name, mail_servers, ttl: 300)
            {
              zone_id: zone_id,
              name: name,
              type: "MX",
              ttl: ttl,
              records: mail_servers
            }
          end

          # TXT record (often used for SPF, DKIM, domain verification)
          def self.txt_record(zone_id, name, values, ttl: 300)
            {
              zone_id: zone_id,
              name: name,
              type: "TXT",
              ttl: ttl,
              records: Array(values)
            }
          end

          # Alias record for AWS resources
          def self.alias_record(zone_id, name, target_dns_name, target_zone_id, evaluate_health: false)
            {
              zone_id: zone_id,
              name: name,
              type: "A",  # Usually A for alias records
              alias: {
                name: target_dns_name,
                zone_id: target_zone_id,
                evaluate_target_health: evaluate_health
              }
            }
          end

          # Weighted routing record
          def self.weighted_record(zone_id, name, type, records, weight, identifier, ttl: 300, health_check_id: nil)
            {
              zone_id: zone_id,
              name: name,
              type: type,
              ttl: ttl,
              records: Array(records),
              set_identifier: identifier,
              weighted_routing_policy: { weight: weight },
              health_check_id: health_check_id
            }.compact
          end

          # Failover routing record
          def self.failover_record(zone_id, name, type, records, failover_type, identifier, ttl: 300, health_check_id: nil)
            {
              zone_id: zone_id,
              name: name,
              type: type,
              ttl: ttl,
              records: Array(records),
              set_identifier: identifier,
              failover_routing_policy: { type: failover_type.upcase },
              health_check_id: health_check_id
            }.compact
          end

          # Geolocation routing record
          def self.geolocation_record(zone_id, name, type, records, location, identifier, ttl: 300)
            {
              zone_id: zone_id,
              name: name,
              type: type,
              ttl: ttl,
              records: Array(records),
              set_identifier: identifier,
              geolocation_routing_policy: location
            }
          end
        end
      end
    end
  end
end
