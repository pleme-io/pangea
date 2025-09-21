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
      class IotTopicRuleAttributes < Dry::Struct
        attribute :name, Resources::Types::IotTopicRuleName
        attribute :enabled, Resources::Types::Bool.default(true)
        attribute :sql, Resources::Types::IotSqlQuery
        attribute :sql_version, Resources::Types::String.default("2016-03-23")
        attribute :aws_iot_sql_version, Resources::Types::String.optional
        attribute :description, Resources::Types::String.optional
        attribute :actions, Resources::Types::Array.of(Types::Hash).default([].freeze)
        attribute :error_action, Resources::Types::Hash.optional
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)
        
        def action_types
          actions.map { |action| action.keys.first.to_s }.uniq
        end
        
        def has_error_handling?
          !error_action.nil?
        end
        
        def sql_complexity_score
          # Simple scoring based on SQL features
          score = 0
          score += 1 if sql.upcase.include?('WHERE')
          score += 1 if sql.upcase.include?('JOIN')
          score += 2 if sql.upcase.include?('CASE')
          score += 1 if sql.upcase.include?('FUNCTION')
          score
        end
      end
    end
  end
end