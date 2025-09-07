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
        class MapRunAttributes < Dry::Struct
          attribute :execution_arn, Types::String
          attribute :max_concurrency, Types::Integer.default(0)
        end

        class MapRunReference < ::Pangea::Resources::ResourceReference
          property :id
          property :arn
        end

        module MapRun
          def aws_sfn_map_run(name, attributes = {})
            attrs = MapRunAttributes.new(attributes)
            
            synthesizer.resource :aws_sfn_map_run, name do
              execution_arn attrs.execution_arn
              max_concurrency attrs.max_concurrency
            end

            MapRunReference.new(name, :aws_sfn_map_run, synthesizer, attrs)
          end
        end
      end
    end
  end
end