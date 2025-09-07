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
        class UserGroupAssociationAttributes < Dry::Struct
          attribute :user_group_id, Types::String
          attribute :user_id, Types::String
        end

        class UserGroupAssociationReference < ::Pangea::Resources::ResourceReference
          property :id
        end

        module UserGroupAssociation
          def aws_elasticache_user_group_association(name, attributes = {})
            attrs = UserGroupAssociationAttributes.new(attributes)
            
            synthesizer.resource :aws_elasticache_user_group_association, name do
              user_group_id attrs.user_group_id
              user_id attrs.user_id
            end

            UserGroupAssociationReference.new(name, :aws_elasticache_user_group_association, synthesizer, attrs)
          end
        end
      end
    end
  end
end