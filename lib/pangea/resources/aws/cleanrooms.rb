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

module Pangea
  module Resources
    module AWS
      # AWS Clean Rooms resources for privacy-preserving data collaboration
      module CleanRooms
        include Base

        # Collaboration and membership management
        def aws_cleanrooms_collaboration(name, attributes = {})
          create_resource(:aws_cleanrooms_collaboration, name, attributes) do |attrs|
            Reference.new(:aws_cleanrooms_collaboration, name, {
              arn: computed_attr("${aws_cleanrooms_collaboration.#{name}.arn}"),
              id: computed_attr("${aws_cleanrooms_collaboration.#{name}.id}"),
              name: attrs[:name],
              description: attrs[:description],
              creator_member_abilities: attrs[:creator_member_abilities],
              members: attrs[:members],
              query_log_status: attrs[:query_log_status]
            })
          end
        end

        def aws_cleanrooms_membership(name, attributes = {})
          create_resource(:aws_cleanrooms_membership, name, attributes) do |attrs|
            Reference.new(:aws_cleanrooms_membership, name, {
              arn: computed_attr("${aws_cleanrooms_membership.#{name}.arn}"),
              id: computed_attr("${aws_cleanrooms_membership.#{name}.id}"),
              collaboration_arn: computed_attr("${aws_cleanrooms_membership.#{name}.collaboration_arn}"),
              collaboration_creator_account_id: computed_attr("${aws_cleanrooms_membership.#{name}.collaboration_creator_account_id}"),
              collaboration_creator_display_name: computed_attr("${aws_cleanrooms_membership.#{name}.collaboration_creator_display_name}"),
              collaboration_id: attrs[:collaboration_id],
              query_log_status: attrs[:query_log_status]
            })
          end
        end

        # Data configuration and table management
        def aws_cleanrooms_configured_table(name, attributes = {})
          create_resource(:aws_cleanrooms_configured_table, name, attributes) do |attrs|
            Reference.new(:aws_cleanrooms_configured_table, name, {
              arn: computed_attr("${aws_cleanrooms_configured_table.#{name}.arn}"),
              id: computed_attr("${aws_cleanrooms_configured_table.#{name}.id}"),
              name: attrs[:name],
              description: attrs[:description],
              table_reference: attrs[:table_reference],
              allowed_columns: attrs[:allowed_columns],
              analysis_method: attrs[:analysis_method]
            })
          end
        end

        def aws_cleanrooms_configured_table_association(name, attributes = {})
          create_resource(:aws_cleanrooms_configured_table_association, name, attributes) do |attrs|
            Reference.new(:aws_cleanrooms_configured_table_association, name, {
              arn: computed_attr("${aws_cleanrooms_configured_table_association.#{name}.arn}"),
              id: computed_attr("${aws_cleanrooms_configured_table_association.#{name}.id}"),
              configured_table_id: attrs[:configured_table_id],
              membership_id: attrs[:membership_id],
              name: attrs[:name],
              description: attrs[:description],
              role_arn: attrs[:role_arn]
            })
          end
        end

        # Schema and analysis management
        def aws_cleanrooms_schema(name, attributes = {})
          create_resource(:aws_cleanrooms_schema, name, attributes) do |attrs|
            Reference.new(:aws_cleanrooms_schema, name, {
              arn: computed_attr("${aws_cleanrooms_schema.#{name}.arn}"),
              id: computed_attr("${aws_cleanrooms_schema.#{name}.id}"),
              name: attrs[:name],
              description: attrs[:description],
              collaboration_id: attrs[:collaboration_id],
              definition: attrs[:definition],
              type: attrs[:type]
            })
          end
        end

        def aws_cleanrooms_analysis_template(name, attributes = {})
          create_resource(:aws_cleanrooms_analysis_template, name, attributes) do |attrs|
            Reference.new(:aws_cleanrooms_analysis_template, name, {
              arn: computed_attr("${aws_cleanrooms_analysis_template.#{name}.arn}"),
              id: computed_attr("${aws_cleanrooms_analysis_template.#{name}.id}"),
              name: attrs[:name],
              description: attrs[:description],
              membership_id: attrs[:membership_id],
              source: attrs[:source],
              format: attrs[:format]
            })
          end
        end

        # Query execution and privacy controls
        def aws_cleanrooms_protected_query(name, attributes = {})
          create_resource(:aws_cleanrooms_protected_query, name, attributes) do |attrs|
            Reference.new(:aws_cleanrooms_protected_query, name, {
              id: computed_attr("${aws_cleanrooms_protected_query.#{name}.id}"),
              membership_id: attrs[:membership_id],
              type: attrs[:type],
              sql_parameters: attrs[:sql_parameters],
              result_configuration: attrs[:result_configuration],
              status: computed_attr("${aws_cleanrooms_protected_query.#{name}.status}"),
              statistics: computed_attr("${aws_cleanrooms_protected_query.#{name}.statistics}")
            })
          end
        end

        def aws_cleanrooms_privacy_budget_template(name, attributes = {})
          create_resource(:aws_cleanrooms_privacy_budget_template, name, attributes) do |attrs|
            Reference.new(:aws_cleanrooms_privacy_budget_template, name, {
              arn: computed_attr("${aws_cleanrooms_privacy_budget_template.#{name}.arn}"),
              id: computed_attr("${aws_cleanrooms_privacy_budget_template.#{name}.id}"),
              membership_id: attrs[:membership_id],
              auto_refresh: attrs[:auto_refresh],
              privacy_budget_type: attrs[:privacy_budget_type],
              parameters: attrs[:parameters],
              tags: attrs[:tags]
            })
          end
        end
      end
    end
  end
end