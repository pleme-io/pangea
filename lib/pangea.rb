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

require 'pangea-core'
require 'pangea/version'
require 'pangea/configuration'
require 'pangea/types'
require 'pangea/entities'
require 'pangea/utilities'

module Pangea
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def config
      configuration
    end

    def configure
      yield(configuration) if block_given?
      configuration
    end

    # Add utilities access
    def utilities
      Utilities
    end
  end
end
