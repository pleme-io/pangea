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
  module Architectures
    module Patterns
      module WebApplication
        # Security tier creation for web application
        module SecurityTier
          private

          def create_security_tier(name, arch_ref, arch_attrs, base_tags)
            security_resources = {}

            security_resources[:web_sg] = create_web_security_group(name, arch_ref, base_tags)

            if arch_attrs.database_enabled
              security_resources[:db_sg] = create_db_security_group(name, arch_ref, arch_attrs,
                                                                    security_resources[:web_sg], base_tags)
            end

            security_resources
          end

          def create_web_security_group(name, arch_ref, base_tags)
            aws_security_group(
              architecture_resource_name(name, :web_sg),
              name_prefix: "#{name}-web-sg",
              vpc_id: arch_ref.network.vpc.id,
              ingress_rules: [
                { from_port: 80, to_port: 80, protocol: 'tcp',
                  cidr_blocks: ['0.0.0.0/0'], description: 'HTTP' },
                { from_port: 443, to_port: 443, protocol: 'tcp',
                  cidr_blocks: ['0.0.0.0/0'], description: 'HTTPS' }
              ],
              egress_rules: [
                { from_port: 0, to_port: 0, protocol: '-1',
                  cidr_blocks: ['0.0.0.0/0'], description: 'All outbound' }
              ],
              tags: base_tags.merge(Tier: 'security', Component: 'web-sg')
            )
          end

          def create_db_security_group(name, arch_ref, arch_attrs, web_sg, base_tags)
            db_port = arch_attrs.database_engine == 'postgres' ? 5432 : 3306

            aws_security_group(
              architecture_resource_name(name, :db_sg),
              name_prefix: "#{name}-db-sg",
              vpc_id: arch_ref.network.vpc.id,
              ingress_rules: [
                { from_port: db_port, to_port: db_port, protocol: 'tcp',
                  security_groups: [web_sg.id],
                  description: "#{arch_attrs.database_engine.upcase} from web tier" }
              ],
              tags: base_tags.merge(Tier: 'security', Component: 'db-sg')
            )
          end
        end
      end
    end
  end
end
