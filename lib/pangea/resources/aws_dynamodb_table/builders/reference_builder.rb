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
      module DynamoDBTable
        # Builds resource references for DynamoDB tables
        module ReferenceBuilder
          TERRAFORM_OUTPUTS = %i[
            id arn name billing_mode hash_key range_key
            read_capacity write_capacity stream_arn stream_label
            table_class tags_all
          ].freeze

          COMPUTED_PROPERTIES = %i[
            is_pay_per_request? is_provisioned? has_range_key? has_gsi?
            has_lsi? has_stream? has_ttl? has_encryption? has_pitr?
            is_global_table? total_indexes estimated_monthly_cost
          ].freeze

          module_function

          def build_reference(name, table_attrs)
            ref = ResourceReference.new(
              type: 'aws_dynamodb_table',
              name: name,
              resource_attributes: table_attrs.to_h,
              outputs: build_outputs(name)
            )

            add_computed_properties(ref, table_attrs)
            ref
          end

          def build_outputs(name)
            TERRAFORM_OUTPUTS.each_with_object({}) do |output, hash|
              hash[output] = "${aws_dynamodb_table.#{name}.#{output}}"
            end
          end

          def add_computed_properties(ref, table_attrs)
            COMPUTED_PROPERTIES.each do |prop|
              ref.define_singleton_method(prop) { table_attrs.public_send(prop) }
            end
          end
        end
      end
    end
  end
end
