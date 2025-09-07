# frozen_string_literal: true

require_relative 'elasticache_extended/global_replication_group'
require_relative 'elasticache_extended/user_group'
require_relative 'elasticache_extended/user_group_association'
require_relative 'elasticache_extended/serverless_cache'
require_relative 'elasticache_extended/reserved_cache_node'
require_relative 'elasticache_extended/cache_policy'
require_relative 'elasticache_extended/parameter_group_parameter'
require_relative 'elasticache_extended/notification_topic'
require_relative 'elasticache_extended/auth_token'
require_relative 'elasticache_extended/backup_policy'

module Pangea
  module Resources
    module AWS
      # Extended ElastiCache resources for advanced caching scenarios
      module ElastiCacheExtended
        include GlobalReplicationGroup
        include UserGroup
        include UserGroupAssociation
        include ServerlessCache
        include ReservedCacheNode
        include CachePolicy
        include ParameterGroupParameter
        include NotificationTopic
        include AuthToken
        include BackupPolicy
      end
    end
  end
end