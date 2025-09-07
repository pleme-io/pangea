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
      module ElastiCacheExtended
        class ParameterGroupParameterAttributes < Dry::Struct
          attribute :cache_parameter_group_name, Types::String
          attribute :parameter_name, Types::String
          attribute :parameter_value, Types::String
        end

        class ParameterGroupParameterReference < ::Pangea::Resources::ResourceReference
          property :id
        end

        module ParameterGroupParameter
          def aws_elasticache_parameter_group_parameter(name, attributes = {})
            attrs = ParameterGroupParameterAttributes.new(attributes)
            
            synthesizer.resource :aws_elasticache_parameter_group_parameter, name do
              cache_parameter_group_name attrs.cache_parameter_group_name
              parameter_name attrs.parameter_name
              parameter_value attrs.parameter_value
            end

            ParameterGroupParameterReference.new(name, :aws_elasticache_parameter_group_parameter, synthesizer, attrs)
          end
        end
      end
    end
  end
end