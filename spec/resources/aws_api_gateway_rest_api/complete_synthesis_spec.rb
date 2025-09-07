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

# Load aws_api_gateway_rest_api resource and terraform-synthesizer for testing
require 'pangea/resources/aws_api_gateway_rest_api/resource'
require 'terraform-synthesizer'

RSpec.describe "aws_api_gateway_rest_api terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  
  # Test basic REST API synthesis
  it "synthesizes basic REST API correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_rest_api(:basic_api, {
        name: "my-basic-api",
        tags: {}
      })
    end
    
    json_output = synthesizer.synthesis
    api_config = json_output.dig(:resource, :aws_api_gateway_rest_api, :basic_api)
    
    expect(api_config[:name]).to eq("my-basic-api")
    expect(api_config[:api_key_source]).to eq("HEADER")
    expect(api_config[:minimum_tls_version]).to eq("TLS_1_2")
    expect(api_config[:disable_execute_api_endpoint]).to eq(false)
  end
  
  # Test REST API with description synthesis
  it "synthesizes REST API with description correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_rest_api(:described_api, {
        name: "described-api",
        description: "This is a comprehensive REST API for our application",
        tags: {}
      })
    end
    
    json_output = synthesizer.synthesis
    api_config = json_output.dig(:resource, :aws_api_gateway_rest_api, :described_api)
    
    expect(api_config[:name]).to eq("described-api")
    expect(api_config[:description]).to eq("This is a comprehensive REST API for our application")
  end
  
  # Test edge-optimized API synthesis
  it "synthesizes edge-optimized API correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_rest_api(:edge_api, {
        name: "global-edge-api",
        description: "Edge-optimized API for global distribution",
        endpoint_configuration: {
          types: ["EDGE"]
        },
        tags: {
          Type: "edge-optimized",
          Distribution: "global"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    api_config = json_output.dig(:resource, :aws_api_gateway_rest_api, :edge_api)
    
    expect(api_config[:endpoint_configuration]).to be_a(Hash)
    expect(api_config[:endpoint_configuration][:types]).to eq(["EDGE"])
    expect(api_config[:tags][:Type]).to eq("edge-optimized")
  end
  
  # Test regional API synthesis
  it "synthesizes regional API correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_rest_api(:regional_api, {
        name: "regional-api",
        endpoint_configuration: {
          types: ["REGIONAL"]
        },
        tags: {
          Type: "regional",
          Region: "us-east-1"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    api_config = json_output.dig(:resource, :aws_api_gateway_rest_api, :regional_api)
    
    expect(api_config[:endpoint_configuration][:types]).to eq(["REGIONAL"])
  end
  
  # Test private API synthesis
  it "synthesizes private API correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_rest_api(:private_api, {
        name: "vpc-private-api",
        description: "Private API accessible only from VPC",
        endpoint_configuration: {
          types: ["PRIVATE"],
          vpc_endpoint_ids: ["vpce-12345678", "vpce-87654321"]
        },
        disable_execute_api_endpoint: true,
        policy: JSON.generate({
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Principal: "*",
            Action: "execute-api:Invoke",
            Resource: "*",
            Condition: {
              StringEquals: {
                "aws:SourceVpce": ["vpce-12345678", "vpce-87654321"]
              }
            }
          }]
        }),
        tags: {
          Access: "private",
          Network: "vpc-only"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    api_config = json_output.dig(:resource, :aws_api_gateway_rest_api, :private_api)
    
    expect(api_config[:endpoint_configuration][:types]).to eq(["PRIVATE"])
    expect(api_config[:endpoint_configuration][:vpc_endpoint_ids]).to eq(["vpce-12345678", "vpce-87654321"])
    expect(api_config[:disable_execute_api_endpoint]).to eq(true)
    expect(api_config[:policy]).to include("execute-api:Invoke")
  end
  
  # Test API with binary media types synthesis
  it "synthesizes API with binary media types correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_rest_api(:binary_api, {
        name: "file-upload-api",
        description: "API supporting file uploads",
        binary_media_types: [
          "image/png",
          "image/jpeg",
          "image/gif",
          "application/pdf",
          "application/octet-stream",
          "multipart/form-data"
        ],
        minimum_compression_size: 5120,
        tags: {
          Purpose: "file-upload",
          BinarySupport: "enabled"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    api_config = json_output.dig(:resource, :aws_api_gateway_rest_api, :binary_api)
    
    expect(api_config[:binary_media_types]).to be_a(Array)
    expect(api_config[:binary_media_types]).to have(6).items
    expect(api_config[:binary_media_types]).to include("image/png", "multipart/form-data")
    expect(api_config[:minimum_compression_size]).to eq(5120)
  end
  
  # Test API with security settings synthesis
  it "synthesizes API with security settings correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_rest_api(:secure_api, {
        name: "secure-api",
        description: "API with enhanced security",
        minimum_tls_version: "TLS_1_2",
        api_key_source: "AUTHORIZER",
        tags: {
          Security: "enhanced",
          TLS: "1.2"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    api_config = json_output.dig(:resource, :aws_api_gateway_rest_api, :secure_api)
    
    expect(api_config[:minimum_tls_version]).to eq("TLS_1_2")
    expect(api_config[:api_key_source]).to eq("AUTHORIZER")
  end
  
  # Test API with version and clone synthesis
  it "synthesizes API with version and clone correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_rest_api(:versioned_api, {
        name: "versioned-api",
        description: "API v2.0 cloned from v1.0",
        version: "v2.0",
        clone_from: "arn:aws:apigateway:us-east-1::/restapis/abcdef123",
        tags: {
          Version: "2.0",
          ClonedFrom: "v1.0"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    api_config = json_output.dig(:resource, :aws_api_gateway_rest_api, :versioned_api)
    
    expect(api_config[:version]).to eq("v2.0")
    expect(api_config[:clone_from]).to eq("arn:aws:apigateway:us-east-1::/restapis/abcdef123")
  end
  
  # Test API with OpenAPI body synthesis
  it "synthesizes API with OpenAPI body correctly" do
    openapi_spec = JSON.generate({
      openapi: "3.0.0",
      info: {
        title: "Pet Store API",
        version: "1.0.0"
      },
      paths: {
        "/pets": {
          get: {
            summary: "List all pets",
            responses: {
              "200": {
                description: "Success"
              }
            }
          }
        }
      }
    })
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_rest_api(:openapi_api, {
        name: "petstore-api",
        description: "Pet Store API from OpenAPI spec",
        body: openapi_spec,
        tags: {
          Source: "openapi",
          Version: "3.0.0"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    api_config = json_output.dig(:resource, :aws_api_gateway_rest_api, :openapi_api)
    
    expect(api_config[:body]).to eq(openapi_spec)
    expect(api_config[:body]).to include("Pet Store API")
  end
  
  # Test API with comprehensive tags synthesis
  it "synthesizes API with comprehensive tags correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_rest_api(:tagged_api, {
        name: "tagged-api",
        tags: {
          Environment: "production",
          Application: "web-service",
          Team: "platform",
          CostCenter: "engineering",
          Project: "api-gateway",
          ManagedBy: "terraform",
          Owner: "platform-team@example.com"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    api_config = json_output.dig(:resource, :aws_api_gateway_rest_api, :tagged_api)
    
    expect(api_config[:tags]).to be_a(Hash)
    expect(api_config[:tags]).to have(7).items
    expect(api_config[:tags][:Environment]).to eq("production")
    expect(api_config[:tags][:Owner]).to eq("platform-team@example.com")
  end
  
  # Test minimal API synthesis
  it "synthesizes minimal API correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_rest_api(:minimal_api, {
        name: "minimal",
        tags: {}
      })
    end
    
    json_output = synthesizer.synthesis
    api_config = json_output.dig(:resource, :aws_api_gateway_rest_api, :minimal_api)
    
    expect(api_config[:name]).to eq("minimal")
    expect(api_config[:tags]).to eq({})
    
    # Optional fields should not be present
    expect(api_config).not_to have_key(:description)
    expect(api_config).not_to have_key(:version)
    expect(api_config).not_to have_key(:binary_media_types)
    expect(api_config).not_to have_key(:policy)
    expect(api_config).not_to have_key(:body)
  end
  
  # Test public REST API pattern synthesis
  it "synthesizes public REST API pattern correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_rest_api(:public_rest_api, {
        name: "public-product-api",
        description: "Public API for product catalog",
        endpoint_configuration: {
          types: ["EDGE"]
        },
        binary_media_types: ["image/jpeg", "image/png"],
        minimum_compression_size: 1024,
        minimum_tls_version: "TLS_1_2",
        tags: {
          Access: "public",
          Service: "product-catalog",
          SLA: "99.9"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    api_config = json_output.dig(:resource, :aws_api_gateway_rest_api, :public_rest_api)
    
    expect(api_config[:endpoint_configuration][:types]).to eq(["EDGE"])
    expect(api_config[:binary_media_types]).to include("image/jpeg")
    expect(api_config[:minimum_compression_size]).to eq(1024)
  end
  
  # Test microservice API pattern synthesis
  it "synthesizes microservice API pattern correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_rest_api(:user_service_api, {
        name: "user-service",
        description: "User microservice API - handles authentication and user management",
        endpoint_configuration: {
          types: ["REGIONAL"]
        },
        api_key_source: "HEADER",
        disable_execute_api_endpoint: false,
        tags: {
          Service: "user-service",
          Type: "microservice",
          Team: "identity",
          Version: "1.0.0"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    api_config = json_output.dig(:resource, :aws_api_gateway_rest_api, :user_service_api)
    
    expect(api_config[:name]).to eq("user-service")
    expect(api_config[:endpoint_configuration][:types]).to eq(["REGIONAL"])
    expect(api_config[:api_key_source]).to eq("HEADER")
    expect(api_config[:tags][:Service]).to eq("user-service")
  end
  
  # Test file upload API pattern synthesis
  it "synthesizes file upload API pattern correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_rest_api(:document_upload_api, {
        name: "document-upload-service",
        description: "API for document upload and processing",
        binary_media_types: [
          "application/pdf",
          "application/msword",
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
          "image/png",
          "image/jpeg",
          "multipart/form-data"
        ],
        minimum_compression_size: 10240,
        tags: {
          Purpose: "document-processing",
          MaxFileSize: "10MB",
          SupportedFormats: "pdf,doc,docx,png,jpg"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    api_config = json_output.dig(:resource, :aws_api_gateway_rest_api, :document_upload_api)
    
    expect(api_config[:binary_media_types]).to have(6).items
    expect(api_config[:binary_media_types]).to include("application/pdf", "multipart/form-data")
    expect(api_config[:minimum_compression_size]).to eq(10240)
  end
  
  # Test internal VPC API pattern synthesis
  it "synthesizes internal VPC API pattern correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_api_gateway_rest_api(:internal_admin_api, {
        name: "internal-admin-api",
        description: "Internal administration API - VPC access only",
        endpoint_configuration: {
          types: ["PRIVATE"],
          vpc_endpoint_ids: ["vpce-0a1b2c3d4e5f6g7h8", "vpce-8h7g6f5e4d3c2b1a0"]
        },
        disable_execute_api_endpoint: true,
        policy: JSON.generate({
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Principal: "*",
            Action: "execute-api:Invoke",
            Resource: "*",
            Condition: {
              StringEquals: {
                "aws:SourceVpce": ["vpce-0a1b2c3d4e5f6g7h8", "vpce-8h7g6f5e4d3c2b1a0"]
              }
            }
          }]
        }),
        tags: {
          Access: "internal",
          SecurityLevel: "restricted",
          Network: "vpc-only",
          Compliance: "pci-dss"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    api_config = json_output.dig(:resource, :aws_api_gateway_rest_api, :internal_admin_api)
    
    expect(api_config[:endpoint_configuration][:types]).to eq(["PRIVATE"])
    expect(api_config[:endpoint_configuration][:vpc_endpoint_ids]).to have(2).items
    expect(api_config[:disable_execute_api_endpoint]).to eq(true)
    expect(api_config[:policy]).to include("aws:SourceVpce")
    expect(api_config[:tags][:Compliance]).to eq("pci-dss")
  end
end