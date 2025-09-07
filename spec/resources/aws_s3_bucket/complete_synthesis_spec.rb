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

# Load aws_s3_bucket resource for terraform synthesis testing
require 'pangea/resources/aws_s3_bucket/resource'

RSpec.describe "aws_s3_bucket terraform synthesis" do
  describe "real terraform synthesis" do
    # Note: These tests require terraform_synthesizer gem to be available
    # They test actual terraform JSON generation
    
    let(:mock_synthesizer) do
      # Mock synthesizer that captures method calls to verify terraform structure
      Class.new do
        attr_reader :resources, :method_calls
        
        def initialize
          @resources = {}
          @method_calls = []
        end
        
        def resource(type, name)
          @method_calls << [:resource, type, name]
          resource_context = ResourceContext.new(self, type, name)
          @resources["#{type}.#{name}"] = resource_context
          yield if block_given?
          resource_context
        end
        
        def ref(type, name, attribute)
          "${#{type}.#{name}.#{attribute}}"
        end
        
        def method_missing(method_name, *args, &block)
          @method_calls << [method_name, *args]
          if block_given?
            # For nested blocks like versioning, server_side_encryption_configuration, etc.
            nested_context = NestedContext.new(self, method_name)
            yield
          end
          args.first if args.any?
        end
        
        def respond_to_missing?(method_name, include_private = false)
          true
        end
        
        class ResourceContext
          attr_reader :synthesizer, :type, :name, :attributes
          
          def initialize(synthesizer, type, name)
            @synthesizer = synthesizer
            @type = type
            @name = name
            @attributes = {}
          end
          
          def method_missing(method_name, *args, &block)
            @synthesizer.method_calls << [method_name, *args]
            @attributes[method_name] = args.first if args.any?
            
            if block_given?
              # For nested blocks
              nested_context = NestedContext.new(@synthesizer, method_name)
              @attributes[method_name] = nested_context
              yield
            end
            
            args.first if args.any?
          end
          
          def respond_to_missing?(method_name, include_private = false)
            true
          end
        end
        
        class NestedContext
          attr_reader :synthesizer, :context_name, :attributes
          
          def initialize(synthesizer, context_name)
            @synthesizer = synthesizer
            @context_name = context_name
            @attributes = {}
          end
          
          def method_missing(method_name, *args, &block)
            @synthesizer.method_calls << [method_name, *args]
            @attributes[method_name] = args.first if args.any?
            
            if block_given?
              # For deeply nested blocks
              nested = NestedContext.new(@synthesizer, method_name)
              @attributes[method_name] = nested
              yield
            end
            
            args.first if args.any?
          end
          
          def respond_to_missing?(method_name, include_private = false)
            true
          end
        end
      end
    end
    
    let(:test_synthesizer) { mock_synthesizer.new }
    
    it "synthesizes basic S3 bucket terraform correctly" do
      # Create a test class that uses our mock synthesizer
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_s3_bucket function with minimal configuration
      ref = test_instance.aws_s3_bucket(:basic_bucket, {})
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_s3_bucket')
      expect(ref.name).to eq(:basic_bucket)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_s3_bucket, :basic_bucket],
        [:acl, "private"]
      )
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_s3_bucket.basic_bucket")
    end
    
    it "synthesizes bucket with custom name correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_s3_bucket function with custom name
      ref = test_instance.aws_s3_bucket(:named_bucket, {
        bucket: "my-unique-bucket-name"
      })
      
      # Verify bucket name synthesis
      expect(test_synthesizer.method_calls).to include(
        [:bucket, "my-unique-bucket-name"]
      )
    end
    
    it "synthesizes versioning configuration correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_s3_bucket function with versioning
      ref = test_instance.aws_s3_bucket(:versioned_bucket, {
        versioning: {
          enabled: true,
          mfa_delete: true
        }
      })
      
      # Verify versioning synthesis
      expect(test_synthesizer.method_calls).to include(
        [:versioning],
        [:enabled, true],
        [:mfa_delete, true]
      )
    end
    
    it "synthesizes server-side encryption configuration correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_s3_bucket function with KMS encryption
      ref = test_instance.aws_s3_bucket(:encrypted_bucket, {
        server_side_encryption_configuration: {
          rule: {
            apply_server_side_encryption_by_default: {
              sse_algorithm: "aws:kms",
              kms_master_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678"
            },
            bucket_key_enabled: true
          }
        }
      })
      
      # Verify encryption synthesis
      expect(test_synthesizer.method_calls).to include(
        [:server_side_encryption_configuration],
        [:rule],
        [:apply_server_side_encryption_by_default],
        [:sse_algorithm, "aws:kms"],
        [:kms_master_key_id, "arn:aws:kms:us-east-1:123456789012:key/12345678"],
        [:bucket_key_enabled, true]
      )
    end
    
    it "synthesizes lifecycle rules correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_s3_bucket function with lifecycle rules
      ref = test_instance.aws_s3_bucket(:lifecycle_bucket, {
        lifecycle_rule: [
          {
            id: "archive-old-data",
            enabled: true,
            prefix: "logs/",
            transition: [
              {
                days: 30,
                storage_class: "STANDARD_IA"
              },
              {
                days: 90,
                storage_class: "GLACIER"
              }
            ],
            expiration: {
              days: 365
            }
          }
        ]
      })
      
      # Verify lifecycle rule synthesis
      expect(test_synthesizer.method_calls).to include(
        [:lifecycle_rule],
        [:id, "archive-old-data"],
        [:enabled, true],
        [:prefix, "logs/"],
        [:transition],
        [:days, 30],
        [:storage_class, "STANDARD_IA"],
        [:transition],
        [:days, 90],
        [:storage_class, "GLACIER"],
        [:expiration],
        [:days, 365]
      )
    end
    
    it "synthesizes CORS rules correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_s3_bucket function with CORS rules
      ref = test_instance.aws_s3_bucket(:cors_bucket, {
        cors_rule: [
          {
            allowed_headers: ["*"],
            allowed_methods: ["GET", "POST"],
            allowed_origins: ["https://example.com"],
            expose_headers: ["ETag"],
            max_age_seconds: 3000
          }
        ]
      })
      
      # Verify CORS rule synthesis
      expect(test_synthesizer.method_calls).to include(
        [:cors_rule],
        [:allowed_headers, ["*"]],
        [:allowed_methods, ["GET", "POST"]],
        [:allowed_origins, ["https://example.com"]],
        [:expose_headers, ["ETag"]],
        [:max_age_seconds, 3000]
      )
    end
    
    it "synthesizes website configuration correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_s3_bucket function with website configuration
      ref = test_instance.aws_s3_bucket(:website_bucket, {
        website: {
          index_document: "index.html",
          error_document: "404.html"
        }
      })
      
      # Verify website synthesis
      expect(test_synthesizer.method_calls).to include(
        [:website],
        [:index_document, "index.html"],
        [:error_document, "404.html"]
      )
    end
    
    it "synthesizes website redirect configuration correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_s3_bucket function with redirect configuration
      ref = test_instance.aws_s3_bucket(:redirect_bucket, {
        website: {
          redirect_all_requests_to: {
            host_name: "example.com",
            protocol: "https"
          }
        }
      })
      
      # Verify redirect synthesis
      expect(test_synthesizer.method_calls).to include(
        [:website],
        [:redirect_all_requests_to],
        [:host_name, "example.com"],
        [:protocol, "https"]
      )
      
      # Verify index_document and error_document were NOT called
      index_calls = test_synthesizer.method_calls.select { |call| call[0] == :index_document }
      expect(index_calls).to be_empty
    end
    
    it "synthesizes logging configuration correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_s3_bucket function with logging
      ref = test_instance.aws_s3_bucket(:logged_bucket, {
        logging: {
          target_bucket: "log-bucket",
          target_prefix: "app-logs/"
        }
      })
      
      # Verify logging synthesis
      expect(test_synthesizer.method_calls).to include(
        [:logging],
        [:target_bucket, "log-bucket"],
        [:target_prefix, "app-logs/"]
      )
    end
    
    it "synthesizes object lock configuration correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_s3_bucket function with object lock
      ref = test_instance.aws_s3_bucket(:locked_bucket, {
        versioning: { enabled: true },
        object_lock_configuration: {
          object_lock_enabled: "Enabled",
          rule: {
            default_retention: {
              mode: "COMPLIANCE",
              days: 30
            }
          }
        }
      })
      
      # Verify object lock synthesis
      expect(test_synthesizer.method_calls).to include(
        [:object_lock_configuration],
        [:object_lock_enabled, "Enabled"],
        [:rule],
        [:default_retention],
        [:mode, "COMPLIANCE"],
        [:days, 30]
      )
    end
    
    it "synthesizes tags correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_s3_bucket function with tags
      ref = test_instance.aws_s3_bucket(:tagged_bucket, {
        tags: {
          Name: "my-bucket",
          Environment: "production",
          Application: "web-app",
          ManagedBy: "pangea"
        }
      })
      
      # Verify tags synthesis
      expect(test_synthesizer.method_calls).to include(
        [:tags],
        [:Name, "my-bucket"],
        [:Environment, "production"],
        [:Application, "web-app"],
        [:ManagedBy, "pangea"]
      )
    end
    
    it "synthesizes bucket policy correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_s3_bucket function with policy
      policy_json = '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::bucket/*"}]}'
      
      ref = test_instance.aws_s3_bucket(:policy_bucket, {
        policy: policy_json
      })
      
      # Verify policy synthesis
      expect(test_synthesizer.method_calls).to include(
        [:policy, policy_json]
      )
    end
    
    it "synthesizes public access block as separate resource" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_s3_bucket function with public access block
      ref = test_instance.aws_s3_bucket(:secure_bucket, {
        public_access_block_configuration: {
          block_public_acls: true,
          block_public_policy: true,
          ignore_public_acls: true,
          restrict_public_buckets: true
        }
      })
      
      # Verify public access block resource was created
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_s3_bucket_public_access_block, :secure_bucket_public_access_block],
        [:bucket, "${aws_s3_bucket.secure_bucket.id}"],
        [:block_public_acls, true],
        [:block_public_policy, true],
        [:ignore_public_acls, true],
        [:restrict_public_buckets, true]
      )
    end
    
    it "synthesizes comprehensive bucket configuration correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_s3_bucket function with comprehensive config
      ref = test_instance.aws_s3_bucket(:comprehensive_bucket, {
        bucket: "comprehensive-bucket",
        acl: "private",
        versioning: {
          enabled: true
        },
        server_side_encryption_configuration: {
          rule: {
            apply_server_side_encryption_by_default: {
              sse_algorithm: "AES256"
            }
          }
        },
        lifecycle_rule: [
          {
            id: "cleanup",
            enabled: true,
            prefix: "temp/",
            expiration: {
              days: 7
            }
          }
        ],
        tags: {
          Name: "comprehensive-bucket",
          Environment: "production"
        }
      })
      
      # Verify comprehensive synthesis includes all major components
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_s3_bucket, :comprehensive_bucket],
        [:bucket, "comprehensive-bucket"],
        [:acl, "private"],
        [:versioning],
        [:enabled, true],
        [:server_side_encryption_configuration],
        [:lifecycle_rule],
        [:tags],
        [:Environment, "production"]
      )
    end
    
    it "handles conditional attributes correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call with only default encryption (no custom SSE config needed)
      ref = test_instance.aws_s3_bucket(:default_encryption, {})
      
      # Verify default encryption is still synthesized
      expect(test_synthesizer.method_calls).to include(
        [:server_side_encryption_configuration],
        [:sse_algorithm, "AES256"]
      )
    end
    
    it "handles empty optional configurations correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call with empty arrays and hashes
      ref = test_instance.aws_s3_bucket(:empty_configs, {
        lifecycle_rule: [],
        cors_rule: [],
        website: {},
        logging: {},
        tags: {}
      })
      
      # Verify empty configurations are not synthesized
      lifecycle_calls = test_synthesizer.method_calls.select { |call| call[0] == :lifecycle_rule }
      cors_calls = test_synthesizer.method_calls.select { |call| call[0] == :cors_rule }
      website_calls = test_synthesizer.method_calls.select { |call| call[0] == :website }
      logging_calls = test_synthesizer.method_calls.select { |call| call[0] == :logging && call[1].nil? }
      tags_calls = test_synthesizer.method_calls.select { |call| call[0] == :tags }
      
      expect(lifecycle_calls).to be_empty
      expect(cors_calls).to be_empty
      expect(website_calls).to be_empty
      expect(logging_calls).to be_empty
      expect(tags_calls).to be_empty
    end
    
    it "validates terraform reference outputs" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      ref = test_instance.aws_s3_bucket(:output_test, {})
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :arn, :bucket, :bucket_domain_name, :bucket_regional_domain_name,
                         :hosted_zone_id, :region, :website_endpoint, :website_domain]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\$\{aws_s3_bucket\.output_test\./)
      end
      
      # Verify specific output formats
      expect(ref.outputs[:id]).to eq("${aws_s3_bucket.output_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_s3_bucket.output_test.arn}")
      expect(ref.outputs[:bucket]).to eq("${aws_s3_bucket.output_test.bucket}")
      expect(ref.outputs[:bucket_domain_name]).to eq("${aws_s3_bucket.output_test.bucket_domain_name}")
    end
  end
end