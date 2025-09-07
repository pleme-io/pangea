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

module Pangea
  module Resources
    module AwsGamesparksGame
      module Types
        include Dry::Types()

        class Attributes < Dry::Struct
          attribute :name, String
          attribute? :description, String
          attribute? :tags, Hash.map(String, String)
        end

        class Reference < Dry::Struct
          attribute :id, String
          attribute :arn, String
          attribute :name, String
          attribute :description, String
          attribute :state, String
          attribute :created_time, String
          attribute :last_updated_time, String
          attribute :game_sdk_version, String
        end
      end
    end
  end
end