# frozen_string_literal: true

require "dry-struct"

module Pangea
  module Resources
    module AwsSumerianProject
      module Types
        include Dry::Types()

        class Attributes < Dry::Struct
          attribute :name, String
          attribute? :description, String
          attribute? :template, String.enum("empty", "starter", "augmented_reality", "virtual_reality")
          attribute? :tags, Hash.map(String, String)
        end

        class Reference < Dry::Struct
          attribute :id, String
          attribute :arn, String
          attribute :name, String
          attribute :description, String
          attribute :project_id, String
          attribute :owner, String
          attribute :creation_time, String
          attribute :last_updated_time, String
          attribute :state, String
        end
      end
    end
  end
end