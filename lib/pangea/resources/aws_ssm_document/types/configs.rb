# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module SsmDocumentConfigs
          def self.command_document(name, commands, description: nil)
            content = { schemaVersion: '2.2', description: description || 'Execute commands on instances',
                        mainSteps: [{ action: 'aws:runShellScript', name: 'executeCommands',
                                      inputs: { runCommand: Array(commands) } }] }
            { name: name, document_type: 'Command', content: JSON.pretty_generate(content), document_format: 'JSON', target_type: '/AWS::EC2::Instance' }
          end

          def self.powershell_command_document(name, commands, description: nil)
            content = { schemaVersion: '2.2', description: description || 'Execute PowerShell commands on Windows instances',
                        mainSteps: [{ action: 'aws:runPowerShellScript', name: 'executePowerShell',
                                      inputs: { runCommand: Array(commands) } }] }
            { name: name, document_type: 'Command', content: JSON.pretty_generate(content), document_format: 'JSON', target_type: '/AWS::EC2::Instance' }
          end

          def self.automation_document(name, steps, description: nil)
            content = { schemaVersion: '0.3', description: description || 'Automation document', assumeRole: '{{ AutomationAssumeRole }}',
                        parameters: { AutomationAssumeRole: { type: 'String', description: 'IAM role for automation execution' } }, mainSteps: steps }
            { name: name, document_type: 'Automation', content: JSON.pretty_generate(content), document_format: 'JSON' }
          end

          def self.session_document(name, shell_profile: {}, description: nil)
            content = { schemaVersion: '1.0', description: description || 'Session Manager configuration', sessionType: 'Standard_Stream',
                        inputs: { s3BucketName: '', s3KeyPrefix: '', s3EncryptionEnabled: true, cloudWatchLogGroupName: '',
                                  cloudWatchEncryptionEnabled: true, kmsKeyId: '', shellProfile: shell_profile } }
            { name: name, document_type: 'Session', content: JSON.pretty_generate(content), document_format: 'JSON' }
          end

          def self.package_install_document(name, package_name, version: 'latest', description: nil)
            content = { schemaVersion: '2.2', description: description || 'Install package on instances',
                        parameters: { PackageName: { type: 'String', default: package_name, description: 'Name of the package to install' },
                                      PackageVersion: { type: 'String', default: version, description: 'Version of the package to install' } },
                        mainSteps: [{ action: 'aws:runShellScript', name: 'installPackage',
                                      inputs: { runCommand: ['#!/bin/bash', 'if command -v yum &> /dev/null; then', '  yum install -y {{ PackageName }}-{{ PackageVersion }}',
                                                             'elif command -v apt-get &> /dev/null; then', '  apt-get update && apt-get install -y {{ PackageName }}={{ PackageVersion }}',
                                                             'else', "  echo 'Package manager not supported'", '  exit 1', 'fi'] } }] }
            { name: name, document_type: 'Command', content: JSON.pretty_generate(content), document_format: 'JSON', target_type: '/AWS::EC2::Instance' }
          end

          def self.shared_document(name, content, account_ids, version: nil)
            { name: name, document_type: 'Command', content: content, document_format: 'JSON',
              permissions: { type: 'Share', account_ids: account_ids, shared_document_version: version } }
          end
        end
      end
    end
  end
end
