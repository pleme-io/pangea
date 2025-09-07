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
        class NotificationTopicAttributes < Dry::Struct
          attribute :cache_cluster_id, Types::String
          attribute :notification_topic_arn, Types::String
        end

        class NotificationTopicReference < ::Pangea::Resources::ResourceReference
          property :id
        end

        module NotificationTopic
          def aws_elasticache_notification_topic(name, attributes = {})
            attrs = NotificationTopicAttributes.new(attributes)
            
            synthesizer.resource :aws_elasticache_notification_topic, name do
              cache_cluster_id attrs.cache_cluster_id
              notification_topic_arn attrs.notification_topic_arn
            end

            NotificationTopicReference.new(name, :aws_elasticache_notification_topic, synthesizer, attrs)
          end
        end
      end
    end
  end
end