# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Route53 Record resources
        class Route53RecordAttributes < Dry::Struct
          transform_keys(&:to_sym)
          # Hosted zone ID where the record will be created
          attribute :zone_id, Pangea::Resources::Types::String

          # DNS record name (FQDN)
          attribute :name, Pangea::Resources::Types::String

          # DNS record type
          attribute :type, Pangea::Resources::Types::String.enum(
            "A", "AAAA", "CNAME", "MX", "NS", "PTR", "SOA", "SPF", "SRV", "TXT"
          )

          # Time To Live (TTL) in seconds (required for simple records)
          attribute :ttl?, Pangea::Resources::Types::Integer.optional.constrained(gteq: 0, lteq: 2147483647)

          # DNS record values (for simple records)
          attribute :records?, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).optional.default(proc { [] }.freeze)

          # Set identifier for weighted/latency-based/failover/geolocation routing
          attribute :set_identifier?, Pangea::Resources::Types::String.optional

          # Health check ID for failover routing
          attribute :health_check_id?, Pangea::Resources::Types::String.optional

          # Multivalue answer routing
          attribute :multivalue_answer?, Pangea::Resources::Types::Bool.optional.default(false)

          # Allow DNS record overwrite
          attribute :allow_overwrite?, Pangea::Resources::Types::Bool.optional.default(false)

          # Weighted routing policy
          attribute :weighted_routing_policy?, Pangea::Resources::Types::Hash.schema(
            weight: Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 255)
          ).optional

          # Latency routing policy
          attribute :latency_routing_policy?, Pangea::Resources::Types::Hash.schema(
            region: Pangea::Resources::Types::String
          ).optional

          # Failover routing policy
          attribute :failover_routing_policy?, Pangea::Resources::Types::Hash.schema(
            type: Pangea::Resources::Types::String.enum("PRIMARY", "SECONDARY")
          ).optional

          # Geolocation routing policy
          attribute :geolocation_routing_policy?, Pangea::Resources::Types::Hash.schema(
            continent?: Pangea::Resources::Types::String.optional,
            country?: Pangea::Resources::Types::String.optional,
            subdivision?: Pangea::Resources::Types::String.optional
          ).optional

          # Geoproximity routing policy (requires Route53 Traffic Flow)
          attribute :geoproximity_routing_policy?, Pangea::Resources::Types::Hash.schema(
            aws_region?: Pangea::Resources::Types::String.optional,
            bias?: Pangea::Resources::Types::Integer.optional.constrained(gteq: -99, lteq: 99),
            coordinates?: Pangea::Resources::Types::Hash.schema(
              latitude: Pangea::Resources::Types::String,
              longitude: Pangea::Resources::Types::String
            ).optional
          ).optional

          # Alias record configuration
          attribute :alias?, Pangea::Resources::Types::Hash.schema(
            name: Pangea::Resources::Types::String,
            zone_id: Pangea::Resources::Types::String,
            evaluate_target_health: Pangea::Resources::Types::Bool.default(false)
          ).optional

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
          
          # Validate zone ID format
          unless attrs.zone_id.match?(/\A[A-Z0-9]+\z/)
            raise Dry::Struct::Error, "Invalid hosted zone ID format: #{attrs.zone_id}"
          end

          # Validate record name format
          unless attrs.valid_record_name?
            raise Dry::Struct::Error, "Invalid DNS record name format: #{attrs.name}"
          end

          # Alias records and regular records are mutually exclusive
          if attrs.alias && (attrs.ttl || attrs.records.any?)
            raise Dry::Struct::Error, "Alias records cannot have TTL or records values"
          end

          # Non-alias records need TTL and records
          if !attrs.alias
            if attrs.records.empty?
              raise Dry::Struct::Error, "Non-alias records must have at least one record value"
            end
            unless attrs.ttl
              raise Dry::Struct::Error, "Non-alias records must have a TTL value"
            end
          end

          # Validate record type specific constraints
          attrs.validate_record_type_constraints

          # Routing policy validations
          routing_policies = [
            attrs.weighted_routing_policy,
            attrs.latency_routing_policy, 
            attrs.failover_routing_policy,
            attrs.geolocation_routing_policy,
            attrs.geoproximity_routing_policy
          ].compact

          if routing_policies.length > 1
            raise Dry::Struct::Error, "Only one routing policy can be specified per record"
          end

          # Set identifier required for routing policies (except multivalue)
          if routing_policies.any? && !attrs.multivalue_answer && !attrs.set_identifier
            raise Dry::Struct::Error, "set_identifier is required when using routing policies"
          end

          # Health check validation
          if attrs.health_check_id
            unless attrs.health_check_id.match?(/\A[a-f0-9\-]+\z/)
              raise Dry::Struct::Error, "Invalid health check ID format: #{attrs.health_check_id}"
            end
          end

            attrs
          end

          # Helper methods
          def valid_record_name?
            # Basic DNS name validation
            return false if name.nil? || name.empty?
            return false if name.length > 253
            
            # Allow wildcard at the beginning
            name_to_check = name.start_with?('*.') ? name[2..-1] : name
            
            # Check each label
            labels = name_to_check.split('.')
            labels.all? { |label| valid_dns_label?(label) }
          end

          def valid_dns_label?(label)
            return false if label.length > 63
            return false if label.empty?
            
            # Can contain letters, numbers, hyphens
            return false unless label.match?(/\A[a-zA-Z0-9\-]+\z/)
            
            # Cannot start or end with hyphen
            return false if label.start_with?('-') || label.end_with?('-')
            
            true
          end

          def validate_record_type_constraints
            case type
            when "A"
              records.each do |record|
                unless valid_ipv4?(record)
                  raise Dry::Struct::Error, "A record must contain valid IPv4 addresses: #{record}"
                end
              end
            when "AAAA"
              records.each do |record|
                unless valid_ipv6?(record)
                  raise Dry::Struct::Error, "AAAA record must contain valid IPv6 addresses: #{record}"
                end
              end
            when "CNAME"
              if records.length != 1
                raise Dry::Struct::Error, "CNAME record must have exactly one target"
              end
            when "MX"
              records.each do |record|
                unless record.match?(/\A\d+\s+\S+\z/)
                  raise Dry::Struct::Error, "MX record must be in format 'priority hostname': #{record}"
                end
              end
            when "SRV"
              records.each do |record|
                unless record.match?(/\A\d+\s+\d+\s+\d+\s+\S+\z/)
                  raise Dry::Struct::Error, "SRV record must be in format 'priority weight port target': #{record}"
                end
              end
            end
          end

          def valid_ipv4?(ip)
            ip.match?(/\A(?:[0-9]{1,3}\.){3}[0-9]{1,3}\z/) &&
              ip.split('.').all? { |octet| (0..255).include?(octet.to_i) }
          end

          def valid_ipv6?(ip)
            # Simplified IPv6 validation
            ip.match?(/\A[0-9a-fA-F:]+\z/) && ip.include?(':')
          end

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