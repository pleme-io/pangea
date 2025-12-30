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

module Pangea
  module Components
    module MicroserviceDeployment
      # Health check configuration
      class HealthCheckConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :path, Types::String.default("/health")
        attribute :interval, Types::Integer.default(30)
        attribute :timeout, Types::Integer.default(5)
        attribute :healthy_threshold, Types::Integer.default(2)
        attribute :unhealthy_threshold, Types::Integer.default(3)
        attribute :matcher, Types::String.default("200")
      end
    end
  end
end
