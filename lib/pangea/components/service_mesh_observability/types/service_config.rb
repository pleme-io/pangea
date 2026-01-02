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
    module ServiceMeshObservability
      # Service configuration for observability
      class ServiceConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String
        attribute :namespace, Types::String.default("default")
        attribute :cluster_ref, Types::ResourceReference
        attribute :task_definition_ref, Types::ResourceReference.optional
        attribute :deployment_ref, Types::ResourceReference.optional
        attribute :port, Types::Integer.default(80)
        attribute :protocol, Types::String.enum('HTTP', 'GRPC', 'TCP').default('HTTP')
        attribute :health_check_path, Types::String.default("/health")
      end
    end
  end
end
