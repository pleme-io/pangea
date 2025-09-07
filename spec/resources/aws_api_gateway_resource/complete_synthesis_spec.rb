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


require 'spec_helper'
require 'json'

# Load aws_api_gateway_resource resource and terraform-synthesizer for testing
require 'pangea/resources/aws_api_gateway_resource/resource'
require 'terraform-synthesizer'

RSpec.describe "aws_api_gateway_resource terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  
  # Test values
  let(:rest_api_id) { "abc123def456" }
  let(:root_resource_id) { "xyz789uvw012" }
  let(:users_resource_id) { "usr123res456" }
  let(:admin_resource_id) { "adm789res012" }

  # Test basic resource synthesis
  it "synthesizes basic API Gateway resource correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_resource(:users, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "users"
      })
    end
    
    json_output = synthesizer.synthesis
    resource_config = json_output.dig(:resource, :aws_api_gateway_resource, :users)
    
    expect(resource_config[:rest_api_id]).to eq(rest_api_id)
    expect(resource_config[:parent_id]).to eq(root_resource_id)
    expect(resource_config[:path_part]).to eq("users")
  end

  # Test resource with path parameter
  it "synthesizes resource with path parameter" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_resource(:user_by_id, {
        rest_api_id: rest_api_id,
        parent_id: users_resource_id,
        path_part: "{userId}"
      })
    end
    
    json_output = synthesizer.synthesis
    resource_config = json_output.dig(:resource, :aws_api_gateway_resource, :user_by_id)
    
    expect(resource_config[:rest_api_id]).to eq(rest_api_id)
    expect(resource_config[:parent_id]).to eq(users_resource_id)
    expect(resource_config[:path_part]).to eq("{userId}")
  end

  # Test resource with greedy parameter
  it "synthesizes resource with greedy parameter" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_resource(:proxy_resource, {
        rest_api_id: rest_api_id,
        parent_id: admin_resource_id,
        path_part: "{proxy+}"
      })
    end
    
    json_output = synthesizer.synthesis
    resource_config = json_output.dig(:resource, :aws_api_gateway_resource, :proxy_resource)
    
    expect(resource_config[:rest_api_id]).to eq(rest_api_id)
    expect(resource_config[:parent_id]).to eq(admin_resource_id)
    expect(resource_config[:path_part]).to eq("{proxy+}")
  end

  # Test versioned API structure
  it "synthesizes versioned API structure" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_resource(:v1, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "v1"
      })
      
      aws_api_gateway_resource(:v1_users, {
        rest_api_id: rest_api_id,
        parent_id: "v1_resource_id",  # Would be reference in real usage
        path_part: "users"
      })
    end
    
    json_output = synthesizer.synthesis
    resources = json_output.dig(:resource, :aws_api_gateway_resource)
    
    expect(resources).to have_key(:v1)
    expect(resources).to have_key(:v1_users)
    
    v1_config = resources[:v1]
    expect(v1_config[:path_part]).to eq("v1")
    
    v1_users_config = resources[:v1_users]
    expect(v1_users_config[:path_part]).to eq("users")
  end

  # Test RESTful resource hierarchy
  it "synthesizes RESTful resource hierarchy" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # /users
      aws_api_gateway_resource(:users, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "users"
      })
      
      # /users/{userId}
      aws_api_gateway_resource(:user_by_id, {
        rest_api_id: rest_api_id,
        parent_id: users_resource_id,
        path_part: "{userId}"
      })
      
      # /users/{userId}/posts
      aws_api_gateway_resource(:user_posts, {
        rest_api_id: rest_api_id,
        parent_id: "user_by_id_resource",
        path_part: "posts"
      })
      
      # /users/{userId}/posts/{postId}
      aws_api_gateway_resource(:user_post_by_id, {
        rest_api_id: rest_api_id,
        parent_id: "user_posts_resource",
        path_part: "{postId}"
      })
    end
    
    json_output = synthesizer.synthesis
    resources = json_output.dig(:resource, :aws_api_gateway_resource)
    
    expect(resources.keys).to contain_exactly(
      :users, :user_by_id, :user_posts, :user_post_by_id
    )
    
    # Verify structure
    expect(resources[:users][:path_part]).to eq("users")
    expect(resources[:user_by_id][:path_part]).to eq("{userId}")
    expect(resources[:user_posts][:path_part]).to eq("posts")
    expect(resources[:user_post_by_id][:path_part]).to eq("{postId}")
  end

  # Test microservices gateway pattern
  it "synthesizes microservices gateway pattern" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # /services
      aws_api_gateway_resource(:services, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "services"
      })
      
      # /services/{serviceName}
      aws_api_gateway_resource(:service_by_name, {
        rest_api_id: rest_api_id,
        parent_id: "services_resource",
        path_part: "{serviceName}"
      })
      
      # /services/{serviceName}/{proxy+}
      aws_api_gateway_resource(:service_proxy, {
        rest_api_id: rest_api_id,
        parent_id: "service_by_name_resource",
        path_part: "{proxy+}"
      })
    end
    
    json_output = synthesizer.synthesis
    resources = json_output.dig(:resource, :aws_api_gateway_resource)
    
    expect(resources[:services][:path_part]).to eq("services")
    expect(resources[:service_by_name][:path_part]).to eq("{serviceName}")
    expect(resources[:service_proxy][:path_part]).to eq("{proxy+}")
  end

  # Test operational endpoints
  it "synthesizes operational endpoints" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # Health check
      aws_api_gateway_resource(:health, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "health"
      })
      
      # Metrics
      aws_api_gateway_resource(:metrics, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "metrics"
      })
      
      # Webhooks
      aws_api_gateway_resource(:webhooks, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "webhooks"
      })
      
      # Webhook receiver
      aws_api_gateway_resource(:webhook_by_type, {
        rest_api_id: rest_api_id,
        parent_id: "webhooks_resource",
        path_part: "{webhookType}"
      })
    end
    
    json_output = synthesizer.synthesis
    resources = json_output.dig(:resource, :aws_api_gateway_resource)
    
    expect(resources[:health][:path_part]).to eq("health")
    expect(resources[:metrics][:path_part]).to eq("metrics")
    expect(resources[:webhooks][:path_part]).to eq("webhooks")
    expect(resources[:webhook_by_type][:path_part]).to eq("{webhookType}")
  end

  # Test search and filtering patterns
  it "synthesizes search and filtering patterns" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # Global search
      aws_api_gateway_resource(:search, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "search"
      })
      
      # Resource-specific search
      aws_api_gateway_resource(:user_search, {
        rest_api_id: rest_api_id,
        parent_id: users_resource_id,
        path_part: "search"
      })
      
      # Filtering endpoint
      aws_api_gateway_resource(:filter, {
        rest_api_id: rest_api_id,
        parent_id: users_resource_id,
        path_part: "filter"
      })
    end
    
    json_output = synthesizer.synthesis
    resources = json_output.dig(:resource, :aws_api_gateway_resource)
    
    expect(resources[:search][:path_part]).to eq("search")
    expect(resources[:user_search][:path_part]).to eq("search")
    expect(resources[:filter][:path_part]).to eq("filter")
  end

  # Test batch operations pattern
  it "synthesizes batch operations pattern" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # Batch endpoint
      aws_api_gateway_resource(:batch, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "batch"
      })
      
      # Batch operations by type
      aws_api_gateway_resource(:batch_operation, {
        rest_api_id: rest_api_id,
        parent_id: "batch_resource",
        path_part: "{operation}"
      })
      
      # Resource-specific batch
      aws_api_gateway_resource(:user_batch, {
        rest_api_id: rest_api_id,
        parent_id: users_resource_id,
        path_part: "batch"
      })
    end
    
    json_output = synthesizer.synthesis
    resources = json_output.dig(:resource, :aws_api_gateway_resource)
    
    expect(resources[:batch][:path_part]).to eq("batch")
    expect(resources[:batch_operation][:path_part]).to eq("{operation}")
    expect(resources[:user_batch][:path_part]).to eq("batch")
  end

  # Test admin interface pattern
  it "synthesizes admin interface pattern" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # Admin section
      aws_api_gateway_resource(:admin, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "admin"
      })
      
      # Admin resource management
      aws_api_gateway_resource(:admin_resource, {
        rest_api_id: rest_api_id,
        parent_id: admin_resource_id,
        path_part: "{resource}"
      })
      
      # Admin actions
      aws_api_gateway_resource(:admin_action, {
        rest_api_id: rest_api_id,
        parent_id: "admin_resource_resource",
        path_part: "{action}"
      })
      
      # Admin proxy for flexibility
      aws_api_gateway_resource(:admin_proxy, {
        rest_api_id: rest_api_id,
        parent_id: admin_resource_id,
        path_part: "{proxy+}"
      })
    end
    
    json_output = synthesizer.synthesis
    resources = json_output.dig(:resource, :aws_api_gateway_resource)
    
    expect(resources[:admin][:path_part]).to eq("admin")
    expect(resources[:admin_resource][:path_part]).to eq("{resource}")
    expect(resources[:admin_action][:path_part]).to eq("{action}")
    expect(resources[:admin_proxy][:path_part]).to eq("{proxy+}")
  end

  # Test data export/import patterns
  it "synthesizes data export/import patterns" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # Export endpoint
      aws_api_gateway_resource(:export, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "export"
      })
      
      # Import endpoint
      aws_api_gateway_resource(:import, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "import"
      })
      
      # Resource-specific export
      aws_api_gateway_resource(:user_export, {
        rest_api_id: rest_api_id,
        parent_id: users_resource_id,
        path_part: "export"
      })
      
      # Format-specific export
      aws_api_gateway_resource(:export_format, {
        rest_api_id: rest_api_id,
        parent_id: "export_resource",
        path_part: "{format}"
      })
    end
    
    json_output = synthesizer.synthesis
    resources = json_output.dig(:resource, :aws_api_gateway_resource)
    
    expect(resources[:export][:path_part]).to eq("export")
    expect(resources[:import][:path_part]).to eq("import")
    expect(resources[:user_export][:path_part]).to eq("export")
    expect(resources[:export_format][:path_part]).to eq("{format}")
  end

  # Test complex nested API structure
  it "synthesizes complex nested API structure" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # API versioning
      aws_api_gateway_resource(:api, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "api"
      })
      
      aws_api_gateway_resource(:v2, {
        rest_api_id: rest_api_id,
        parent_id: "api_resource",
        path_part: "v2"
      })
      
      # Organizations
      aws_api_gateway_resource(:organizations, {
        rest_api_id: rest_api_id,
        parent_id: "v2_resource",
        path_part: "organizations"
      })
      
      aws_api_gateway_resource(:org_by_id, {
        rest_api_id: rest_api_id,
        parent_id: "organizations_resource",
        path_part: "{orgId}"
      })
      
      # Projects within organizations
      aws_api_gateway_resource(:projects, {
        rest_api_id: rest_api_id,
        parent_id: "org_by_id_resource",
        path_part: "projects"
      })
      
      aws_api_gateway_resource(:project_by_id, {
        rest_api_id: rest_api_id,
        parent_id: "projects_resource",
        path_part: "{projectId}"
      })
      
      # Resources within projects
      aws_api_gateway_resource(:resources, {
        rest_api_id: rest_api_id,
        parent_id: "project_by_id_resource",
        path_part: "resources"
      })
      
      aws_api_gateway_resource(:resource_by_id, {
        rest_api_id: rest_api_id,
        parent_id: "resources_resource",
        path_part: "{resourceId}"
      })
    end
    
    json_output = synthesizer.synthesis
    resources = json_output.dig(:resource, :aws_api_gateway_resource)
    
    # Verify all resources are created
    expect(resources.keys).to contain_exactly(
      :api, :v2, :organizations, :org_by_id,
      :projects, :project_by_id, :resources, :resource_by_id
    )
    
    # Verify path structure
    expect(resources[:api][:path_part]).to eq("api")
    expect(resources[:v2][:path_part]).to eq("v2")
    expect(resources[:organizations][:path_part]).to eq("organizations")
    expect(resources[:org_by_id][:path_part]).to eq("{orgId}")
    expect(resources[:projects][:path_part]).to eq("projects")
    expect(resources[:project_by_id][:path_part]).to eq("{projectId}")
    expect(resources[:resources][:path_part]).to eq("resources")
    expect(resources[:resource_by_id][:path_part]).to eq("{resourceId}")
  end

  # Test resource naming patterns
  it "synthesizes resources with various naming patterns" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # Hyphenated names
      aws_api_gateway_resource(:user_profiles, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "user-profiles"
      })
      
      # Underscore names
      aws_api_gateway_resource(:api_keys, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "api_keys"
      })
      
      # Numeric names
      aws_api_gateway_resource(:version_2, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "v2"
      })
      
      # Mixed patterns
      aws_api_gateway_resource(:user_session_v1, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "user-session-v1"
      })
    end
    
    json_output = synthesizer.synthesis
    resources = json_output.dig(:resource, :aws_api_gateway_resource)
    
    expect(resources[:user_profiles][:path_part]).to eq("user-profiles")
    expect(resources[:api_keys][:path_part]).to eq("api_keys")
    expect(resources[:version_2][:path_part]).to eq("v2")
    expect(resources[:user_session_v1][:path_part]).to eq("user-session-v1")
  end

  # Test parameter naming patterns
  it "synthesizes resources with various parameter patterns" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # Simple ID
      aws_api_gateway_resource(:simple_id, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "{id}"
      })
      
      # Entity-specific ID
      aws_api_gateway_resource(:user_id, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "{userId}"
      })
      
      # Hyphenated parameter
      aws_api_gateway_resource(:user_profile_id, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "{user-profile-id}"
      })
      
      # Underscore parameter
      aws_api_gateway_resource(:api_key_id, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "{api_key_id}"
      })
      
      # Greedy parameters
      aws_api_gateway_resource(:catch_all, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "{catchAll+}"
      })
    end
    
    json_output = synthesizer.synthesis
    resources = json_output.dig(:resource, :aws_api_gateway_resource)
    
    expect(resources[:simple_id][:path_part]).to eq("{id}")
    expect(resources[:user_id][:path_part]).to eq("{userId}")
    expect(resources[:user_profile_id][:path_part]).to eq("{user-profile-id}")
    expect(resources[:api_key_id][:path_part]).to eq("{api_key_id}")
    expect(resources[:catch_all][:path_part]).to eq("{catchAll+}")
  end

  # Test multiple APIs in single synthesis
  it "synthesizes resources for multiple APIs" do
    api_1_id = "api1abc123"
    api_2_id = "api2def456"
    root_1_id = "root1xyz"
    root_2_id = "root2uvw"
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # API 1 resources
      aws_api_gateway_resource(:api1_users, {
        rest_api_id: api_1_id,
        parent_id: root_1_id,
        path_part: "users"
      })
      
      aws_api_gateway_resource(:api1_user_id, {
        rest_api_id: api_1_id,
        parent_id: "api1_users_resource",
        path_part: "{userId}"
      })
      
      # API 2 resources
      aws_api_gateway_resource(:api2_products, {
        rest_api_id: api_2_id,
        parent_id: root_2_id,
        path_part: "products"
      })
      
      aws_api_gateway_resource(:api2_product_id, {
        rest_api_id: api_2_id,
        parent_id: "api2_products_resource",
        path_part: "{productId}"
      })
    end
    
    json_output = synthesizer.synthesis
    resources = json_output.dig(:resource, :aws_api_gateway_resource)
    
    # Verify all resources are created
    expect(resources.keys).to contain_exactly(
      :api1_users, :api1_user_id, :api2_products, :api2_product_id
    )
    
    # Verify API separation
    expect(resources[:api1_users][:rest_api_id]).to eq(api_1_id)
    expect(resources[:api1_user_id][:rest_api_id]).to eq(api_1_id)
    expect(resources[:api2_products][:rest_api_id]).to eq(api_2_id)
    expect(resources[:api2_product_id][:rest_api_id]).to eq(api_2_id)
  end

  # Test synthesis with edge cases
  it "synthesizes resources with edge case configurations" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # Single character path
      aws_api_gateway_resource(:single_char, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "a"
      })
      
      # Numeric path
      aws_api_gateway_resource(:numeric_path, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "123"
      })
      
      # Long path part
      aws_api_gateway_resource(:long_path, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "very-long-resource-name-with-many-hyphens"
      })
      
      # Mixed case (API Gateway normalizes)
      aws_api_gateway_resource(:mixed_case, {
        rest_api_id: rest_api_id,
        parent_id: root_resource_id,
        path_part: "MixedCase"
      })
    end
    
    json_output = synthesizer.synthesis
    resources = json_output.dig(:resource, :aws_api_gateway_resource)
    
    expect(resources[:single_char][:path_part]).to eq("a")
    expect(resources[:numeric_path][:path_part]).to eq("123")
    expect(resources[:long_path][:path_part]).to eq("very-long-resource-name-with-many-hyphens")
    expect(resources[:mixed_case][:path_part]).to eq("MixedCase")
  end

  # Test synthesis validates input parameters
  it "validates synthesis parameters through dry-struct" do
    expect {
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        
        aws_api_gateway_resource(:invalid_path, {
          rest_api_id: rest_api_id,
          parent_id: root_resource_id,
          path_part: "users/profile"  # Contains slash
        })
      end
    }.to raise_error(Dry::Struct::Error, /Path part cannot contain slashes/)
    
    expect {
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        
        aws_api_gateway_resource(:invalid_greedy, {
          rest_api_id: rest_api_id,
          parent_id: root_resource_id,
          path_part: "prefix{proxy+}"  # Invalid greedy format
        })
      end
    }.to raise_error(Dry::Struct::Error, /Greedy path variables/)
  end
end