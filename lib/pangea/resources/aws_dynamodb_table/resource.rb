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
require 'pangea/resources/aws_dynamodb_table/types'
require 'pangea/resource_registry'
require_relative 'builders/table_builder'
require_relative 'builders/reference_builder'

module Pangea
  module Resources
    module AWS
      # Create an AWS DynamoDB Table with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] DynamoDB table attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_dynamodb_table(name, attributes = {})
        table_attrs = AWS::Types::Types::DynamoDbTableAttributes.new(attributes)

        resource(:aws_dynamodb_table, name) do
          DynamoDBTable::TableBuilder.build_table(self, table_attrs)
        end

        DynamoDBTable::ReferenceBuilder.build_reference(name, table_attrs)
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)
