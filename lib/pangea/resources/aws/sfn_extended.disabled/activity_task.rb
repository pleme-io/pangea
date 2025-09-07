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