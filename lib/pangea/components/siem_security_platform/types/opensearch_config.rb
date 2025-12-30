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
require 'pangea/components/types'

module Pangea
  module Components
    module SiemSecurityPlatform
      # OpenSearch domain configuration
      class OpenSearchConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :domain_name, Types::String.constrained(
          format: /\A[a-z][a-z0-9-]*\z/,
          min_size: 3,
          max_size: 28
        )
        attribute :engine_version, Types::String.default('OpenSearch_2.11')
        attribute :instance_type, Types::String.default('r5.large.search')
        attribute :instance_count, Types::Integer.default(3).constrained(gteq: 1)
        attribute :dedicated_master_enabled, Types::Bool.default(true)
        attribute :dedicated_master_type, Types::String.default('r5.large.search')
        attribute :dedicated_master_count, Types::Integer.default(3)
        attribute :zone_awareness_enabled, Types::Bool.default(true)
        attribute :availability_zone_count, Types::Integer.default(3).constrained(included_in: [2, 3])
        attribute :ebs_enabled, Types::Bool.default(true)
        attribute :volume_type, Types::String.enum('gp3', 'gp2', 'io1').default('gp3')
        attribute :volume_size, Types::Integer.default(100).constrained(gteq: 10, lteq: 16384)
        attribute :iops, Types::Integer.optional
        attribute :throughput, Types::Integer.optional
      end
    end
  end
end
