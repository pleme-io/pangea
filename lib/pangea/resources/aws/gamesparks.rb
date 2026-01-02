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
require_relative "gamesparks/types"

module Pangea
  module Resources
    module AWS
      # Comprehensive AWS GameSparks Service Resource Functions
      # Covers game backend services, configuration, and player management
      module GameSparks
        def aws_gamesparks_game(name, attributes = {})
          validated = Types::GameAttributes.from_dynamic(attributes)
          resource :aws_gamesparks_game, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          OpenStruct.new(
            id: "${aws_gamesparks_game.#{name}.id}",
            arn: "${aws_gamesparks_game.#{name}.arn}",
            name: "${aws_gamesparks_game.#{name}.name}",
            description: "${aws_gamesparks_game.#{name}.description}",
            state: "${aws_gamesparks_game.#{name}.state}",
            created_time: "${aws_gamesparks_game.#{name}.created_time}",
            last_updated_time: "${aws_gamesparks_game.#{name}.last_updated_time}",
            game_sdk_version: "${aws_gamesparks_game.#{name}.game_sdk_version}"
          )
        end

        def aws_gamesparks_stage(name, attributes = {})
          validated = Types::StageAttributes.from_dynamic(attributes)
          resource :aws_gamesparks_stage, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          OpenStruct.new(
            id: "${aws_gamesparks_stage.#{name}.id}",
            arn: "${aws_gamesparks_stage.#{name}.arn}",
            game_name: "${aws_gamesparks_stage.#{name}.game_name}",
            stage_name: "${aws_gamesparks_stage.#{name}.stage_name}",
            description: "${aws_gamesparks_stage.#{name}.description}",
            state: "${aws_gamesparks_stage.#{name}.state}",
            created_time: "${aws_gamesparks_stage.#{name}.created_time}",
            last_updated_time: "${aws_gamesparks_stage.#{name}.last_updated_time}",
            endpoint: "${aws_gamesparks_stage.#{name}.endpoint}"
          )
        end

        def aws_gamesparks_snapshot(name, attributes = {})
          validated = Types::SnapshotAttributes.from_dynamic(attributes)
          resource :aws_gamesparks_snapshot, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          OpenStruct.new(
            id: "${aws_gamesparks_snapshot.#{name}.id}",
            game_name: "${aws_gamesparks_snapshot.#{name}.game_name}",
            description: "${aws_gamesparks_snapshot.#{name}.description}",
            created_time: "${aws_gamesparks_snapshot.#{name}.created_time}",
            last_updated_time: "${aws_gamesparks_snapshot.#{name}.last_updated_time}"
          )
        end

        def aws_gamesparks_extension(name, attributes = {})
          validated = Types::ExtensionAttributes.from_dynamic(attributes)
          resource :aws_gamesparks_extension, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          OpenStruct.new(
            id: "${aws_gamesparks_extension.#{name}.id}",
            namespace: "${aws_gamesparks_extension.#{name}.namespace}",
            name: "${aws_gamesparks_extension.#{name}.name}",
            description: "${aws_gamesparks_extension.#{name}.description}",
            extension_version: "${aws_gamesparks_extension.#{name}.extension_version}",
            created_time: "${aws_gamesparks_extension.#{name}.created_time}"
          )
        end

        def aws_gamesparks_extension_version(name, attributes = {})
          validated = Types::ExtensionVersionAttributes.from_dynamic(attributes)
          resource :aws_gamesparks_extension_version, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          OpenStruct.new(
            id: "${aws_gamesparks_extension_version.#{name}.id}",
            extension_namespace: "${aws_gamesparks_extension_version.#{name}.extension_namespace}",
            extension_name: "${aws_gamesparks_extension_version.#{name}.extension_name}",
            extension_version: "${aws_gamesparks_extension_version.#{name}.extension_version}",
            schema: "${aws_gamesparks_extension_version.#{name}.schema}",
            status: "${aws_gamesparks_extension_version.#{name}.status}"
          )
        end

        def aws_gamesparks_configuration(name, attributes = {})
          validated = Types::ConfigurationAttributes.from_dynamic(attributes)
          resource :aws_gamesparks_configuration, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          OpenStruct.new(
            id: "${aws_gamesparks_configuration.#{name}.id}",
            game_name: "${aws_gamesparks_configuration.#{name}.game_name}",
            stage_name: "${aws_gamesparks_configuration.#{name}.stage_name}",
            sections: "${aws_gamesparks_configuration.#{name}.sections}",
            created_time: "${aws_gamesparks_configuration.#{name}.created_time}",
            last_updated_time: "${aws_gamesparks_configuration.#{name}.last_updated_time}"
          )
        end

        def aws_gamesparks_player_connection_status(name, attributes = {})
          validated = Types::PlayerConnectionAttributes.from_dynamic(attributes)
          resource :aws_gamesparks_player_connection_status, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          OpenStruct.new(
            id: "${aws_gamesparks_player_connection_status.#{name}.id}",
            game_name: "${aws_gamesparks_player_connection_status.#{name}.game_name}",
            stage_name: "${aws_gamesparks_player_connection_status.#{name}.stage_name}",
            player_id: "${aws_gamesparks_player_connection_status.#{name}.player_id}",
            connection_id: "${aws_gamesparks_player_connection_status.#{name}.connection_id}",
            status: "${aws_gamesparks_player_connection_status.#{name}.status}",
            last_updated_time: "${aws_gamesparks_player_connection_status.#{name}.last_updated_time}"
          )
        end

        def aws_gamesparks_generated_code_job(name, attributes = {})
          validated = Types::GeneratedCodeJobAttributes.from_dynamic(attributes)
          resource :aws_gamesparks_generated_code_job, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          OpenStruct.new(
            id: "${aws_gamesparks_generated_code_job.#{name}.id}",
            game_name: "${aws_gamesparks_generated_code_job.#{name}.game_name}",
            stage_name: "${aws_gamesparks_generated_code_job.#{name}.stage_name}",
            job_id: "${aws_gamesparks_generated_code_job.#{name}.job_id}",
            status: "${aws_gamesparks_generated_code_job.#{name}.status}",
            generated_code_s3_url: "${aws_gamesparks_generated_code_job.#{name}.generated_code_s3_url}",
            creation_time: "${aws_gamesparks_generated_code_job.#{name}.creation_time}"
          )
        end
      end
    end
  end
end
