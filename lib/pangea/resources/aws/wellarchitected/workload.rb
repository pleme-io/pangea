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
      module WellArchitected
        # AWS Well-Architected Workload resource
        # This resource manages Well-Architected workloads which are collections of resources
        # and code that deliver business value. Workloads are assessed against the
        # Well-Architected Framework pillars.
        #
        # @see https://docs.aws.amazon.com/wellarchitected/latest/userguide/workloads.html
        module Workload
          # Creates an AWS Well-Architected Workload
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the workload
          # @option attributes [String] :workload_name The name of the workload (required)
          # @option attributes [String] :description A description of the workload (required)
          # @option attributes [String] :environment The environment for the workload (required)
          # @option attributes [Array<String>] :account_ids The AWS account IDs associated with the workload
          # @option attributes [Array<String>] :aws_regions The AWS regions for the workload
          # @option attributes [Array<String>] :non_aws_regions Non-AWS regions for the workload
          # @option attributes [Array<String>] :pillar_priorities The prioritized pillars for the workload
          # @option attributes [String] :architectural_design The architectural design of the workload
          # @option attributes [String] :review_owner The owner of the workload review
          # @option attributes [String] :industry_type The industry type for the workload
          # @option attributes [String] :industry The industry for the workload
          # @option attributes [Array<String>] :lenses The lenses to apply to the workload
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Basic web application workload
          #   aws_wellarchitected_workload(:web_application, {
          #     workload_name: "E-commerce Web Application",
          #     description: "Customer-facing e-commerce platform with microservices architecture",
          #     environment: "PRODUCTION",
          #     account_ids: ["123456789012", "234567890123"],
          #     aws_regions: ["us-east-1", "us-west-2"],
          #     pillar_priorities: ["Security", "Reliability", "Performance Efficiency"],
          #     architectural_design: "Microservices architecture with containerized services running on EKS, using RDS for data persistence and ElastiCache for caching. CloudFront for global content delivery.",
          #     review_owner: "architecture-team@company.com",
          #     industry_type: "Retail",
          #     industry: "E-commerce",
          #     lenses: ["wellarchitected"],
          #     tags: {
          #       Team: "Platform",
          #       Project: "Ecommerce",
          #       CostCenter: "12345"
          #     }
          #   })
          #
          # @example Data analytics workload
          #   aws_wellarchitected_workload(:data_platform, {
          #     workload_name: "Data Analytics Platform",
          #     description: "Real-time and batch data processing platform for business intelligence",
          #     environment: "PRODUCTION",
          #     account_ids: ["111122223333"],
          #     aws_regions: ["us-east-1"],
          #     pillar_priorities: ["Cost Optimization", "Performance Efficiency", "Security"],
          #     architectural_design: "Lambda-based data processing with Kinesis for streaming, S3 for data lake, and Redshift for analytics warehouse. QuickSight for visualization.",
          #     review_owner: "data-team@company.com",
          #     industry_type: "Technology",
          #     industry: "Software",
          #     lenses: ["wellarchitected", "serverless"]
          #   })
          #
          # @return [WorkloadResource] The workload resource
          def aws_wellarchitected_workload(name, attributes = {})
            resource :aws_wellarchitected_workload, name do
              workload_name attributes[:workload_name] if attributes[:workload_name]
              description attributes[:description] if attributes[:description]
              environment attributes[:environment] if attributes[:environment]
              account_ids attributes[:account_ids] if attributes[:account_ids]
              aws_regions attributes[:aws_regions] if attributes[:aws_regions]
              non_aws_regions attributes[:non_aws_regions] if attributes[:non_aws_regions]
              pillar_priorities attributes[:pillar_priorities] if attributes[:pillar_priorities]
              architectural_design attributes[:architectural_design] if attributes[:architectural_design]
              review_owner attributes[:review_owner] if attributes[:review_owner]
              industry_type attributes[:industry_type] if attributes[:industry_type]
              industry attributes[:industry] if attributes[:industry]
              lenses attributes[:lenses] if attributes[:lenses]
              tags attributes[:tags] if attributes[:tags]
            end
          end
        end
      end
    end
  end
end