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

# Load aws_lambda_function resource and terraform-synthesizer for testing
require 'pangea/resources/aws_lambda_function/resource'
require 'terraform_synthesizer'

RSpec.describe "aws_lambda_function terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  let(:execution_role_arn) { "arn:aws:iam::123456789012:role/lambda-execution-role" }
  let(:vpc_execution_role_arn) { "arn:aws:iam::123456789012:role/lambda-vpc-execution-role" }

  # Test basic lambda function synthesis
  it "synthesizes basic lambda function correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:api_handler, {
        function_name: "api-handler",
        role: execution_role_arn,
        handler: "index.handler",
        runtime: "nodejs18.x",
        filename: "function.zip",
        description: "API request handler",
        timeout: 30,
        memory_size: 512,
        publish: true
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "api_handler")
    
    expect(function_config["function_name"]).to eq("api-handler")
    expect(function_config["role"]).to eq(execution_role_arn)
    expect(function_config["handler"]).to eq("index.handler")
    expect(function_config["runtime"]).to eq("nodejs18.x")
    expect(function_config["filename"]).to eq("function.zip")
    expect(function_config["description"]).to eq("API request handler")
    expect(function_config["timeout"]).to eq(30)
    expect(function_config["memory_size"]).to eq(512)
    expect(function_config["publish"]).to eq(true)
    expect(function_config["architectures"]).to eq(["x86_64"])
    expect(function_config["package_type"]).to eq("Zip")
  end

  # Test S3 code source synthesis
  it "synthesizes lambda with S3 code source correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:s3_function, {
        function_name: "s3-deployed-function",
        role: execution_role_arn,
        handler: "app.lambda_handler",
        runtime: "python3.11",
        s3_bucket: "my-lambda-deployments",
        s3_key: "functions/app-v1.2.3.zip",
        s3_object_version: "abc123def456"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "s3_function")
    
    expect(function_config["s3_bucket"]).to eq("my-lambda-deployments")
    expect(function_config["s3_key"]).to eq("functions/app-v1.2.3.zip")
    expect(function_config["s3_object_version"]).to eq("abc123def456")
    expect(function_config).not_to have_key("filename")
  end

  # Test container image function synthesis
  it "synthesizes container image function correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:container_function, {
        function_name: "ml-processor",
        role: execution_role_arn,
        package_type: "Image",
        image_uri: "123456789012.dkr.ecr.us-east-1.amazonaws.com/ml-processor:v2.0",
        timeout: 900,
        memory_size: 3008,
        image_config: {
          entry_point: ["/app/bootstrap"],
          command: ["handler.main"],
          working_directory: "/app"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "container_function")
    
    expect(function_config["package_type"]).to eq("Image")
    expect(function_config["image_uri"]).to eq("123456789012.dkr.ecr.us-east-1.amazonaws.com/ml-processor:v2.0")
    expect(function_config["timeout"]).to eq(900)
    expect(function_config["memory_size"]).to eq(3008)
    expect(function_config).not_to have_key("handler")
    expect(function_config).not_to have_key("runtime")
    expect(function_config).not_to have_key("filename")
    
    # Check image config
    image_config = function_config["image_config"]
    expect(image_config).not_to be_nil
    expect(image_config["entry_point"]).to eq(["/app/bootstrap"])
    expect(image_config["command"]).to eq(["handler.main"])
    expect(image_config["working_directory"]).to eq("/app")
  end

  # Test VPC configuration synthesis
  it "synthesizes VPC lambda function correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:vpc_function, {
        function_name: "database-processor",
        role: vpc_execution_role_arn,
        handler: "db.process",
        runtime: "python3.11",
        filename: "db-function.zip",
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"],
          security_group_ids: ["sg-lambda", "sg-database"]
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "vpc_function")
    
    vpc_config = function_config["vpc_config"]
    expect(vpc_config).not_to be_nil
    expect(vpc_config["subnet_ids"]).to eq(["subnet-12345", "subnet-67890"])
    expect(vpc_config["security_group_ids"]).to eq(["sg-lambda", "sg-database"])
  end

  # Test environment variables synthesis
  it "synthesizes environment variables correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:env_function, {
        function_name: "config-processor",
        role: execution_role_arn,
        handler: "config.handler",
        runtime: "python3.11",
        filename: "config.zip",
        environment: {
          variables: {
            "NODE_ENV" => "production",
            "API_BASE_URL" => "https://api.example.com",
            "TIMEOUT_SECONDS" => "60",
            "DEBUG_MODE" => "false"
          }
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "env_function")
    
    env_config = function_config["environment"]
    expect(env_config).not_to be_nil
    variables = env_config["variables"]
    expect(variables["NODE_ENV"]).to eq("production")
    expect(variables["API_BASE_URL"]).to eq("https://api.example.com")
    expect(variables["TIMEOUT_SECONDS"]).to eq("60")
    expect(variables["DEBUG_MODE"]).to eq("false")
  end

  # Test dead letter queue synthesis
  it "synthesizes dead letter queue configuration correctly" do
    dlq_arn = "arn:aws:sqs:us-east-1:123456789012:lambda-dlq"
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:dlq_function, {
        function_name: "event-processor",
        role: execution_role_arn,
        handler: "events.process",
        runtime: "python3.11",
        filename: "events.zip",
        dead_letter_config: {
          target_arn: dlq_arn
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "dlq_function")
    
    dlq_config = function_config["dead_letter_config"]
    expect(dlq_config).not_to be_nil
    expect(dlq_config["target_arn"]).to eq(dlq_arn)
  end

  # Test EFS file system synthesis
  it "synthesizes EFS file system configuration correctly" do
    efs_arn = "arn:aws:elasticfilesystem:us-east-1:123456789012:file-system/fs-12345"
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:efs_function, {
        function_name: "file-processor",
        role: vpc_execution_role_arn,
        handler: "files.process",
        runtime: "python3.11",
        filename: "files.zip",
        file_system_config: [{
          arn: efs_arn,
          local_mount_path: "/mnt/storage"
        }]
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "efs_function")
    
    fs_configs = function_config["file_system_config"]
    expect(fs_configs).to be_an(Array)
    expect(fs_configs.first["arn"]).to eq(efs_arn)
    expect(fs_configs.first["local_mount_path"]).to eq("/mnt/storage")
  end

  # Test layers synthesis
  it "synthesizes lambda layers correctly" do
    layer_arns = [
      "arn:aws:lambda:us-east-1:123456789012:layer:shared-utils:3",
      "arn:aws:lambda:us-east-1:123456789012:layer:database-lib:1"
    ]
    
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:layered_function, {
        function_name: "layered-app",
        role: execution_role_arn,
        handler: "app.handler",
        runtime: "python3.11",
        filename: "app.zip",
        layers: layer_arns
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "layered_function")
    
    expect(function_config["layers"]).to eq(layer_arns)
  end

  # Test X-Ray tracing synthesis
  it "synthesizes X-Ray tracing configuration correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:traced_function, {
        function_name: "traced-api",
        role: execution_role_arn,
        handler: "api.handler",
        runtime: "python3.11",
        filename: "api.zip",
        tracing_config: {
          mode: "Active"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "traced_function")
    
    tracing_config = function_config["tracing_config"]
    expect(tracing_config).not_to be_nil
    expect(tracing_config["mode"]).to eq("Active")
  end

  # Test reserved concurrent executions synthesis
  it "synthesizes reserved concurrent executions correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:limited_function, {
        function_name: "rate-limited-processor",
        role: execution_role_arn,
        handler: "processor.handler",
        runtime: "python3.11",
        filename: "processor.zip",
        reserved_concurrent_executions: 100
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "limited_function")
    
    expect(function_config["reserved_concurrent_executions"]).to eq(100)
  end

  # Test ARM64 architecture synthesis
  it "synthesizes ARM64 architecture correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:arm_function, {
        function_name: "arm-optimized",
        role: execution_role_arn,
        handler: "bootstrap",
        runtime: "provided.al2",
        filename: "arm-function.zip",
        architectures: ["arm64"]
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "arm_function")
    
    expect(function_config["architectures"]).to eq(["arm64"])
  end

  # Test Java function with snap start synthesis
  it "synthesizes Java function with snap start correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:java_function, {
        function_name: "java-processor",
        role: execution_role_arn,
        handler: "com.example.ProcessorHandler::handleRequest",
        runtime: "java17",
        filename: "processor.jar",
        timeout: 60,
        memory_size: 1024,
        snap_start: {
          apply_on: "PublishedVersions"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "java_function")
    
    expect(function_config["handler"]).to eq("com.example.ProcessorHandler::handleRequest")
    expect(function_config["runtime"]).to eq("java17")
    
    snap_start_config = function_config["snap_start"]
    expect(snap_start_config).not_to be_nil
    expect(snap_start_config["apply_on"]).to eq("PublishedVersions")
  end

  # Test ephemeral storage synthesis
  it "synthesizes ephemeral storage correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:storage_function, {
        function_name: "large-storage-processor",
        role: execution_role_arn,
        handler: "storage.handler",
        runtime: "python3.11",
        filename: "storage.zip",
        ephemeral_storage: {
          size: 5120
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "storage_function")
    
    ephemeral_config = function_config["ephemeral_storage"]
    expect(ephemeral_config).not_to be_nil
    expect(ephemeral_config["size"]).to eq(5120)
  end

  # Test KMS encryption synthesis
  it "synthesizes KMS encryption correctly" do
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:encrypted_function, {
        function_name: "encrypted-processor",
        role: execution_role_arn,
        handler: "secure.handler",
        runtime: "python3.11",
        filename: "secure.zip",
        kms_key_arn: kms_key_arn,
        environment: {
          variables: {
            "SECRET_KEY" => "encrypted-value"
          }
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "encrypted_function")
    
    expect(function_config["kms_key_arn"]).to eq(kms_key_arn)
    
    env_config = function_config["environment"]
    expect(env_config["variables"]["SECRET_KEY"]).to eq("encrypted-value")
  end

  # Test logging configuration synthesis
  it "synthesizes logging configuration correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:logging_function, {
        function_name: "structured-logging",
        role: execution_role_arn,
        handler: "log.handler",
        runtime: "python3.11",
        filename: "logging.zip",
        logging_config: {
          log_format: "JSON",
          log_group: "/aws/lambda/structured-logging",
          system_log_level: "INFO",
          application_log_level: "DEBUG"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "logging_function")
    
    logging_config = function_config["logging_config"]
    expect(logging_config).not_to be_nil
    expect(logging_config["log_format"]).to eq("JSON")
    expect(logging_config["log_group"]).to eq("/aws/lambda/structured-logging")
    expect(logging_config["system_log_level"]).to eq("INFO")
    expect(logging_config["application_log_level"]).to eq("DEBUG")
  end

  # Test comprehensive configuration synthesis
  it "synthesizes comprehensive lambda configuration correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:comprehensive_function, {
        function_name: "comprehensive-processor",
        role: vpc_execution_role_arn,
        handler: "comprehensive.handler",
        runtime: "python3.11",
        filename: "comprehensive.zip",
        description: "Comprehensive lambda with all features",
        timeout: 300,
        memory_size: 2048,
        publish: true,
        reserved_concurrent_executions: 50,
        layers: ["arn:aws:lambda:us-east-1:123456789012:layer:utils:1"],
        vpc_config: {
          subnet_ids: ["subnet-private1", "subnet-private2"],
          security_group_ids: ["sg-lambda"]
        },
        environment: {
          variables: {
            "ENVIRONMENT" => "production",
            "LOG_LEVEL" => "INFO"
          }
        },
        dead_letter_config: {
          target_arn: "arn:aws:sqs:us-east-1:123456789012:lambda-dlq"
        },
        tracing_config: {
          mode: "Active"
        },
        tags: {
          Environment: "production",
          Service: "data-processing",
          Team: "platform"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "comprehensive_function")
    
    expect(function_config["function_name"]).to eq("comprehensive-processor")
    expect(function_config["description"]).to eq("Comprehensive lambda with all features")
    expect(function_config["timeout"]).to eq(300)
    expect(function_config["memory_size"]).to eq(2048)
    expect(function_config["publish"]).to eq(true)
    expect(function_config["reserved_concurrent_executions"]).to eq(50)
    expect(function_config["layers"]).to eq(["arn:aws:lambda:us-east-1:123456789012:layer:utils:1"])
    
    # Check VPC configuration
    vpc_config = function_config["vpc_config"]
    expect(vpc_config["subnet_ids"]).to eq(["subnet-private1", "subnet-private2"])
    expect(vpc_config["security_group_ids"]).to eq(["sg-lambda"])
    
    # Check environment variables
    env_config = function_config["environment"]
    expect(env_config["variables"]["ENVIRONMENT"]).to eq("production")
    expect(env_config["variables"]["LOG_LEVEL"]).to eq("INFO")
    
    # Check dead letter queue
    dlq_config = function_config["dead_letter_config"]
    expect(dlq_config["target_arn"]).to eq("arn:aws:sqs:us-east-1:123456789012:lambda-dlq")
    
    # Check tracing
    tracing_config = function_config["tracing_config"]
    expect(tracing_config["mode"]).to eq("Active")
    
    # Check tags
    tags_config = function_config["tags"]
    expect(tags_config["Environment"]).to eq("production")
    expect(tags_config["Service"]).to eq("data-processing")
    expect(tags_config["Team"]).to eq("platform")
  end

  # Test minimal configuration synthesis (optional fields excluded)
  it "synthesizes minimal lambda without optional fields" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:minimal_function, {
        function_name: "minimal-function",
        role: execution_role_arn,
        handler: "index.handler",
        runtime: "nodejs18.x",
        filename: "function.zip"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "minimal_function")
    
    # Required fields should be present
    expect(function_config["function_name"]).to eq("minimal-function")
    expect(function_config["role"]).to eq(execution_role_arn)
    expect(function_config["handler"]).to eq("index.handler")
    expect(function_config["runtime"]).to eq("nodejs18.x")
    expect(function_config["filename"]).to eq("function.zip")
    expect(function_config["timeout"]).to eq(3)
    expect(function_config["memory_size"]).to eq(128)
    expect(function_config["publish"]).to eq(false)
    expect(function_config["architectures"]).to eq(["x86_64"])
    
    # Optional fields should not be present when not specified
    expect(function_config).not_to have_key("description")
    expect(function_config).not_to have_key("reserved_concurrent_executions")
    expect(function_config).not_to have_key("layers")
    expect(function_config).not_to have_key("vpc_config")
    expect(function_config).not_to have_key("environment")
    expect(function_config).not_to have_key("dead_letter_config")
    expect(function_config).not_to have_key("file_system_config")
    expect(function_config).not_to have_key("tracing_config")
    expect(function_config).not_to have_key("kms_key_arn")
    expect(function_config).not_to have_key("ephemeral_storage")
    expect(function_config).not_to have_key("snap_start")
    expect(function_config).not_to have_key("logging_config")
    expect(function_config).not_to have_key("code_signing_config_arn")
  end

  # Test code signing synthesis
  it "synthesizes code signing configuration correctly" do
    signing_arn = "arn:aws:signer:us-east-1:123456789012:/signing-profiles/MyProfile"
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:signed_function, {
        function_name: "signed-processor",
        role: execution_role_arn,
        handler: "secure.handler",
        runtime: "python3.11",
        filename: "secure.zip",
        code_signing_config_arn: signing_arn
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "signed_function")
    
    expect(function_config["code_signing_config_arn"]).to eq(signing_arn)
  end

  # Test Python runtime patterns
  it "synthesizes Python runtime patterns correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:python_function, {
        function_name: "data-analyzer",
        role: execution_role_arn,
        handler: "analyzer.process_data",
        runtime: "python3.11",
        filename: "analyzer.zip",
        timeout: 180,
        memory_size: 1024,
        layers: ["arn:aws:lambda:us-east-1:123456789012:layer:pandas:1"]
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "python_function")
    
    expect(function_config["handler"]).to eq("analyzer.process_data")
    expect(function_config["runtime"]).to eq("python3.11")
    expect(function_config["timeout"]).to eq(180)
    expect(function_config["memory_size"]).to eq(1024)
  end

  # Test Go runtime patterns
  it "synthesizes Go runtime patterns correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:go_function, {
        function_name: "go-processor",
        role: execution_role_arn,
        handler: "main",
        runtime: "go1.x",
        filename: "main.zip",
        architectures: ["arm64"]
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "go_function")
    
    expect(function_config["handler"]).to eq("main")
    expect(function_config["runtime"]).to eq("go1.x")
    expect(function_config["architectures"]).to eq(["arm64"])
  end

  # Test .NET runtime patterns
  it "synthesizes .NET runtime patterns correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:dotnet_function, {
        function_name: "dotnet-api",
        role: execution_role_arn,
        handler: "DotNetApi::DotNetApi.Functions.ApiFunction::FunctionHandler",
        runtime: "dotnet8",
        filename: "dotnet-api.zip",
        timeout: 60,
        memory_size: 512
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "dotnet_function")
    
    expect(function_config["handler"]).to eq("DotNetApi::DotNetApi.Functions.ApiFunction::FunctionHandler")
    expect(function_config["runtime"]).to eq("dotnet8")
  end

  # Test Ruby runtime patterns  
  it "synthesizes Ruby runtime patterns correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_function(:ruby_function, {
        function_name: "ruby-processor",
        role: execution_role_arn,
        handler: "lambda_function.lambda_handler",
        runtime: "ruby3.2",
        filename: "ruby-function.zip"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    function_config = json_output.dig("resource", "aws_lambda_function", "ruby_function")
    
    expect(function_config["handler"]).to eq("lambda_function.lambda_handler")
    expect(function_config["runtime"]).to eq("ruby3.2")
  end
end