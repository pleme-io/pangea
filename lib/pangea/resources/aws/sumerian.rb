# frozen_string_literal: true

require "dry-struct"

module Pangea
  module Resources
    module AWS
      # Comprehensive Amazon Sumerian AR/VR Service Resource Functions
      # Covers 3D content creation, AR/VR deployment, and asset management
      module Sumerian
        include Dry::Types()

        # Sumerian Project
        module SumerianProject
          class ProjectAttributes < Dry::Struct
            attribute :name, String
            attribute? :description, String
            attribute? :template, String
            attribute? :tags, Types::Hash.map(Types::String, Types::String)
          end
        end

        # Sumerian Scene
        module SumerianScene
          class SceneAttributes < Dry::Struct
            attribute :project_name, String
            attribute :scene_name, String
            attribute? :description, String
            attribute? :scene_data, String
            attribute? :thumbnail_url, String
            attribute? :tags, Types::Hash.map(Types::String, Types::String)
          end
        end

        # Sumerian Asset
        module SumerianAsset
          class AssetAttributes < Dry::Struct
            attribute :project_name, String
            attribute :asset_name, String
            attribute :asset_type, String
            attribute? :asset_data, String
            attribute? :asset_url, String
            attribute? :description, String
            attribute? :tags, Types::Hash.map(Types::String, Types::String)
          end
        end

        # Sumerian Bundle
        module SumerianBundle
          class BundleAttributes < Dry::Struct
            attribute :project_name, String
            attribute :bundle_name, String
            attribute :asset_ids, Types::Array.of(Types::String)
            attribute? :description, String
            attribute? :tags, Types::Hash.map(Types::String, Types::String)
          end
        end

        # Sumerian Host
        module SumerianHost
          class HostAttributes < Dry::Struct
            attribute :project_name, String
            attribute :host_name, String
            attribute? :host_configuration, Hash
            attribute? :polly_config, Hash
            attribute? :tags, Types::Hash.map(Types::String, Types::String)
          end
        end

        # Sumerian Published Scene
        module SumerianPublishedScene
          class PublishedSceneAttributes < Dry::Struct
            attribute :project_name, String
            attribute :scene_name, String
            attribute :version, String
            attribute? :description, String
            attribute? :access_policy, String
          end
        end

        # Public resource functions for Amazon Sumerian
        def aws_sumerian_project(name, attributes = {})
          validated = SumerianProject::ProjectAttributes.from_dynamic(attributes)
          
          resource :aws_sumerian_project, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_sumerian_project.#{name}.id}",
            arn: "${aws_sumerian_project.#{name}.arn}",
            name: "${aws_sumerian_project.#{name}.name}",
            description: "${aws_sumerian_project.#{name}.description}",
            project_id: "${aws_sumerian_project.#{name}.project_id}",
            owner: "${aws_sumerian_project.#{name}.owner}",
            creation_time: "${aws_sumerian_project.#{name}.creation_time}",
            last_updated_time: "${aws_sumerian_project.#{name}.last_updated_time}",
            state: "${aws_sumerian_project.#{name}.state}"
          )
        end

        def aws_sumerian_scene(name, attributes = {})
          validated = SumerianScene::SceneAttributes.from_dynamic(attributes)
          
          resource :aws_sumerian_scene, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_sumerian_scene.#{name}.id}",
            arn: "${aws_sumerian_scene.#{name}.arn}",
            project_name: "${aws_sumerian_scene.#{name}.project_name}",
            scene_name: "${aws_sumerian_scene.#{name}.scene_name}",
            description: "${aws_sumerian_scene.#{name}.description}",
            scene_id: "${aws_sumerian_scene.#{name}.scene_id}",
            url: "${aws_sumerian_scene.#{name}.url}",
            creation_time: "${aws_sumerian_scene.#{name}.creation_time}",
            last_updated_time: "${aws_sumerian_scene.#{name}.last_updated_time}",
            size: "${aws_sumerian_scene.#{name}.size}"
          )
        end

        def aws_sumerian_asset(name, attributes = {})
          validated = SumerianAsset::AssetAttributes.from_dynamic(attributes)
          
          resource :aws_sumerian_asset, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_sumerian_asset.#{name}.id}",
            arn: "${aws_sumerian_asset.#{name}.arn}",
            project_name: "${aws_sumerian_asset.#{name}.project_name}",
            asset_name: "${aws_sumerian_asset.#{name}.asset_name}",
            asset_id: "${aws_sumerian_asset.#{name}.asset_id}",
            asset_type: "${aws_sumerian_asset.#{name}.asset_type}",
            asset_url: "${aws_sumerian_asset.#{name}.asset_url}",
            description: "${aws_sumerian_asset.#{name}.description}",
            creation_time: "${aws_sumerian_asset.#{name}.creation_time}",
            last_updated_time: "${aws_sumerian_asset.#{name}.last_updated_time}",
            size: "${aws_sumerian_asset.#{name}.size}"
          )
        end

        def aws_sumerian_bundle(name, attributes = {})
          validated = SumerianBundle::BundleAttributes.from_dynamic(attributes)
          
          resource :aws_sumerian_bundle, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_sumerian_bundle.#{name}.id}",
            arn: "${aws_sumerian_bundle.#{name}.arn}",
            project_name: "${aws_sumerian_bundle.#{name}.project_name}",
            bundle_name: "${aws_sumerian_bundle.#{name}.bundle_name}",
            bundle_id: "${aws_sumerian_bundle.#{name}.bundle_id}",
            asset_ids: "${aws_sumerian_bundle.#{name}.asset_ids}",
            description: "${aws_sumerian_bundle.#{name}.description}",
            url: "${aws_sumerian_bundle.#{name}.url}",
            creation_time: "${aws_sumerian_bundle.#{name}.creation_time}",
            last_updated_time: "${aws_sumerian_bundle.#{name}.last_updated_time}",
            size: "${aws_sumerian_bundle.#{name}.size}"
          )
        end

        def aws_sumerian_host(name, attributes = {})
          validated = SumerianHost::HostAttributes.from_dynamic(attributes)
          
          resource :aws_sumerian_host, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_sumerian_host.#{name}.id}",
            arn: "${aws_sumerian_host.#{name}.arn}",
            project_name: "${aws_sumerian_host.#{name}.project_name}",
            host_name: "${aws_sumerian_host.#{name}.host_name}",
            host_id: "${aws_sumerian_host.#{name}.host_id}",
            engine: "${aws_sumerian_host.#{name}.engine}",
            creation_time: "${aws_sumerian_host.#{name}.creation_time}",
            last_updated_time: "${aws_sumerian_host.#{name}.last_updated_time}"
          )
        end

        def aws_sumerian_published_scene(name, attributes = {})
          validated = SumerianPublishedScene::PublishedSceneAttributes.from_dynamic(attributes)
          
          resource :aws_sumerian_published_scene, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_sumerian_published_scene.#{name}.id}",
            arn: "${aws_sumerian_published_scene.#{name}.arn}",
            project_name: "${aws_sumerian_published_scene.#{name}.project_name}",
            scene_name: "${aws_sumerian_published_scene.#{name}.scene_name}",
            version: "${aws_sumerian_published_scene.#{name}.version}",
            url: "${aws_sumerian_published_scene.#{name}.url}",
            description: "${aws_sumerian_published_scene.#{name}.description}",
            access_policy: "${aws_sumerian_published_scene.#{name}.access_policy}",
            creation_time: "${aws_sumerian_published_scene.#{name}.creation_time}",
            last_updated_time: "${aws_sumerian_published_scene.#{name}.last_updated_time}"
          )
        end
      end
    end
  end
end