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

require_relative 'helpers/basic'
require_relative 'helpers/configuration'
require_relative 'helpers/method_settings'

module Pangea
  module Resources
    module AWS
      module ApiGatewayStageResource
        # Helper methods for API Gateway Stage resource reference
        module Helpers
          include HelpersModules::Basic
          include HelpersModules::Configuration
          include HelpersModules::MethodSettings

          # Add computed properties to the resource reference
          def add_reference_helpers(ref, name, stage_attrs)
            add_basic_helpers(ref, stage_attrs)
            add_stage_type_helpers(ref, stage_attrs)
            add_cache_helpers(ref, stage_attrs)
            add_throttling_helpers(ref, stage_attrs)
            add_logging_helpers(ref, stage_attrs)
            add_canary_helpers(ref, stage_attrs)
            add_variable_helpers(ref, stage_attrs)
            add_method_settings_helpers(ref, name, stage_attrs)
            add_security_helpers(ref, stage_attrs)
            add_optimization_helpers(ref, stage_attrs)
          end
        end
      end
    end
  end
end
