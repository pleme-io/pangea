# frozen_string_literal: true

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