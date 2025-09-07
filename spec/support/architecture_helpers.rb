# frozen_string_literal: true

# Test helpers for architecture function testing
module ArchitectureHelpers
  # Generate test attributes for web application architecture
  def valid_web_app_attributes
    {
      domain: 'test-app.com',
      environment: 'production',
      vpc_cidr: '10.0.0.0/16',
      availability_zones: ['us-east-1a', 'us-east-1b'],
      high_availability: true,
      auto_scaling: { min: 2, max: 10, desired: 3 },
      instance_type: 't3.small',
      ami_id: 'ami-12345678',
      database_enabled: true,
      database_engine: 'postgres',
      database_instance_class: 'db.t3.micro',
      s3_bucket_enabled: true,
      monitoring_enabled: true,
      tags: {
        Project: 'test-project',
        Owner: 'test-team'
      }
    }
  end

  # Generate minimal web application attributes for development
  def minimal_web_app_attributes
    {
      domain: 'dev.test-app.com',
      environment: 'development'
    }
  end

  # Generate test attributes for microservices platform
  def valid_microservices_platform_attributes
    {
      platform_name: 'test-platform',
      environment: 'production',
      vpc_cidr: '10.1.0.0/16',
      availability_zones: ['us-east-1a', 'us-east-1b', 'us-east-1c'],
      service_mesh: 'istio',
      orchestrator: 'ecs',
      api_gateway: true,
      message_queue: 'sqs',
      shared_cache: true,
      centralized_logging: true,
      secrets_management: true,
      tags: {
        Platform: 'microservices',
        Environment: 'production'
      }
    }
  end

  # Generate test attributes for individual microservice
  def valid_microservice_attributes
    {
      service_name: 'user-service',
      runtime: 'nodejs',
      port: 3000,
      min_instances: 2,
      max_instances: 10,
      database_type: 'postgresql',
      database_size: 'db.t3.micro',
      security_level: 'medium',
      expose_publicly: false,
      depends_on: [],
      tags: {
        Service: 'user-service',
        Team: 'backend'
      }
    }
  end

  # Generate test attributes for data lake architecture
  def valid_data_lake_attributes
    {
      data_lake_name: 'test-data-lake',
      environment: 'production',
      vpc_cidr: '10.2.0.0/16',
      data_sources: ['s3', 'rds', 'kinesis'],
      real_time_processing: true,
      batch_processing: true,
      data_warehouse: 'athena',
      machine_learning: false,
      emr_enabled: true,
      glue_enabled: true,
      tags: {
        DataLake: 'analytics',
        Purpose: 'testing'
      }
    }
  end

  # Generate test attributes for streaming architecture
  def valid_streaming_attributes
    {
      stream_name: 'test-stream',
      stream_type: 'kinesis',
      shard_count: 2,
      retention_hours: 24,
      stream_processing_framework: 'kinesis-analytics',
      output_destinations: ['s3', 'elasticsearch'],
      monitoring_enabled: true,
      alerting_enabled: true
    }
  end

  # Helper to create mock platform reference for microservice testing
  def create_mock_platform_reference
    platform_attrs = valid_microservices_platform_attributes
    platform_ref = Pangea::Architectures::ArchitectureReference.new(
      architecture_type: 'microservices_platform',
      name: :test_platform,
      resource_attributes: platform_attrs
    )

    # Mock the network tier
    platform_ref.network = OpenStruct.new(
      vpc: OpenStruct.new(id: 'vpc-testplatform'),
      public_subnet_ids: ['subnet-pub1', 'subnet-pub2'],
      private_subnet_ids: ['subnet-priv1', 'subnet-priv2'],
      all_subnet_ids: ['subnet-pub1', 'subnet-pub2', 'subnet-priv1', 'subnet-priv2']
    )

    # Mock the compute tier
    platform_ref.compute = {
      cluster: OpenStruct.new(
        id: 'arn:aws:ecs:us-east-1:123456789012:cluster/test-platform-cluster',
        name: 'test-platform-cluster'
      )
    }

    # Mock the security tier  
    platform_ref.security = {
      default_sg: OpenStruct.new(id: 'sg-default123')
    }

    platform_ref
  end

  # Helper to verify architecture has all expected tiers
  def expect_complete_architecture(architecture)
    expect(architecture).to be_a(Pangea::Architectures::ArchitectureReference)
    expect(architecture.architecture_type).to be_a(String)
    expect(architecture.name).to be_a(Symbol)
    expect(architecture.resource_attributes).to be_a(Hash)
  end

  # Helper to verify architecture has required infrastructure tiers
  def expect_web_app_tiers(architecture)
    expect(architecture.network).to be_present, 'Missing network tier'
    expect(architecture.security).to be_present, 'Missing security tier'  
    expect(architecture.compute).to be_present, 'Missing compute tier'
  end

  # Helper to verify high availability configuration
  def expect_high_availability(architecture)
    expect(architecture.is_highly_available?).to be true
    expect(architecture.availability_zones.count).to be >= 2
  end

  # Helper to verify cost estimation is reasonable
  def expect_reasonable_cost(architecture, min_cost: 10, max_cost: 1000)
    cost = architecture.estimated_monthly_cost
    expect(cost).to be >= min_cost, "Cost #{cost} is unreasonably low"
    expect(cost).to be <= max_cost, "Cost #{cost} is unreasonably high"
  end

  # Helper to verify security compliance score
  def expect_good_security_score(architecture, min_score: 70.0)
    score = architecture.security_compliance_score
    expect(score).to be >= min_score, "Security score #{score} is too low"
    expect(score).to be <= 100.0, "Security score #{score} is invalid"
  end

  # Helper to count resources of a specific type
  def count_resources_of_type(architecture, resource_type)
    architecture.all_resources.count do |resource|
      resource.respond_to?(:type) && resource.type == resource_type
    end
  end

  # Helper to find resource by type and name
  def find_resource(architecture, type, name)
    architecture.all_resources.find do |resource|
      resource.respond_to?(:type) && resource.respond_to?(:name) &&
        resource.type == type && resource.name == name
    end
  end

  # Helper to verify resource attributes match expected values
  def expect_resource_attributes(resource, expected_attrs)
    expected_attrs.each do |key, value|
      actual_value = resource.resource_attributes[key]
      expect(actual_value).to eq(value), 
        "Resource #{resource.name} attribute #{key}: expected #{value}, got #{actual_value}"
    end
  end

  # Helper to test architecture override functionality
  def test_architecture_override(architecture, component, &block)
    original_component = architecture.send(component)
    overridden = architecture.override(component, &block)
    
    expect(overridden).not_to eq(architecture), 'Override should return new architecture'
    expect(overridden.overrides[component]).to be true, 'Override should be tracked'
    expect(overridden.send(component)).not_to eq(original_component), 'Component should be different'
    
    overridden
  end

  # Property-based testing helper for generating random valid attributes
  def random_valid_attributes(base_attrs)
    base_attrs.merge(
      environment: ['development', 'staging', 'production'].sample,
      tags: {
        RandomTag: Faker::Lorem.word,
        TestRun: SecureRandom.uuid
      }
    )
  end

  # Helper to simulate terraform-synthesizer output
  def mock_terraform_synthesis_result(resources = {})
    {
      'terraform' => {
        'required_version' => '>= 1.0',
        'required_providers' => {
          'aws' => {
            'source' => 'hashicorp/aws',
            'version' => '~> 5.0'
          }
        }
      },
      'resource' => resources
    }
  end
end

RSpec.configure do |config|
  config.include ArchitectureHelpers
end