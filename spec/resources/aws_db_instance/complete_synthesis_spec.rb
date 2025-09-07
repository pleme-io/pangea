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

# Load aws_db_instance resource for terraform synthesis testing
require 'pangea/resources/aws_db_instance/resource'

RSpec.describe "aws_db_instance terraform synthesis" do
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
            # For nested blocks like tags
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
    
    it "synthesizes basic RDS instance terraform correctly" do
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
      
      # Call aws_db_instance function with minimal configuration
      ref = test_instance.aws_db_instance(:basic_db, {
        engine: "postgres",
        instance_class: "db.t3.micro",
        allocated_storage: 20
      })
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_db_instance')
      expect(ref.name).to eq(:basic_db)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_db_instance, :basic_db],
        [:engine, "postgres"],
        [:instance_class, "db.t3.micro"],
        [:allocated_storage, 20],
        [:storage_encrypted, true],
        [:manage_master_user_password, true],
        [:multi_az, false],
        [:publicly_accessible, false],
        [:backup_retention_period, 7],
        [:auto_minor_version_upgrade, true],
        [:deletion_protection, false],
        [:skip_final_snapshot, true]
      )
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_db_instance.basic_db")
    end
    
    it "synthesizes database with custom identifier correctly" do
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
      
      # Call aws_db_instance function with custom identifier
      ref = test_instance.aws_db_instance(:named_db, {
        identifier: "production-postgres",
        engine: "postgres",
        engine_version: "15.3",
        instance_class: "db.t3.medium",
        allocated_storage: 100
      })
      
      # Verify identifier and engine version synthesis
      expect(test_synthesizer.method_calls).to include(
        [:identifier, "production-postgres"],
        [:engine_version, "15.3"]
      )
    end
    
    it "synthesizes high-performance database with IOPS correctly" do
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
      
      # Call aws_db_instance function with io2 storage and IOPS
      ref = test_instance.aws_db_instance(:perf_db, {
        engine: "mysql",
        instance_class: "db.r5.2xlarge",
        allocated_storage: 1000,
        storage_type: "io2",
        iops: 20000
      })
      
      # Verify IOPS synthesis
      expect(test_synthesizer.method_calls).to include(
        [:storage_type, "io2"],
        [:iops, 20000]
      )
    end
    
    it "synthesizes database with network configuration correctly" do
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
      
      # Call aws_db_instance function with network config
      ref = test_instance.aws_db_instance(:network_db, {
        engine: "postgres",
        instance_class: "db.t3.large",
        allocated_storage: 200,
        db_subnet_group_name: "my-db-subnet-group",
        vpc_security_group_ids: ["sg-12345", "sg-67890"],
        availability_zone: "us-east-1a",
        multi_az: true
      })
      
      # Verify network configuration synthesis
      expect(test_synthesizer.method_calls).to include(
        [:db_subnet_group_name, "my-db-subnet-group"],
        [:vpc_security_group_ids, ["sg-12345", "sg-67890"]],
        [:availability_zone, "us-east-1a"],
        [:multi_az, true]
      )
    end
    
    it "synthesizes database with backup configuration correctly" do
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
      
      # Call aws_db_instance function with backup settings
      ref = test_instance.aws_db_instance(:backup_db, {
        engine: "mysql",
        instance_class: "db.m5.xlarge",
        allocated_storage: 500,
        backup_retention_period: 30,
        backup_window: "03:00-04:00",
        maintenance_window: "sun:04:00-sun:05:00"
      })
      
      # Verify backup configuration synthesis
      expect(test_synthesizer.method_calls).to include(
        [:backup_retention_period, 30],
        [:backup_window, "03:00-04:00"],
        [:maintenance_window, "sun:04:00-sun:05:00"]
      )
    end
    
    it "synthesizes database with performance insights correctly" do
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
      
      # Call aws_db_instance function with performance insights
      ref = test_instance.aws_db_instance(:monitored_db, {
        engine: "postgres",
        instance_class: "db.r5.large",
        allocated_storage: 1000,
        enabled_cloudwatch_logs_exports: ["postgresql"],
        performance_insights_enabled: true,
        performance_insights_retention_period: 31
      })
      
      # Verify performance monitoring synthesis
      expect(test_synthesizer.method_calls).to include(
        [:enabled_cloudwatch_logs_exports, ["postgresql"]],
        [:performance_insights_enabled, true],
        [:performance_insights_retention_period, 31]
      )
    end
    
    it "synthesizes database with encryption correctly" do
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
      
      # Call aws_db_instance function with KMS encryption
      ref = test_instance.aws_db_instance(:encrypted_db, {
        engine: "mysql",
        instance_class: "db.t3.medium",
        allocated_storage: 100,
        storage_encrypted: true,
        kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678"
      })
      
      # Verify encryption synthesis
      expect(test_synthesizer.method_calls).to include(
        [:storage_encrypted, true],
        [:kms_key_id, "arn:aws:kms:us-east-1:123456789012:key/12345678"]
      )
    end
    
    it "synthesizes database with deletion protection correctly" do
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
      
      # Call aws_db_instance function with deletion settings
      ref = test_instance.aws_db_instance(:protected_db, {
        engine: "postgres",
        instance_class: "db.t3.large",
        allocated_storage: 500,
        deletion_protection: true,
        skip_final_snapshot: false,
        final_snapshot_identifier: "final-backup-2023"
      })
      
      # Verify deletion protection synthesis
      expect(test_synthesizer.method_calls).to include(
        [:deletion_protection, true],
        [:skip_final_snapshot, false],
        [:final_snapshot_identifier, "final-backup-2023"]
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
      
      # Call aws_db_instance function with tags
      ref = test_instance.aws_db_instance(:tagged_db, {
        engine: "mysql",
        instance_class: "db.t3.small",
        allocated_storage: 50,
        tags: {
          Name: "production-database",
          Environment: "production",
          Application: "web-app",
          ManagedBy: "terraform"
        }
      })
      
      # Verify tags synthesis
      expect(test_synthesizer.method_calls).to include(
        [:tags],
        [:Name, "production-database"],
        [:Environment, "production"],
        [:Application, "web-app"],
        [:ManagedBy, "terraform"]
      )
    end
    
    it "synthesizes Aurora instance correctly (no allocated_storage)" do
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
      
      # Call aws_db_instance function with Aurora engine
      ref = test_instance.aws_db_instance(:aurora_instance, {
        engine: "aurora-mysql",
        engine_version: "8.0.mysql_aurora.3.02.0",
        instance_class: "db.r5.large"
      })
      
      # Verify Aurora synthesis (no allocated_storage)
      expect(test_synthesizer.method_calls).to include(
        [:engine, "aurora-mysql"],
        [:engine_version, "8.0.mysql_aurora.3.02.0"],
        [:instance_class, "db.r5.large"]
      )
      
      # Verify allocated_storage was NOT called
      allocated_storage_calls = test_synthesizer.method_calls.select { |call| call[0] == :allocated_storage }
      expect(allocated_storage_calls).to be_empty
    end
    
    it "synthesizes database credentials correctly" do
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
      
      # Call aws_db_instance function with credentials
      ref = test_instance.aws_db_instance(:creds_db, {
        engine: "postgres",
        instance_class: "db.t3.medium",
        allocated_storage: 100,
        db_name: "myapp",
        username: "dbadmin",
        manage_master_user_password: true
      })
      
      # Verify credentials synthesis
      expect(test_synthesizer.method_calls).to include(
        [:db_name, "myapp"],
        [:username, "dbadmin"],
        [:manage_master_user_password, true]
      )
    end
    
    it "synthesizes comprehensive database configuration correctly" do
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
      
      # Call aws_db_instance function with comprehensive config
      ref = test_instance.aws_db_instance(:comprehensive_db, {
        identifier: "production-main",
        engine: "postgres",
        engine_version: "15.3",
        instance_class: "db.m5.2xlarge",
        allocated_storage: 1000,
        storage_type: "io2",
        iops: 10000,
        storage_encrypted: true,
        
        db_name: "mainapp",
        username: "dbadmin",
        manage_master_user_password: true,
        
        db_subnet_group_name: "prod-db-subnet",
        vpc_security_group_ids: ["sg-prod"],
        multi_az: true,
        
        backup_retention_period: 14,
        backup_window: "03:00-04:00",
        maintenance_window: "sun:04:00-sun:05:00",
        
        performance_insights_enabled: true,
        enabled_cloudwatch_logs_exports: ["postgresql"],
        
        deletion_protection: true,
        
        tags: {
          Name: "production-main",
          Environment: "production"
        }
      })
      
      # Verify comprehensive synthesis includes all major components
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_db_instance, :comprehensive_db],
        [:identifier, "production-main"],
        [:engine, "postgres"],
        [:engine_version, "15.3"],
        [:instance_class, "db.m5.2xlarge"],
        [:allocated_storage, 1000],
        [:storage_type, "io2"],
        [:iops, 10000],
        [:multi_az, true],
        [:backup_retention_period, 14],
        [:performance_insights_enabled, true],
        [:deletion_protection, true],
        [:tags]
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
      
      # Call with minimal config (no optional attributes)
      ref = test_instance.aws_db_instance(:minimal, {
        engine: "mysql",
        instance_class: "db.t3.micro",
        allocated_storage: 20
      })
      
      # Verify optional attributes were not synthesized
      identifier_calls = test_synthesizer.method_calls.select { |call| call[0] == :identifier }
      engine_version_calls = test_synthesizer.method_calls.select { |call| call[0] == :engine_version }
      db_name_calls = test_synthesizer.method_calls.select { |call| call[0] == :db_name }
      username_calls = test_synthesizer.method_calls.select { |call| call[0] == :username }
      password_calls = test_synthesizer.method_calls.select { |call| call[0] == :password }
      
      expect(identifier_calls).to be_empty
      expect(engine_version_calls).to be_empty
      expect(db_name_calls).to be_empty
      expect(username_calls).to be_empty
      expect(password_calls).to be_empty
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
      
      ref = test_instance.aws_db_instance(:output_test, {
        engine: "postgres",
        instance_class: "db.t3.micro",
        allocated_storage: 20
      })
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :arn, :address, :endpoint, :hosted_zone_id, :resource_id, :status, :port]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\$\{aws_db_instance\.output_test\./)
      end
      
      # Verify specific output formats
      expect(ref.outputs[:id]).to eq("${aws_db_instance.output_test.id}")
      expect(ref.outputs[:endpoint]).to eq("${aws_db_instance.output_test.endpoint}")
      expect(ref.outputs[:address]).to eq("${aws_db_instance.output_test.address}")
      expect(ref.outputs[:port]).to eq("${aws_db_instance.output_test.port}")
    end
  end
end