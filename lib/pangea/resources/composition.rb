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

require 'pangea/resources/reference'

require_relative 'composition/helpers'
require_relative 'composition/vpc_with_subnets'
require_relative 'composition/web_server'
require_relative 'composition/auto_scaling_web_tier'
require_relative 'composition/composite_vpc_reference'
require_relative 'composition/composite_web_server_reference'
require_relative 'composition/composite_auto_scaling_reference'

module Pangea
  module Resources
    # Resource composition helpers for common infrastructure patterns
    module Composition
      include AWS
      include Composition::Helpers
      include Composition::VpcWithSubnets
      include Composition::WebServer
      include Composition::AutoScalingWebTier
    end
  end
end
