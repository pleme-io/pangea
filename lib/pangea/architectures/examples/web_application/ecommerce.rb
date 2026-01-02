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

# Example 2: High-Performance E-commerce Platform
template :ecommerce_platform do
  include Pangea::Architectures

  ecommerce = web_application_architecture(:ecommerce, {
    domain_name: 'store.example.com',
    environment: 'production',
    instance_type: 'c5.large',
    auto_scaling: { min: 3, max: 20, desired: 5 },
    database_engine: 'aurora-mysql',
    database_instance_class: 'db.r5.xlarge',
    database_allocated_storage: 500,
    enable_caching: true,
    enable_cdn: true,
    security: {
      encryption_at_rest: true,
      encryption_in_transit: true,
      enable_waf: true,
      enable_ddos_protection: true,
      compliance_standards: ['PCI-DSS']
    },
    monitoring: {
      detailed_monitoring: true,
      enable_logging: true,
      log_retention_days: 90,
      enable_alerting: true,
      enable_tracing: true
    },
    backup: {
      backup_schedule: 'daily',
      retention_days: 30,
      cross_region_backup: true,
      point_in_time_recovery: true
    },
    tags: {
      Application: 'ECommerce',
      CostCenter: 'Retail',
      Compliance: 'PCI-DSS'
    }
  })

  ecommerce.extend_with({
    elasticsearch: aws_elasticsearch_domain(:ecommerce_search, {
      domain_name: 'ecommerce-search',
      elasticsearch_version: '7.10',
      instance_type: 't3.small.elasticsearch',
      instance_count: 2,
      ebs_options: { ebs_enabled: true, volume_size: 20 }
    }),
    order_queue: aws_sqs_queue(:order_processing, {
      name: 'ecommerce-orders',
      visibility_timeout_seconds: 300,
      message_retention_seconds: 1_209_600
    }),
    images_bucket: aws_s3_bucket(:product_images, {
      bucket: "ecommerce-product-images-#{SecureRandom.hex(8)}",
      versioning: { enabled: true },
      server_side_encryption_configuration: {
        rule: {
          apply_server_side_encryption_by_default: { sse_algorithm: 'AES256' }
        }
      }
    })
  })

  output :store_url do
    value ecommerce.application_url
    description 'E-commerce store URL'
  end

  output :cdn_domain do
    value ecommerce.cdn_domain
    description 'CloudFront distribution for static assets'
  end

  output :search_endpoint do
    value ecommerce.elasticsearch.domain_endpoint
    description 'Elasticsearch domain for product search'
  end

  output :total_monthly_cost do
    value ecommerce.estimated_monthly_cost + 45.0
    description 'Total estimated monthly cost including extensions'
  end
end
