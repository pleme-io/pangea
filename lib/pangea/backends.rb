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


require 'pangea/backends/base'
require 'pangea/backends/s3'
require 'pangea/backends/local'

module Pangea
  module Backends
    # Registry of available backends
    REGISTRY = {
      's3' => S3,
      'local' => Local
    }.freeze
    
    # Create a backend instance from configuration
    def self.create(type:, config: {})
      backend_class = REGISTRY[type.to_s]
      
      unless backend_class
        raise ArgumentError, "Unknown backend type: #{type}. Available: #{REGISTRY.keys.join(', ')}"
      end
      
      backend_class.new(config)
    end
    
    # Create backend from namespace entity
    def self.from_namespace(namespace)
      return nil unless namespace.state
      
      type = namespace.state[:type]
      config = namespace.state.dup
      config.delete(:type)
      
      create(type: type, config: config)
    end
  end
end