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

module Pangea
  module Resources
    module AWS
      module Types
        # Valid ElastiCache node types
        module ElastiCacheNodeTypes
          # Burstable Performance node types
          BURSTABLE = [
            'cache.t4g.nano', 'cache.t4g.micro', 'cache.t4g.small', 'cache.t4g.medium',
            'cache.t3.micro', 'cache.t3.small', 'cache.t3.medium'
          ].freeze

          # General Purpose node types
          GENERAL_PURPOSE = [
            'cache.m6g.large', 'cache.m6g.xlarge', 'cache.m6g.2xlarge', 'cache.m6g.4xlarge',
            'cache.m6g.8xlarge', 'cache.m6g.12xlarge', 'cache.m6g.16xlarge',
            'cache.m5.large', 'cache.m5.xlarge', 'cache.m5.2xlarge', 'cache.m5.4xlarge',
            'cache.m5.12xlarge', 'cache.m5.24xlarge'
          ].freeze

          # Memory Optimized node types
          MEMORY_OPTIMIZED = [
            'cache.r6g.large', 'cache.r6g.xlarge', 'cache.r6g.2xlarge', 'cache.r6g.4xlarge',
            'cache.r6g.8xlarge', 'cache.r6g.12xlarge', 'cache.r6g.16xlarge',
            'cache.r5.large', 'cache.r5.xlarge', 'cache.r5.2xlarge', 'cache.r5.4xlarge',
            'cache.r5.12xlarge', 'cache.r5.24xlarge'
          ].freeze

          # All valid node types
          ALL = (BURSTABLE + GENERAL_PURPOSE + MEMORY_OPTIMIZED).freeze
        end
      end
    end
  end
end
