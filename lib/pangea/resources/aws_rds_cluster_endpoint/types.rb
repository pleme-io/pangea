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
require_relative 'types/members'
require_relative 'types/configs'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS RDS Cluster Endpoint resources
        class RdsClusterEndpointAttributes < Dry::Struct
          # Cluster identifier that the endpoint will belong to
          attribute :cluster_identifier, Resources::Types::String

          # Cluster endpoint identifier (unique within the cluster)
          attribute :cluster_endpoint_identifier, Resources::Types::String

          # Custom endpoint type (READER, WRITER, ANY)
          attribute :custom_endpoint_type, Resources::Types::String.enum("READER", "WRITER", "ANY")

          # List of static cluster members to include in the endpoint
          # These members will always be included regardless of their role
          attribute :static_members, Resources::Types::Array.of(StaticMember).default([].freeze)

          # List of cluster members to exclude from the endpoint
          # These members will never be included in load balancing
          attribute :excluded_members, Resources::Types::Array.of(ExcludedMember).default([].freeze)

          # Tags to apply to the cluster endpoint
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            # Cannot have the same DB instance in both static_members and excluded_members
            static_db_ids = attrs.static_members.map(&:db_instance_identifier).to_set
            excluded_db_ids = attrs.excluded_members.map(&:db_instance_identifier).to_set

            overlap = static_db_ids & excluded_db_ids
            if overlap.any?
              raise Dry::Struct::Error, "DB instances cannot be in both static_members and excluded_members: #{overlap.to_a.join(', ')}"
            end

            validate_endpoint_identifier(attrs.cluster_endpoint_identifier)
            validate_writer_restrictions(attrs)

            attrs
          end

          # Validate endpoint identifier format and length
          def self.validate_endpoint_identifier(identifier)
            unless identifier =~ /^[a-zA-Z][a-zA-Z0-9-]*$/
              raise Dry::Struct::Error, "cluster_endpoint_identifier must start with a letter and contain only letters, numbers, and hyphens"
            end

            if identifier.length > 63
              raise Dry::Struct::Error, "cluster_endpoint_identifier cannot exceed 63 characters"
            end
          end

          # Validate WRITER endpoint restrictions
          def self.validate_writer_restrictions(attrs)
            return unless attrs.custom_endpoint_type == "WRITER"

            if attrs.static_members.any?
              raise Dry::Struct::Error, "WRITER endpoints cannot have static members"
            end

            if attrs.excluded_members.any?
              raise Dry::Struct::Error, "WRITER endpoints cannot have excluded members"
            end
          end

          # Check if this is a reader endpoint
          def is_reader?
            custom_endpoint_type == "READER"
          end

          # Check if this is a writer endpoint
          def is_writer?
            custom_endpoint_type == "WRITER"
          end

          # Check if this is an any endpoint
          def is_any?
            custom_endpoint_type == "ANY"
          end

          # Check if endpoint has static member configuration
          def has_static_members?
            static_members.any?
          end

          # Check if endpoint has excluded member configuration
          def has_excluded_members?
            excluded_members.any?
          end

          # Get list of static member DB instance identifiers
          def static_member_db_ids
            static_members.map(&:db_instance_identifier)
          end

          # Get list of excluded member DB instance identifiers
          def excluded_member_db_ids
            excluded_members.map(&:db_instance_identifier)
          end

          # Check if endpoint uses custom member configuration
          def uses_custom_member_config?
            has_static_members? || has_excluded_members?
          end

          # Get endpoint configuration summary
          def configuration_summary
            config = ["Type: #{custom_endpoint_type}"]

            config << "Static members: #{static_member_db_ids.join(', ')}" if has_static_members?
            config << "Excluded members: #{excluded_member_db_ids.join(', ')}" if has_excluded_members?
            config << "Uses cluster default member selection" unless uses_custom_member_config?

            config.join("; ")
          end

          # Validate that referenced DB instance exists in the cluster
          def validate_db_instances(cluster_instances)
            all_referenced_ids = static_member_db_ids + excluded_member_db_ids
            cluster_db_ids = cluster_instances.map { |instance| instance.fetch(:db_instance_identifier) }

            invalid_ids = all_referenced_ids - cluster_db_ids
            if invalid_ids.any?
              raise Dry::Struct::Error, "Referenced DB instances not found in cluster: #{invalid_ids.join(', ')}"
            end
          end

          # Generate unique endpoint name for use in DNS and connection strings
          def endpoint_dns_name(cluster_arn_or_id)
            cluster_id = cluster_arn_or_id.include?(':') ? cluster_arn_or_id.split(':').last : cluster_arn_or_id
            "#{cluster_id}.cluster-custom-#{cluster_endpoint_identifier}"
          end

          # Estimate additional monthly cost (Aurora endpoints are generally free)
          def estimated_monthly_cost
            "$0.00 (Custom endpoints are included with Aurora clusters)"
          end
        end
      end
    end
  end
end
