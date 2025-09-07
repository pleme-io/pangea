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
        # ElastiCache user group for Redis AUTH
        class UserGroupAttributes < Dry::Struct
          attribute :user_group_id, Types::String
          attribute :engine, Types::String.default('redis')
          attribute :user_ids, Types::Array.of(Types::String).default(['default'])
          attribute :tags, Types::Hash.default({})
        end

        # ElastiCache user group reference
        class UserGroupReference < ::Pangea::Resources::ResourceReference
          property :id
          property :user_group_id
          property :arn
          property :engine
          property :status

          def user_ids
            get_attribute(:user_ids) || ['default']
          end

          def redis?
            engine == 'redis'
          end

          def active?
            status == 'active'
          end

          def creating?
            status == 'creating'
          end

          def user_count
            user_ids.length
          end

          def has_default_user?
            user_ids.include?('default')
          end
        end

        module UserGroup
          # Creates an ElastiCache user group for Redis AUTH
          #
          # @param name [Symbol] The user group name
          # @param attributes [Hash] User group configuration
          # @return [UserGroupReference] Reference to the user group
          def aws_elasticache_user_group(name, attributes = {})
            group_attrs = UserGroupAttributes.new(attributes)
            
            synthesizer.resource :aws_elasticache_user_group, name do
              user_group_id group_attrs.user_group_id
              engine group_attrs.engine
              user_ids group_attrs.user_ids
              
              tags group_attrs.tags unless group_attrs.tags.empty?
            end

            UserGroupReference.new(name, :aws_elasticache_user_group, synthesizer, group_attrs)
          end
        end
      end
    end
  end
end