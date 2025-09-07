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
      # Comprehensive AWS GameDev Service Resource Functions
      # Covers game development workflow, CI/CD, and deployment automation
      module GameDev
        include Dry::Types()

        # GameDev Project
        module GameDeveloperProject
          class ProjectAttributes < Dry::Struct
            attribute :name, String
            attribute? :description, String
            attribute? :game_engine, String
            attribute? :repository_url, String
            attribute? :tags, Types::Hash.map(Types::String, Types::String)
          end
        end

        # GameDev Stage
        module GameDeveloperStage
          class StageAttributes < Dry::Struct
            attribute :project_name, String
            attribute :stage_name, String
            attribute? :description, String
            attribute? :stage_configuration, Hash
            attribute? :tags, Types::Hash.map(Types::String, Types::String)
          end
        end

        # GameDev Deployment
        module GameDeveloperDeployment
          class DeploymentAttributes < Dry::Struct
            attribute :project_name, String
            attribute :stage_name, String
            attribute? :deployment_id, String
            attribute? :source_version, String
            attribute? :deployment_configuration, Hash
          end
        end

        # GameDev Snapshot
        module GameDeveloperSnapshot
          class SnapshotAttributes < Dry::Struct
            attribute :project_name, String
            attribute? :description, String
            attribute? :source_version, String
          end
        end

        # GameDev Extension
        module GameDeveloperExtension
          class ExtensionAttributes < Dry::Struct
            attribute :project_name, String
            attribute :extension_name, String
            attribute? :extension_configuration, Hash
            attribute? :tags, Types::Hash.map(Types::String, Types::String)
          end
        end

        # Public resource functions for AWS GameDev
        def aws_gamedeveloper_project(name, attributes = {})
          validated = GameDeveloperProject::ProjectAttributes.from_dynamic(attributes)
          
          resource :aws_gamedeveloper_project, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_gamedeveloper_project.#{name}.id}",
            arn: "${aws_gamedeveloper_project.#{name}.arn}",
            name: "${aws_gamedeveloper_project.#{name}.name}",
            description: "${aws_gamedeveloper_project.#{name}.description}",
            project_id: "${aws_gamedeveloper_project.#{name}.project_id}",
            state: "${aws_gamedeveloper_project.#{name}.state}",
            game_engine: "${aws_gamedeveloper_project.#{name}.game_engine}",
            repository_url: "${aws_gamedeveloper_project.#{name}.repository_url}",
            created_time: "${aws_gamedeveloper_project.#{name}.created_time}",
            last_updated_time: "${aws_gamedeveloper_project.#{name}.last_updated_time}"
          )
        end

        def aws_gamedeveloper_stage(name, attributes = {})
          validated = GameDeveloperStage::StageAttributes.from_dynamic(attributes)
          
          resource :aws_gamedeveloper_stage, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_gamedeveloper_stage.#{name}.id}",
            arn: "${aws_gamedeveloper_stage.#{name}.arn}",
            project_name: "${aws_gamedeveloper_stage.#{name}.project_name}",
            stage_name: "${aws_gamedeveloper_stage.#{name}.stage_name}",
            description: "${aws_gamedeveloper_stage.#{name}.description}",
            state: "${aws_gamedeveloper_stage.#{name}.state}",
            role: "${aws_gamedeveloper_stage.#{name}.role}",
            created_time: "${aws_gamedeveloper_stage.#{name}.created_time}",
            last_updated_time: "${aws_gamedeveloper_stage.#{name}.last_updated_time}"
          )
        end

        def aws_gamedeveloper_deployment(name, attributes = {})
          validated = GameDeveloperDeployment::DeploymentAttributes.from_dynamic(attributes)
          
          resource :aws_gamedeveloper_deployment, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_gamedeveloper_deployment.#{name}.id}",
            deployment_id: "${aws_gamedeveloper_deployment.#{name}.deployment_id}",
            project_name: "${aws_gamedeveloper_deployment.#{name}.project_name}",
            stage_name: "${aws_gamedeveloper_deployment.#{name}.stage_name}",
            deployment_state: "${aws_gamedeveloper_deployment.#{name}.deployment_state}",
            deployment_result: "${aws_gamedeveloper_deployment.#{name}.deployment_result}",
            source_version: "${aws_gamedeveloper_deployment.#{name}.source_version}",
            created_time: "${aws_gamedeveloper_deployment.#{name}.created_time}",
            last_updated_time: "${aws_gamedeveloper_deployment.#{name}.last_updated_time}"
          )
        end

        def aws_gamedeveloper_snapshot(name, attributes = {})
          validated = GameDeveloperSnapshot::SnapshotAttributes.from_dynamic(attributes)
          
          resource :aws_gamedeveloper_snapshot, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_gamedeveloper_snapshot.#{name}.id}",
            project_name: "${aws_gamedeveloper_snapshot.#{name}.project_name}",
            description: "${aws_gamedeveloper_snapshot.#{name}.description}",
            source_version: "${aws_gamedeveloper_snapshot.#{name}.source_version}",
            created_time: "${aws_gamedeveloper_snapshot.#{name}.created_time}",
            last_updated_time: "${aws_gamedeveloper_snapshot.#{name}.last_updated_time}"
          )
        end

        def aws_gamedeveloper_extension(name, attributes = {})
          validated = GameDeveloperExtension::ExtensionAttributes.from_dynamic(attributes)
          
          resource :aws_gamedeveloper_extension, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_gamedeveloper_extension.#{name}.id}",
            project_name: "${aws_gamedeveloper_extension.#{name}.project_name}",
            extension_name: "${aws_gamedeveloper_extension.#{name}.extension_name}",
            extension_namespace: "${aws_gamedeveloper_extension.#{name}.extension_namespace}",
            extension_version: "${aws_gamedeveloper_extension.#{name}.extension_version}",
            created_time: "${aws_gamedeveloper_extension.#{name}.created_time}",
            last_updated_time: "${aws_gamedeveloper_extension.#{name}.last_updated_time}"
          )
        end
      end
    end
  end
end