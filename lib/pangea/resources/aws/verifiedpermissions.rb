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
      # AWS Verified Permissions resources for fine-grained authorization
      module VerifiedPermissions
        include Base

        # Policy store management
        def aws_verifiedpermissions_policy_store(name, attributes = {})
          create_resource(:aws_verifiedpermissions_policy_store, name, attributes) do |attrs|
            Reference.new(:aws_verifiedpermissions_policy_store, name, {
              arn: computed_attr("${aws_verifiedpermissions_policy_store.#{name}.arn}"),
              id: computed_attr("${aws_verifiedpermissions_policy_store.#{name}.id}"),
              policy_store_id: computed_attr("${aws_verifiedpermissions_policy_store.#{name}.policy_store_id}"),
              validation_settings: attrs[:validation_settings],
              description: attrs[:description],
              created_date: computed_attr("${aws_verifiedpermissions_policy_store.#{name}.created_date}")
            })
          end
        end

        # Policy management
        def aws_verifiedpermissions_policy(name, attributes = {})
          create_resource(:aws_verifiedpermissions_policy, name, attributes) do |attrs|
            Reference.new(:aws_verifiedpermissions_policy, name, {
              arn: computed_attr("${aws_verifiedpermissions_policy.#{name}.arn}"),
              policy_id: computed_attr("${aws_verifiedpermissions_policy.#{name}.policy_id}"),
              policy_store_id: attrs[:policy_store_id],
              definition: attrs[:definition],
              policy_type: attrs[:policy_type],
              created_date: computed_attr("${aws_verifiedpermissions_policy.#{name}.created_date}"),
              last_updated_date: computed_attr("${aws_verifiedpermissions_policy.#{name}.last_updated_date}")
            })
          end
        end

        def aws_verifiedpermissions_policy_template(name, attributes = {})
          create_resource(:aws_verifiedpermissions_policy_template, name, attributes) do |attrs|
            Reference.new(:aws_verifiedpermissions_policy_template, name, {
              arn: computed_attr("${aws_verifiedpermissions_policy_template.#{name}.arn}"),
              policy_template_id: computed_attr("${aws_verifiedpermissions_policy_template.#{name}.policy_template_id}"),
              policy_store_id: attrs[:policy_store_id],
              description: attrs[:description],
              statement: attrs[:statement],
              created_date: computed_attr("${aws_verifiedpermissions_policy_template.#{name}.created_date}"),
              last_updated_date: computed_attr("${aws_verifiedpermissions_policy_template.#{name}.last_updated_date}")
            })
          end
        end

        # Identity source management
        def aws_verifiedpermissions_identity_source(name, attributes = {})
          create_resource(:aws_verifiedpermissions_identity_source, name, attributes) do |attrs|
            Reference.new(:aws_verifiedpermissions_identity_source, name, {
              arn: computed_attr("${aws_verifiedpermissions_identity_source.#{name}.arn}"),
              identity_source_id: computed_attr("${aws_verifiedpermissions_identity_source.#{name}.identity_source_id}"),
              policy_store_id: attrs[:policy_store_id],
              configuration: attrs[:configuration],
              principal_entity_type: attrs[:principal_entity_type],
              created_date: computed_attr("${aws_verifiedpermissions_identity_source.#{name}.created_date}"),
              last_updated_date: computed_attr("${aws_verifiedpermissions_identity_source.#{name}.last_updated_date}")
            })
          end
        end

        # Schema management
        def aws_verifiedpermissions_schema(name, attributes = {})
          create_resource(:aws_verifiedpermissions_schema, name, attributes) do |attrs|
            Reference.new(:aws_verifiedpermissions_schema, name, {
              arn: computed_attr("${aws_verifiedpermissions_schema.#{name}.arn}"),
              policy_store_id: attrs[:policy_store_id],
              definition: attrs[:definition],
              created_date: computed_attr("${aws_verifiedpermissions_schema.#{name}.created_date}"),
              last_updated_date: computed_attr("${aws_verifiedpermissions_schema.#{name}.last_updated_date}"),
              namespaces: computed_attr("${aws_verifiedpermissions_schema.#{name}.namespaces}")
            })
          end
        end
      end
    end
  end
end