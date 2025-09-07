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


require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      # AWS RoboMaker resources for robotics development and simulation
      module RoboMaker
        include Base

        # Robot application development and versioning
        def aws_robomaker_robot_application(name, attributes = {})
          create_resource(:aws_robomaker_robot_application, name, attributes) do |attrs|
            Reference.new(:aws_robomaker_robot_application, name, {
              arn: computed_attr("${aws_robomaker_robot_application.#{name}.arn}"),
              name: attrs[:name],
              version: attrs[:current_revision_id],
              sources: attrs[:sources]
            })
          end
        end

        def aws_robomaker_robot_application_version(name, attributes = {})
          create_resource(:aws_robomaker_robot_application_version, name, attributes) do |attrs|
            Reference.new(:aws_robomaker_robot_application_version, name, {
              arn: computed_attr("${aws_robomaker_robot_application_version.#{name}.arn}"),
              version: computed_attr("${aws_robomaker_robot_application_version.#{name}.version}"),
              application: attrs[:application],
              current_revision_id: attrs[:current_revision_id]
            })
          end
        end

        # Simulation application development and versioning
        def aws_robomaker_simulation_application(name, attributes = {})
          create_resource(:aws_robomaker_simulation_application, name, attributes) do |attrs|
            Reference.new(:aws_robomaker_simulation_application, name, {
              arn: computed_attr("${aws_robomaker_simulation_application.#{name}.arn}"),
              name: attrs[:name],
              version: attrs[:current_revision_id],
              sources: attrs[:sources],
              simulation_software_suite: attrs[:simulation_software_suite]
            })
          end
        end

        def aws_robomaker_simulation_application_version(name, attributes = {})
          create_resource(:aws_robomaker_simulation_application_version, name, attributes) do |attrs|
            Reference.new(:aws_robomaker_simulation_application_version, name, {
              arn: computed_attr("${aws_robomaker_simulation_application_version.#{name}.arn}"),
              version: computed_attr("${aws_robomaker_simulation_application_version.#{name}.version}"),
              application: attrs[:application],
              current_revision_id: attrs[:current_revision_id]
            })
          end
        end

        # Simulation job execution and batch processing
        def aws_robomaker_simulation_job(name, attributes = {})
          create_resource(:aws_robomaker_simulation_job, name, attributes) do |attrs|
            Reference.new(:aws_robomaker_simulation_job, name, {
              arn: computed_attr("${aws_robomaker_simulation_job.#{name}.arn}"),
              id: computed_attr("${aws_robomaker_simulation_job.#{name}.id}"),
              status: computed_attr("${aws_robomaker_simulation_job.#{name}.status}"),
              iam_role: attrs[:iam_role],
              max_job_duration_in_seconds: attrs[:max_job_duration_in_seconds]
            })
          end
        end

        def aws_robomaker_simulation_job_batch(name, attributes = {})
          create_resource(:aws_robomaker_simulation_job_batch, name, attributes) do |attrs|
            Reference.new(:aws_robomaker_simulation_job_batch, name, {
              arn: computed_attr("${aws_robomaker_simulation_job_batch.#{name}.arn}"),
              id: computed_attr("${aws_robomaker_simulation_job_batch.#{name}.id}"),
              status: computed_attr("${aws_robomaker_simulation_job_batch.#{name}.status}"),
              batch_policy: attrs[:batch_policy],
              create_simulation_job_requests: attrs[:create_simulation_job_requests]
            })
          end
        end

        # Fleet and robot management
        def aws_robomaker_fleet(name, attributes = {})
          create_resource(:aws_robomaker_fleet, name, attributes) do |attrs|
            Reference.new(:aws_robomaker_fleet, name, {
              arn: computed_attr("${aws_robomaker_fleet.#{name}.arn}"),
              id: computed_attr("${aws_robomaker_fleet.#{name}.id}"),
              name: attrs[:name],
              last_deployment_status: computed_attr("${aws_robomaker_fleet.#{name}.last_deployment_status}"),
              last_deployment_time: computed_attr("${aws_robomaker_fleet.#{name}.last_deployment_time}")
            })
          end
        end

        def aws_robomaker_robot(name, attributes = {})
          create_resource(:aws_robomaker_robot, name, attributes) do |attrs|
            Reference.new(:aws_robomaker_robot, name, {
              arn: computed_attr("${aws_robomaker_robot.#{name}.arn}"),
              id: computed_attr("${aws_robomaker_robot.#{name}.id}"),
              name: attrs[:name],
              fleet: attrs[:fleet],
              status: computed_attr("${aws_robomaker_robot.#{name}.status}")
            })
          end
        end

        def aws_robomaker_deployment_job(name, attributes = {})
          create_resource(:aws_robomaker_deployment_job, name, attributes) do |attrs|
            Reference.new(:aws_robomaker_deployment_job, name, {
              arn: computed_attr("${aws_robomaker_deployment_job.#{name}.arn}"),
              id: computed_attr("${aws_robomaker_deployment_job.#{name}.id}"),
              status: computed_attr("${aws_robomaker_deployment_job.#{name}.status}"),
              deployment_config: attrs[:deployment_config],
              fleet: attrs[:fleet]
            })
          end
        end

        # World template and generation
        def aws_robomaker_world_template(name, attributes = {})
          create_resource(:aws_robomaker_world_template, name, attributes) do |attrs|
            Reference.new(:aws_robomaker_world_template, name, {
              arn: computed_attr("${aws_robomaker_world_template.#{name}.arn}"),
              id: computed_attr("${aws_robomaker_world_template.#{name}.id}"),
              name: attrs[:name],
              template_body: attrs[:template_body],
              template_location: attrs[:template_location]
            })
          end
        end

        def aws_robomaker_world_generation_job(name, attributes = {})
          create_resource(:aws_robomaker_world_generation_job, name, attributes) do |attrs|
            Reference.new(:aws_robomaker_world_generation_job, name, {
              arn: computed_attr("${aws_robomaker_world_generation_job.#{name}.arn}"),
              id: computed_attr("${aws_robomaker_world_generation_job.#{name}.id}"),
              status: computed_attr("${aws_robomaker_world_generation_job.#{name}.status}"),
              template: attrs[:template],
              world_count: attrs[:world_count]
            })
          end
        end

        def aws_robomaker_world_export_job(name, attributes = {})
          create_resource(:aws_robomaker_world_export_job, name, attributes) do |attrs|
            Reference.new(:aws_robomaker_world_export_job, name, {
              arn: computed_attr("${aws_robomaker_world_export_job.#{name}.arn}"),
              id: computed_attr("${aws_robomaker_world_export_job.#{name}.id}"),
              status: computed_attr("${aws_robomaker_world_export_job.#{name}.status}"),
              worlds: attrs[:worlds],
              output_location: attrs[:output_location]
            })
          end
        end
      end
    end
  end
end