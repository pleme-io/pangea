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
      module EmrCluster
        class DSLBuilder
          # EC2 attributes building methods for EMR clusters
          module Ec2Attributes
            def build_ec2_attributes(ctx)
              ec2_attrs = attrs.ec2_attributes
              ctx.ec2_attributes do
                instance_profile ec2_attrs[:instance_profile]
                key_name ec2_attrs[:key_name] if ec2_attrs[:key_name]

                if ec2_attrs[:emr_managed_master_security_group]
                  emr_managed_master_security_group ec2_attrs[:emr_managed_master_security_group]
                end
                if ec2_attrs[:emr_managed_slave_security_group]
                  emr_managed_slave_security_group ec2_attrs[:emr_managed_slave_security_group]
                end
                if ec2_attrs[:service_access_security_group]
                  service_access_security_group ec2_attrs[:service_access_security_group]
                end

                if ec2_attrs[:additional_master_security_groups]&.any?
                  additional_master_security_groups ec2_attrs[:additional_master_security_groups]
                end
                if ec2_attrs[:additional_slave_security_groups]&.any?
                  additional_slave_security_groups ec2_attrs[:additional_slave_security_groups]
                end

                subnet_id ec2_attrs[:subnet_id] if ec2_attrs[:subnet_id]
                subnet_ids ec2_attrs[:subnet_ids] if ec2_attrs[:subnet_ids]&.any?
              end
            end
          end
        end
      end
    end
  end
end
