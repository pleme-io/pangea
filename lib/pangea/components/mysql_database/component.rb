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

require 'pangea/components/base'
require 'pangea/components/mysql_database/types'
require 'pangea/resources/aws'
require_relative 'component/database'
require_relative 'component/monitoring'
require_relative 'component/helpers'

module Pangea
  module Components
    # MySQL Database component with backups, monitoring, and security
    # Creates a production-ready RDS MySQL instance with comprehensive features
    def mysql_database(name, attributes = {})
      include Base
      include Resources::AWS
      extend MySqlDatabaseComponent::Database
      extend MySqlDatabaseComponent::Monitoring
      extend MySqlDatabaseComponent::Helpers

      # Validate and set defaults
      component_attrs = MySqlDatabase::MySqlDatabaseAttributes.new(attributes)

      # Generate component-specific tags
      component_tag_set = component_tags('MySqlDatabase', name, component_attrs.tags)

      resources = {}

      # Create DB Subnet Group
      subnet_group_ref = create_subnet_group(name, component_attrs, component_tag_set)
      resources[:subnet_group] = subnet_group_ref

      # Create DB Parameter Group if requested
      parameter_group_ref = create_parameter_group(name, component_attrs, component_tag_set)
      resources[:parameter_group] = parameter_group_ref if parameter_group_ref

      # Build RDS instance attributes and create the instance
      rds_attrs = build_rds_attributes(name, component_attrs, subnet_group_ref, parameter_group_ref, component_tag_set)
      db_instance_ref = aws_db_instance(component_resource_name(name, :db_instance), rds_attrs)
      resources[:db_instance] = db_instance_ref

      # Create read replicas if requested
      read_replicas = create_read_replicas(name, component_attrs, db_instance_ref, component_tag_set)
      resources[:read_replicas] = read_replicas unless read_replicas.empty?

      # Create CloudWatch alarms for monitoring
      resources[:alarms] = create_cloudwatch_alarms(name, db_instance_ref, component_tag_set)

      # Calculate outputs
      outputs = build_component_outputs(
        name,
        component_attrs,
        db_instance_ref,
        subnet_group_ref,
        parameter_group_ref,
        read_replicas
      )

      create_component_reference(
        'mysql_database',
        name,
        component_attrs.to_h,
        resources,
        outputs
      )
    end
  end
end
