# frozen_string_literal: true

# Test configuration data and fixtures
module TestConfigurations
  # VPC test configurations
  VPC_CONFIG = {
    cidr_block: "10.0.0.0/16",
    enable_dns_hostnames: true,
    enable_dns_support: true,
    tags: {
      Name: "test-vpc",
      Environment: "test"
    }
  }.freeze

  VPC_MINIMAL_CONFIG = {
    cidr_block: "10.0.0.0/16"
  }.freeze

  VPC_INVALID_CONFIGS = {
    invalid_cidr: {
      cidr_block: "invalid-cidr"
    },
    missing_cidr: {
      enable_dns_hostnames: true
    },
    invalid_cidr_range: {
      cidr_block: "10.0.0.0/7"  # Too broad
    }
  }.freeze

  # Subnet test configurations
  SUBNET_CONFIG = {
    vpc_id: "${aws_vpc.test.id}",
    cidr_block: "10.0.1.0/24",
    availability_zone: "us-east-1a",
    map_public_ip_on_launch: true,
    tags: {
      Name: "test-subnet",
      Type: "public"
    }
  }.freeze

  # Security Group test configurations
  SECURITY_GROUP_CONFIG = {
    name: "test-sg",
    description: "Test security group",
    vpc_id: "${aws_vpc.test.id}",
    ingress: [
      {
        from_port: 80,
        to_port: 80,
        protocol: "tcp",
        cidr_blocks: ["0.0.0.0/0"]
      },
      {
        from_port: 443,
        to_port: 443,
        protocol: "tcp",
        cidr_blocks: ["0.0.0.0/0"]
      }
    ],
    egress: [
      {
        from_port: 0,
        to_port: 0,
        protocol: "-1",
        cidr_blocks: ["0.0.0.0/0"]
      }
    ]
  }.freeze

  # Load Balancer test configurations
  LOAD_BALANCER_CONFIG = {
    name: "test-alb",
    load_balancer_type: "application",
    security_groups: ["${aws_security_group.test.id}"],
    subnets: ["${aws_subnet.test_a.id}", "${aws_subnet.test_b.id}"],
    enable_deletion_protection: false,
    tags: {
      Name: "test-alb",
      Environment: "test"
    }
  }.freeze

  # RDS test configurations
  RDS_CONFIG = {
    allocated_storage: 20,
    storage_type: "gp2",
    engine: "mysql",
    engine_version: "8.0",
    instance_class: "db.t3.micro",
    db_name: "testdb",
    username: "testuser",
    password: "testpass123",
    parameter_group_name: "default.mysql8.0",
    skip_final_snapshot: true,
    tags: {
      Name: "test-db",
      Environment: "test"
    }
  }.freeze

  # Component test configurations
  SECURE_VPC_CONFIG = {
    cidr_block: "10.0.0.0/16",
    availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"],
    enable_flow_logs: true,
    tags: {
      Name: "secure-vpc-test",
      Security: "enhanced"
    }
  }.freeze

  APPLICATION_LOAD_BALANCER_CONFIG = {
    subnet_refs: [], # Will be populated in tests
    security_group_refs: [], # Will be populated in tests
    enable_deletion_protection: false,
    certificate_arn: nil,
    tags: {
      Name: "test-alb",
      Component: "LoadBalancer"
    }
  }.freeze

  AUTO_SCALING_CONFIG = {
    subnet_refs: [], # Will be populated in tests
    target_group_ref: nil, # Will be populated in tests
    min_size: 1,
    max_size: 3,
    desired_capacity: 2,
    instance_type: "t3.micro",
    tags: {
      Name: "test-asg",
      Component: "AutoScaling"
    }
  }.freeze

  # Architecture test configurations
  WEB_APPLICATION_CONFIG = {
    domain_name: "test.example.com",
    environment: "test",
    region: "us-east-1",
    vpc_cidr: "10.0.0.0/16",
    availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"],
    instance_type: "t3.micro",
    auto_scaling: {
      min: 1,
      max: 3,
      desired: 2
    },
    database_enabled: true,
    database_engine: "mysql",
    database_instance_class: "db.t3.micro",
    database_allocated_storage: 20,
    high_availability: false,
    enable_caching: false,
    enable_cdn: false,
    monitoring: {
      detailed_monitoring: false,
      enable_logging: true,
      log_retention_days: 7,
      enable_alerting: false,
      enable_tracing: false
    },
    security: {
      encryption_at_rest: true,
      encryption_in_transit: true,
      enable_waf: false,
      enable_ddos_protection: false,
      compliance_standards: []
    },
    backup: {
      backup_schedule: "daily",
      retention_days: 3,
      cross_region_backup: false,
      point_in_time_recovery: false
    },
    cost_optimization: {
      use_spot_instances: false,
      use_reserved_instances: false,
      enable_auto_shutdown: false
    },
    tags: {
      Application: "TestApp",
      Environment: "test"
    }
  }.freeze

  WEB_APPLICATION_PRODUCTION_CONFIG = {
    domain_name: "prod.example.com",
    environment: "production",
    region: "us-east-1",
    vpc_cidr: "10.0.0.0/16",
    availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"],
    instance_type: "t3.medium",
    auto_scaling: {
      min: 2,
      max: 10,
      desired: 3
    },
    database_enabled: true,
    database_engine: "mysql",
    database_instance_class: "db.r5.large",
    database_allocated_storage: 100,
    high_availability: true,
    enable_caching: true,
    enable_cdn: true,
    monitoring: {
      detailed_monitoring: true,
      enable_logging: true,
      log_retention_days: 30,
      enable_alerting: true,
      enable_tracing: true
    },
    security: {
      encryption_at_rest: true,
      encryption_in_transit: true,
      enable_waf: true,
      enable_ddos_protection: true,
      compliance_standards: ["SOC2", "PCI-DSS"]
    },
    backup: {
      backup_schedule: "daily",
      retention_days: 30,
      cross_region_backup: true,
      point_in_time_recovery: true
    },
    cost_optimization: {
      use_spot_instances: false,
      use_reserved_instances: true,
      enable_auto_shutdown: false
    },
    tags: {
      Application: "ProductionApp",
      Environment: "production"
    }
  }.freeze

  # Environment-specific configurations
  DEVELOPMENT_CONFIG = {
    environment: "development",
    instance_type: "t3.micro",
    auto_scaling: { min: 1, max: 2, desired: 1 },
    database_instance_class: "db.t3.micro",
    high_availability: false,
    enable_caching: false,
    enable_cdn: false
  }.freeze

  STAGING_CONFIG = {
    environment: "staging",
    instance_type: "t3.small",
    auto_scaling: { min: 1, max: 4, desired: 2 },
    database_instance_class: "db.t3.small",
    high_availability: true,
    enable_caching: true,
    enable_cdn: false
  }.freeze

  PRODUCTION_CONFIG = {
    environment: "production",
    instance_type: "t3.medium",
    auto_scaling: { min: 2, max: 10, desired: 3 },
    database_instance_class: "db.r5.large",
    high_availability: true,
    enable_caching: true,
    enable_cdn: true
  }.freeze

  # Invalid configurations for testing error handling
  INVALID_WEB_APP_CONFIGS = {
    invalid_domain: {
      domain_name: "invalid-domain",
      environment: "test"
    },
    invalid_environment: {
      domain_name: "test.example.com",
      environment: "invalid"
    },
    invalid_auto_scaling: {
      domain_name: "test.example.com",
      environment: "test",
      auto_scaling: {
        min: 5,
        max: 3  # min > max
      }
    },
    invalid_cidr: {
      domain_name: "test.example.com",
      environment: "test",
      vpc_cidr: "invalid-cidr"
    },
    invalid_region_az_mismatch: {
      domain_name: "test.example.com",
      environment: "test",
      region: "us-east-1",
      availability_zones: ["us-west-2a", "us-west-2b"]  # Different region
    }
  }.freeze

  # Test resource reference objects
  class TestResourceReference
    attr_reader :type, :name, :attributes

    def initialize(type, name, attributes = {})
      @type = type
      @name = name
      @attributes = attributes
    end

    def id
      "${#{@type}.#{@name}.id}"
    end

    def method_missing(method_name, *args, &block)
      if @attributes.has_key?(method_name.to_s)
        @attributes[method_name.to_s]
      else
        "${#{@type}.#{@name}.#{method_name}}"
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @attributes.has_key?(method_name.to_s) || super
    end
  end

  # Helper methods for creating test resources
  def create_test_vpc_ref
    TestResourceReference.new("aws_vpc", "test", VPC_CONFIG)
  end

  def create_test_subnet_ref
    TestResourceReference.new("aws_subnet", "test", SUBNET_CONFIG)
  end

  def create_test_security_group_ref
    TestResourceReference.new("aws_security_group", "test", SECURITY_GROUP_CONFIG)
  end

  def create_test_load_balancer_ref
    TestResourceReference.new("aws_lb", "test", LOAD_BALANCER_CONFIG)
  end

  def create_test_database_ref
    TestResourceReference.new("aws_db_instance", "test", RDS_CONFIG)
  end

  # Validation helpers
  def valid_cidr_blocks
    ["10.0.0.0/16", "172.16.0.0/12", "192.168.0.0/16", "10.1.0.0/24"]
  end

  def invalid_cidr_blocks
    ["invalid", "10.0.0.0", "10.0.0.0/33", "256.256.256.256/16"]
  end

  def valid_availability_zones
    [
      ["us-east-1a", "us-east-1b"],
      ["us-west-2a", "us-west-2b", "us-west-2c"],
      ["eu-west-1a", "eu-west-1b"]
    ]
  end

  def invalid_availability_zones
    [
      ["invalid-az"],
      ["us-east-1a", "us-west-2b"],  # Mixed regions
      []  # Empty
    ]
  end

  def valid_domain_names
    ["example.com", "test.example.com", "api.v1.example.co.uk"]
  end

  def invalid_domain_names
    ["invalid", ".example.com", "example.", "ex ample.com", "toolong" + "a" * 250 + ".com"]
  end

  def valid_instance_types
    ["t3.micro", "t3.small", "t3.medium", "c5.large", "r5.xlarge", "m5.2xlarge"]
  end

  def invalid_instance_types
    ["invalid", "t3", "t3.huge", "z99.micro"]
  end

  def valid_database_engines
    ["mysql", "postgresql", "mariadb", "aurora", "aurora-mysql", "aurora-postgresql"]
  end

  def invalid_database_engines
    ["invalid", "oracle", "sqlserver", "mongodb"]
  end
end