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


require 'pangea/resources/types'
require 'pangea/resources/base'
require 'pangea/resources/reference'

# Provider gems (loaded via gem dependencies)
require 'pangea-aws'
require 'pangea-cloudflare'
require 'pangea-hcloud'

require 'pangea/resources/composition'

module Pangea
  # Resource abstraction system with type-safe functions and return values
  module Resources
    # Auto-include all provider resources and composition helpers in template contexts
    def self.included(base)
      base.include AWS
      base.include Cloudflare
      base.include Hetzner
      base.include Composition
    end
  end
end