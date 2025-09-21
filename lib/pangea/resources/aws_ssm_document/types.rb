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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Systems Manager Document resources
      class SsmDocumentAttributes < Dry::Struct
        # Document name (required)
        attribute :name, Resources::Types::String

        # Document type (required)
        attribute :document_type, Resources::Types::String.enum(
          "Command", 
          "Policy", 
          "Automation", 
          "Session", 
          "Package", 
          "ApplicationConfiguration",
          "ApplicationConfigurationSchema",
          "DeploymentStrategy",
          "ChangeCalendar",
          "Composite",
          "ProblemAnalysis",
          "ProblemAnalysisTemplate",
          "CloudFormation",
          "ConformancePackTemplate",
          "QuickSetup"
        )

        # Document content (required) - JSON or YAML
        attribute :content, Resources::Types::String

        # Document format
        attribute :document_format, Resources::Types::String.enum("YAML", "JSON").default("JSON")

        # Target type for Command documents
        attribute :target_type, Resources::Types::String.optional

        # Schema version
        attribute :schema_version, Resources::Types::String.optional

        # Document version name
        attribute :version_name, Resources::Types::String.optional

        # Document permissions
        attribute :permissions, Resources::Types::Hash.schema(
          type: Types::String.enum("Share", "Private"),
          account_ids?: Types::Array.of(Types::String).optional,
          shared_document_version?: Types::String.optional
        ).default({ type: "Private" })

        # Requires (dependencies)
        attribute :requires, Resources::Types::Array.of(
          Types::Hash.schema(
            name: Types::String,
            version?: Types::String.optional
          )
        ).default([].freeze)

        # Attachments
        attribute :attachments_source, Resources::Types::Array.of(
          Types::Hash.schema(
            key: Types::String,
            values: Types::Array.of(Types::String),
            name?: Types::String.optional
          )
        ).default([].freeze)

        # Tags for the document
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate document content based on format
          begin
            if attrs.document_format == "JSON"
              JSON.parse(attrs.content)
            elsif attrs.document_format == "YAML"
              YAML.safe_load(attrs.content)
            end
          rescue JSON::ParserError, Psych::SyntaxError => e
            raise Dry::Struct::Error, "Invalid #{attrs.document_format} content: #{e.message}"
          end

          # Validate document name format
          unless attrs.name.match?(/\A[a-zA-Z0-9_\-\.]{3,128}\z/)
            raise Dry::Struct::Error, "Document name must be 3-128 characters and contain only letters, numbers, hyphens, underscores, and periods"
          end

          # Validate target_type for Command documents
          if attrs.document_type == "Command"
            unless attrs.target_type
              attrs = attrs.copy_with(target_type: "/AWS::EC2::Instance")
            end
            
            valid_targets = [
              "/AWS::EC2::Instance",
              "/AWS::IoT::Thing", 
              "/AWS::SSM::ManagedInstance"
            ]
            
            if attrs.target_type && !valid_targets.include?(attrs.target_type)
              raise Dry::Struct::Error, "Invalid target_type for Command document. Must be one of: #{valid_targets.join(', ')}"
            end
          elsif attrs.target_type
            raise Dry::Struct::Error, "target_type can only be specified for Command documents"
          end

          # Validate schema version format
          if attrs.schema_version && !attrs.schema_version.match?(/\A\d+\.\d+\z/)
            raise Dry::Struct::Error, "Schema version must be in format 'major.minor' (e.g., '1.2')"
          end

          # Validate permissions
          if attrs.permissions[:type] == "Share"
            unless attrs.permissions[:account_ids] && attrs.permissions[:account_ids].any?
              raise Dry::Struct::Error, "account_ids is required when sharing document"
            end
            
            # Validate AWS account IDs format
            attrs.permissions[:account_ids].each do |account_id|
              unless account_id.match?(/\A\d{12}\z/)
                raise Dry::Struct::Error, "Invalid AWS account ID format: #{account_id}"
              end
            end
          end

          # Validate version name format
          if attrs.version_name && !attrs.version_name.match?(/\A[a-zA-Z0-9_\-\.]{1,128}\z/)
            raise Dry::Struct::Error, "Version name must be 1-128 characters and contain only letters, numbers, hyphens, underscores, and periods"
          end

          attrs
        end

        # Helper methods
        def is_command_document?
          document_type == "Command"
        end

        def is_automation_document?
          document_type == "Automation"
        end

        def is_policy_document?
          document_type == "Policy"
        end

        def is_session_document?
          document_type == "Session"
        end

        def uses_json_format?
          document_format == "JSON"
        end

        def uses_yaml_format?
          document_format == "YAML"
        end

        def has_target_type?
          !target_type.nil?
        end

        def has_schema_version?
          !schema_version.nil?
        end

        def has_version_name?
          !version_name.nil?
        end

        def is_shared?
          permissions[:type] == "Share"
        end

        def is_private?
          permissions[:type] == "Private"
        end

        def has_dependencies?
          requires.any?
        end

        def has_attachments?
          attachments_source.any?
        end

        def shared_with_accounts
          return [] unless is_shared?
          permissions[:account_ids] || []
        end

        def dependency_names
          requires.map { |req| req[:name] }
        end

        def parsed_content
          if uses_json_format?
            JSON.parse(content)
          elsif uses_yaml_format?
            YAML.safe_load(content)
          end
        rescue JSON::ParserError, Psych::SyntaxError
          nil
        end

        def document_steps
          parsed = parsed_content
          return [] unless parsed

          case document_type
          when "Command"
            parsed.dig("mainSteps") || []
          when "Automation"
            parsed.dig("mainSteps") || []
          else
            []
          end
        end

        def estimated_execution_time
          steps = document_steps
          return "Unknown" if steps.empty?
          
          # Rough estimation based on step count and types
          estimated_minutes = steps.count * 2 # 2 minutes per step average
          "~#{estimated_minutes} minutes"
        end
      end

      # Common SSM Document configurations
      module SsmDocumentConfigs
        # Simple command document
        def self.command_document(name, commands, description: nil)
          content = {
            schemaVersion: "2.2",
            description: description || "Execute commands on instances",
            mainSteps: [
              {
                action: "aws:runShellScript",
                name: "executeCommands",
                inputs: {
                  runCommand: commands.is_a?(Array) ? commands : [commands]
                }
              }
            ]
          }

          {
            name: name,
            document_type: "Command",
            content: JSON.pretty_generate(content),
            document_format: "JSON",
            target_type: "/AWS::EC2::Instance"
          }
        end

        # PowerShell command document
        def self.powershell_command_document(name, commands, description: nil)
          content = {
            schemaVersion: "2.2",
            description: description || "Execute PowerShell commands on Windows instances",
            mainSteps: [
              {
                action: "aws:runPowerShellScript",
                name: "executePowerShell",
                inputs: {
                  runCommand: commands.is_a?(Array) ? commands : [commands]
                }
              }
            ]
          }

          {
            name: name,
            document_type: "Command",
            content: JSON.pretty_generate(content),
            document_format: "JSON",
            target_type: "/AWS::EC2::Instance"
          }
        end

        # Automation document
        def self.automation_document(name, steps, description: nil)
          content = {
            schemaVersion: "0.3",
            description: description || "Automation document",
            assumeRole: "{{ AutomationAssumeRole }}",
            parameters: {
              AutomationAssumeRole: {
                type: "String",
                description: "IAM role for automation execution"
              }
            },
            mainSteps: steps
          }

          {
            name: name,
            document_type: "Automation",
            content: JSON.pretty_generate(content),
            document_format: "JSON"
          }
        end

        # Session document (for Session Manager)
        def self.session_document(name, shell_profile: {}, description: nil)
          content = {
            schemaVersion: "1.0",
            description: description || "Session Manager configuration",
            sessionType: "Standard_Stream",
            inputs: {
              s3BucketName: "",
              s3KeyPrefix: "",
              s3EncryptionEnabled: true,
              cloudWatchLogGroupName: "",
              cloudWatchEncryptionEnabled: true,
              kmsKeyId: "",
              shellProfile: shell_profile
            }
          }

          {
            name: name,
            document_type: "Session",
            content: JSON.pretty_generate(content),
            document_format: "JSON"
          }
        end

        # Package installation document
        def self.package_install_document(name, package_name, version: "latest", description: nil)
          content = {
            schemaVersion: "2.2",
            description: description || "Install package on instances",
            parameters: {
              PackageName: {
                type: "String",
                default: package_name,
                description: "Name of the package to install"
              },
              PackageVersion: {
                type: "String",
                default: version,
                description: "Version of the package to install"
              }
            },
            mainSteps: [
              {
                action: "aws:runShellScript",
                name: "installPackage",
                inputs: {
                  runCommand: [
                    "#!/bin/bash",
                    "if command -v yum &> /dev/null; then",
                    "  yum install -y {{ PackageName }}-{{ PackageVersion }}",
                    "elif command -v apt-get &> /dev/null; then",
                    "  apt-get update && apt-get install -y {{ PackageName }}={{ PackageVersion }}",
                    "else",
                    "  echo 'Package manager not supported'",
                    "  exit 1",
                    "fi"
                  ]
                }
              }
            ]
          }

          {
            name: name,
            document_type: "Command",
            content: JSON.pretty_generate(content),
            document_format: "JSON",
            target_type: "/AWS::EC2::Instance"
          }
        end

        # Shared document across accounts
        def self.shared_document(name, content, account_ids, version: nil)
          {
            name: name,
            document_type: "Command",
            content: content,
            document_format: "JSON",
            permissions: {
              type: "Share",
              account_ids: account_ids,
              shared_document_version: version
            }
          }
        end
      end
    end
      end
    end
  end
end