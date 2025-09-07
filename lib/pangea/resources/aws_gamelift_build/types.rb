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
    module AwsGameliftBuild
      module Types
        # Storage location for game build files
        class StorageLocation < Dry::Struct
          attribute :bucket, Pangea::Types::String
          attribute :key, Pangea::Types::String
          attribute :role_arn, Pangea::Types::String
          attribute :object_version?, Pangea::Types::String
        end

        # Main attributes for GameLift build
        class Attributes < Dry::Struct
          # Required attributes
          attribute :name, Pangea::Types::String
          attribute :operating_system, Pangea::Types::String.enum(
            "AMAZON_LINUX",
            "AMAZON_LINUX_2",
            "WINDOWS_2012",
            "WINDOWS_2016"
          )
          attribute :storage_location, StorageLocation
          
          # Optional attributes
          attribute :version?, Pangea::Types::String
          attribute :tags?, Pangea::Types::Hash.map(Pangea::Types::String, Pangea::Types::String)

          def self.from_dynamic(d)
            d = Pangea::Types::Hash[d]
            new(
              name: d.fetch(:name),
              operating_system: d.fetch(:operating_system),
              storage_location: StorageLocation.from_dynamic(d.fetch(:storage_location)),
              version: d[:version],
              tags: d[:tags]
            )
          end
        end

        # Reference for GameLift build resources
        class Reference < Dry::Struct
          attribute :id, Pangea::Types::String
          attribute :arn, Pangea::Types::String
          attribute :creation_time, Pangea::Types::String
          attribute :size_on_disk, Pangea::Types::Integer
          attribute :status, Pangea::Types::String
        end
      end
    end
  end
end