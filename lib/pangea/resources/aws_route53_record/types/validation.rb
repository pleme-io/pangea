# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module Route53RecordValidation
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
        end
      end
    end
  end
end
