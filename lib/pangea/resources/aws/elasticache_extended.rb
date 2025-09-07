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