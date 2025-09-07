# frozen_string_literal: true

module Pangea
  module Resources
    module AWS
      module SSM
        # AWS Systems Manager Maintenance Window Task resource
        # This resource manages tasks that run during Systems Manager maintenance windows.
        # Tasks can include running commands, AWS Lambda functions, Step Functions, or
        # Automation documents during scheduled maintenance periods.
        #
        # @see https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-maintenance-tasks.html
        module MaintenanceWindowTask
          # Creates an AWS Systems Manager Maintenance Window Task
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the task
          # @option attributes [String] :window_id The maintenance window ID (required)
          # @option attributes [String] :task_type The type of task (required)
          # @option attributes [String] :task_arn The ARN of the task (required)
          # @option attributes [String] :service_role_arn The service role ARN for the task (required)
          # @option attributes [Array<Hash>] :targets The targets for the task (required)
          # @option attributes [Integer] :priority The priority of the task (0-999)
          # @option attributes [Hash] :task_invocation_parameters Parameters for task invocation
          # @option attributes [Integer] :max_concurrency Maximum concurrency for the task
          # @option attributes [Integer] :max_errors Maximum errors allowed for the task
          # @option attributes [String] :name The name for the task
          # @option attributes [String] :description The description for the task
          # @option attributes [String] :cutoff_behavior The cutoff behavior for the task
          #
          # @example Run Command task
          #   aws_ssm_maintenance_window_task(:patch_windows_servers, {
          #     window_id: ref(:aws_ssm_maintenance_window, :weekly_patching, :id),
          #     task_type: "RUN_COMMAND",
          #     task_arn: "AWS-RunPatchBaseline",
          #     service_role_arn: ref(:aws_iam_role, :ssm_maintenance_role, :arn),
          #     targets: [
          #       {
          #         key: "tag:Environment",
          #         values: ["Production"]
          #       },
          #       {
          #         key: "tag:OS",
          #         values: ["Windows"]
          #       }
          #     ],
          #     priority: 1,
          #     max_concurrency: "50%",
          #     max_errors: "10%",
          #     name: "PatchWindowsServers",
          #     description: "Apply security patches to Windows servers",
          #     task_invocation_parameters: {
          #       run_command_parameters: {
          #         comment: "Patching Windows servers",
          #         document_hash: "SHA256:hash123",
          #         document_hash_type: "Sha256",
          #         notification_config: {
          #           notification_arn: ref(:aws_sns_topic, :maintenance_notifications, :arn),
          #           notification_events: ["Success", "Failed"],
          #           notification_type: "Command"
          #         },
          #         output_s3_bucket_name: "maintenance-logs-bucket",
          #         output_s3_key_prefix: "patch-logs/",
          #         parameters: {
          #           Operation: ["Install"],
          #           RebootOption: ["RebootIfNeeded"]
          #         },
          #         service_role_arn: ref(:aws_iam_role, :ssm_maintenance_role, :arn),
          #         timeout_seconds: 3600
          #       }
          #     }
          #   })
          #
          # @example Lambda function task
          #   aws_ssm_maintenance_window_task(:backup_cleanup, {
          #     window_id: ref(:aws_ssm_maintenance_window, :nightly_maintenance, :id),
          #     task_type: "LAMBDA",
          #     task_arn: ref(:aws_lambda_function, :cleanup_old_backups, :arn),
          #     service_role_arn: ref(:aws_iam_role, :lambda_maintenance_role, :arn),
          #     targets: [
          #       {
          #         key: "WindowTargetIds",
          #         values: [ref(:aws_ssm_maintenance_window_target, :all_instances, :id)]
          #       }
          #     ],
          #     priority: 3,
          #     max_concurrency: "1",
          #     max_errors: "0",
          #     name: "BackupCleanup",
          #     description: "Clean up old backup files",
          #     task_invocation_parameters: {
          #       lambda_parameters: {
          #         client_context: "maintenance-window",
          #         payload: JSON.generate({
          #           action: "cleanup",
          #           retention_days: 30
          #         }),
          #         qualifier: "$LATEST"
          #       }
          #     }
          #   })
          #
          # @return [MaintenanceWindowTaskResource] The maintenance window task resource
          def aws_ssm_maintenance_window_task(name, attributes = {})
            resource :aws_ssm_maintenance_window_task, name do
              window_id attributes[:window_id] if attributes[:window_id]
              task_type attributes[:task_type] if attributes[:task_type]
              task_arn attributes[:task_arn] if attributes[:task_arn]
              service_role_arn attributes[:service_role_arn] if attributes[:service_role_arn]
              priority attributes[:priority] if attributes[:priority]
              max_concurrency attributes[:max_concurrency] if attributes[:max_concurrency]
              max_errors attributes[:max_errors] if attributes[:max_errors]
              name attributes[:name] if attributes[:name]
              description attributes[:description] if attributes[:description]
              cutoff_behavior attributes[:cutoff_behavior] if attributes[:cutoff_behavior]
              
              if attributes[:targets]
                attributes[:targets].each do |target|
                  targets do
                    key target[:key]
                    values target[:values]
                  end
                end
              end
              
              if attributes[:task_invocation_parameters]
                task_invocation_parameters attributes[:task_invocation_parameters]
              end
            end
          end
        end
      end
    end
  end
end