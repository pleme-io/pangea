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

require 'pangea'

# Example 3: Multi-Environment Deployment
template :multi_environment_saas do
  include Pangea::Architectures

  environments = [
    {
      name: 'development',
      domain: 'dev.saas-app.com',
      config: {
        instance_type: 't3.micro',
        auto_scaling: { min: 1, max: 2 },
        database_instance_class: 'db.t3.micro',
        enable_caching: false,
        enable_cdn: false
      }
    },
    {
      name: 'staging',
      domain: 'staging.saas-app.com',
      config: {
        instance_type: 't3.small',
        auto_scaling: { min: 1, max: 4 },
        database_instance_class: 'db.t3.small',
        enable_caching: true,
        enable_cdn: false
      }
    },
    {
      name: 'production',
      domain: 'saas-app.com',
      config: {
        instance_type: 't3.medium',
        auto_scaling: { min: 2, max: 15 },
        database_instance_class: 'db.r5.large',
        enable_caching: true,
        enable_cdn: true
      }
    }
  ]

  environments.each do |env|
    app = web_application_architecture(:"saas_#{env[:name]}", {
      domain_name: env[:domain],
      environment: env[:name],
      **env[:config],
      database_engine: 'postgresql',
      security: {
        encryption_at_rest: true,
        encryption_in_transit: true,
        enable_waf: env[:name] == 'production',
        enable_ddos_protection: env[:name] == 'production'
      },
      tags: {
        Application: 'SaaSApp',
        Environment: env[:name].capitalize,
        Project: 'MultiTenant'
      }
    })

    output :"#{env[:name]}_url" do
      value app.application_url
      description "#{env[:name].capitalize} environment URL"
    end

    output :"#{env[:name]}_cost" do
      value app.estimated_monthly_cost
      description "#{env[:name].capitalize} estimated monthly cost"
    end
  end
end
