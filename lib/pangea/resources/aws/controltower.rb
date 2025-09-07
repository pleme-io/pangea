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


require 'pangea/resources/aws/controltower/control'
require 'pangea/resources/aws/controltower/landing_zone'
require 'pangea/resources/aws/controltower/enabled_control'

module Pangea
  module Resources
    module AWS
      # AWS Control Tower resources module
      # Includes all Control Tower resource implementations for managing
      # governance and compliance across AWS organizations.
      module ControlTower
        include Control
        include LandingZone
        include EnabledControl
      end
    end
  end
end