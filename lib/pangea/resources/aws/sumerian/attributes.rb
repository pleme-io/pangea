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
      module Sumerian
        # Sumerian Project
        module SumerianProject
          class ProjectAttributes < Dry::Struct
            attribute :name, Types::String
            attribute? :description, Types::String
            attribute? :template, Types::String
            attribute? :tags, Types::Hash.map(Types::String, Types::String)
          end
        end

        # Sumerian Scene
        module SumerianScene
          class SceneAttributes < Dry::Struct
            attribute :project_name, Types::String
            attribute :scene_name, Types::String
            attribute? :description, Types::String
            attribute? :scene_data, Types::String
            attribute? :thumbnail_url, Types::String
            attribute? :tags, Types::Hash.map(Types::String, Types::String)
          end
        end

        # Sumerian Asset
        module SumerianAsset
          class AssetAttributes < Dry::Struct
            attribute :project_name, Types::String
            attribute :asset_name, Types::String
            attribute :asset_type, Types::String
            attribute? :asset_data, Types::String
            attribute? :asset_url, Types::String
            attribute? :description, Types::String
            attribute? :tags, Types::Hash.map(Types::String, Types::String)
          end
        end

        # Sumerian Bundle
        module SumerianBundle
          class BundleAttributes < Dry::Struct
            attribute :project_name, Types::String
            attribute :bundle_name, Types::String
            attribute :asset_ids, Types::Array.of(Types::String)
            attribute? :description, Types::String
            attribute? :tags, Types::Hash.map(Types::String, Types::String)
          end
        end

        # Sumerian Host
        module SumerianHost
          class HostAttributes < Dry::Struct
            attribute :project_name, Types::String
            attribute :host_name, Types::String
            attribute? :host_configuration, Types::Hash
            attribute? :polly_config, Types::Hash
            attribute? :tags, Types::Hash.map(Types::String, Types::String)
          end
        end

        # Sumerian Published Scene
        module SumerianPublishedScene
          class PublishedSceneAttributes < Dry::Struct
            attribute :project_name, Types::String
            attribute :scene_name, Types::String
            attribute :version, Types::String
            attribute? :description, Types::String
            attribute? :access_policy, Types::String
          end
        end
      end
    end
  end
end
