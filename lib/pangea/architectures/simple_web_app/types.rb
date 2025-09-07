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
  module Architectures
    module SimpleWebApp
      module Types
        # Simple web app architecture attributes
        class SimpleWebAppAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :vpc_cidr, Resources::Types::CidrBlock.default("10.1.0.0/16")
          attribute :environment, Resources::Types::String.default("development")
          attribute :availability_zones, Resources::Types::Array.of(Resources::Types::String).default(["us-east-1a", "us-east-1b"])
          attribute :tags, Resources::Types::AwsTags.default({})
        end
      end
    end
  end
end