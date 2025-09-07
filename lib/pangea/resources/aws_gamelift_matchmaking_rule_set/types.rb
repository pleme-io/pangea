# frozen_string_literal: true

require "dry-struct"

module Pangea
  module Resources
    module AwsGameliftMatchmakingRuleSet
      module Types
        include Dry::Types()

        class Attributes < Dry::Struct
          attribute :name, String
          attribute :rule_set_body, String
          attribute? :tags, Hash.map(String, String)
        end

        class Reference < Dry::Struct
          attribute :id, String
          attribute :arn, String
          attribute :name, String
          attribute :creation_time, String
          attribute :rule_set_body, String
        end
      end
    end
  end
end