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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Route53 Query Log Configuration resources
      class Route53QueryLogAttributes < Dry::Struct
        # Name for the query log configuration
        attribute :name, Resources::Types::String

        # Hosted zone ID to log queries for
        attribute :hosted_zone_id, Resources::Types::String

        # CloudWatch Logs destination ARN
        attribute :destination_arn, Resources::Types::String

        # Tags to apply to the query log configuration
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate hosted zone ID format
          unless attrs.hosted_zone_id.match?(/\A[A-Z0-9]{10,32}\z/)
            raise Dry::Struct::Error, "Invalid hosted zone ID format: #{attrs.hosted_zone_id}"
          end

          # Validate CloudWatch Logs ARN format
          unless attrs.destination_arn.match?(/\Aarn:aws:logs:[a-z0-9\-]+:[0-9]+:log-group:.+\z/)
            raise Dry::Struct::Error, "Invalid CloudWatch Logs ARN format: #{attrs.destination_arn}"
          end

          # Validate name format
          unless attrs.name.match?(/\A[a-zA-Z0-9\-_]{1,64}\z/)
            raise Dry::Struct::Error, "Query log name must be 1-64 characters and contain only alphanumeric, hyphens, and underscores"
          end

          attrs
        end

        # Helper methods
        def log_group_name
          destination_arn.split(':log-group:').last.split(':').first
        end

        def aws_region
          destination_arn.split(':')[3]
        end

        def aws_account_id
          destination_arn.split(':')[4]
        end

        def estimated_monthly_cost
          "$1.00 per million queries logged + CloudWatch Logs ingestion costs"
        end

        def validate_configuration
          warnings = []
          
          unless destination_arn.include?('/aws/route53')
            warnings << "Consider using AWS Route53-specific log group naming convention"
          end
          
          if name.length < 3
            warnings << "Very short configuration name - consider more descriptive naming"
          end
          
          warnings
        end

        # Check if this is for a private hosted zone
        def private_zone_logging?
          # This would need additional context about the hosted zone
          # For now, return false as a default
          false
        end

        # Get logging scope
        def logging_scope
          private_zone_logging? ? "private_zone" : "public_zone"
        end
      end

      # Common Route53 query log configurations
      module Route53QueryLogConfigs
        # Standard query logging for public zone
        def self.public_zone_logging(zone_name, hosted_zone_id, log_group_arn)
          {
            name: "#{zone_name.gsub('.', '-')}-query-logs",
            hosted_zone_id: hosted_zone_id,
            destination_arn: log_group_arn,
            tags: {
              ZoneName: zone_name,
              Purpose: "DNS query logging",
              LogType: "route53_queries"
            }
          }
        end

        # Private zone query logging
        def self.private_zone_logging(zone_name, hosted_zone_id, log_group_arn)
          {
            name: "#{zone_name.gsub('.', '-')}-private-query-logs",
            hosted_zone_id: hosted_zone_id,
            destination_arn: log_group_arn,
            tags: {
              ZoneName: zone_name,
              ZoneType: "private",
              Purpose: "Private DNS query logging",
              LogType: "route53_private_queries"
            }
          }
        end

        # Development environment query logging
        def self.development_logging(zone_name, hosted_zone_id, log_group_arn)
          {
            name: "#{zone_name.gsub('.', '-')}-dev-query-logs",
            hosted_zone_id: hosted_zone_id,
            destination_arn: log_group_arn,
            tags: {
              Environment: "development",
              ZoneName: zone_name,
              Purpose: "Development DNS debugging",
              LogType: "route53_dev_queries",
              AutoDelete: "true"
            }
          }
        end

        # Corporate security logging
        def self.security_logging(zone_name, hosted_zone_id, log_group_arn, organization)
          {
            name: "#{zone_name.gsub('.', '-')}-security-query-logs",
            hosted_zone_id: hosted_zone_id,
            destination_arn: log_group_arn,
            tags: {
              Organization: organization,
              ZoneName: zone_name,
              Purpose: "Security DNS monitoring",
              LogType: "route53_security_queries",
              CriticalityLevel: "high",
              SecurityMonitoring: "enabled"
            }
          }
        end

        # High-traffic zone logging
        def self.high_traffic_logging(zone_name, hosted_zone_id, log_group_arn)
          {
            name: "#{zone_name.gsub('.', '-')}-traffic-query-logs",
            hosted_zone_id: hosted_zone_id,
            destination_arn: log_group_arn,
            tags: {
              ZoneName: zone_name,
              TrafficLevel: "high",
              Purpose: "High-traffic DNS analysis",
              LogType: "route53_traffic_queries",
              AnalyticsEnabled: "true"
            }
          }
        end
      end
    end
  end
end