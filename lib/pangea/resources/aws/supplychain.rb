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
      # AWS Supply Chain resources for supply chain optimization and visibility
      module SupplyChain
        include Base

        # Data lake and dataset management
        def aws_supplychain_data_lake_dataset(name, attributes = {})
          create_resource(:aws_supplychain_data_lake_dataset, name, attributes) do |attrs|
            Reference.new(:aws_supplychain_data_lake_dataset, name, {
              arn: computed_attr("${aws_supplychain_data_lake_dataset.#{name}.arn}"),
              id: computed_attr("${aws_supplychain_data_lake_dataset.#{name}.id}"),
              name: attrs[:name],
              namespace: attrs[:namespace],
              description: attrs[:description],
              instance_id: attrs[:instance_id],
              schema: attrs[:schema]
            })
          end
        end

        def aws_supplychain_asc_data_lake_dataset(name, attributes = {})
          create_resource(:aws_supplychain_asc_data_lake_dataset, name, attributes) do |attrs|
            Reference.new(:aws_supplychain_asc_data_lake_dataset, name, {
              arn: computed_attr("${aws_supplychain_asc_data_lake_dataset.#{name}.arn}"),
              id: computed_attr("${aws_supplychain_asc_data_lake_dataset.#{name}.id}"),
              name: attrs[:name],
              namespace: attrs[:namespace],
              description: attrs[:description],
              instance_id: attrs[:instance_id],
              schema: attrs[:schema],
              asc_version: attrs[:asc_version]
            })
          end
        end

        def aws_supplychain_data_lake_dataset_access_policy(name, attributes = {})
          create_resource(:aws_supplychain_data_lake_dataset_access_policy, name, attributes) do |attrs|
            Reference.new(:aws_supplychain_data_lake_dataset_access_policy, name, {
              arn: computed_attr("${aws_supplychain_data_lake_dataset_access_policy.#{name}.arn}"),
              id: computed_attr("${aws_supplychain_data_lake_dataset_access_policy.#{name}.id}"),
              dataset_name: attrs[:dataset_name],
              dataset_namespace: attrs[:dataset_namespace],
              instance_id: attrs[:instance_id],
              policy: attrs[:policy],
              policy_type: attrs[:policy_type]
            })
          end
        end

        # Data integration and processing
        def aws_supplychain_data_integration_flow(name, attributes = {})
          create_resource(:aws_supplychain_data_integration_flow, name, attributes) do |attrs|
            Reference.new(:aws_supplychain_data_integration_flow, name, {
              arn: computed_attr("${aws_supplychain_data_integration_flow.#{name}.arn}"),
              id: computed_attr("${aws_supplychain_data_integration_flow.#{name}.id}"),
              name: attrs[:name],
              instance_id: attrs[:instance_id],
              sources: attrs[:sources],
              transformation: attrs[:transformation],
              target: attrs[:target],
              schedule: attrs[:schedule]
            })
          end
        end

        # Supply chain instance management
        def aws_supplychain_instance(name, attributes = {})
          create_resource(:aws_supplychain_instance, name, attributes) do |attrs|
            Reference.new(:aws_supplychain_instance, name, {
              arn: computed_attr("${aws_supplychain_instance.#{name}.arn}"),
              id: computed_attr("${aws_supplychain_instance.#{name}.id}"),
              instance_name: attrs[:instance_name],
              instance_description: attrs[:instance_description],
              kms_key_arn: attrs[:kms_key_arn],
              tags: attrs[:tags],
              status: computed_attr("${aws_supplychain_instance.#{name}.status}"),
              web_app_dns_domain: computed_attr("${aws_supplychain_instance.#{name}.web_app_dns_domain}")
            })
          end
        end

        # Bill of materials management
        def aws_supplychain_bill_of_materials_import_job(name, attributes = {})
          create_resource(:aws_supplychain_bill_of_materials_import_job, name, attributes) do |attrs|
            Reference.new(:aws_supplychain_bill_of_materials_import_job, name, {
              arn: computed_attr("${aws_supplychain_bill_of_materials_import_job.#{name}.arn}"),
              job_id: computed_attr("${aws_supplychain_bill_of_materials_import_job.#{name}.job_id}"),
              instance_id: attrs[:instance_id],
              s3uri: attrs[:s3uri],
              client_token: attrs[:client_token],
              status: computed_attr("${aws_supplychain_bill_of_materials_import_job.#{name}.status}"),
              message: computed_attr("${aws_supplychain_bill_of_materials_import_job.#{name}.message}")
            })
          end
        end
      end
    end
  end
end