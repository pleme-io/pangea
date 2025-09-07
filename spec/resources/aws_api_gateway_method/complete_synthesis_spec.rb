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

# Load aws_api_gateway_method resource and terraform-synthesizer for testing
require 'pangea/resources/aws_api_gateway_method/resource'
require 'terraform-synthesizer'

RSpec.describe "aws_api_gateway_method terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  
  # Test values
  let(:rest_api_id) { "abc123def456" }
  let(:resource_id) { "xyz789uvw012" }
  let(:authorizer_id) { "auth123def456" }
  let(:validator_id) { "valid123def456" }

  # Test basic method synthesis
  it "synthesizes basic GET method correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_method(:get_users, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET"
      })
    end
    
    json_output = synthesizer.synthesis
    method_config = json_output.dig(:resource, :aws_api_gateway_method, :get_users)
    
    expect(method_config[:rest_api_id]).to eq(rest_api_id)
    expect(method_config[:resource_id]).to eq(resource_id)
    expect(method_config[:http_method]).to eq("GET")
    expect(method_config[:authorization]).to eq("NONE")
    expect(method_config[:api_key_required]).to eq(false)
  end

  # Test POST method with request models
  it "synthesizes POST method with request models" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_method(:create_user, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        request_models: {
          "application/json" => "UserModel"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    method_config = json_output.dig(:resource, :aws_api_gateway_method, :create_user)
    
    expect(method_config[:http_method]).to eq("POST")
    expect(method_config[:request_models]).to eq({
      "application/json" => "UserModel"
    })
  end

  # Test method with IAM authorization
  it "synthesizes method with IAM authorization" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_method(:iam_protected, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        authorization: "AWS_IAM"
      })
    end
    
    json_output = synthesizer.synthesis
    method_config = json_output.dig(:resource, :aws_api_gateway_method, :iam_protected)
    
    expect(method_config[:authorization]).to eq("AWS_IAM")
    expect(method_config).not_to have_key(:authorizer_id)
    expect(method_config).not_to have_key(:authorization_scopes)
  end

  # Test method with custom authorizer
  it "synthesizes method with custom authorizer" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_method(:custom_auth_method, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        authorization: "CUSTOM",
        authorizer_id: authorizer_id
      })
    end
    
    json_output = synthesizer.synthesis
    method_config = json_output.dig(:resource, :aws_api_gateway_method, :custom_auth_method)
    
    expect(method_config[:authorization]).to eq("CUSTOM")
    expect(method_config[:authorizer_id]).to eq(authorizer_id)
  end

  # Test method with Cognito User Pool authorization and scopes
  it "synthesizes method with Cognito User Pool authorization" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_method(:cognito_method, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        authorization: "COGNITO_USER_POOLS",
        authorizer_id: authorizer_id,
        authorization_scopes: ["read", "write", "admin"]
      })
    end
    
    json_output = synthesizer.synthesis
    method_config = json_output.dig(:resource, :aws_api_gateway_method, :cognito_method)
    
    expect(method_config[:authorization]).to eq("COGNITO_USER_POOLS")
    expect(method_config[:authorizer_id]).to eq(authorizer_id)
    expect(method_config[:authorization_scopes]).to eq(["read", "write", "admin"])
  end

  # Test method with API key requirement
  it "synthesizes method with API key requirement" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_method(:api_key_method, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET",
        api_key_required: true
      })
    end
    
    json_output = synthesizer.synthesis
    method_config = json_output.dig(:resource, :aws_api_gateway_method, :api_key_method)
    
    expect(method_config[:api_key_required]).to eq(true)
  end

  # Test method with request parameters
  it "synthesizes method with request parameters" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_method(:parameterized_method, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET",
        request_parameters: {
          "method.request.path.userId" => true,
          "method.request.querystring.page" => false,
          "method.request.header.Authorization" => true
        }
      })
    end
    
    json_output = synthesizer.synthesis
    method_config = json_output.dig(:resource, :aws_api_gateway_method, :parameterized_method)
    
    expect(method_config[:request_parameters]).to eq({
      "method.request.path.userId" => true,
      "method.request.querystring.page" => false,
      "method.request.header.Authorization" => true
    })
  end

  # Test method with multiple request models
  it "synthesizes method with multiple request models" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_method(:multi_model_method, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        request_models: {
          "application/json" => "UserJsonModel",
          "application/xml" => "UserXmlModel",
          "application/x-www-form-urlencoded" => "UserFormModel"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    method_config = json_output.dig(:resource, :aws_api_gateway_method, :multi_model_method)
    
    expect(method_config[:request_models]).to eq({
      "application/json" => "UserJsonModel",
      "application/xml" => "UserXmlModel",
      "application/x-www-form-urlencoded" => "UserFormModel"
    })
  end

  # Test method with request validator
  it "synthesizes method with request validator" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_method(:validated_method, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        request_validator_id: validator_id
      })
    end
    
    json_output = synthesizer.synthesis
    method_config = json_output.dig(:resource, :aws_api_gateway_method, :validated_method)
    
    expect(method_config[:request_validator_id]).to eq(validator_id)
  end

  # Test method with operation name
  it "synthesizes method with operation name for SDK generation" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_method(:named_operation, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET",
        operation_name: "getUserById"
      })
    end
    
    json_output = synthesizer.synthesis
    method_config = json_output.dig(:resource, :aws_api_gateway_method, :named_operation)
    
    expect(method_config[:operation_name]).to eq("getUserById")
  end

  # Test CORS OPTIONS method
  it "synthesizes CORS OPTIONS method" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_method(:cors_preflight, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "OPTIONS"
      })
    end
    
    json_output = synthesizer.synthesis
    method_config = json_output.dig(:resource, :aws_api_gateway_method, :cors_preflight)
    
    expect(method_config[:http_method]).to eq("OPTIONS")
    expect(method_config[:authorization]).to eq("NONE")
  end

  # Test comprehensive method configuration
  it "synthesizes method with comprehensive configuration" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_method(:comprehensive_method, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "POST",
        authorization: "COGNITO_USER_POOLS",
        authorizer_id: authorizer_id,
        authorization_scopes: ["read", "write"],
        api_key_required: true,
        request_parameters: {
          "method.request.path.id" => true,
          "method.request.header.Content-Type" => true,
          "method.request.querystring.expand" => false
        },
        request_models: {
          "application/json" => "ComprehensiveModel"
        },
        request_validator_id: validator_id,
        operation_name: "comprehensiveOperation"
      })
    end
    
    json_output = synthesizer.synthesis
    method_config = json_output.dig(:resource, :aws_api_gateway_method, :comprehensive_method)
    
    # Verify all attributes are present
    expect(method_config[:http_method]).to eq("POST")
    expect(method_config[:authorization]).to eq("COGNITO_USER_POOLS")
    expect(method_config[:authorizer_id]).to eq(authorizer_id)
    expect(method_config[:authorization_scopes]).to eq(["read", "write"])
    expect(method_config[:api_key_required]).to eq(true)
    expect(method_config[:request_parameters]).to be_a(Hash)
    expect(method_config[:request_models]).to be_a(Hash)
    expect(method_config[:request_validator_id]).to eq(validator_id)
    expect(method_config[:operation_name]).to eq("comprehensiveOperation")
  end

  # Test RESTful CRUD operations
  it "synthesizes complete RESTful CRUD operations" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # List users (GET /users)
      aws_api_gateway_method(:list_users, {
        rest_api_id: rest_api_id,
        resource_id: "users_resource_id",
        http_method: "GET",
        operation_name: "listUsers",
        request_parameters: {
          "method.request.querystring.page" => false,
          "method.request.querystring.limit" => false
        }
      })
      
      # Create user (POST /users)
      aws_api_gateway_method(:create_user, {
        rest_api_id: rest_api_id,
        resource_id: "users_resource_id",
        http_method: "POST",
        operation_name: "createUser",
        request_models: {
          "application/json" => "UserCreateModel"
        }
      })
      
      # Get user (GET /users/{id})
      aws_api_gateway_method(:get_user, {
        rest_api_id: rest_api_id,
        resource_id: "user_by_id_resource_id",
        http_method: "GET",
        operation_name: "getUserById",
        request_parameters: {
          "method.request.path.id" => true
        }
      })
      
      # Update user (PUT /users/{id})
      aws_api_gateway_method(:update_user, {
        rest_api_id: rest_api_id,
        resource_id: "user_by_id_resource_id",
        http_method: "PUT",
        operation_name: "updateUser",
        request_parameters: {
          "method.request.path.id" => true
        },
        request_models: {
          "application/json" => "UserUpdateModel"
        }
      })
      
      # Delete user (DELETE /users/{id})
      aws_api_gateway_method(:delete_user, {
        rest_api_id: rest_api_id,
        resource_id: "user_by_id_resource_id",
        http_method: "DELETE",
        operation_name: "deleteUser",
        request_parameters: {
          "method.request.path.id" => true
        }
      })
    end
    
    json_output = synthesizer.synthesis
    methods = json_output.dig(:resource, :aws_api_gateway_method)
    
    expect(methods.keys).to contain_exactly(
      :list_users, :create_user, :get_user, :update_user, :delete_user
    )
    
    # Verify each method has correct configuration
    expect(methods[:list_users][:http_method]).to eq("GET")
    expect(methods[:create_user][:http_method]).to eq("POST")
    expect(methods[:get_user][:http_method]).to eq("GET")
    expect(methods[:update_user][:http_method]).to eq("PUT")
    expect(methods[:delete_user][:http_method]).to eq("DELETE")
  end

  # Test different HTTP methods
  it "synthesizes all supported HTTP methods" do
    methods = ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'HEAD', 'PATCH', 'ANY']
    
    methods.each_with_index do |method, index|
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        
        aws_api_gateway_method(:"method_#{method.downcase}", {
          rest_api_id: rest_api_id,
          resource_id: "resource_#{index}",
          http_method: method
        })
      end
    end
    
    json_output = synthesizer.synthesis
    method_configs = json_output.dig(:resource, :aws_api_gateway_method)
    
    methods.each do |method|
      method_key = :"method_#{method.downcase}"
      expect(method_configs[method_key][:http_method]).to eq(method)
    end
  end

  # Test different authorization types
  it "synthesizes all authorization types correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # NONE authorization
      aws_api_gateway_method(:auth_none, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET",
        authorization: "NONE"
      })
      
      # AWS_IAM authorization
      aws_api_gateway_method(:auth_iam, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET",
        authorization: "AWS_IAM"
      })
      
      # CUSTOM authorization
      aws_api_gateway_method(:auth_custom, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET",
        authorization: "CUSTOM",
        authorizer_id: authorizer_id
      })
      
      # COGNITO_USER_POOLS authorization
      aws_api_gateway_method(:auth_cognito, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET",
        authorization: "COGNITO_USER_POOLS",
        authorizer_id: authorizer_id,
        authorization_scopes: ["openid", "profile"]
      })
    end
    
    json_output = synthesizer.synthesis
    methods = json_output.dig(:resource, :aws_api_gateway_method)
    
    expect(methods[:auth_none][:authorization]).to eq("NONE")
    expect(methods[:auth_none]).not_to have_key(:authorizer_id)
    
    expect(methods[:auth_iam][:authorization]).to eq("AWS_IAM")
    expect(methods[:auth_iam]).not_to have_key(:authorizer_id)
    
    expect(methods[:auth_custom][:authorization]).to eq("CUSTOM")
    expect(methods[:auth_custom][:authorizer_id]).to eq(authorizer_id)
    expect(methods[:auth_custom]).not_to have_key(:authorization_scopes)
    
    expect(methods[:auth_cognito][:authorization]).to eq("COGNITO_USER_POOLS")
    expect(methods[:auth_cognito][:authorizer_id]).to eq(authorizer_id)
    expect(methods[:auth_cognito][:authorization_scopes]).to eq(["openid", "profile"])
  end

  # Test API Gateway batch operations pattern
  it "synthesizes batch operations pattern" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # Batch create
      aws_api_gateway_method(:batch_create_users, {
        rest_api_id: rest_api_id,
        resource_id: "batch_users_resource",
        http_method: "POST",
        operation_name: "batchCreateUsers",
        request_models: {
          "application/json" => "BatchUsersModel"
        }
      })
      
      # Batch update
      aws_api_gateway_method(:batch_update_users, {
        rest_api_id: rest_api_id,
        resource_id: "batch_users_resource",
        http_method: "PUT",
        operation_name: "batchUpdateUsers",
        request_models: {
          "application/json" => "BatchUsersModel"
        }
      })
      
      # Batch delete
      aws_api_gateway_method(:batch_delete_users, {
        rest_api_id: rest_api_id,
        resource_id: "batch_users_resource",
        http_method: "DELETE",
        operation_name: "batchDeleteUsers",
        request_models: {
          "application/json" => "BatchDeleteModel"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    methods = json_output.dig(:resource, :aws_api_gateway_method)
    
    expect(methods[:batch_create_users][:operation_name]).to eq("batchCreateUsers")
    expect(methods[:batch_update_users][:operation_name]).to eq("batchUpdateUsers")
    expect(methods[:batch_delete_users][:operation_name]).to eq("batchDeleteUsers")
  end

  # Test webhook receiver pattern
  it "synthesizes webhook receiver pattern" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # GitHub webhook
      aws_api_gateway_method(:github_webhook, {
        rest_api_id: rest_api_id,
        resource_id: "github_webhook_resource",
        http_method: "POST",
        operation_name: "handleGitHubWebhook",
        request_parameters: {
          "method.request.header.X-Hub-Signature" => true,
          "method.request.header.X-GitHub-Event" => true
        },
        request_models: {
          "application/json" => "GitHubWebhookModel"
        }
      })
      
      # Stripe webhook
      aws_api_gateway_method(:stripe_webhook, {
        rest_api_id: rest_api_id,
        resource_id: "stripe_webhook_resource",
        http_method: "POST",
        operation_name: "handleStripeWebhook",
        request_parameters: {
          "method.request.header.Stripe-Signature" => true
        },
        request_models: {
          "application/json" => "StripeWebhookModel"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    methods = json_output.dig(:resource, :aws_api_gateway_method)
    
    github_method = methods[:github_webhook]
    expect(github_method[:request_parameters]).to include(
      "method.request.header.X-Hub-Signature" => true,
      "method.request.header.X-GitHub-Event" => true
    )
    
    stripe_method = methods[:stripe_webhook]
    expect(stripe_method[:request_parameters]).to include(
      "method.request.header.Stripe-Signature" => true
    )
  end

  # Test search and filtering endpoints
  it "synthesizes search and filtering endpoints" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # Search endpoint
      aws_api_gateway_method(:search_users, {
        rest_api_id: rest_api_id,
        resource_id: "search_resource",
        http_method: "GET",
        operation_name: "searchUsers",
        request_parameters: {
          "method.request.querystring.q" => true,
          "method.request.querystring.filter" => false,
          "method.request.querystring.sort" => false,
          "method.request.querystring.limit" => false
        }
      })
      
      # Advanced filter endpoint
      aws_api_gateway_method(:filter_users, {
        rest_api_id: rest_api_id,
        resource_id: "filter_resource",
        http_method: "POST",
        operation_name: "filterUsers",
        request_models: {
          "application/json" => "FilterCriteriaModel"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    methods = json_output.dig(:resource, :aws_api_gateway_method)
    
    search_method = methods[:search_users]
    expect(search_method[:request_parameters]).to include(
      "method.request.querystring.q" => true,
      "method.request.querystring.filter" => false
    )
    
    filter_method = methods[:filter_users]
    expect(filter_method[:request_models]).to include(
      "application/json" => "FilterCriteriaModel"
    )
  end

  # Test file upload endpoints
  it "synthesizes file upload endpoints" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # File upload via multipart form
      aws_api_gateway_method(:upload_file, {
        rest_api_id: rest_api_id,
        resource_id: "upload_resource",
        http_method: "POST",
        operation_name: "uploadFile",
        request_models: {
          "multipart/form-data" => "FileUploadModel"
        },
        request_parameters: {
          "method.request.header.Content-Type" => true
        }
      })
      
      # Direct file upload via binary
      aws_api_gateway_method(:upload_binary, {
        rest_api_id: rest_api_id,
        resource_id: "binary_upload_resource",
        http_method: "PUT",
        operation_name: "uploadBinary",
        request_parameters: {
          "method.request.path.filename" => true,
          "method.request.header.Content-Type" => true,
          "method.request.header.Content-Length" => true
        }
      })
    end
    
    json_output = synthesizer.synthesis
    methods = json_output.dig(:resource, :aws_api_gateway_method)
    
    upload_method = methods[:upload_file]
    expect(upload_method[:request_models]).to include(
      "multipart/form-data" => "FileUploadModel"
    )
    
    binary_method = methods[:upload_binary]
    expect(binary_method[:request_parameters]).to include(
      "method.request.path.filename" => true,
      "method.request.header.Content-Length" => true
    )
  end

  # Test complex parameter combinations
  it "synthesizes methods with complex parameter combinations" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_method(:complex_params, {
        rest_api_id: rest_api_id,
        resource_id: resource_id,
        http_method: "GET",
        request_parameters: {
          # Path parameters
          "method.request.path.userId" => true,
          "method.request.path.resourceId" => true,
          
          # Query parameters
          "method.request.querystring.page" => false,
          "method.request.querystring.limit" => false,
          "method.request.querystring.expand" => false,
          "method.request.querystring.fields" => false,
          
          # Headers
          "method.request.header.Authorization" => true,
          "method.request.header.Accept" => false,
          "method.request.header.User-Agent" => false,
          
          # Multi-value parameters
          "method.request.multivalueheader.X-Custom-Headers" => false,
          "method.request.multivaluequerystring.tags" => false
        }
      })
    end
    
    json_output = synthesizer.synthesis
    method_config = json_output.dig(:resource, :aws_api_gateway_method, :complex_params)
    
    params = method_config[:request_parameters]
    expect(params.size).to eq(11)
    
    # Verify required vs optional parameters
    expect(params["method.request.path.userId"]).to be true
    expect(params["method.request.querystring.page"]).to be false
    expect(params["method.request.header.Authorization"]).to be true
    expect(params["method.request.header.Accept"]).to be false
  end

  # Test synthesis validates input parameters
  it "validates synthesis parameters through dry-struct" do
    expect {
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        
        aws_api_gateway_method(:invalid_method, {
          rest_api_id: rest_api_id,
          resource_id: resource_id,
          http_method: "INVALID"
        })
      end
    }.to raise_error(Dry::Struct::Error)
    
    expect {
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        
        aws_api_gateway_method(:missing_authorizer, {
          rest_api_id: rest_api_id,
          resource_id: resource_id,
          http_method: "GET",
          authorization: "CUSTOM"
        })
      end
    }.to raise_error(Dry::Struct::Error, /authorizer_id is required/)
    
    expect {
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        
        aws_api_gateway_method(:invalid_params, {
          rest_api_id: rest_api_id,
          resource_id: resource_id,
          http_method: "GET",
          request_parameters: {
            "invalid.parameter.format" => true
          }
        })
      end
    }.to raise_error(Dry::Struct::Error, /Invalid request parameter format/)
  end
end