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
    module Composition
      # Web server composition pattern
      module WebServer
        # Create a web server with its required networking components
        #
        # @param name [Symbol] Server name
        # @param subnet_ref [ResourceReference] Subnet to place the instance in
        # @param attributes [Hash] Instance attributes and customization
        # @return [CompositeWebServerReference] Reference with instance and security group
        def web_server(name, subnet_ref:, attributes: {})
          results = CompositeWebServerReference.new(name)

          results.security_group = create_web_security_group(name, subnet_ref, attributes)
          results.instance = create_web_instance(name, subnet_ref, results.security_group, attributes)

          results
        end

        private

        def create_web_security_group(name, subnet_ref, attributes)
          aws_security_group(:"#{name}_sg", {
                               name_prefix: "#{name}-sg",
                               vpc_id: subnet_ref.vpc_id,
                               ingress_rules: [
                                 { from_port: 80, to_port: 80, protocol: 'tcp',
                                   cidr_blocks: ['0.0.0.0/0'], description: 'HTTP' },
                                 { from_port: 443, to_port: 443, protocol: 'tcp',
                                   cidr_blocks: ['0.0.0.0/0'], description: 'HTTPS' },
                                 { from_port: 22, to_port: 22, protocol: 'tcp',
                                   cidr_blocks: [subnet_ref.computed_attributes.cidr_block], description: 'SSH from subnet' }
                               ],
                               tags: { Name: "#{name}-security-group" }.merge(attributes[:sg_tags] || {})
                             })
        end

        def create_web_instance(name, subnet_ref, security_group, attributes)
          aws_instance(name, {
                         ami: attributes[:ami] || 'ami-0c55b159cbfafe1f0',
                         instance_type: attributes[:instance_type] || 't3.micro',
                         subnet_id: subnet_ref.id,
                         vpc_security_group_ids: [security_group.id],
                         key_name: attributes[:key_name],
                         user_data: attributes[:user_data] || default_web_server_user_data,
                         tags: {
                           Name: "#{name}-web-server",
                           Type: 'web'
                         }.merge(attributes[:instance_tags] || {})
                       })
        end
      end
    end
  end
end
