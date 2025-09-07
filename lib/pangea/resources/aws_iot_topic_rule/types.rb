# frozen_string_literal: true

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
        attribute :actions, Resources::Types::Array.of(Types::Hash).default([])
        attribute :error_action, Resources::Types::Hash.optional
        attribute :tags, Resources::Types::AwsTags.default({})
        
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