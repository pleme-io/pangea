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

# Load aws_s3_bucket resource and types for testing
require 'pangea/resources/aws_s3_bucket/resource'
require 'pangea/resources/aws_s3_bucket/types'

RSpec.describe "aws_s3_bucket resource function" do
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
      
      # Mock ref method for public access block
      def ref(type, name, attribute)
        "${#{type}.#{name}.#{attribute}}"
      end
    end
  end
  
  let(:test_instance) { test_class.new }
  
  describe "S3BucketAttributes validation" do
    it "accepts minimal configuration with defaults" do
      attrs = Pangea::Resources::AWS::S3BucketAttributes.new({})
      
      expect(attrs.acl).to eq('private')
      expect(attrs.versioning[:enabled]).to eq(false)
      expect(attrs.server_side_encryption_configuration[:rule][:apply_server_side_encryption_by_default][:sse_algorithm]).to eq('AES256')
      expect(attrs.lifecycle_rule).to eq([])
      expect(attrs.cors_rule).to eq([])
      expect(attrs.website).to eq({})
      expect(attrs.logging).to eq({})
      expect(attrs.object_lock_configuration).to eq({})
      expect(attrs.public_access_block_configuration).to eq({})
      expect(attrs.tags).to eq({})
    end
    
    it "accepts custom bucket name" do
      attrs = Pangea::Resources::AWS::S3BucketAttributes.new({
        bucket: "my-custom-bucket-name"
      })
      
      expect(attrs.bucket).to eq("my-custom-bucket-name")
    end
    
    it "accepts different ACL values" do
      acl_values = ['private', 'public-read', 'public-read-write', 'authenticated-read', 'log-delivery-write']
      
      acl_values.each do |acl|
        attrs = Pangea::Resources::AWS::S3BucketAttributes.new({ acl: acl })
        expect(attrs.acl).to eq(acl)
      end
    end
    
    it "accepts versioning configuration" do
      attrs = Pangea::Resources::AWS::S3BucketAttributes.new({
        versioning: {
          enabled: true,
          mfa_delete: true
        }
      })
      
      expect(attrs.versioning[:enabled]).to eq(true)
      expect(attrs.versioning[:mfa_delete]).to eq(true)
    end
    
    it "accepts KMS encryption configuration" do
      attrs = Pangea::Resources::AWS::S3BucketAttributes.new({
        server_side_encryption_configuration: {
          rule: {
            apply_server_side_encryption_by_default: {
              sse_algorithm: 'aws:kms',
              kms_master_key_id: 'arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012'
            },
            bucket_key_enabled: true
          }
        }
      })
      
      expect(attrs.server_side_encryption_configuration[:rule][:apply_server_side_encryption_by_default][:sse_algorithm]).to eq('aws:kms')
      expect(attrs.server_side_encryption_configuration[:rule][:apply_server_side_encryption_by_default][:kms_master_key_id]).to include('key/')
      expect(attrs.server_side_encryption_configuration[:rule][:bucket_key_enabled]).to eq(true)
    end
    
    it "validates KMS encryption requires key ID" do
      expect {
        Pangea::Resources::AWS::S3BucketAttributes.new({
          server_side_encryption_configuration: {
            rule: {
              apply_server_side_encryption_by_default: {
                sse_algorithm: 'aws:kms'
                # Missing kms_master_key_id
              }
            }
          }
        })
      }.to raise_error(Dry::Struct::Error, /kms_master_key_id is required when using aws:kms encryption/)
    end
    
    it "accepts lifecycle rules" do
      attrs = Pangea::Resources::AWS::S3BucketAttributes.new({
        lifecycle_rule: [
          {
            id: "archive-old-objects",
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
      
      expect(attrs.lifecycle_rule.size).to eq(1)
      expect(attrs.lifecycle_rule[0][:id]).to eq("archive-old-objects")
      expect(attrs.lifecycle_rule[0][:transition].size).to eq(2)
      expect(attrs.lifecycle_rule[0][:expiration][:days]).to eq(365)
    end
    
    it "validates lifecycle rules must have actions" do
      expect {
        Pangea::Resources::AWS::S3BucketAttributes.new({
          lifecycle_rule: [
            {
              id: "invalid-rule",
              enabled: true
              # No actions specified
            }
          ]
        })
      }.to raise_error(Dry::Struct::Error, /Lifecycle rule 'invalid-rule' must have at least one action/)
    end
    
    it "accepts CORS rules" do
      attrs = Pangea::Resources::AWS::S3BucketAttributes.new({
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
      
      expect(attrs.cors_rule.size).to eq(1)
      expect(attrs.cors_rule[0][:allowed_methods]).to eq(["GET", "POST"])
      expect(attrs.cors_rule[0][:allowed_origins]).to eq(["https://example.com"])
    end
    
    it "accepts website configuration" do
      attrs = Pangea::Resources::AWS::S3BucketAttributes.new({
        website: {
          index_document: "index.html",
          error_document: "error.html"
        }
      })
      
      expect(attrs.website[:index_document]).to eq("index.html")
      expect(attrs.website[:error_document]).to eq("error.html")
    end
    
    it "accepts website redirect configuration" do
      attrs = Pangea::Resources::AWS::S3BucketAttributes.new({
        website: {
          redirect_all_requests_to: {
            host_name: "example.com",
            protocol: "https"
          }
        }
      })
      
      expect(attrs.website[:redirect_all_requests_to][:host_name]).to eq("example.com")
      expect(attrs.website[:redirect_all_requests_to][:protocol]).to eq("https")
    end
    
    it "validates website configuration consistency" do
      expect {
        Pangea::Resources::AWS::S3BucketAttributes.new({
          website: {
            index_document: "index.html",
            redirect_all_requests_to: {
              host_name: "example.com"
            }
          }
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both redirect_all_requests_to and index\/error documents/)
    end
    
    it "accepts logging configuration" do
      attrs = Pangea::Resources::AWS::S3BucketAttributes.new({
        logging: {
          target_bucket: "my-log-bucket",
          target_prefix: "logs/"
        }
      })
      
      expect(attrs.logging[:target_bucket]).to eq("my-log-bucket")
      expect(attrs.logging[:target_prefix]).to eq("logs/")
    end
    
    it "accepts object lock configuration" do
      attrs = Pangea::Resources::AWS::S3BucketAttributes.new({
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
      
      expect(attrs.object_lock_configuration[:object_lock_enabled]).to eq("Enabled")
      expect(attrs.object_lock_configuration[:rule][:default_retention][:mode]).to eq("COMPLIANCE")
      expect(attrs.object_lock_configuration[:rule][:default_retention][:days]).to eq(30)
    end
    
    it "validates object lock requires versioning" do
      expect {
        Pangea::Resources::AWS::S3BucketAttributes.new({
          object_lock_configuration: {
            object_lock_enabled: "Enabled"
          }
        })
      }.to raise_error(Dry::Struct::Error, /Object lock requires versioning to be enabled/)
    end
    
    it "accepts public access block configuration" do
      attrs = Pangea::Resources::AWS::S3BucketAttributes.new({
        public_access_block_configuration: {
          block_public_acls: true,
          block_public_policy: true,
          ignore_public_acls: true,
          restrict_public_buckets: true
        }
      })
      
      expect(attrs.public_access_block_configuration[:block_public_acls]).to eq(true)
      expect(attrs.public_access_block_configuration[:block_public_policy]).to eq(true)
      expect(attrs.public_access_block_configuration[:ignore_public_acls]).to eq(true)
      expect(attrs.public_access_block_configuration[:restrict_public_buckets]).to eq(true)
    end
    
    it "accepts bucket policy as JSON string" do
      policy_json = '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::my-bucket/*"}]}'
      
      attrs = Pangea::Resources::AWS::S3BucketAttributes.new({
        policy: policy_json
      })
      
      expect(attrs.policy).to eq(policy_json)
    end
    
    it "accepts tags" do
      attrs = Pangea::Resources::AWS::S3BucketAttributes.new({
        tags: {
          Name: "my-bucket",
          Environment: "production",
          Application: "web-app"
        }
      })
      
      expect(attrs.tags[:Name]).to eq("my-bucket")
      expect(attrs.tags[:Environment]).to eq("production")
      expect(attrs.tags[:Application]).to eq("web-app")
    end
  end
  
  describe "aws_s3_bucket function behavior" do
    it "creates a resource reference with minimal attributes" do
      ref = test_instance.aws_s3_bucket(:test, {})
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_s3_bucket')
      expect(ref.name).to eq(:test)
    end
    
    it "creates a bucket with custom name" do
      ref = test_instance.aws_s3_bucket(:my_bucket, {
        bucket: "my-unique-bucket-name"
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:bucket]).to eq("my-unique-bucket-name")
    end
    
    it "creates a bucket with versioning" do
      ref = test_instance.aws_s3_bucket(:versioned, {
        versioning: {
          enabled: true,
          mfa_delete: false
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:versioning][:enabled]).to eq(true)
      expect(attrs[:versioning][:mfa_delete]).to eq(false)
    end
    
    it "creates a bucket with KMS encryption" do
      ref = test_instance.aws_s3_bucket(:encrypted, {
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
      
      attrs = ref.resource_attributes
      expect(attrs[:server_side_encryption_configuration][:rule][:apply_server_side_encryption_by_default][:sse_algorithm]).to eq("aws:kms")
      expect(attrs[:server_side_encryption_configuration][:rule][:bucket_key_enabled]).to eq(true)
    end
    
    it "creates a bucket with lifecycle rules" do
      ref = test_instance.aws_s3_bucket(:lifecycle, {
        lifecycle_rule: [
          {
            id: "archive-rule",
            enabled: true,
            prefix: "archive/",
            transition: [
              {
                days: 30,
                storage_class: "STANDARD_IA"
              }
            ],
            expiration: {
              days: 90
            }
          }
        ]
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:lifecycle_rule].size).to eq(1)
      expect(attrs[:lifecycle_rule][0][:id]).to eq("archive-rule")
    end
    
    it "creates a bucket with CORS configuration" do
      ref = test_instance.aws_s3_bucket(:cors, {
        cors_rule: [
          {
            allowed_methods: ["GET", "POST"],
            allowed_origins: ["https://example.com"],
            allowed_headers: ["*"],
            max_age_seconds: 3000
          }
        ]
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:cors_rule].size).to eq(1)
      expect(attrs[:cors_rule][0][:allowed_methods]).to eq(["GET", "POST"])
    end
    
    it "creates a bucket with website configuration" do
      ref = test_instance.aws_s3_bucket(:website, {
        website: {
          index_document: "index.html",
          error_document: "404.html"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:website][:index_document]).to eq("index.html")
      expect(attrs[:website][:error_document]).to eq("404.html")
    end
    
    it "creates a bucket with logging" do
      ref = test_instance.aws_s3_bucket(:logged, {
        logging: {
          target_bucket: "log-bucket",
          target_prefix: "app-logs/"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:logging][:target_bucket]).to eq("log-bucket")
      expect(attrs[:logging][:target_prefix]).to eq("app-logs/")
    end
    
    it "creates a bucket with public access block" do
      ref = test_instance.aws_s3_bucket(:secure, {
        public_access_block_configuration: {
          block_public_acls: true,
          block_public_policy: true,
          ignore_public_acls: true,
          restrict_public_buckets: true
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:public_access_block_configuration][:block_public_acls]).to eq(true)
      expect(attrs[:public_access_block_configuration][:block_public_policy]).to eq(true)
    end
    
    it "creates a bucket with comprehensive configuration" do
      ref = test_instance.aws_s3_bucket(:comprehensive, {
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
      
      attrs = ref.resource_attributes
      expect(attrs[:bucket]).to eq("comprehensive-bucket")
      expect(attrs[:versioning][:enabled]).to eq(true)
      expect(attrs[:lifecycle_rule].size).to eq(1)
      expect(attrs[:tags][:Environment]).to eq("production")
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_s3_bucket(:test, {})
      
      expected_outputs = [
        :id, :arn, :bucket, :bucket_domain_name, :bucket_regional_domain_name,
        :hosted_zone_id, :region, :website_endpoint, :website_domain
      ]
      
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_s3_bucket.test.")
      end
    end
    
    it "provides computed properties via method delegation" do
      ref = test_instance.aws_s3_bucket(:test, {
        versioning: { enabled: true },
        server_side_encryption_configuration: {
          rule: {
            apply_server_side_encryption_by_default: {
              sse_algorithm: "aws:kms",
              kms_master_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678"
            }
          }
        },
        website: {
          index_document: "index.html"
        }
      })
      
      expect(ref.encryption_enabled?).to eq(true)
      expect(ref.kms_encrypted?).to eq(true)
      expect(ref.versioning_enabled?).to eq(true)
      expect(ref.website_enabled?).to eq(true)
      expect(ref.lifecycle_rules_count).to eq(0)
      expect(ref.public_access_blocked?).to eq(false)
    end
  end
  
  describe "common S3 bucket patterns" do
    it "creates a static website hosting bucket" do
      ref = test_instance.aws_s3_bucket(:static_site, {
        bucket: "my-static-website",
        acl: "public-read",
        website: {
          index_document: "index.html",
          error_document: "404.html"
        },
        cors_rule: [
          {
            allowed_methods: ["GET", "HEAD"],
            allowed_origins: ["*"],
            max_age_seconds: 3600
          }
        ],
        tags: {
          Name: "static-website",
          Type: "website"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:acl]).to eq("public-read")
      expect(attrs[:website][:index_document]).to eq("index.html")
      expect(attrs[:cors_rule][0][:allowed_methods]).to include("GET")
      expect(ref.website_enabled?).to eq(true)
    end
    
    it "creates a secure backup bucket" do
      ref = test_instance.aws_s3_bucket(:backup, {
        bucket: "secure-backups",
        versioning: {
          enabled: true,
          mfa_delete: true
        },
        server_side_encryption_configuration: {
          rule: {
            apply_server_side_encryption_by_default: {
              sse_algorithm: "aws:kms",
              kms_master_key_id: "arn:aws:kms:us-east-1:123456789012:key/backup-key"
            }
          }
        },
        lifecycle_rule: [
          {
            id: "transition-to-glacier",
            enabled: true,
            transition: [
              {
                days: 30,
                storage_class: "GLACIER"
              }
            ]
          }
        ],
        public_access_block_configuration: {
          block_public_acls: true,
          block_public_policy: true,
          ignore_public_acls: true,
          restrict_public_buckets: true
        },
        tags: {
          Name: "secure-backups",
          Type: "backup",
          Encryption: "KMS"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:versioning][:enabled]).to eq(true)
      expect(attrs[:versioning][:mfa_delete]).to eq(true)
      expect(ref.kms_encrypted?).to eq(true)
      expect(ref.public_access_blocked?).to eq(true)
    end
    
    it "creates a log storage bucket" do
      ref = test_instance.aws_s3_bucket(:logs, {
        bucket: "application-logs",
        acl: "log-delivery-write",
        lifecycle_rule: [
          {
            id: "expire-old-logs",
            enabled: true,
            prefix: "logs/",
            expiration: {
              days: 90
            },
            noncurrent_version_expiration: {
              days: 30
            }
          }
        ],
        server_side_encryption_configuration: {
          rule: {
            apply_server_side_encryption_by_default: {
              sse_algorithm: "AES256"
            }
          }
        },
        tags: {
          Name: "application-logs",
          Type: "logs",
          RetentionDays: "90"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:acl]).to eq("log-delivery-write")
      expect(attrs[:lifecycle_rule][0][:expiration][:days]).to eq(90)
      expect(ref.encryption_enabled?).to eq(true)
    end
    
    it "creates a data lake bucket" do
      ref = test_instance.aws_s3_bucket(:data_lake, {
        bucket: "company-data-lake",
        versioning: {
          enabled: true
        },
        lifecycle_rule: [
          {
            id: "archive-raw-data",
            enabled: true,
            prefix: "raw/",
            transition: [
              {
                days: 30,
                storage_class: "STANDARD_IA"
              },
              {
                days: 90,
                storage_class: "GLACIER"
              }
            ]
          },
          {
            id: "archive-processed-data",
            enabled: true,
            prefix: "processed/",
            transition: [
              {
                days: 60,
                storage_class: "STANDARD_IA"
              }
            ]
          }
        ],
        tags: {
          Name: "company-data-lake",
          Type: "data-lake",
          DataClassification: "internal"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:versioning][:enabled]).to eq(true)
      expect(attrs[:lifecycle_rule].size).to eq(2)
      expect(ref.lifecycle_rules_count).to eq(2)
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_s3_bucket(:test_bucket, {})
      
      expect(ref.outputs[:id]).to eq("${aws_s3_bucket.test_bucket.id}")
      expect(ref.outputs[:arn]).to eq("${aws_s3_bucket.test_bucket.arn}")
      expect(ref.outputs[:bucket]).to eq("${aws_s3_bucket.test_bucket.bucket}")
      expect(ref.outputs[:bucket_domain_name]).to eq("${aws_s3_bucket.test_bucket.bucket_domain_name}")
      expect(ref.outputs[:website_endpoint]).to eq("${aws_s3_bucket.test_bucket.website_endpoint}")
    end
    
    it "can be used with other AWS resources" do
      bucket_ref = test_instance.aws_s3_bucket(:for_cloudfront, {
        bucket: "cdn-origin-bucket"
      })
      
      # Simulate using bucket reference in CloudFront distribution
      bucket_domain = bucket_ref.outputs[:bucket_domain_name]
      bucket_arn = bucket_ref.outputs[:arn]
      
      expect(bucket_domain).to eq("${aws_s3_bucket.for_cloudfront.bucket_domain_name}")
      expect(bucket_arn).to eq("${aws_s3_bucket.for_cloudfront.arn}")
    end
    
    it "supports complex cross-resource references" do
      ref = test_instance.aws_s3_bucket(:cross_ref, {
        bucket: "${var.application}-${var.environment}-data",
        logging: {
          target_bucket: "${aws_s3_bucket.logs.bucket}",
          target_prefix: "${var.application}/"
        },
        server_side_encryption_configuration: {
          rule: {
            apply_server_side_encryption_by_default: {
              sse_algorithm: "aws:kms",
              kms_master_key_id: "${aws_kms_key.bucket_key.arn}"
            }
          }
        },
        tags: {
          Name: "${var.application}-bucket",
          Environment: "${var.environment}"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:bucket]).to include("var.application")
      expect(attrs[:logging][:target_bucket]).to include("aws_s3_bucket.logs")
      expect(attrs[:server_side_encryption_configuration][:rule][:apply_server_side_encryption_by_default][:kms_master_key_id]).to include("aws_kms_key")
    end
  end
  
  describe "error conditions and edge cases" do
    it "handles default values correctly" do
      ref = test_instance.aws_s3_bucket(:defaults, {})
      
      attrs = ref.resource_attributes
      expect(attrs[:acl]).to eq("private")
      expect(attrs[:versioning][:enabled]).to eq(false)
      expect(attrs[:server_side_encryption_configuration][:rule][:apply_server_side_encryption_by_default][:sse_algorithm]).to eq("AES256")
      expect(attrs[:lifecycle_rule]).to eq([])
      expect(attrs[:cors_rule]).to eq([])
    end
    
    it "handles empty configurations correctly" do
      ref = test_instance.aws_s3_bucket(:empty_configs, {
        website: {},
        logging: {},
        object_lock_configuration: {},
        public_access_block_configuration: {}
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:website]).to eq({})
      expect(attrs[:logging]).to eq({})
      expect(attrs[:object_lock_configuration]).to eq({})
      expect(attrs[:public_access_block_configuration]).to eq({})
    end
    
    it "handles string keys in attributes" do
      ref = test_instance.aws_s3_bucket(:string_keys, {
        "bucket" => "string-key-bucket",
        "acl" => "private",
        "versioning" => {
          "enabled" => true
        }
      })
      
      expect(ref.resource_attributes[:bucket]).to eq("string-key-bucket")
      expect(ref.resource_attributes[:acl]).to eq("private")
      expect(ref.resource_attributes[:versioning][:enabled]).to eq(true)
    end
    
    it "rejects invalid configurations early" do
      # Invalid ACL
      expect {
        test_instance.aws_s3_bucket(:invalid_acl, {
          acl: "invalid-acl"
        })
      }.to raise_error(Dry::Struct::Error)
      
      # KMS without key
      expect {
        test_instance.aws_s3_bucket(:invalid_kms, {
          server_side_encryption_configuration: {
            rule: {
              apply_server_side_encryption_by_default: {
                sse_algorithm: "aws:kms"
              }
            }
          }
        })
      }.to raise_error(Dry::Struct::Error, /kms_master_key_id is required/)
      
      # Object lock without versioning
      expect {
        test_instance.aws_s3_bucket(:invalid_lock, {
          object_lock_configuration: {
            object_lock_enabled: "Enabled"
          }
        })
      }.to raise_error(Dry::Struct::Error, /Object lock requires versioning/)
    end
  end
end