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
    module AWS
      module GameSparks
        # GameSparks Types module - Contains all attribute structs for GameSparks resources
        module Types
          include Dry::Types()

          # GameSparks Game Attributes
          class GameAttributes < Dry::Struct
            attribute :name, Dry::Types()["string"]
            attribute? :description, Dry::Types()["string"]
            attribute? :tags, Dry::Types()["hash"].map(Dry::Types()["string"], Dry::Types()["string"])
          end

          # GameSparks Stage Attributes
          class StageAttributes < Dry::Struct
            attribute :game_name, Dry::Types()["string"]
            attribute :stage_name, Dry::Types()["string"]
            attribute? :description, Dry::Types()["string"]
            attribute? :tags, Dry::Types()["hash"].map(Dry::Types()["string"], Dry::Types()["string"])
          end

          # GameSparks Snapshot Attributes
          class SnapshotAttributes < Dry::Struct
            attribute :game_name, Dry::Types()["string"]
            attribute? :description, Dry::Types()["string"]
          end

          # GameSparks Extension Attributes
          class ExtensionAttributes < Dry::Struct
            attribute :namespace, Dry::Types()["string"]
            attribute :name, Dry::Types()["string"]
            attribute? :description, Dry::Types()["string"]
            attribute? :extension_version, Dry::Types()["string"]
          end

          # GameSparks Extension Version Attributes
          class ExtensionVersionAttributes < Dry::Struct
            attribute :extension_namespace, Dry::Types()["string"]
            attribute :extension_name, Dry::Types()["string"]
            attribute :extension_version, Dry::Types()["string"]
            attribute? :schema, Dry::Types()["string"]
          end

          # GameSparks Configuration Attributes
          class ConfigurationAttributes < Dry::Struct
            attribute :game_name, Dry::Types()["string"]
            attribute :stage_name, Dry::Types()["string"]
            attribute? :sections, Dry::Types()["hash"]
          end

          # GameSparks Player Connection Status Attributes
          class PlayerConnectionAttributes < Dry::Struct
            attribute :game_name, Dry::Types()["string"]
            attribute :stage_name, Dry::Types()["string"]
            attribute :player_id, Dry::Types()["string"]
          end

          # GameSparks Generated Code Job Attributes
          class GeneratedCodeJobAttributes < Dry::Struct
            attribute :game_name, Dry::Types()["string"]
            attribute :stage_name, Dry::Types()["string"]
            attribute :generator, Dry::Types()["hash"]
          end
        end
      end
    end
  end
end
