# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module SfnExtended
        class ActivityTaskAttributes < Dry::Struct
          attribute :activity_arn, Types::String
          attribute :worker_name, Types::String.optional
        end

        class ActivityTaskReference < ::Pangea::Resources::ResourceReference
          property :id
          property :task_token
        end

        module ActivityTask
          def aws_sfn_activity_task(name, attributes = {})
            attrs = ActivityTaskAttributes.new(attributes)
            
            synthesizer.resource :aws_sfn_activity_task, name do
              activity_arn attrs.activity_arn
              worker_name attrs.worker_name if attrs.worker_name
            end

            ActivityTaskReference.new(name, :aws_sfn_activity_task, synthesizer, attrs)
          end
        end
      end
    end
  end
end