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

# Load aws_lambda_function resource and types for testing
require 'pangea/resources/aws_lambda_function/resource'
require 'pangea/resources/aws_lambda_function/types'

RSpec.describe "aws_lambda_function resource function" do
  # Create a test class that includes the AWS module and mocks terraform-synthesizer
  let(:test_class) do
    Class.new do
      include Pangea::Resources::AWS
      
      # Mock the terraform-synthesizer resource method
      def resource(type, name)
        @resources ||= {}
        resource_data = { type: type, name: name, attributes: {} }
        
        yield if block_given?
        
        @resources["#{type}.#{name}"] = resource_data
        resource_data
      end
      
      # Method missing to capture terraform attributes
      def method_missing(method_name, *args, &block)
        # Don't capture certain methods that might interfere
        return super if [:expect, :be_a, :eq].include?(method_name)
        # For terraform-synthesizer attribute calls, just return the value
        args.first if args.any?
      end
      
      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end
  end
  
  let(:test_instance) { test_class.new }
  let(:execution_role_arn) { "arn:aws:iam::123456789012:role/lambda-execution-role" }
  let(:vpc_execution_role_arn) { "arn:aws:iam::123456789012:role/lambda-vpc-execution-role" }
  
  describe "LambdaFunctionAttributes validation" do
    it "accepts basic lambda function configuration" do
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "test-function",
        role: execution_role_arn,
        handler: "index.handler",
        runtime: "nodejs18.x",
        filename: "function.zip"
      })
      
      expect(attrs.function_name).to eq("test-function")
      expect(attrs.role).to eq(execution_role_arn)
      expect(attrs.handler).to eq("index.handler")
      expect(attrs.runtime).to eq("nodejs18.x")
      expect(attrs.filename).to eq("function.zip")
      expect(attrs.package_type).to eq("Zip")
      expect(attrs.timeout).to eq(3)
      expect(attrs.memory_size).to eq(128)
      expect(attrs.publish).to eq(false)
    end
    
    it "accepts S3 code source configuration" do
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "s3-function",
        role: execution_role_arn,
        handler: "app.handler",
        runtime: "python3.11",
        s3_bucket: "my-deployments",
        s3_key: "lambda/function.zip",
        s3_object_version: "abc123"
      })
      
      expect(attrs.s3_bucket).to eq("my-deployments")
      expect(attrs.s3_key).to eq("lambda/function.zip")
      expect(attrs.s3_object_version).to eq("abc123")
      expect(attrs.filename).to be_nil
    end
    
    it "accepts container image configuration" do
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "container-function",
        role: execution_role_arn,
        package_type: "Image",
        image_uri: "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-function:latest"
      })
      
      expect(attrs.package_type).to eq("Image")
      expect(attrs.image_uri).to eq("123456789012.dkr.ecr.us-east-1.amazonaws.com/my-function:latest")
      expect(attrs.is_container_based?).to eq(true)
    end
    
    it "accepts VPC configuration" do
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "vpc-function",
        role: vpc_execution_role_arn,
        handler: "lambda.handler",
        runtime: "python3.11",
        filename: "function.zip",
        vpc_config: {
          subnet_ids: ["subnet-12345", "subnet-67890"],
          security_group_ids: ["sg-abcdef"]
        }
      })
      
      expect(attrs.vpc_config).not_to be_nil
      expect(attrs.vpc_config[:subnet_ids]).to eq(["subnet-12345", "subnet-67890"])
      expect(attrs.vpc_config[:security_group_ids]).to eq(["sg-abcdef"])
      expect(attrs.requires_vpc?).to eq(true)
    end
    
    it "accepts environment variables configuration" do
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "env-function",
        role: execution_role_arn,
        handler: "app.handler",
        runtime: "nodejs18.x",
        filename: "function.zip",
        environment: {
          variables: {
            "NODE_ENV" => "production",
            "API_KEY" => "secret-key",
            "TIMEOUT_SECONDS" => "30"
          }
        }
      })
      
      expect(attrs.environment).not_to be_nil
      expect(attrs.environment[:variables]).to include("NODE_ENV" => "production")
      expect(attrs.environment[:variables]).to include("API_KEY" => "secret-key")
      expect(attrs.environment[:variables]).to include("TIMEOUT_SECONDS" => "30")
    end
    
    it "accepts dead letter queue configuration" do
      dlq_arn = "arn:aws:sqs:us-east-1:123456789012:lambda-dlq"
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "dlq-function",
        role: execution_role_arn,
        handler: "index.handler",
        runtime: "nodejs18.x",
        filename: "function.zip",
        dead_letter_config: {
          target_arn: dlq_arn
        }
      })
      
      expect(attrs.dead_letter_config).not_to be_nil
      expect(attrs.dead_letter_config[:target_arn]).to eq(dlq_arn)
      expect(attrs.has_dlq?).to eq(true)
    end
    
    it "accepts EFS file system configuration" do
      efs_arn = "arn:aws:elasticfilesystem:us-east-1:123456789012:file-system/fs-12345"
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "efs-function",
        role: vpc_execution_role_arn,
        handler: "app.handler",
        runtime: "python3.11",
        filename: "function.zip",
        file_system_config: [{
          arn: efs_arn,
          local_mount_path: "/mnt/data"
        }]
      })
      
      expect(attrs.file_system_config).not_to be_empty
      expect(attrs.file_system_config.first[:arn]).to eq(efs_arn)
      expect(attrs.file_system_config.first[:local_mount_path]).to eq("/mnt/data")
      expect(attrs.uses_efs?).to eq(true)
    end
    
    it "accepts memory size configuration with validation" do
      # Test valid memory sizes
      [128, 256, 512, 1024, 3008, 10240].each do |memory_size|
        attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "memory-function",
          role: execution_role_arn,
          handler: "index.handler",
          runtime: "nodejs18.x",
          filename: "function.zip",
          memory_size: memory_size
        })
        
        expect(attrs.memory_size).to eq(memory_size)
      end
    end
    
    it "accepts timeout configuration with validation" do
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "timeout-function",
        role: execution_role_arn,
        handler: "index.handler",
        runtime: "nodejs18.x",
        filename: "function.zip",
        timeout: 300
      })
      
      expect(attrs.timeout).to eq(300)
    end
    
    it "accepts layers configuration" do
      layer_arns = [
        "arn:aws:lambda:us-east-1:123456789012:layer:my-layer:1",
        "arn:aws:lambda:us-east-1:123456789012:layer:another-layer:2"
      ]
      
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "layered-function",
        role: execution_role_arn,
        handler: "app.handler",
        runtime: "python3.11",
        filename: "function.zip",
        layers: layer_arns
      })
      
      expect(attrs.layers).to eq(layer_arns)
    end
    
    it "accepts reserved concurrent executions configuration" do
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "reserved-function",
        role: execution_role_arn,
        handler: "index.handler",
        runtime: "nodejs18.x",
        filename: "function.zip",
        reserved_concurrent_executions: 50
      })
      
      expect(attrs.reserved_concurrent_executions).to eq(50)
    end
    
    it "accepts ARM64 architecture" do
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "arm-function",
        role: execution_role_arn,
        handler: "bootstrap",
        runtime: "provided.al2",
        filename: "function.zip",
        architectures: ["arm64"]
      })
      
      expect(attrs.architectures).to eq(["arm64"])
      expect(attrs.architecture).to eq("arm64")
    end
    
    it "accepts tracing configuration" do
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "traced-function",
        role: execution_role_arn,
        handler: "index.handler",
        runtime: "nodejs18.x",
        filename: "function.zip",
        tracing_config: {
          mode: "Active"
        }
      })
      
      expect(attrs.tracing_config).not_to be_nil
      expect(attrs.tracing_config[:mode]).to eq("Active")
    end
    
    it "accepts ephemeral storage configuration" do
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "storage-function",
        role: execution_role_arn,
        handler: "app.handler",
        runtime: "python3.11",
        filename: "function.zip",
        ephemeral_storage: {
          size: 2048
        }
      })
      
      expect(attrs.ephemeral_storage).not_to be_nil
      expect(attrs.ephemeral_storage[:size]).to eq(2048)
    end
    
    it "accepts snap start configuration for Java" do
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "java-function",
        role: execution_role_arn,
        handler: "com.example.Handler::handleRequest",
        runtime: "java17",
        filename: "function.jar",
        snap_start: {
          apply_on: "PublishedVersions"
        }
      })
      
      expect(attrs.snap_start).not_to be_nil
      expect(attrs.snap_start[:apply_on]).to eq("PublishedVersions")
      expect(attrs.supports_snap_start?).to eq(true)
    end
    
    it "accepts image configuration for container functions" do
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "image-function",
        role: execution_role_arn,
        package_type: "Image",
        image_uri: "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-function:latest",
        image_config: {
          entry_point: ["/app/bootstrap"],
          command: ["handler.main"],
          working_directory: "/app"
        }
      })
      
      expect(attrs.image_config).not_to be_nil
      expect(attrs.image_config[:entry_point]).to eq(["/app/bootstrap"])
      expect(attrs.image_config[:command]).to eq(["handler.main"])
      expect(attrs.image_config[:working_directory]).to eq("/app")
    end
    
    it "accepts logging configuration" do
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "logging-function",
        role: execution_role_arn,
        handler: "index.handler",
        runtime: "nodejs18.x",
        filename: "function.zip",
        logging_config: {
          log_format: "JSON",
          log_group: "/aws/lambda/my-function",
          system_log_level: "INFO",
          application_log_level: "DEBUG"
        }
      })
      
      expect(attrs.logging_config).not_to be_nil
      expect(attrs.logging_config[:log_format]).to eq("JSON")
      expect(attrs.logging_config[:log_group]).to eq("/aws/lambda/my-function")
      expect(attrs.logging_config[:system_log_level]).to eq("INFO")
      expect(attrs.logging_config[:application_log_level]).to eq("DEBUG")
    end
    
    it "accepts KMS encryption configuration" do
      kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "encrypted-function",
        role: execution_role_arn,
        handler: "app.handler",
        runtime: "python3.11",
        filename: "function.zip",
        kms_key_arn: kms_key_arn
      })
      
      expect(attrs.kms_key_arn).to eq(kms_key_arn)
    end
    
    it "accepts code signing configuration" do
      signing_arn = "arn:aws:signer:us-east-1:123456789012:/signing-profiles/MySigningProfile"
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "signed-function",
        role: execution_role_arn,
        handler: "index.handler",
        runtime: "nodejs18.x",
        filename: "function.zip",
        code_signing_config_arn: signing_arn
      })
      
      expect(attrs.code_signing_config_arn).to eq(signing_arn)
    end
    
    it "accepts comprehensive tags configuration" do
      tags = {
        Environment: "production",
        Service: "api",
        Team: "backend",
        Version: "1.2.3"
      }
      
      attrs = Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
        function_name: "tagged-function",
        role: execution_role_arn,
        handler: "main.handler",
        runtime: "python3.11",
        filename: "function.zip",
        tags: tags
      })
      
      expect(attrs.tags).to eq(tags)
    end
    
    it "validates function name format" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "invalid function name!", # spaces and special chars
          role: execution_role_arn,
          handler: "index.handler",
          runtime: "nodejs18.x",
          filename: "function.zip"
        })
      }.to raise_error(Dry::Struct::Error, /function_name/)
    end
    
    it "validates function name length" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "a" * 65, # too long
          role: execution_role_arn,
          handler: "index.handler",
          runtime: "nodejs18.x",
          filename: "function.zip"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates timeout range" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "timeout-function",
          role: execution_role_arn,
          handler: "index.handler",
          runtime: "nodejs18.x",
          filename: "function.zip",
          timeout: 1000 # too long
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates memory size range" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "memory-function",
          role: execution_role_arn,
          handler: "index.handler",
          runtime: "nodejs18.x",
          filename: "function.zip",
          memory_size: 100 # too small
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates reserved concurrent executions range" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "concurrent-function",
          role: execution_role_arn,
          handler: "index.handler",
          runtime: "nodejs18.x",
          filename: "function.zip",
          reserved_concurrent_executions: 2000 # too high
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates architecture count" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "multi-arch-function",
          role: execution_role_arn,
          handler: "index.handler",
          runtime: "nodejs18.x",
          filename: "function.zip",
          architectures: ["x86_64", "arm64"] # multiple architectures not allowed
        })
      }.to raise_error(Dry::Struct::Error, /one architecture/)
    end
    
    it "validates container image requirements" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "image-function",
          role: execution_role_arn,
          package_type: "Image"
          # missing image_uri
        })
      }.to raise_error(Dry::Struct::Error, /image_uri is required/)
    end
    
    it "validates zip package requirements" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "zip-function",
          role: execution_role_arn,
          handler: "index.handler",
          runtime: "nodejs18.x"
          # missing filename or s3_bucket/s3_key
        })
      }.to raise_error(Dry::Struct::Error, /Either filename or s3_bucket/)
    end
    
    it "validates S3 configuration requirements" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "s3-function",
          role: execution_role_arn,
          handler: "index.handler",
          runtime: "nodejs18.x",
          s3_bucket: "my-bucket"
          # missing s3_key
        })
      }.to raise_error(Dry::Struct::Error, /s3_key is required/)
    end
    
    it "validates snap start requires Java runtime" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "snap-function",
          role: execution_role_arn,
          handler: "index.handler",
          runtime: "nodejs18.x", # not java
          filename: "function.zip",
          snap_start: {
            apply_on: "PublishedVersions"
          }
        })
      }.to raise_error(Dry::Struct::Error, /Java runtimes/)
    end
    
    it "validates handler format for Python runtime" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "python-function",
          role: execution_role_arn,
          handler: "invalid-handler-format", # should be module.function
          runtime: "python3.11",
          filename: "function.zip"
        })
      }.to raise_error(Dry::Struct::Error, /Python handler/)
    end
    
    it "validates handler format for Node.js runtime" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "node-function",
          role: execution_role_arn,
          handler: "invalid_handler_format", # should be filename.export
          runtime: "nodejs18.x",
          filename: "function.zip"
        })
      }.to raise_error(Dry::Struct::Error, /Node.js handler/)
    end
    
    it "validates handler format for Java runtime" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "java-function",
          role: execution_role_arn,
          handler: "invalid.handler.format", # should be package.Class::method
          runtime: "java17",
          filename: "function.jar"
        })
      }.to raise_error(Dry::Struct::Error, /Java handler/)
    end
    
    it "validates handler format for Go runtime" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "go-function",
          role: execution_role_arn,
          handler: "main.handler", # should just be executable name
          runtime: "go1.x",
          filename: "function.zip"
        })
      }.to raise_error(Dry::Struct::Error, /Go handler/)
    end
    
    it "validates image package excludes handler/runtime" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "image-function",
          role: execution_role_arn,
          package_type: "Image",
          image_uri: "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-function:latest",
          handler: "index.handler" # should not be specified for images
        })
      }.to raise_error(Dry::Struct::Error, /should not be specified/)
    end
    
    it "validates EFS mount path format" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "efs-function",
          role: vpc_execution_role_arn,
          handler: "app.handler",
          runtime: "python3.11",
          filename: "function.zip",
          file_system_config: [{
            arn: "arn:aws:elasticfilesystem:us-east-1:123456789012:file-system/fs-12345",
            local_mount_path: "/invalid-path" # should be /mnt/something
          }]
        })
      }.to raise_error(Dry::Struct::Error)
    end
  end
  
  describe "aws_lambda_function function" do
    it "creates basic lambda function resource reference" do
      result = test_instance.aws_lambda_function(:test_function, {
        function_name: "test-function",
        role: execution_role_arn,
        handler: "index.handler",
        runtime: "nodejs18.x",
        filename: "function.zip"
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_lambda_function')
      expect(result.name).to eq(:test_function)
    end
    
    it "returns lambda function reference with terraform outputs" do
      result = test_instance.aws_lambda_function(:api_function, {
        function_name: "api-handler",
        role: execution_role_arn,
        handler: "app.handler",
        runtime: "python3.11",
        filename: "api.zip"
      })
      
      expect(result.arn).to eq("${aws_lambda_function.api_function.arn}")
      expect(result.function_name).to eq("${aws_lambda_function.api_function.function_name}")
      expect(result.qualified_arn).to eq("${aws_lambda_function.api_function.qualified_arn}")
      expect(result.invoke_arn).to eq("${aws_lambda_function.api_function.invoke_arn}")
      expect(result.version).to eq("${aws_lambda_function.api_function.version}")
      expect(result.source_code_hash).to eq("${aws_lambda_function.api_function.source_code_hash}")
    end
    
    it "returns lambda function reference with computed properties" do
      result = test_instance.aws_lambda_function(:vpc_function, {
        function_name: "vpc-db-function",
        role: vpc_execution_role_arn,
        handler: "db.handler",
        runtime: "python3.11",
        filename: "function.zip",
        memory_size: 1024,
        vpc_config: {
          subnet_ids: ["subnet-12345"],
          security_group_ids: ["sg-abcdef"]
        },
        dead_letter_config: {
          target_arn: "arn:aws:sqs:us-east-1:123456789012:dlq"
        }
      })
      
      expect(result.requires_vpc?).to eq(true)
      expect(result.has_dlq?).to eq(true)
      expect(result.is_container_based?).to eq(false)
      expect(result.architecture).to eq("x86_64")
      expect(result.estimated_monthly_cost).to be_a(Float)
      expect(result.estimated_monthly_cost).to be > 0
    end
    
    it "returns container function reference with computed properties" do
      result = test_instance.aws_lambda_function(:container_function, {
        function_name: "ml-processor",
        role: execution_role_arn,
        package_type: "Image",
        image_uri: "123456789012.dkr.ecr.us-east-1.amazonaws.com/ml-processor:v1.0",
        memory_size: 3008,
        timeout: 900
      })
      
      expect(result.is_container_based?).to eq(true)
      expect(result.requires_vpc?).to eq(false)
      expect(result.has_dlq?).to eq(false)
      expect(result.uses_efs?).to eq(false)
    end
    
    it "returns Java function reference with snap start support" do
      result = test_instance.aws_lambda_function(:java_function, {
        function_name: "java-processor",
        role: execution_role_arn,
        handler: "com.example.Handler::handleRequest",
        runtime: "java17",
        filename: "processor.jar",
        snap_start: {
          apply_on: "PublishedVersions"
        }
      })
      
      expect(result.supports_snap_start?).to eq(true)
    end
    
    it "returns function reference with EFS support detection" do
      result = test_instance.aws_lambda_function(:efs_function, {
        function_name: "data-processor",
        role: vpc_execution_role_arn,
        handler: "process.handler",
        runtime: "python3.11",
        filename: "function.zip",
        file_system_config: [{
          arn: "arn:aws:elasticfilesystem:us-east-1:123456789012:file-system/fs-12345",
          local_mount_path: "/mnt/efs"
        }]
      })
      
      expect(result.uses_efs?).to eq(true)
    end
    
    it "calculates estimated monthly cost based on memory and execution" do
      # Test different memory sizes
      small_function = test_instance.aws_lambda_function(:small, {
        function_name: "small-function",
        role: execution_role_arn,
        handler: "index.handler",
        runtime: "nodejs18.x",
        filename: "function.zip",
        memory_size: 128
      })
      
      large_function = test_instance.aws_lambda_function(:large, {
        function_name: "large-function", 
        role: execution_role_arn,
        handler: "index.handler",
        runtime: "nodejs18.x",
        filename: "function.zip",
        memory_size: 1024
      })
      
      expect(large_function.estimated_monthly_cost).to be > small_function.estimated_monthly_cost
    end
    
    it "validates runtime enumeration" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "runtime-function",
          role: execution_role_arn,
          handler: "index.handler",
          runtime: "invalid-runtime", # not in enum
          filename: "function.zip"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates architecture enumeration" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "arch-function",
          role: execution_role_arn,
          handler: "index.handler",
          runtime: "nodejs18.x",
          filename: "function.zip",
          architectures: ["invalid-arch"] # not in enum
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates tracing mode enumeration" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "tracing-function",
          role: execution_role_arn,
          handler: "index.handler",
          runtime: "nodejs18.x",
          filename: "function.zip",
          tracing_config: {
            mode: "InvalidMode" # not in enum
          }
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates logging configuration format" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "log-function",
          role: execution_role_arn,
          handler: "index.handler",
          runtime: "nodejs18.x",
          filename: "function.zip",
          logging_config: {
            log_format: "XML", # not in enum
            application_log_level: "DEBUG"
          }
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates environment variable names" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "env-function",
          role: execution_role_arn,
          handler: "index.handler",
          runtime: "nodejs18.x",
          filename: "function.zip",
          environment: {
            variables: {
              "123_INVALID" => "value" # cannot start with number
            }
          }
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates ephemeral storage size range" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "storage-function",
          role: execution_role_arn,
          handler: "index.handler",
          runtime: "nodejs18.x",
          filename: "function.zip",
          ephemeral_storage: {
            size: 100 # too small, minimum 512MB
          }
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates dead letter queue ARN format" do
      expect {
        Pangea::Resources::AWS::Types::LambdaFunctionAttributes.new({
          function_name: "dlq-function",
          role: execution_role_arn,
          handler: "index.handler",
          runtime: "nodejs18.x",
          filename: "function.zip",
          dead_letter_config: {
            target_arn: "invalid-arn-format" # must be SQS or SNS ARN
          }
        })
      }.to raise_error(Dry::Struct::Error)
    end
  end
end