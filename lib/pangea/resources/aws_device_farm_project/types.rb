# frozen_string_literal: true

require "dry-struct"
require "pangea/types"

module Pangea
  module Resources
    module AwsDeviceFarmProject
      module Types
        # Main attributes for Device Farm project
        class Attributes < Dry::Struct
          # Required attributes
          attribute :name, Pangea::Types::String
          
          # Optional attributes
          attribute :default_job_timeout_minutes?, Pangea::Types::Integer.constrained(gteq: 5, lteq: 150)
          attribute :tags?, Pangea::Types::Hash.map(Pangea::Types::String, Pangea::Types::String)

          def self.from_dynamic(d)
            d = Pangea::Types::Hash[d]
            new(
              name: d.fetch(:name),
              default_job_timeout_minutes: d[:default_job_timeout_minutes],
              tags: d[:tags]
            )
          end
        end

        # Reference for Device Farm project resources
        class Reference < Dry::Struct
          attribute :id, Pangea::Types::String
          attribute :arn, Pangea::Types::String
        end
      end
    end
  end
end