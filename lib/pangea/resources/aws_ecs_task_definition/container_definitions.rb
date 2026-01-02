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

module Pangea
  module Resources
    module AWS
      module EcsTaskDefinition
        # Builds container definition JSON for ECS task definitions
        module ContainerDefinitions
          extend self

          # Convert container definitions to JSON-compatible array
          # @param containers [Array] Array of container definition objects
          # @return [Array<Hash>] Array of container definition hashes
          def build(containers)
            containers.map { |container| build_container(container) }
          end

          private

          def build_container(container)
            hash = base_container_hash(container)
            add_port_mappings(hash, container)
            add_environment_config(hash, container)
            add_logging_config(hash, container)
            add_health_check(hash, container)
            add_filesystem_config(hash, container)
            add_linux_config(hash, container)
            add_misc_config(hash, container)
            hash
          end

          def base_container_hash(container)
            hash = {
              name: container.name,
              image: container.image,
              essential: container.essential
            }
            hash[:cpu] = container.cpu if container.cpu
            hash[:memory] = container.memory if container.memory
            hash[:memoryReservation] = container.memory_reservation if container.memory_reservation
            hash
          end

          def add_port_mappings(hash, container)
            return unless container.port_mappings.any?

            hash[:portMappings] = container.port_mappings.map do |pm|
              pm_hash = { containerPort: pm[:container_port] }
              pm_hash[:hostPort] = pm[:host_port] if pm[:host_port]
              pm_hash[:protocol] = pm[:protocol] if pm[:protocol]
              pm_hash[:name] = pm[:name] if pm[:name]
              pm_hash[:appProtocol] = pm[:app_protocol] if pm[:app_protocol]
              pm_hash
            end
          end

          def add_environment_config(hash, container)
            hash[:environment] = container.environment if container.environment.any?
            return unless container.secrets.any?

            hash[:secrets] = container.secrets.map do |s|
              { name: s[:name], valueFrom: s[:value_from] }
            end
          end

          def add_logging_config(hash, container)
            return unless container.log_configuration

            log_config = { logDriver: container.log_configuration[:log_driver] }
            log_config[:options] = container.log_configuration[:options] if container.log_configuration[:options]
            log_config[:secretOptions] = container.log_configuration[:secret_options] if container.log_configuration[:secret_options]
            hash[:logConfiguration] = log_config
          end

          def add_health_check(hash, container)
            return unless container.health_check

            hc = { command: container.health_check[:command] }
            hc[:interval] = container.health_check[:interval] if container.health_check[:interval]
            hc[:timeout] = container.health_check[:timeout] if container.health_check[:timeout]
            hc[:retries] = container.health_check[:retries] if container.health_check[:retries]
            hc[:startPeriod] = container.health_check[:start_period] if container.health_check[:start_period]
            hash[:healthCheck] = hc
          end

          def add_filesystem_config(hash, container)
            hash[:entryPoint] = container.entry_point if container.entry_point.any?
            hash[:command] = container.command if container.command.any?
            hash[:workingDirectory] = container.working_directory if container.working_directory
            hash[:links] = container.links if container.links.any?

            add_mount_points(hash, container)
            add_volumes_from(hash, container)
            add_depends_on(hash, container)
          end

          def add_mount_points(hash, container)
            return unless container.mount_points.any?

            hash[:mountPoints] = container.mount_points.map do |mp|
              mp_hash = { sourceVolume: mp[:source_volume], containerPath: mp[:container_path] }
              mp_hash[:readOnly] = mp[:read_only] unless mp[:read_only].nil?
              mp_hash
            end
          end

          def add_volumes_from(hash, container)
            return unless container.volumes_from.any?

            hash[:volumesFrom] = container.volumes_from.map do |vf|
              vf_hash = { sourceContainer: vf[:source_container] }
              vf_hash[:readOnly] = vf[:read_only] unless vf[:read_only].nil?
              vf_hash
            end
          end

          def add_depends_on(hash, container)
            return unless container.depends_on.any?

            hash[:dependsOn] = container.depends_on.map do |dep|
              { containerName: dep[:container_name], condition: dep[:condition] }
            end
          end

          def add_linux_config(hash, container)
            return unless container.linux_parameters

            lp = {}
            lp[:capabilities] = container.linux_parameters[:capabilities] if container.linux_parameters[:capabilities]
            lp[:devices] = container.linux_parameters[:devices] if container.linux_parameters[:devices]
            lp[:initProcessEnabled] = container.linux_parameters[:init_process_enabled] unless container.linux_parameters[:init_process_enabled].nil?
            lp[:maxSwap] = container.linux_parameters[:max_swap] if container.linux_parameters[:max_swap]
            lp[:sharedMemorySize] = container.linux_parameters[:shared_memory_size] if container.linux_parameters[:shared_memory_size]
            lp[:swappiness] = container.linux_parameters[:swappiness] if container.linux_parameters[:swappiness]
            lp[:tmpfs] = container.linux_parameters[:tmpfs] if container.linux_parameters[:tmpfs]
            hash[:linuxParameters] = lp
          end

          def add_misc_config(hash, container)
            add_ulimits(hash, container)
            add_container_attributes(hash, container)
            add_firelens_config(hash, container)
          end

          def add_ulimits(hash, container)
            return unless container.ulimits.any?

            hash[:ulimits] = container.ulimits.map do |u|
              { name: u[:name], softLimit: u[:soft_limit], hardLimit: u[:hard_limit] }
            end
          end

          def add_container_attributes(hash, container)
            hash[:user] = container.user if container.user
            hash[:privileged] = container.privileged if container.privileged
            hash[:readonlyRootFilesystem] = container.readonly_root_filesystem if container.readonly_root_filesystem
            hash[:dnsServers] = container.dns_servers if container.dns_servers.any?
            hash[:dnsSearchDomains] = container.dns_search_domains if container.dns_search_domains.any?
            hash[:extraHosts] = container.extra_hosts.map { |eh| { hostname: eh[:hostname], ipAddress: eh[:ip_address] } } if container.extra_hosts.any?
            hash[:dockerSecurityOptions] = container.docker_security_options if container.docker_security_options.any?
            hash[:dockerLabels] = container.docker_labels if container.docker_labels.any?
            hash[:systemControls] = container.system_controls if container.system_controls.any?
          end

          def add_firelens_config(hash, container)
            return unless container.firelens_configuration

            hash[:firelensConfiguration] = {
              type: container.firelens_configuration[:type],
              options: container.firelens_configuration[:options]
            }.compact
          end
        end
      end
    end
  end
end
