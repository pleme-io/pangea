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

# Example 1: Basic Web Application
template :basic_web_application do
  include Pangea::Architectures

  web_app = web_application_architecture(:basic_app, {
    domain_name: 'basic-app.com',
    environment: 'production',
    auto_scaling: { min: 2, max: 5, desired: 2 },
    instance_type: 't3.small',
    database_engine: 'mysql'
  })

  output :application_url do
    value web_app.application_url
    description 'Primary application URL'
  end

  output :estimated_cost do
    value web_app.estimated_monthly_cost
    description 'Estimated monthly AWS cost'
  end
end
