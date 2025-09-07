# frozen_string_literal: true

module Pangea
  module Resources
    module AWS
      module SSM
        # AWS Systems Manager Maintenance Window Target resource
        # This resource manages targets for Systems Manager maintenance windows.
        # Targets define which resources should be included in maintenance operations.
        #
        # @see https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-maintenance-targets.html
        module MaintenanceWindowTarget
          # Creates an AWS Systems Manager Maintenance Window Target
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the target
          # @option attributes [String] :window_id The maintenance window ID (required)
          # @option attributes [String] :resource_type The type of resource (required)
          # @option attributes [Array<Hash>] :targets The targets specification (required)
          # @option attributes [String] :name The name for the target
          # @option attributes [String] :description The description for the target
          # @option attributes [String] :owner_information Information about the owner
          #
          # @example EC2 instance targets by tag
          #   aws_ssm_maintenance_window_target(:production_web_servers, {
          #     window_id: ref(:aws_ssm_maintenance_window, :weekly_patching, :id),
          #     resource_type: "INSTANCE",
          #     targets: [
          #       {
          #         key: "tag:Environment",
          #         values: ["Production"]
          #       },
          #       {
          #         key: "tag:Role",
          #         values: ["WebServer"]
          #       }
          #     ],
          #     name: "ProductionWebServers",
          #     description: "Production web servers for patching",
          #     owner_information: "DevOps Team"
          #   })
          #
          # @example Specific instance IDs
          #   aws_ssm_maintenance_window_target(:critical_servers, {
          #     window_id: ref(:aws_ssm_maintenance_window, :emergency_maintenance, :id),
          #     resource_type: "INSTANCE",
          #     targets: [
          #       {
          #         key: "InstanceIds",
          #         values: ["i-1234567890abcdef0", "i-0987654321fedcba0"]
          #       }
          #     ],
          #     name: "CriticalServers"
          #   })
          #
          # @return [MaintenanceWindowTargetResource] The maintenance window target resource
          def aws_ssm_maintenance_window_target(name, attributes = {})
            resource :aws_ssm_maintenance_window_target, name do
              window_id attributes[:window_id] if attributes[:window_id]
              resource_type attributes[:resource_type] if attributes[:resource_type]
              name attributes[:name] if attributes[:name]
              description attributes[:description] if attributes[:description]
              owner_information attributes[:owner_information] if attributes[:owner_information]
              
              if attributes[:targets]
                attributes[:targets].each do |target|
                  targets do
                    key target[:key]
                    values target[:values]
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end