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

require 'pangea/architectures/patterns/web_application'
require 'pangea/architectures/patterns/microservices'
require 'pangea/architectures/patterns/data_processing'

require_relative 'examples/architectures/ecommerce_platform'
require_relative 'examples/architectures/multi_region_saas'
require_relative 'examples/architectures/ml_platform'
require_relative 'examples/architectures/devops_platform'
require_relative 'examples/architectures/helpers'

module Pangea
  module Architectures
    # Example architecture compositions demonstrating real-world patterns
    module Examples
      include Patterns::WebApplication
      include Patterns::Microservices
      include Patterns::DataProcessing

      include EcommercePlatform
      include MultiRegionSaas
      include MlPlatform
      include DevopsPlatform
      include Helpers
    end
  end
end
