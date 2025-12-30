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
      module Lightsail
        # Database resources for AWS Lightsail
        module Database
          def aws_lightsail_database(name, attributes = {})
            required_attrs = %i[relational_database_blueprint_id relational_database_bundle_id master_database_name master_username]
            optional_attrs = {
              master_password: nil,
              availability_zone: nil,
              skip_final_snapshot: false,
              final_snapshot_name: nil,
              tags: {}
            }

            db_attrs = optional_attrs.merge(attributes)
            validate_required_attrs!(required_attrs, db_attrs)

            resource(:aws_lightsail_database, name) do
              relational_database_blueprint_id db_attrs[:relational_database_blueprint_id]
              relational_database_bundle_id db_attrs[:relational_database_bundle_id]
              master_database_name db_attrs[:master_database_name]
              master_username db_attrs[:master_username]
              master_password db_attrs[:master_password] if db_attrs[:master_password]
              availability_zone db_attrs[:availability_zone] if db_attrs[:availability_zone]
              skip_final_snapshot db_attrs[:skip_final_snapshot]
              final_snapshot_name db_attrs[:final_snapshot_name] if db_attrs[:final_snapshot_name]
              tags db_attrs[:tags] if db_attrs[:tags].any?
            end

            ResourceReference.new(
              type: 'aws_lightsail_database',
              name: name,
              resource_attributes: db_attrs,
              outputs: {
                id: "${aws_lightsail_database.#{name}.id}",
                arn: "${aws_lightsail_database.#{name}.arn}",
                master_endpoint_address: "${aws_lightsail_database.#{name}.master_endpoint_address}",
                master_endpoint_port: "${aws_lightsail_database.#{name}.master_endpoint_port}",
                engine: "${aws_lightsail_database.#{name}.engine}",
                engine_version: "${aws_lightsail_database.#{name}.engine_version}"
              }
            )
          end
        end
      end
    end
  end
end
