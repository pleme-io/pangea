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

require_relative "types/enums"
require_relative "types/input"
require_relative "types/output"

module Pangea
  module Components
    module SpotInstanceCarbonOptimizer
      module Types
        # Regional carbon intensity data (gCO2/kWh)
        REGIONAL_CARBON_BASELINE = {
          'us-east-1' => 400,      # Virginia - mixed grid
          'us-east-2' => 450,      # Ohio - coal heavy
          'us-west-1' => 250,      # California - mixed renewables
          'us-west-2' => 50,       # Oregon - hydro
          'eu-central-1' => 350,   # Frankfurt - mixed
          'eu-west-1' => 80,       # Ireland - wind heavy
          'eu-north-1' => 40,      # Stockholm - renewable
          'ca-central-1' => 30,    # Montreal - hydro
          'ap-southeast-1' => 600, # Singapore - gas
          'ap-southeast-2' => 700, # Sydney - coal heavy
          'sa-east-1' => 100       # Sao Paulo - hydro
        }.freeze

        # Validation methods
        def self.validate_capacity(capacity)
          raise ArgumentError, "Target capacity must be positive" if capacity <= 0
          raise ArgumentError, "Target capacity cannot exceed 1000 for spot optimizer" if capacity > 1000
        end

        def self.validate_carbon_threshold(threshold)
          raise ArgumentError, "Carbon threshold must be between 0 and 1000 gCO2/kWh" unless (0..1000).include?(threshold)
        end

        def self.validate_regions(allowed, preferred)
          invalid = preferred - allowed
          raise ArgumentError, "Preferred regions must be subset of allowed regions: #{invalid.join(', ')}" unless invalid.empty?
        end

        def self.validate_spot_block_duration(use_blocks, duration)
          return unless use_blocks
          raise ArgumentError, "Spot block duration required when use_spot_blocks is true" if duration.nil?
          raise ArgumentError, "Spot block duration must be 1-6 hours" unless (1..6).include?(duration)
        end
      end
    end
  end
end
