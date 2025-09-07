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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_db_snapshot/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS DB Snapshot with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] DB snapshot attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_db_snapshot(name, attributes = {})
        # Validate attributes using dry-struct
        snapshot_attrs = Types::DbSnapshotAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_db_snapshot, name) do
          db_instance_identifier snapshot_attrs.db_instance_identifier
          db_snapshot_identifier snapshot_attrs.db_snapshot_identifier
          
          # Apply tags if present
          if snapshot_attrs.tags.any?
            tags do
              snapshot_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_db_snapshot',
          name: name,
          resource_attributes: snapshot_attrs.to_h,
          outputs: {
            id: "${aws_db_snapshot.#{name}.id}",
            arn: "${aws_db_snapshot.#{name}.db_snapshot_arn}",
            db_instance_identifier: "${aws_db_snapshot.#{name}.db_instance_identifier}",
            db_snapshot_identifier: "${aws_db_snapshot.#{name}.db_snapshot_identifier}",
            allocated_storage: "${aws_db_snapshot.#{name}.allocated_storage}",
            availability_zone: "${aws_db_snapshot.#{name}.availability_zone}",
            db_instance_class: "${aws_db_snapshot.#{name}.instance_class}",
            engine: "${aws_db_snapshot.#{name}.engine}",
            engine_version: "${aws_db_snapshot.#{name}.engine_version}",
            license_model: "${aws_db_snapshot.#{name}.license_model}",
            master_username: "${aws_db_snapshot.#{name}.master_username}",
            option_group_name: "${aws_db_snapshot.#{name}.option_group_name}",
            port: "${aws_db_snapshot.#{name}.port}",
            snapshot_create_time: "${aws_db_snapshot.#{name}.snapshot_create_time}",
            snapshot_type: "${aws_db_snapshot.#{name}.snapshot_type}",
            source_region: "${aws_db_snapshot.#{name}.source_region}",
            status: "${aws_db_snapshot.#{name}.status}",
            storage_type: "${aws_db_snapshot.#{name}.storage_type}",
            vpc_id: "${aws_db_snapshot.#{name}.vpc_id}",
            tags: "${aws_db_snapshot.#{name}.tags}",
            tags_all: "${aws_db_snapshot.#{name}.tags_all}"
          },
          computed_properties: {
            follows_naming_convention: snapshot_attrs.follows_naming_convention?,
            base_name: snapshot_attrs.base_name,
            timestamp: snapshot_attrs.timestamp,
            age_in_days: snapshot_attrs.age_in_days,
            snapshot_summary: snapshot_attrs.snapshot_summary,
            estimated_monthly_storage_cost: snapshot_attrs.estimated_monthly_storage_cost
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)