# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # SageMaker Pipeline attributes with MLOps workflow validation
        class SageMakerPipelineAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :pipeline_name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 256,
            format: /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/
          )
          attribute :pipeline_definition, Resources::Types::String
          attribute :role_arn, Resources::Types::String.constrained(
            format: /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9_+=,.@-]+\z/
          )
          
          # Optional attributes
          attribute :pipeline_description, Resources::Types::String.optional
          attribute :pipeline_display_name, Resources::Types::String.optional
          attribute :parallelism_configuration, Resources::Types::Hash.schema(
            max_parallel_execution_steps: Integer.constrained(gteq: 1, lteq: 256)
          ).optional
          attribute :tags, Resources::Types::AwsTags
          
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate pipeline definition is valid JSON
            if attrs[:pipeline_definition]
              begin
                JSON.parse(attrs[:pipeline_definition])
              rescue JSON::ParserError
                raise Dry::Struct::Error, "pipeline_definition must be valid JSON"
              end
            end
            
            super(attrs)
          end
          
          def estimated_pipeline_cost
            # Pipeline execution cost is based on step execution
            50.0 # Base estimate for typical pipeline execution
          end
          
          def has_parallelism_config?
            !parallelism_configuration.nil?
          end
          
          def max_parallel_steps
            parallelism_configuration&.dig(:max_parallel_execution_steps) || 50 # Default SageMaker limit
          end
        end
      end
    end
  end
end