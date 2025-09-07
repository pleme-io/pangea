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
      module ControlTower
        # AWS Control Tower Landing Zone resource
        # This resource manages the Control Tower Landing Zone which provides a baseline
        # environment with security and governance guardrails for your AWS organization.
        #
        # @see https://docs.aws.amazon.com/controltower/latest/userguide/landing-zone.html
        module LandingZone
          # Creates an AWS Control Tower Landing Zone
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the landing zone
          # @option attributes [String] :version The version of the landing zone (required)
          # @option attributes [Hash] :manifest The landing zone configuration manifest (required)
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Basic landing zone setup
          #   aws_controltower_landing_zone(:main, {
          #     version: "3.0",
          #     manifest: {
          #       governedRegions: ["us-east-1", "us-west-2"],
          #       organizationStructure: {
          #         security: {
          #           name: "Security"
          #         },
          #         sandbox: {
          #           name: "Sandbox"
          #         }
          #       },
          #       centralizedLogging: {
          #         accountId: "123456789012",
          #         configurations: {
          #           loggingBucket: {
          #             retentionDays: 365
          #           },
          #           accessLoggingBucket: {
          #             retentionDays: 3653
          #           },
          #           kmsKeyId: "arn:aws:kms:us-east-1:123456789012:key/abcd1234-a123-456a-a12b-a123b4cd56ef"
          #         }
          #       },
          #       securityRoles: {
          #         accountId: "234567890123"
          #       },
          #       accessManagement: {
          #         enabled: true
          #       }
          #     }
          #   })
          #
          # @example Landing zone with multiple regions and advanced configuration
          #   aws_controltower_landing_zone(:enterprise, {
          #     version: "3.0",
          #     manifest: {
          #       governedRegions: ["us-east-1", "us-west-2", "eu-west-1", "ap-southeast-1"],
          #       organizationStructure: {
          #         security: {
          #           name: "Security",
          #           organizationalUnitId: "ou-root-security123"
          #         },
          #         sandbox: {
          #           name: "Sandbox",
          #           organizationalUnitId: "ou-root-sandbox456"
          #         },
          #         workloads: {
          #           name: "Workloads",
          #           organizationalUnitId: "ou-root-workloads789"
          #         }
          #       },
          #       centralizedLogging: {
          #         accountId: "111122223333",
          #         configurations: {
          #           loggingBucket: {
          #             retentionDays: 2555
          #           },
          #           accessLoggingBucket: {
          #             retentionDays: 3653
          #           },
          #           kmsKeyId: "arn:aws:kms:us-east-1:111122223333:key/enterprise-key"
          #         }
          #       },
          #       securityRoles: {
          #         accountId: "444455556666"
          #       },
          #       accessManagement: {
          #         enabled: true
          #       }
          #     },
          #     tags: {
          #       Environment: "Production",
          #       Organization: "Enterprise",
          #       CostCenter: "12345"
          #     }
          #   })
          #
          # @return [LandingZoneResource] The landing zone resource
          def aws_controltower_landing_zone(name, attributes = {})
            resource :aws_controltower_landing_zone, name do
              version attributes[:version] if attributes[:version]
              manifest attributes[:manifest] if attributes[:manifest]
              tags attributes[:tags] if attributes[:tags]
            end
          end
        end
      end
    end
  end
end