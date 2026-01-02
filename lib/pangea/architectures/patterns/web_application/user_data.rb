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
        # User data generation for web application instances
        module UserData
          private

          def generate_user_data(name, arch_ref, arch_attrs)
            database_endpoint = arch_attrs.database_enabled ? arch_ref.database[:instance].endpoint : 'localhost'

            <<~USERDATA
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd

              # Install CloudWatch agent
              yum install -y amazon-cloudwatch-agent

              # Create application directory
              mkdir -p /var/www/#{name}

              # Create index.html with architecture info
              cat > /var/www/html/index.html << 'EOF'
              #{generate_html_content(name, arch_attrs, database_endpoint)}
              EOF

              # Set environment variables for application
              echo "export DB_HOST=#{database_endpoint}" >> /etc/environment
              echo "export APP_ENV=#{arch_attrs.environment}" >> /etc/environment
              echo "export APP_NAME=#{name}" >> /etc/environment
            USERDATA
          end

          def generate_html_content(name, arch_attrs, database_endpoint)
            humanized_name = name.to_s.split('_').map(&:capitalize).join(' ')

            <<~HTML
              <html>
              <head>
                  <title>#{humanized_name} - #{arch_attrs.environment.capitalize}</title>
                  <style>
                      body { font-family: Arial, sans-serif; margin: 40px; }
                      .header { color: #232F3E; }
                      .info { background: #f5f5f5; padding: 20px; margin: 20px 0; }
                      .status { color: #28a745; }
                  </style>
              </head>
              <body>
                  <h1 class="header">#{humanized_name}</h1>
                  <p class="status">Application is running successfully!</p>

                  <div class="info">
                      <h3>Architecture Information</h3>
                      <ul>
                          <li><strong>Environment:</strong> #{arch_attrs.environment}</li>
                          <li><strong>Instance Type:</strong> #{arch_attrs.instance_type}</li>
                          <li><strong>Database:</strong> #{database_info(arch_attrs)}</li>
                          <li><strong>High Availability:</strong> #{arch_attrs.high_availability ? 'Yes' : 'No'}</li>
                          <li><strong>Availability Zones:</strong> #{arch_attrs.availability_zones.count}</li>
                      </ul>
                  </div>

                  <div class="info">
                      <h3>Infrastructure Details</h3>
                      <ul>
                          <li><strong>Domain:</strong> #{arch_attrs.domain}</li>
                          <li><strong>VPC CIDR:</strong> #{arch_attrs.vpc_cidr}</li>
                          <li><strong>Database Endpoint:</strong> #{database_endpoint}</li>
                          <li><strong>Deployment Time:</strong> #{Time.now}</li>
                      </ul>
                  </div>
              </body>
              </html>
            HTML
          end

          def database_info(arch_attrs)
            if arch_attrs.database_enabled
              "#{arch_attrs.database_engine} (#{arch_attrs.database_instance_class})"
            else
              'Disabled'
            end
          end
        end
      end
    end
  end
end
