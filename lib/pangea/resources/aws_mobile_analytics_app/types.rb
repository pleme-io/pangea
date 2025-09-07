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


require "dry-struct"
require "pangea/types"

module Pangea
  module Resources
    module AwsMobileAnalyticsApp
      module Types
        # Main attributes for Mobile Analytics app
        class Attributes < Dry::Struct
          # Required attributes
          attribute :name, Pangea::Types::String
          
          # Note: AWS Mobile Analytics is deprecated in favor of Amazon Pinpoint
          # This resource is maintained for legacy support
          
          def self.from_dynamic(d)
            d = Pangea::Types::Hash[d]
            new(
              name: d.fetch(:name)
            )
          end
        end

        # Reference for Mobile Analytics app resources
        class Reference < Dry::Struct
          attribute :id, Pangea::Types::String
        end
      end
    end
  end
end