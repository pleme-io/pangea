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


require 'dry-struct'
require 'dry-types'
require 'json'
require 'base64'

module Pangea
  module Resources
    # Common types for resource definitions
    module Types
      include Dry.Types()
      
      # AWS-specific types
      AwsRegion = String.enum(
        'us-east-1', 'us-east-2', 'us-west-1', 'us-west-2',
        'eu-west-1', 'eu-west-2', 'eu-central-1',
        'ap-southeast-1', 'ap-southeast-2', 'ap-northeast-1'
      )
      
      AwsAvailabilityZone = String.constrained(
        format: /\A[a-z]{2}-[a-z]+-\d[a-z]\z/
      )
      
      # CIDR block validation
      CidrBlock = String.constrained(
        format: /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}\z/
      )
      
      # EC2 instance types
      Ec2InstanceType = String.enum(
        # General purpose
        't3.nano', 't3.micro', 't3.small', 't3.medium', 't3.large', 't3.xlarge', 't3.2xlarge',
        't3a.nano', 't3a.micro', 't3a.small', 't3a.medium', 't3a.large', 't3a.xlarge', 't3a.2xlarge',
        'm5.large', 'm5.xlarge', 'm5.2xlarge', 'm5.4xlarge', 'm5.8xlarge', 'm5.12xlarge', 'm5.16xlarge', 'm5.24xlarge',
        'm5a.large', 'm5a.xlarge', 'm5a.2xlarge', 'm5a.4xlarge', 'm5a.8xlarge', 'm5a.12xlarge', 'm5a.16xlarge', 'm5a.24xlarge',
        
        # Compute optimized
        'c5.large', 'c5.xlarge', 'c5.2xlarge', 'c5.4xlarge', 'c5.9xlarge', 'c5.12xlarge', 'c5.18xlarge', 'c5.24xlarge',
        'c5n.large', 'c5n.xlarge', 'c5n.2xlarge', 'c5n.4xlarge', 'c5n.9xlarge', 'c5n.18xlarge',
        
        # Memory optimized  
        'r5.large', 'r5.xlarge', 'r5.2xlarge', 'r5.4xlarge', 'r5.8xlarge', 'r5.12xlarge', 'r5.16xlarge', 'r5.24xlarge',
        
        # Storage optimized
        'i3.large', 'i3.xlarge', 'i3.2xlarge', 'i3.4xlarge', 'i3.8xlarge', 'i3.16xlarge'
      )
      
      # Common AWS resource attributes
      AwsTags = Hash.map(Symbol, String).default({}.freeze)
      
      # Network protocols
      IpProtocol = String.enum('tcp', 'udp', 'icmp', 'icmpv6', 'all', '-1')
      
      # Port ranges
      Port = Integer.constrained(gteq: 0, lteq: 65535)
      PortRange = Hash.schema(
        from_port: Port,
        to_port: Port
      )
      
      # Security group rule
      SecurityGroupRule = Hash.schema(
        from_port: Port,
        to_port: Port,
        protocol: IpProtocol,
        cidr_blocks?: Array.of(CidrBlock).default([].freeze),
        security_groups?: Array.of(String).default([].freeze),
        description?: String.optional
      )
      
      # Instance tenancy
      InstanceTenancy = String.default('default').enum('default', 'dedicated', 'host')
      
      # EBS volume types
      EbsVolumeType = String.enum('gp2', 'gp3', 'io1', 'io2', 'st1', 'sc1', 'standard')
      
      # RDS engine types
      RdsEngine = String.enum(
        'mysql', 'postgres', 'mariadb', 'oracle-ee', 'oracle-se2', 
        'oracle-se1', 'oracle-se', 'sqlserver-ee', 'sqlserver-se', 
        'sqlserver-ex', 'sqlserver-web', 'aurora-mysql', 'aurora-postgresql'
      )
      
      # RDS instance classes
      RdsInstanceClass = String.enum(
        'db.t3.micro', 'db.t3.small', 'db.t3.medium', 'db.t3.large', 'db.t3.xlarge', 'db.t3.2xlarge',
        'db.t4g.micro', 'db.t4g.small', 'db.t4g.medium', 'db.t4g.large', 'db.t4g.xlarge', 'db.t4g.2xlarge',
        'db.m5.large', 'db.m5.xlarge', 'db.m5.2xlarge', 'db.m5.4xlarge', 'db.m5.8xlarge', 'db.m5.12xlarge', 'db.m5.16xlarge', 'db.m5.24xlarge',
        'db.r5.large', 'db.r5.xlarge', 'db.r5.2xlarge', 'db.r5.4xlarge', 'db.r5.8xlarge', 'db.r5.12xlarge', 'db.r5.16xlarge', 'db.r5.24xlarge'
      )
      
      # S3 bucket versioning
      S3Versioning = String.enum('Enabled', 'Suspended', 'Disabled')
      
      # Load balancer types
      LoadBalancerType = String.default('application').enum('application', 'network', 'gateway')
      
      # Application load balancer target types
      AlbTargetType = String.enum('instance', 'ip', 'lambda', 'alb')
      
      # Health check protocols
      HealthCheckProtocol = String.enum('HTTP', 'HTTPS', 'TCP', 'TLS', 'UDP', 'TCP_UDP', 'GENEVE')
      
      # VPN-related types
      VpnConnectionType = String.enum('ipsec.1')
      VpnGatewayType = String.enum('ipsec.1')
      VpnTunnelProtocol = String.enum('ikev1', 'ikev2')
      
      # BGP ASN validation (16-bit and 32-bit ASNs)
      BgpAsn = Integer.constrained(
        gteq: 1,
        lteq: 4294967295
      ).constructor { |value|
        # AWS reserved ASNs: 7224, 9059, 10124, 17943
        reserved_asns = [7224, 9059, 10124, 17943]
        if reserved_asns.include?(value)
          raise Dry::Types::ConstraintError, "ASN #{value} is reserved by AWS"
        end
        value
      }
      
      # Customer Gateway IP address validation
      PublicIpAddress = String.constrained(
        format: /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/
      ).constructor { |value|
        # Reject private IP ranges for customer gateway
        ip_parts = value.split('.').map(&:to_i)
        
        # 10.0.0.0/8
        if ip_parts[0] == 10
          raise Dry::Types::ConstraintError, "Customer Gateway IP cannot be in private range 10.0.0.0/8"
        end
        
        # 172.16.0.0/12
        if ip_parts[0] == 172 && (16..31).include?(ip_parts[1])
          raise Dry::Types::ConstraintError, "Customer Gateway IP cannot be in private range 172.16.0.0/12"
        end
        
        # 192.168.0.0/16
        if ip_parts[0] == 192 && ip_parts[1] == 168
          raise Dry::Types::ConstraintError, "Customer Gateway IP cannot be in private range 192.168.0.0/16"
        end
        
        value
      }
      
      # EFS-specific types
      EfsPerformanceMode = String.constrained(included_in: ['generalPurpose', 'maxIO'])
      EfsThroughputMode = String.constrained(included_in: ['bursting', 'provisioned', 'elastic'])
      
      # EFS Lifecycle Policy configuration
      EfsLifecyclePolicy = Hash.schema(
        transition_to_ia?: String.constrained(included_in: ['AFTER_7_DAYS', 'AFTER_14_DAYS', 'AFTER_30_DAYS', 'AFTER_60_DAYS', 'AFTER_90_DAYS']).optional,
        transition_to_primary_storage_class?: String.constrained(included_in: ['AFTER_1_ACCESS']).optional
      ).constructor { |value|
        # Ensure at least one transition is specified
        if value.empty? || (!value[:transition_to_ia] && !value[:transition_to_primary_storage_class])
          raise Dry::Types::ConstraintError, "EFS lifecycle policy must specify at least one transition"
        end
        value
      }
      
      # EFS Access Point POSIX user
      EfsPosixUser = Hash.schema(
        uid: Integer.constrained(gteq: 0, lteq: 4294967295),
        gid: Integer.constrained(gteq: 0, lteq: 4294967295),
        secondary_gids?: Array.of(Integer.constrained(gteq: 0, lteq: 4294967295)).optional
      )
      
      # EFS Access Point root directory creation info
      EfsCreationInfo = Hash.schema(
        owner_uid: Integer.constrained(gteq: 0, lteq: 4294967295),
        owner_gid: Integer.constrained(gteq: 0, lteq: 4294967295),
        permissions: String.constrained(format: /\A[0-7]{3,4}\z/)
      )
      
      # EFS Access Point root directory
      EfsRootDirectory = Hash.schema(
        path?: String.constrained(format: /\A\/.*/).default("/"),
        creation_info?: EfsCreationInfo.optional
      )
      
      # POSIX permissions (octal format)
      PosixPermissions = String.constrained(format: /\A[0-7]{3,4}\z/)
      
      # Unix User/Group IDs
      UnixUserId = Integer.constrained(gteq: 0, lteq: 4294967295)
      UnixGroupId = Integer.constrained(gteq: 0, lteq: 4294967295)
      
      # Lambda-specific types
      LambdaRuntime = String.enum(
        # Python runtimes
        'python3.12', 'python3.11', 'python3.10', 'python3.9', 'python3.8',
        # Node.js runtimes
        'nodejs20.x', 'nodejs18.x', 'nodejs16.x',
        # Java runtimes
        'java21', 'java17', 'java11', 'java8.al2', 'java8',
        # .NET runtimes
        'dotnet8', 'dotnet6',
        # Go runtime
        'go1.x',
        # Ruby runtime
        'ruby3.2', 'ruby2.7',
        # Custom runtime
        'provided.al2023', 'provided.al2', 'provided'
      )
      
      LambdaArchitecture = String.enum('x86_64', 'arm64')
      
      LambdaPackageType = String.enum('Zip', 'Image')
      
      LambdaTracingMode = String.enum('Active', 'PassThrough')
      
      # Lambda memory validation (128MB to 10240MB in 1MB increments)
      LambdaMemory = Integer.constrained(gteq: 128, lteq: 10240).constructor { |value|
        unless value >= 512 || value % 64 == 0
          raise Dry::Types::ConstraintError, "Lambda memory must be in 64MB increments between 128-512MB, or 1MB increments above 512MB"
        end
        value
      }
      
      # Lambda timeout validation (1s to 900s/15min)
      LambdaTimeout = Integer.constrained(gteq: 1, lteq: 900)
      
      # Lambda reserved concurrent executions
      LambdaReservedConcurrency = Integer.constrained(gteq: 0, lteq: 1000)
      
      # Lambda provisioned concurrent executions
      LambdaProvisionedConcurrency = Integer.constrained(gteq: 1, lteq: 1000)
      
      # Lambda event source mapping
      LambdaEventSourcePosition = String.enum('TRIM_HORIZON', 'LATEST', 'AT_TIMESTAMP')
      
      # Lambda dead letter queue config
      LambdaDeadLetterConfig = Hash.schema(
        target_arn: String.constrained(format: /\Aarn:aws:(sqs|sns):/)
      )
      
      # Lambda VPC config
      LambdaVpcConfig = Hash.schema(
        subnet_ids: Array.of(String).constrained(min_size: 1),
        security_group_ids: Array.of(String).constrained(min_size: 1)
      )
      
      # Lambda environment variables
      LambdaEnvironmentVariables = Hash.map(String.constrained(format: /\A[a-zA-Z_][a-zA-Z0-9_]*\z/), String)
      
      # Lambda file system config (EFS)
      LambdaFileSystemConfig = Hash.schema(
        arn: String.constrained(format: /\Aarn:aws:elasticfilesystem:/),
        local_mount_path: String.constrained(format: /\A\/mnt\/[a-zA-Z0-9_-]+\z/)
      )
      
      # Lambda ephemeral storage
      LambdaEphemeralStorage = Hash.schema(
        size: Integer.constrained(gteq: 512, lteq: 10240)
      )
      
      # Lambda snap start
      LambdaSnapStart = Hash.schema(
        apply_on: String.default('None').enum('PublishedVersions', 'None')
      )
      
      # Lambda image config
      LambdaImageConfig = Hash.schema(
        entry_point?: Array.of(String).optional,
        command?: Array.of(String).optional,
        working_directory?: String.optional
      )
      
      # Lambda permission actions
      LambdaPermissionAction = String.enum(
        'lambda:InvokeFunction',
        'lambda:GetFunction',
        'lambda:GetFunctionConfiguration',
        'lambda:UpdateFunctionConfiguration',
        'lambda:UpdateFunctionCode',
        'lambda:DeleteFunction',
        'lambda:PublishVersion',
        'lambda:CreateAlias',
        'lambda:UpdateAlias',
        'lambda:DeleteAlias',
        'lambda:GetAlias',
        'lambda:ListVersionsByFunction',
        'lambda:GetPolicy',
        'lambda:PutFunctionConcurrency',
        'lambda:DeleteFunctionConcurrency',
        'lambda:GetFunctionConcurrency',
        'lambda:ListTags',
        'lambda:TagResource',
        'lambda:UntagResource'
      )
      
      # Lambda event source types
      LambdaEventSourceType = String.enum(
        'kinesis',
        'dynamodb',
        'sqs',
        'msk',
        'self-managed-kafka',
        'rabbitmq'
      )
      
      # Lambda destination on failure
      LambdaDestinationOnFailure = Hash.schema(
        destination: String.constrained(format: /\Aarn:aws:(sqs|sns|lambda|events):/)
      )
      
      # Lambda self managed event source
      LambdaSelfManagedEventSource = Hash.schema(
        endpoints: Hash.map(String.enum('KAFKA_BOOTSTRAP_SERVERS'), Array.of(String))
      )
      
      # Lambda source access configuration
      LambdaSourceAccessConfiguration = Hash.schema(
        type: String.enum('BASIC_AUTH', 'VPC_SUBNET', 'VPC_SECURITY_GROUP', 'SASL_SCRAM_256_AUTH', 'SASL_SCRAM_512_AUTH'),
        uri: String
      )
      
      # ACM Certificate-specific types
      AcmValidationMethod = String.enum('DNS', 'EMAIL')
      AcmCertificateStatus = String.enum('PENDING_VALIDATION', 'ISSUED', 'INACTIVE', 'EXPIRED', 'VALIDATION_TIMED_OUT', 'REVOKED', 'FAILED')
      AcmKeyAlgorithm = String.enum('RSA-2048', 'RSA-1024', 'RSA-4096', 'EC-prime256v1', 'EC-secp384r1', 'EC-secp521r1')
      
      # Domain name validation (basic - more detailed validation in resource types)
      DomainName = String.constrained(
        format: /\A(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)*[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z/i
      )
      
      # Wildcard domain name validation
      WildcardDomainName = String.constrained(
        format: /\A\*\.(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)*[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z/i
      )
      
      # Email address validation for ACM email validation
      EmailAddress = String.constrained(
        format: /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/
      )
      
      # KMS key-specific types
      KmsKeyUsage = String.enum('SIGN_VERIFY', 'ENCRYPT_DECRYPT')
      KmsKeySpec = String.enum('SYMMETRIC_DEFAULT', 'RSA_2048', 'RSA_3072', 'RSA_4096', 'ECC_NIST_P256', 'ECC_NIST_P384', 'ECC_NIST_P521', 'ECC_SECG_P256K1')
      KmsOrigin = String.enum('AWS_KMS', 'EXTERNAL', 'AWS_CLOUDHSM')
      KmsMultiRegion = Bool.default(false)
      
      # KMS key policy document (simplified - actual policies are complex JSON)
      KmsKeyPolicy = String.constrained(
        format: /\A\{.*\}\z/
      ).constructor { |value|
        # Basic validation that it's JSON-like
        begin
          JSON.parse(value)
          value
        rescue JSON::ParserError
          raise Dry::Types::ConstraintError, "KMS key policy must be valid JSON"
        end
      }
      
      # Secrets Manager-specific types
      SecretsManagerSecretType = String.enum('SecureString', 'String', 'StringList')
      SecretsManagerRecoveryWindowInDays = Integer.constrained(gteq: 7, lteq: 30).default(30)
      
      # Secret name validation (AWS Secrets Manager naming rules)
      SecretName = String.constrained(
        format: /\A[a-zA-Z0-9\/_+=.@-]{1,512}\z/
      ).constructor { |value|
        # Cannot start or end with a slash
        if value.start_with?('/') || value.end_with?('/')
          raise Dry::Types::ConstraintError, "Secret name cannot start or end with a slash"
        end
        
        # Cannot contain consecutive slashes
        if value.include?('//')
          raise Dry::Types::ConstraintError, "Secret name cannot contain consecutive slashes"
        end
        
        value
      }
      
      # Secret ARN pattern validation
      SecretArn = String.constrained(
        format: /\Aarn:aws:secretsmanager:[a-z0-9-]+:\d{12}:secret:[a-zA-Z0-9\/_+=.@-]+-[a-zA-Z0-9]{6}\z/
      )
      
      # Secret version stage names
      SecretVersionStage = String.enum('AWSCURRENT', 'AWSPENDING').constructor { |value|
        # Also allow custom stage names (alphanumeric, max 256 chars)
        if !['AWSCURRENT', 'AWSPENDING'].include?(value)
          unless value.match?(/\A[a-zA-Z0-9_]{1,256}\z/)
            raise Dry::Types::ConstraintError, "Custom version stage must be alphanumeric with underscores, max 256 characters"
          end
        end
        value
      }
      
      # Certificate transparency logging preference
      CertificateTransparencyLogging = String.default('ENABLED').enum('ENABLED', 'DISABLED')
      
      # ACM certificate validation options
      AcmValidationOption = Hash.schema(
        domain_name: DomainName,
        validation_domain?: DomainName.optional
      )
      
      # ACM domain validation option (for DNS validation)
      AcmDomainValidationOption = Hash.schema(
        domain_name: DomainName,
        resource_record_name?: String.optional,
        resource_record_type?: String.enum('CNAME', 'A', 'AAAA', 'TXT').optional,
        resource_record_value?: String.optional
      )
      
      # KMS key rotation - only valid for customer managed keys
      KmsEnableKeyRotation = Bool.constructor { |value, attrs|
        # This validation would need access to key attributes
        # For now, just pass through - validation happens in resource
        value
      }
      
      # Secrets Manager replica region configuration
      SecretsManagerReplicaRegion = Hash.schema(
        region: AwsRegion,
        kms_key_id?: String.optional
      )
      
      # Secret value types (for secret versions)
      SecretValue = String | Hash.map(String, String)
      
      # Secret binary value validation
      SecretBinary = String.constructor { |value|
        # Must be base64 encoded
        unless value.match?(/\A[A-Za-z0-9+\/]*={0,2}\z/)
          raise Dry::Types::ConstraintError, "Secret binary must be base64 encoded"
        end
        
        # Decode to validate it's proper base64
        begin
          Base64.decode64(value)
          value
        rescue ArgumentError
          raise Dry::Types::ConstraintError, "Secret binary must be valid base64"
        end
      }
      
      # Load Balancer Listener-specific types
      ListenerProtocol = String.enum('HTTP', 'HTTPS', 'TCP', 'TLS', 'UDP', 'TCP_UDP', 'GENEVE')
      
      ListenerPort = Integer.constrained(gteq: 1, lteq: 65535)
      
      # SSL policies for HTTPS/TLS listeners
      SslPolicy = String.enum(
        'ELBSecurityPolicy-TLS-1-0-2015-04',
        'ELBSecurityPolicy-TLS-1-1-2017-01',
        'ELBSecurityPolicy-TLS-1-2-2017-01',
        'ELBSecurityPolicy-TLS-1-2-Ext-2018-06',
        'ELBSecurityPolicy-FS-2018-06',
        'ELBSecurityPolicy-FS-1-1-2019-08',
        'ELBSecurityPolicy-FS-1-2-2019-08',
        'ELBSecurityPolicy-FS-1-2-Res-2019-08',
        'ELBSecurityPolicy-FS-1-2-Res-2020-10',
        'ELBSecurityPolicy-TLS-1-2-2017-01',
        'ELBSecurityPolicy-2016-08'
      )
      
      # Listener action types
      ListenerActionType = String.enum(
        'forward',
        'redirect', 
        'fixed-response',
        'authenticate-cognito',
        'authenticate-oidc'
      )
      
      # Listener rule condition types  
      ListenerConditionType = String.enum(
        'host-header',
        'path-pattern',
        'http-method',
        'query-string',
        'http-header',
        'source-ip'
      )
      
      # HTTP methods for listener rules
      HttpMethod = String.enum(
        'GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'OPTIONS', 'PATCH'
      )
      
      # Listener action forward configuration
      ListenerForwardAction = Hash.schema(
        target_groups: Array.of(
          Hash.schema(
            arn: String,
            weight?: Integer.constrained(gteq: 0, lteq: 999).default(100)
          )
        ).constrained(min_size: 1),
        stickiness?: Hash.schema(
          enabled: Bool,
          duration?: Integer.constrained(gteq: 1, lteq: 604800).optional
        ).optional
      )
      
      # Listener action redirect configuration
      ListenerRedirectAction = Hash.schema(
        protocol?: String.enum('HTTP', 'HTTPS', '#{protocol}').optional,
        port?: String.optional,
        host?: String.optional,
        path?: String.optional,
        query?: String.optional,
        status_code: String.enum('HTTP_301', 'HTTP_302')
      )
      
      # Listener action fixed response configuration
      ListenerFixedResponseAction = Hash.schema(
        content_type?: String.enum('text/plain', 'text/css', 'text/html', 'application/javascript', 'application/json').optional,
        message_body?: String.optional,
        status_code: String.constrained(format: /\A[1-5][0-9]{2}\z/)
      )
      
      # Listener action authenticate cognito configuration
      ListenerAuthenticateCognitoAction = Hash.schema(
        user_pool_arn: String.constrained(format: /\Aarn:aws:cognito-idp:/),
        user_pool_client_id: String,
        user_pool_domain: String,
        authentication_request_extra_params?: Hash.map(String, String).optional,
        on_unauthenticated_request?: String.enum('deny', 'allow', 'authenticate').optional,
        scope?: String.optional,
        session_cookie_name?: String.optional,
        session_timeout?: Integer.constrained(gteq: 1, lteq: 604800).optional
      )
      
      # Listener action authenticate OIDC configuration  
      ListenerAuthenticateOidcAction = Hash.schema(
        authorization_endpoint: String,
        client_id: String,
        client_secret: String,
        issuer: String,
        token_endpoint: String,
        user_info_endpoint: String,
        authentication_request_extra_params?: Hash.map(String, String).optional,
        on_unauthenticated_request?: String.enum('deny', 'allow', 'authenticate').optional,
        scope?: String.optional,
        session_cookie_name?: String.optional,
        session_timeout?: Integer.constrained(gteq: 1, lteq: 604800).optional
      )
      
      # Listener rule condition configurations
      ListenerConditionHostHeader = Hash.schema(
        values: Array.of(String).constrained(min_size: 1)
      )
      
      ListenerConditionPathPattern = Hash.schema(
        values: Array.of(String).constrained(min_size: 1)
      )
      
      ListenerConditionHttpMethod = Hash.schema(
        values: Array.of(HttpMethod).constrained(min_size: 1)
      )
      
      ListenerConditionQueryString = Hash.schema(
        values: Array.of(
          Hash.schema(
            key?: String.optional,
            value: String
          )
        ).constrained(min_size: 1)
      )
      
      ListenerConditionHttpHeader = Hash.schema(
        http_header_name: String,
        values: Array.of(String).constrained(min_size: 1)
      )
      
      ListenerConditionSourceIp = Hash.schema(
        values: Array.of(CidrBlock).constrained(min_size: 1)
      )
      
      # Target group attachment types
      TargetAttachmentType = String.enum('instance', 'ip', 'lambda', 'alb')
      
      # Target availability zone (required for IP targets in different AZ than ALB)
      TargetAvailabilityZone = AwsAvailabilityZone.optional
      
      # Transit Gateway-specific types
      
      # Transit Gateway ASN validation (16-bit: 64512-65534, 32-bit: 4200000000-4294967294)
      TransitGatewayAsn = Integer.constructor { |value|
        # Validate 16-bit ASN range
        if (64512..65534).include?(value)
          return value
        end
        
        # Validate 32-bit ASN range
        if (4200000000..4294967294).include?(value)
          return value
        end
        
        # AWS reserved ASNs
        reserved_asns = [7224, 9059, 10124, 17943]
        if reserved_asns.include?(value)
          raise Dry::Types::ConstraintError, "ASN #{value} is reserved by AWS"
        end
        
        raise Dry::Types::ConstraintError, "Transit Gateway ASN must be in range 64512-65534 (16-bit) or 4200000000-4294967294 (32-bit)"
      }
      
      # Transit Gateway default route table association/propagation
      TransitGatewayDefaultRouteTableAssociation = String.default('enable').enum('enable', 'disable')
      TransitGatewayDefaultRouteTablePropagation = String.default('enable').enum('enable', 'disable')
      
      # Transit Gateway DNS support
      TransitGatewayDnsSupport = String.default('enable').enum('enable', 'disable')
      
      # Transit Gateway multicast support
      TransitGatewayMulticastSupport = String.default('disable').enum('enable', 'disable')
      
      # Transit Gateway VPN ECMP support
      TransitGatewayVpnEcmpSupport = String.default('enable').enum('enable', 'disable')
      
      # Transit Gateway attachment types
      TransitGatewayAttachmentResourceType = String.enum(
        'vpc',
        'vpn', 
        'direct-connect-gateway',
        'peering',
        'tgw-peering'
      )
      
      # Transit Gateway route table route types
      TransitGatewayRouteType = String.enum('static', 'propagated')
      
      # Transit Gateway route state
      TransitGatewayRouteState = String.enum('active', 'blackhole')
      
      # Transit Gateway VPC attachment DNS support
      TransitGatewayVpcAttachmentDnsSupport = String.default('enable').enum('enable', 'disable')
      
      # Transit Gateway VPC attachment IPv6 support
      TransitGatewayVpcAttachmentIpv6Support = String.default('disable').enum('enable', 'disable')
      
      # Transit Gateway VPC attachment appliance mode support
      TransitGatewayVpcAttachmentApplianceModeSupport = String.default('disable').enum('enable', 'disable')
      
      # CIDR block validation for Transit Gateway routes
      TransitGatewayCidrBlock = String.constructor { |value|
        # Allow standard CIDR blocks
        if value.match?(/\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}\z/)
          # Validate IP address components
          ip, prefix = value.split('/')
          ip_parts = ip.split('.').map(&:to_i)
          prefix_int = prefix.to_i
          
          # Validate IP address octets
          unless ip_parts.all? { |octet| (0..255).include?(octet) }
            raise Dry::Types::ConstraintError, "Invalid IP address in CIDR block: #{value}"
          end
          
          # Validate prefix length
          unless (0..32).include?(prefix_int)
            raise Dry::Types::ConstraintError, "Invalid prefix length in CIDR block: #{value}. Must be 0-32."
          end
          
          return value
        end
        
        # Allow default route
        if value == '0.0.0.0/0'
          return value
        end
        
        raise Dry::Types::ConstraintError, "Transit Gateway CIDR block must be valid CIDR notation or '0.0.0.0/0'"
      }
      
      # AWS Security Services Types
      
      # WAF v2 Scope types
      WafV2Scope = String.enum('REGIONAL', 'CLOUDFRONT')
      
      # WAF v2 IP address version
      WafV2IpAddressVersion = String.enum('IPV4', 'IPV6')
      
      # WAF v2 Default actions
      WafV2DefaultAction = String.enum('ALLOW', 'BLOCK')
      
      # WAF v2 Rule action types
      WafV2RuleActionType = String.enum('ALLOW', 'BLOCK', 'COUNT', 'CAPTCHA', 'CHALLENGE')
      
      # WAF v2 Statement types
      WafV2StatementType = String.enum(
        'ByteMatchStatement',
        'SqliMatchStatement', 
        'XssMatchStatement',
        'SizeConstraintStatement',
        'GeoMatchStatement',
        'RuleGroupReferenceStatement',
        'IPSetReferenceStatement',
        'RegexPatternSetReferenceStatement',
        'RateBasedStatement',
        'AndStatement',
        'OrStatement',
        'NotStatement',
        'ManagedRuleGroupStatement',
        'LabelMatchStatement'
      )
      
      # WAF v2 Text transformation types
      WafV2TextTransformation = String.enum(
        'NONE',
        'COMPRESS_WHITE_SPACE',
        'HTML_ENTITY_DECODE',
        'LOWERCASE',
        'CMD_LINE',
        'URL_DECODE',
        'BASE64_DECODE',
        'HEX_DECODE',
        'MD5',
        'REPLACE_COMMENTS',
        'ESCAPE_SEQ_DECODE',
        'SQL_HEX_DECODE',
        'CSS_DECODE',
        'JS_DECODE',
        'NORMALIZE_PATH',
        'NORMALIZE_PATH_WIN',
        'REMOVE_NULLS',
        'REPLACE_NULLS',
        'BASE64_DECODE_EXT',
        'URL_DECODE_UNI',
        'UTF8_TO_UNICODE'
      )
      
      # WAF v2 Field to match types
      WafV2FieldToMatch = String.enum(
        'URI',
        'QUERY_STRING',
        'HEADER',
        'METHOD',
        'BODY',
        'SINGLE_HEADER',
        'SINGLE_QUERY_ARGUMENT',
        'ALL_QUERY_ARGUMENTS',
        'URI_PATH',
        'JSON_BODY',
        'HEADERS',
        'COOKIES'
      )
      
      # WAF v2 Compare operators
      WafV2ComparisonOperator = String.enum('EQ', 'NE', 'LE', 'LT', 'GE', 'GT')
      
      # WAF v2 Position constraint for ByteMatchStatement
      WafV2PositionalConstraint = String.enum('EXACTLY', 'STARTS_WITH', 'ENDS_WITH', 'CONTAINS', 'CONTAINS_WORD')
      
      # GuardDuty Finding Publishing Frequency
      GuardDutyFindingPublishingFrequency = String.enum('FIFTEEN_MINUTES', 'ONE_HOUR', 'SIX_HOURS')
      
      # GuardDuty Detector Status
      GuardDutyDetectorStatus = String.enum('ENABLED', 'DISABLED')
      
      # GuardDuty Data Source configurations
      GuardDutyDataSourceStatus = String.enum('ENABLED', 'DISABLED')
      
      # GuardDuty Threat Intel Set format
      GuardDutyThreatIntelSetFormat = String.enum('TXT', 'STIX', 'OTX_CSV', 'ALIEN_VAULT', 'PROOF_POINT', 'FIRE_EYE')
      
      # GuardDuty IP Set format  
      GuardDutyIpSetFormat = String.enum('TXT', 'STIX', 'OTX_CSV', 'ALIEN_VAULT', 'PROOF_POINT', 'FIRE_EYE')
      
      # GuardDuty Member invitation status
      GuardDutyMemberStatus = String.enum('CREATED', 'INVITED', 'DISABLED', 'ENABLED', 'REMOVED', 'RESIGNED')
      
      # Inspector v2 Resource types
      InspectorV2ResourceType = String.enum('ECR', 'EC2')
      
      # Inspector v2 Scan types
      InspectorV2ScanType = String.enum('NETWORK', 'PACKAGE')
      
      # Security Hub Standards
      SecurityHubStandardsArn = String.constrained(
        format: /\Aarn:aws:securityhub:[a-z0-9-]+::\w+\/\w+\/\w+\z/
      )
      
      # Security Hub Control Status
      SecurityHubControlStatus = String.enum('ENABLED', 'DISABLED')
      
      # Security Hub Compliance Status
      SecurityHubComplianceStatus = String.enum('PASSED', 'WARNING', 'FAILED', 'NOT_AVAILABLE')
      
      # Security Hub Severity
      SecurityHubSeverity = String.enum('INFORMATIONAL', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL')
      
      # Security Hub Record State
      SecurityHubRecordState = String.enum('ACTIVE', 'ARCHIVED')
      
      # Security Hub Workflow Status  
      SecurityHubWorkflowStatus = String.enum('NEW', 'NOTIFIED', 'RESOLVED', 'SUPPRESSED')
      
      # AWS Account ID validation
      AwsAccountId = String.constrained(
        format: /\A\d{12}\z/
      ).constructor { |value|
        unless value.length == 12 && value.match?(/\A\d+\z/)
          raise Dry::Types::ConstraintError, "AWS Account ID must be exactly 12 digits"
        end
        value
      }
      
      # Security service ARN patterns
      GuardDutyDetectorArn = String.constrained(
        format: /\Aarn:aws:guardduty:[a-z0-9-]+:\d{12}:detector\/[a-f0-9]{32}\z/
      )
      
      SecurityHubArn = String.constrained(
        format: /\Aarn:aws:securityhub:[a-z0-9-]+:\d{12}:hub\/default\z/
      )
      
      WafV2WebAclArn = String.constrained(
        format: /\Aarn:aws:wafv2:[a-z0-9-]+:\d{12}:(global|regional)\/webacl\/[a-zA-Z0-9_-]+\/[a-f0-9-]{36}\z/
      )
      
      # Email validation for GuardDuty invitations
      GuardDutyInvitationEmail = String.constrained(
        format: /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/
      ).constructor { |value|
        # Additional business rule validation
        if value.length > 320 # RFC 5321 limit
          raise Dry::Types::ConstraintError, "Email address cannot exceed 320 characters"
        end
        value
      }
      
      # WAF v2 Web ACL Capacity units validation
      WafV2CapacityUnits = Integer.constrained(gteq: 1, lteq: 1500)
      
      # WAF v2 Rate limit for rate-based rules  
      WafV2RateLimit = Integer.constrained(gteq: 100, lteq: 2000000000)
      
      # GuardDuty S3 bucket validation
      S3BucketName = String.constrained(
        format: /\A[a-z0-9][a-z0-9\-\.]{1,61}[a-z0-9]\z/
      ).constructor { |value|
        # Additional S3 bucket name rules
        if value.include?('..')
          raise Dry::Types::ConstraintError, "S3 bucket name cannot contain consecutive periods"
        end
        
        if value.match?(/\A\d+\.\d+\.\d+\.\d+\z/)
          raise Dry::Types::ConstraintError, "S3 bucket name cannot be formatted as IP address"
        end
        
        if value.start_with?('xn--')
          raise Dry::Types::ConstraintError, "S3 bucket name cannot start with 'xn--'"
        end
        
        if value.end_with?('-s3alias')
          raise Dry::Types::ConstraintError, "S3 bucket name cannot end with '-s3alias'"
        end
        
        value
      }
      
      # Inspector v2 scan status
      InspectorV2ScanStatus = String.enum('ENABLED', 'DISABLED', 'SUSPENDED')
      
      # WAF v2 JSON body configuration
      WafV2JsonBodyMatchPattern = Hash.schema(
        all?: Hash.schema({}).optional,
        included_paths?: Array.of(String).optional
      ).constructor { |value|
        # Must specify either 'all' or 'included_paths', but not both
        has_all = value.key?(:all)
        has_paths = value.key?(:included_paths) && value[:included_paths]&.any?
        
        if has_all && has_paths
          raise Dry::Types::ConstraintError, "WAF v2 JSON body match pattern cannot specify both 'all' and 'included_paths'"
        end
        
        if !has_all && !has_paths
          raise Dry::Types::ConstraintError, "WAF v2 JSON body match pattern must specify either 'all' or 'included_paths'"
        end
        
        value
      }

      # AWS IoT Core Types
      
      # IoT Thing name validation (1-128 characters, alphanumeric plus certain special chars)
      IotThingName = String.constrained(
        format: /\A[a-zA-Z0-9:_-]{1,128}\z/
      ).constructor { |value|
        # Cannot start with :, $, or #
        if value.start_with?(':', '$', '#')
          raise Dry::Types::ConstraintError, "IoT Thing name cannot start with ':', '$', or '#'"
        end
        value
      }
      
      # IoT Thing Type name validation
      IotThingTypeName = String.constrained(
        format: /\A[a-zA-Z0-9:_-]{1,128}\z/
      ).constructor { |value|
        # Cannot start with :, $, or #
        if value.start_with?(':', '$', '#')
          raise Dry::Types::ConstraintError, "IoT Thing Type name cannot start with ':', '$', or '#'"
        end
        value
      }
      
      # IoT Certificate status
      IotCertificateStatus = String.enum('ACTIVE', 'INACTIVE', 'REVOKED', 'PENDING_TRANSFER', 'REGISTER_INACTIVE', 'PENDING_ACTIVATION')
      
      # IoT Certificate format
      IotCertificateFormat = String.enum('PEM')
      
      # IoT Policy name validation (1-128 characters)
      IotPolicyName = String.constrained(
        format: /\A[a-zA-Z0-9:_-]{1,128}\z/
      ).constructor { |value|
        # Cannot start with :, $, or #
        if value.start_with?(':', '$', '#')
          raise Dry::Types::ConstraintError, "IoT Policy name cannot start with ':', '$', or '#'"
        end
        value
      }
      
      # IoT Policy document (JSON format)
      IotPolicyDocument = String.constructor { |value|
        begin
          parsed = JSON.parse(value)
          # Basic structure validation for IoT policy
          unless parsed.is_a?(Hash) && parsed['Version'] && parsed['Statement']
            raise Dry::Types::ConstraintError, "IoT Policy document must have 'Version' and 'Statement' fields"
          end
          value
        rescue JSON::ParserError
          raise Dry::Types::ConstraintError, "IoT Policy document must be valid JSON"
        end
      }
      
      # IoT Topic Rule name validation (1-128 characters)
      IotTopicRuleName = String.constrained(
        format: /\A[a-zA-Z0-9_]{1,128}\z/
      ).constructor { |value|
        # Must start with letter or underscore
        unless value.match?(/\A[a-zA-Z_]/)
          raise Dry::Types::ConstraintError, "IoT Topic Rule name must start with a letter or underscore"
        end
        value
      }
      
      # IoT SQL query string validation
      IotSqlQuery = String.constructor { |value|
        # Basic SQL validation - must start with SELECT
        unless value.strip.upcase.start_with?('SELECT')
          raise Dry::Types::ConstraintError, "IoT SQL query must start with SELECT"
        end
        
        # Check for required FROM clause
        unless value.upcase.include?('FROM')
          raise Dry::Types::ConstraintError, "IoT SQL query must include FROM clause"
        end
        
        value
      }
      
      # IoT Topic Rule destination confirmation status
      IotTopicRuleDestinationStatus = String.enum('ENABLED', 'DISABLED', 'IN_PROGRESS', 'ERROR')
      
      # IoT Topic Rule destination type
      IotTopicRuleDestinationType = String.enum('VPC')
      
      # IoT Security Profile name validation
      IotSecurityProfileName = String.constrained(
        format: /\A[a-zA-Z0-9:_-]{1,128}\z/
      ).constructor { |value|
        # Cannot start with :, $, or #
        if value.start_with?(':', '$', '#')
          raise Dry::Types::ConstraintError, "IoT Security Profile name cannot start with ':', '$', or '#'"
        end
        value
      }
      
      # IoT Device Defender behavior criteria types
      IotBehaviorCriteriaType = String.enum(
        'consecutive-datapoints-to-alarm',
        'consecutive-datapoints-to-clear',
        'statistical-threshold',
        'ml-detection-config'
      )
      
      # IoT Device Defender metric types
      IotMetricType = String.enum(
        'ip-count',
        'tcp-port-count', 
        'udp-port-count',
        'source-ip-count',
        'authorization-failure-count',
        'connection-attempt-count',
        'disconnection-count',
        'data-size-in-bytes',
        'message-count',
        'number-of-authorization-failures'
      )
      
      # IoT Device Defender statistical threshold
      IotStatisticalThreshold = Hash.schema(
        statistic?: String.optional
      )
      
      # IoT Device Defender ML detection config
      IotMlDetectionConfig = Hash.schema(
        confidence_level: String.enum('LOW', 'MEDIUM', 'HIGH')
      )
      
      # IoT Analytics Channel name validation (1-128 characters)
      IotAnalyticsChannelName = String.constrained(
        format: /\A[a-zA-Z0-9_]{1,128}\z/
      ).constructor { |value|
        # Must start with letter or underscore, cannot end with underscore
        unless value.match?(/\A[a-zA-Z_]/) && !value.end_with?('_')
          raise Dry::Types::ConstraintError, "IoT Analytics Channel name must start with letter or underscore and cannot end with underscore"
        end
        value
      }
      
      # IoT Analytics Datastore name validation (1-128 characters)
      IotAnalyticsDatastoreName = String.constrained(
        format: /\A[a-zA-Z0-9_]{1,128}\z/
      ).constructor { |value|
        # Must start with letter or underscore, cannot end with underscore
        unless value.match?(/\A[a-zA-Z_]/) && !value.end_with?('_')
          raise Dry::Types::ConstraintError, "IoT Analytics Datastore name must start with letter or underscore and cannot end with underscore"
        end
        value
      }
      
      # IoT Analytics retention period in days (1-2147483647)
      IotAnalyticsRetentionPeriod = Integer.constrained(gteq: 1, lteq: 2147483647)
      
      # IoT Analytics file format type
      IotAnalyticsFileFormatType = String.enum('JSON', 'PARQUET')
      
      # IoT Analytics dataset content type
      IotAnalyticsDatasetContentType = String.enum('CSV', 'JSON')
      
      # IoT MQTT topic validation
      IotMqttTopic = String.constructor { |value|
        # MQTT topic validation rules
        if value.length > 256
          raise Dry::Types::ConstraintError, "MQTT topic cannot exceed 256 characters"
        end
        
        # Cannot contain null character
        if value.include?("\0")
          raise Dry::Types::ConstraintError, "MQTT topic cannot contain null character"
        end
        
        # Wildcard validation for subscriptions
        if value.include?('+') || value.include?('#')
          # + can only be used at level boundaries
          if value.include?('+') && !value.match?(/\A([^+]*\+[^+]*\/)*[^+]*\+?[^+]*\z/)
            raise Dry::Types::ConstraintError, "MQTT topic wildcard '+' must be at topic level boundaries"
          end
          
          # # can only be at the end
          if value.include?('#') && !value.end_with?('#') && !value.end_with?('/#')
            raise Dry::Types::ConstraintError, "MQTT topic wildcard '#' must be at the end of topic"
          end
        end
        
        value
      }
      
      # IoT Thing attributes (key-value pairs with restrictions)
      IotThingAttributes = Hash.map(
        String.constrained(format: /\A[a-zA-Z0-9_-]{1,128}\z/),
        String.constrained(max_size: 800)
      ).constructor { |value|
        # Max 50 attributes per thing
        if value.keys.length > 50
          raise Dry::Types::ConstraintError, "IoT Thing cannot have more than 50 attributes"
        end
        
        # Check for reserved attribute names
        reserved_names = %w[thingName thingId thingTypeName]
        reserved_found = value.keys.map(&:to_s) & reserved_names
        unless reserved_found.empty?
          raise Dry::Types::ConstraintError, "IoT Thing attributes cannot use reserved names: #{reserved_found.join(', ')}"
        end
        
        value
      }
      
      # IoT Thing Type properties
      IotThingTypeProperties = Hash.schema(
        description?: String.constrained(max_size: 2028).optional,
        searchable_attributes?: Array.of(
          String.constrained(format: /\A[a-zA-Z0-9_-]{1,128}\z/)
        ).constrained(max_size: 3).optional
      )
      
      # IoT Certificate ARN validation
      IotCertificateArn = String.constrained(
        format: /\Aarn:aws:iot:[a-z0-9-]+:\d{12}:cert\/[a-f0-9]{64}\z/
      )
      
      # IoT Principal ARN (Certificate or Cognito Identity)
      IotPrincipalArn = String.constructor { |value|
        # Certificate ARN pattern
        cert_pattern = /\Aarn:aws:iot:[a-z0-9-]+:\d{12}:cert\/[a-f0-9]{64}\z/
        # Cognito Identity pattern
        cognito_pattern = /\Aarn:aws:cognito-identity:[a-z0-9-]+:\d{12}:identitypool\/[a-z0-9-]+:[a-f0-9-]+\z/
        
        unless value.match?(cert_pattern) || value.match?(cognito_pattern)
          raise Dry::Types::ConstraintError, "IoT Principal ARN must be a valid certificate or Cognito identity ARN"
        end
        
        value
      }
      
      # IoT Job execution status
      IotJobExecutionStatus = String.enum(
        'QUEUED', 'IN_PROGRESS', 'SUCCEEDED', 'FAILED', 'TIMED_OUT', 'REJECTED', 'REMOVED', 'CANCELED'
      )
      
      # IoT Job target selection
      IotJobTargetSelection = String.enum('CONTINUOUS', 'SNAPSHOT')
      
      # IoT OTA Update status
      IotOtaUpdateStatus = String.enum(
        'CREATE_PENDING', 'CREATE_IN_PROGRESS', 'CREATE_COMPLETE', 'CREATE_FAILED',
        'DELETE_IN_PROGRESS', 'DELETE_FAILED'
      )
      
      # IoT Fleet indexing configuration
      IotIndexingConfiguration = Hash.schema(
        thing_indexing_mode?: String.enum('OFF', 'REGISTRY', 'REGISTRY_AND_SHADOW').optional,
        thing_connectivity_indexing_mode?: String.enum('OFF', 'STATUS').optional
      )
      
      # IoT Logs level
      IotLogsLevel = String.enum('DEBUG', 'INFO', 'ERROR', 'WARN', 'DISABLED')
      
      # IoT Logs target type
      IotLogsTargetType = String.enum('DEFAULT', 'THING_GROUP')
      
      # IoT endpoint types
      IotEndpointType = String.enum('iot:Data', 'iot:Data-ATS', 'iot:CredentialProvider', 'iot:Jobs')
      
      # IoT Device Shadow service data (JSON format)
      IotShadowDocument = String.constructor { |value|
        begin
          parsed = JSON.parse(value)
          # Shadow document must be an object
          unless parsed.is_a?(Hash)
            raise Dry::Types::ConstraintError, "IoT Shadow document must be a JSON object"
          end
          
          # Check size limit (8KB for device shadow)
          if value.bytesize > 8192
            raise Dry::Types::ConstraintError, "IoT Shadow document cannot exceed 8KB"
          end
          
          value
        rescue JSON::ParserError
          raise Dry::Types::ConstraintError, "IoT Shadow document must be valid JSON"
        end
      }
      
      # IoT Analytics S3 bucket configuration
      IotAnalyticsS3Configuration = Hash.schema(
        bucket: S3BucketName,
        key?: String.optional,
        role_arn: String.constrained(format: /\Aarn:aws:iam::\d{12}:role\//),
        file_format_configuration?: Hash.schema(
          json_configuration?: Hash.schema({}).optional,
          parquet_configuration?: Hash.schema({}).optional
        ).optional
      )
      
      # IoT Analytics Lambda configuration
      IotAnalyticsLambdaConfiguration = Hash.schema(
        lambda_name: String.constrained(format: /\A[a-zA-Z0-9\-_]{1,64}\z/),
        batch_size?: Integer.constrained(gteq: 1, lteq: 1000).optional
      )
      
      # IoT Device Defender alert targets
      IotAlertTargetType = String.enum('SNS')
      
      # IoT Device Defender alert target configuration
      IotAlertTarget = Hash.schema(
        alert_target_arn: String.constrained(format: /\Aarn:aws:sns:/),
        role_arn: String.constrained(format: /\Aarn:aws:iam::\d{12}:role\//)
      )

      # IoT Billing group properties
      IotBillingGroupProperties = Hash.schema(
        billing_group_description?: String.constrained(max_size: 2028).optional
      )

      # IoT Dynamic group query string
      IotDynamicGroupQueryString = String.constructor { |value|
        # Must be a valid IoT fleet indexing query
        if value.length > 500
          raise Dry::Types::ConstraintError, "IoT Dynamic group query string cannot exceed 500 characters"
        end

        # Basic validation - should contain searchable attributes
        unless value.include?('attributes.') || value.include?('connectivity.') || value.include?('registry.')
          raise Dry::Types::ConstraintError, "IoT Dynamic group query must reference searchable attributes"
        end

        value
      }

      # ============================================================================
      # Cloudflare Types
      # ============================================================================

      # Cloudflare Zone Types
      CloudflareZoneType = String.default('full').enum('full', 'partial', 'secondary')
      CloudflareZonePlan = String.default('free').enum('free', 'pro', 'business', 'enterprise')
      CloudflareZoneStatus = String.enum('active', 'pending', 'initializing', 'moved', 'deleted', 'deactivated')

      # Cloudflare DNS Record Types
      CloudflareDnsRecordType = String.enum(
        'A', 'AAAA', 'CNAME', 'TXT', 'MX', 'NS', 'SRV', 'CAA',
        'HTTPS', 'SVCB', 'LOC', 'PTR', 'CERT', 'DNSKEY', 'DS',
        'NAPTR', 'SMIMEA', 'SSHFP', 'TLSA', 'URI'
      )

      # Cloudflare proxied status (orange cloud vs grey cloud)
      CloudflareProxied = Bool.default(false)

      # Cloudflare TTL validation (1 = automatic, or 60-86400 for manual)
      CloudflareTtl = Integer.constructor { |value|
        # TTL = 1 means automatic (proxied mode)
        next value if value == 1

        # Manual TTL must be between 60 and 86400 seconds
        unless (60..86400).include?(value)
          raise Dry::Types::ConstraintError, "Cloudflare TTL must be 1 (automatic) or between 60-86400 seconds"
        end

        value
      }

      # Cloudflare priority (for MX, SRV records)
      CloudflarePriority = Integer.constrained(gteq: 0, lteq: 65535)

      # Cloudflare Page Rule actions
      CloudflarePageRuleAction = String.enum(
        'always_online', 'always_use_https', 'automatic_https_rewrites',
        'browser_cache_ttl', 'browser_check', 'bypass_cache_on_cookie',
        'cache_by_device_type', 'cache_deception_armor', 'cache_key_fields',
        'cache_level', 'cache_on_cookie', 'cache_ttl_by_status',
        'disable_apps', 'disable_performance', 'disable_railgun',
        'disable_security', 'edge_cache_ttl', 'email_obfuscation',
        'explicit_cache_control', 'forwarding_url', 'host_header_override',
        'ip_geolocation', 'minify', 'mirage', 'opportunistic_encryption',
        'origin_error_page_pass_thru', 'polish', 'resolve_override',
        'respect_strong_etag', 'response_buffering', 'rocket_loader',
        'security_level', 'server_side_exclude', 'sort_query_string_for_cache',
        'ssl', 'true_client_ip_header', 'waf'
      )

      # Cloudflare cache level
      CloudflareCacheLevel = String.enum('bypass', 'basic', 'simplified', 'aggressive', 'cache_everything')

      # Cloudflare security level
      CloudflareSecurityLevel = String.enum('off', 'essentially_off', 'low', 'medium', 'high', 'under_attack')

      # Cloudflare SSL mode
      CloudflareSslMode = String.enum('off', 'flexible', 'full', 'strict', 'origin_pull')

      # Cloudflare Rocket Loader setting
      CloudflareRocketLoader = String.enum('off', 'manual', 'automatic')

      # Cloudflare Polish setting
      CloudflarePolish = String.enum('off', 'lossless', 'lossy')

      # Cloudflare Worker script format
      CloudflareWorkerScriptFormat = String.enum('service-worker', 'modules')

      # Cloudflare Worker route pattern validation
      CloudflareWorkerRoutePattern = String.constructor { |value|
        # Must contain a valid hostname pattern
        unless value.match?(/\A[a-z0-9\-\.\*]+\/.*\z/i)
          raise Dry::Types::ConstraintError, "Worker route pattern must include hostname and path (e.g., 'example.com/*')"
        end

        # Cannot have multiple consecutive asterisks
        if value.include?('**')
          raise Dry::Types::ConstraintError, "Worker route pattern cannot contain consecutive asterisks"
        end

        value
      }

      # Cloudflare Load Balancer steering policy
      CloudflareLoadBalancerSteeringPolicy = String.default('off').enum(
        'off', 'geo', 'random', 'dynamic_latency', 'proximity', 'least_outstanding_requests', 'least_connections'
      )

      # Cloudflare Load Balancer session affinity
      CloudflareLoadBalancerSessionAffinity = String.default('none').enum('none', 'cookie', 'ip_cookie', 'header')

      # Cloudflare Load Balancer fallback pool
      CloudflareLoadBalancerFallbackPool = String.optional

      # Cloudflare Load Balancer Pool health check region
      CloudflareHealthCheckRegion = String.enum(
        'WNAM', 'ENAM', 'WEU', 'EEU', 'NSAM', 'SSAM', 'OC', 'ME', 'NAF', 'SAF',
        'SAS', 'SEAS', 'NEAS', 'ALL_REGIONS'
      )

      # Cloudflare Load Balancer Monitor type
      CloudflareMonitorType = String.default('http').enum('http', 'https', 'tcp', 'udp_icmp', 'icmp_ping', 'smtp')

      # Cloudflare Load Balancer Monitor method
      CloudflareMonitorMethod = String.default('GET').enum('GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'CONNECT', 'OPTIONS', 'TRACE', 'PATCH')

      # Cloudflare Load Balancer Monitor interval (in seconds)
      CloudflareMonitorInterval = Integer.constrained(gteq: 5, lteq: 3600)

      # Cloudflare Load Balancer Monitor timeout (in seconds)
      CloudflareMonitorTimeout = Integer.constrained(gteq: 1, lteq: 10)

      # Cloudflare Load Balancer Monitor retries
      CloudflareMonitorRetries = Integer.constrained(gteq: 0, lteq: 5)

      # Cloudflare Load Balancer Monitor expected codes (e.g., "2xx", "200-299")
      CloudflareMonitorExpectedCodes = String.constructor { |value|
        # Valid formats: "2xx", "200", "200-299"
        valid_formats = [
          /\A\dxx\z/,                    # 2xx, 3xx, etc.
          /\A\d{3}\z/,                   # 200, 404, etc.
          /\A\d{3}-\d{3}\z/              # 200-299, etc.
        ]

        unless valid_formats.any? { |pattern| value.match?(pattern) }
          raise Dry::Types::ConstraintError, "Monitor expected codes must be in format '2xx', '200', or '200-299'"
        end

        value
      }

      # Cloudflare Firewall rule action
      CloudflareFirewallAction = String.enum(
        'block', 'challenge', 'js_challenge', 'managed_challenge', 'allow', 'log', 'bypass'
      )

      # Cloudflare Filter expression (Wirefilter syntax)
      CloudflareFilterExpression = String.constructor { |value|
        # Basic validation - must not be empty
        if value.strip.empty?
          raise Dry::Types::ConstraintError, "Filter expression cannot be empty"
        end

        # Check for common fields to ensure it's likely valid
        common_fields = ['http.', 'ip.', 'cf.', 'ssl.', 'http.request.', 'http.host', 'http.user_agent']
        unless common_fields.any? { |field| value.include?(field) }
          # Allow it anyway, but it might be suspicious
        end

        value
      }

      # Cloudflare Access application type
      CloudflareAccessApplicationType = String.enum('self_hosted', 'saas', 'ssh', 'vnc', 'app_launcher', 'warp', 'biso', 'bookmark')

      # Cloudflare Access session duration
      CloudflareAccessSessionDuration = String.constructor { |value|
        # Valid formats: "24h", "12h", "30m", "1h"
        unless value.match?(/\A\d+[mhd]\z/)
          raise Dry::Types::ConstraintError, "Access session duration must be in format like '24h', '30m', '7d'"
        end

        value
      }

      # Cloudflare Access policy decision
      CloudflareAccessPolicyDecision = String.enum('allow', 'deny', 'non_identity', 'bypass')

      # Cloudflare Access identity provider type
      CloudflareAccessIdentityProviderType = String.enum(
        'onetimepin', 'azureAD', 'saml', 'centrify', 'facebook',
        'github', 'google-apps', 'google', 'linkedin', 'oidc',
        'okta', 'onelogin', 'pingone', 'yandex'
      )

      # Cloudflare Rate Limit threshold
      CloudflareRateLimitThreshold = Integer.constrained(gteq: 2, lteq: 1000000)

      # Cloudflare Rate Limit period (in seconds)
      CloudflareRateLimitPeriod = Integer.constrained(gteq: 1, lteq: 86400)

      # Cloudflare Rate Limit action mode
      CloudflareRateLimitActionMode = String.enum('simulate', 'ban', 'challenge', 'js_challenge', 'managed_challenge')

      # Cloudflare Rate Limit action timeout (in seconds)
      CloudflareRateLimitActionTimeout = Integer.constrained(gteq: 10, lteq: 86400)

      # Cloudflare Argo smart routing
      CloudflareArgoSmartRouting = String.enum('on', 'off')

      # Cloudflare Argo Tiered Caching
      CloudflareArgoTieredCaching = String.enum('on', 'off')

      # Cloudflare Logpush job dataset
      CloudflareLogpushDataset = String.enum(
        'http_requests', 'spectrum_events', 'firewall_events', 'nel_reports',
        'dns_logs', 'network_analytics_logs', 'workers_trace_events',
        'access_requests', 'gateway_dns', 'gateway_http', 'gateway_network'
      )

      # Cloudflare Logpush destination type
      CloudflareLogpushDestinationType = String.enum('s3', 'gcs', 'azure', 'sumo_logic', 'splunk', 'datadog')

      # Cloudflare Logpush frequency
      CloudflareLogpushFrequency = String.enum('high', 'low')

      # Cloudflare Spectrum application protocol
      CloudflareSpectrumProtocol = String.enum('tcp/22', 'tcp/80', 'tcp/443', 'tcp/3389', 'tcp/8080', 'udp/53')

      # Cloudflare Spectrum edge IP connectivity
      CloudflareSpectrumEdgeIpConnectivity = String.enum('all', 'ipv4', 'ipv6')

      # Cloudflare Spectrum TLS mode
      CloudflareSpectrumTls = String.enum('off', 'flexible', 'full', 'strict')

      # Cloudflare Custom Hostname SSL method
      CloudflareCustomHostnameSslMethod = String.enum('http', 'txt', 'email')

      # Cloudflare Custom Hostname SSL type
      CloudflareCustomHostnameSslType = String.enum('dv')

      # Cloudflare Custom Hostname SSL settings
      CloudflareCustomHostnameSslSettings = Hash.schema(
        http2?: String.enum('on', 'off').optional,
        http3?: String.enum('on', 'off').optional,
        tls_1_3?: String.enum('on', 'off').optional,
        min_tls_version?: String.enum('1.0', '1.1', '1.2', '1.3').optional,
        ciphers?: Array.of(String).optional
      )

      # Cloudflare WAF rule mode
      CloudflareWafRuleMode = String.enum('default', 'disable', 'simulate', 'block', 'challenge')

      # Cloudflare WAF package sensitivity
      CloudflareWafPackageSensitivity = String.enum('high', 'medium', 'low', 'off')

      # Cloudflare WAF package action mode
      CloudflareWafPackageActionMode = String.enum('simulate', 'block', 'challenge')

      # Cloudflare Zone ID validation
      # Accepts both valid 32-char hex IDs and Terraform interpolation strings
      CloudflareZoneId = String.constructor { |value|
        # Allow Terraform interpolation strings
        next value if value.match?(/\A\$\{.+\}\z/)

        # Validate as 32-character hex zone ID
        unless value.match?(/\A[a-f0-9]{32}\z/)
          raise Dry::Types::ConstraintError, "Cloudflare Zone ID must be 32-character hex or a Terraform interpolation string"
        end

        value
      }

      # Cloudflare Account ID validation
      # Accepts both valid 32-char hex IDs and Terraform interpolation strings
      CloudflareAccountId = String.constructor { |value|
        # Allow Terraform interpolation strings
        next value if value.match?(/\A\$\{.+\}\z/)

        # Validate as 32-character hex account ID
        unless value.match?(/\A[a-f0-9]{32}\z/)
          raise Dry::Types::ConstraintError, "Cloudflare Account ID must be 32-character hex or a Terraform interpolation string"
        end

        value
      }

      # Cloudflare API Token validation (40 character hex)
      CloudflareApiToken = String.constrained(
        min_size: 40,
        max_size: 40
      )

      # Cloudflare Email validation
      CloudflareEmail = String.constrained(
        format: /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/
      )

      # Cloudflare origin pool configuration
      CloudflareOriginPoolOrigin = Hash.schema(
        name: String,
        address: String,  # IP or hostname
        enabled?: Bool.default(true),
        weight?: Integer.constrained(gteq: 0, lteq: 1).default(1),
        header?: Hash.map(String, String).optional
      )

      # Cloudflare Load Balancer region pool
      CloudflareRegionPool = Hash.schema(
        region: CloudflareHealthCheckRegion,
        pool_ids: Array.of(String).constrained(min_size: 1)
      )

      # Cloudflare Load Balancer pop pool
      CloudflarePopPool = Hash.schema(
        pop: String.constrained(format: /\A[A-Z]{3}\z/),  # 3-letter airport code
        pool_ids: Array.of(String).constrained(min_size: 1)
      )

      # Cloudflare Load Balancer adaptive routing
      CloudflareAdaptiveRouting = Hash.schema(
        failover_across_pools?: Bool.default(false)
      )

      # Cloudflare Load Balancer location strategy
      CloudflareLocationStrategy = Hash.schema(
        prefer_ecs?: String.enum('always', 'never', 'proximity', 'geo').optional,
        mode?: String.enum('pop', 'resolver_ip').optional
      )

      # Cloudflare Load Balancer random steering
      CloudflareRandomSteering = Hash.schema(
        pool_weights: Hash.map(String, Integer.constrained(gteq: 0, lteq: 1))
      )

      # Cloudflare Access CORS headers
      CloudflareAccessCorsHeaders = Hash.schema(
        allowed_methods?: Array.of(String).optional,
        allowed_origins?: Array.of(String).optional,
        allow_credentials?: Bool.optional,
        max_age?: Integer.optional
      )

      # Cloudflare Access include/exclude configuration
      CloudflareAccessRuleConfiguration = Hash.schema(
        email?: Array.of(String).optional,
        email_domain?: Array.of(String).optional,
        ip?: Array.of(String).optional,
        ip_list?: Array.of(String).optional,
        everyone?: Bool.optional,
        certificate?: Bool.optional,
        common_name?: String.optional,
        auth_method?: String.optional,
        geo?: Array.of(String).optional,
        login_method?: Array.of(String).optional,
        service_token?: Array.of(String).optional,
        any_valid_service_token?: Bool.optional,
        group?: Array.of(String).optional,
        azure?: Array.of(Hash).optional,
        github?: Array.of(Hash).optional,
        google?: Array.of(Hash).optional,
        okta?: Array.of(Hash).optional,
        saml?: Array.of(Hash).optional
      )

      # Cloudflare common tags
      CloudflareTags = Hash.map(String, String).default({}.freeze)

      # ======================================================================
      # Hetzner Cloud Types
      # ======================================================================

      # Hetzner datacenter locations
      HetznerLocation = String.enum(
        'fsn1',  # Falkenstein, Germany
        'nbg1',  # Nuremberg, Germany
        'hel1',  # Helsinki, Finland
        'ash',   # Ashburn, Virginia, USA
        'hil',   # Hillsboro, Oregon, USA
        'sin'    # Singapore
      )

      # Hetzner server types by series
      HetznerServerType = String.enum(
        # CX Series - Cost-Optimized x86
        'cx23', 'cx33', 'cx43', 'cx53',
        # CAX Series - Cost-Optimized ARM
        'cax11', 'cax21', 'cax31', 'cax41',
        # CPX Series - Shared AMD (legacy)
        'cpx11', 'cpx21', 'cpx31', 'cpx41', 'cpx51',
        # CCX Series - Dedicated AMD EPYC
        'ccx13', 'ccx23', 'ccx33', 'ccx43', 'ccx53', 'ccx63'
      )

      # Hetzner network zones
      HetznerNetworkZone = String.enum(
        'eu-central',    # Helsinki, Falkenstein, Nuremberg
        'us-east',       # Ashburn
        'us-west',       # Hillsboro
        'ap-southeast'   # Singapore
      )

      # Hetzner firewall rule direction
      HetznerFirewallDirection = String.enum('in', 'out')

      # Hetzner firewall protocols
      HetznerFirewallProtocol = String.enum('tcp', 'udp', 'icmp', 'esp', 'gre')

      # Hetzner load balancer types
      HetznerLoadBalancerType = String.enum(
        'lb11',  # 10k connections, 5 services, 25 targets
        'lb21',  # 20k connections, 15 services, 75 targets
        'lb31'   # 40k connections, 30 services, 150 targets
      )

      # Hetzner load balancing algorithms
      HetznerLoadBalancerAlgorithm = String.enum('round_robin', 'least_connections')

      # Hetzner certificate types
      HetznerCertificateType = String.enum('uploaded', 'managed')

      # Hetzner volume filesystem formats
      HetznerVolumeFormat = String.enum('xfs', 'ext4')

      # Hetzner server ID (positive integer)
      HetznerServerId = Integer.constrained(gteq: 1)

      # IPv4 address validation
      HetznerIpv4 = String.constrained(
        format: /\A(?:[0-9]{1,3}\.){3}[0-9]{1,3}\z/
      )

      # IPv6 address/range validation
      HetznerIpv6 = String.constrained(
        format: /\A(?:[0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}(\/\d{1,3})?\z/
      )

      # Hetzner image name (OS images)
      HetznerImageName = String.constrained(
        format: /\A[a-z0-9\-\.]+\z/
      )

      # Hetzner placement group types
      HetznerPlacementGroupType = String.enum('spread')

      # Hetzner load balancer protocol
      HetznerLoadBalancerProtocol = String.enum('http', 'https', 'tcp')

      # Hetzner load balancer health check protocol
      HetznerHealthCheckProtocol = String.enum('http', 'https', 'tcp')

      # Hetzner network subnet type
      HetznerSubnetType = String.enum('cloud', 'server', 'vswitch')

      # Hetzner common labels (like tags)
      HetznerLabels = Hash.map(String, String).default({}.freeze)

      # Hetzner firewall rule
      HetznerFirewallRule = Hash.schema(
        direction: HetznerFirewallDirection,
        protocol: HetznerFirewallProtocol,
        port?: String.optional,
        source_ips?: Array.of(String).optional,
        destination_ips?: Array.of(String).optional,
        description?: String.optional
      )

      # Hetzner DNS record types
      HetznerDnsRecordType = String.enum(
        'A', 'AAAA', 'NS', 'MX', 'CNAME', 'RP', 'TXT', 'SOA', 'HINFO',
        'SRV', 'DANE', 'TLSA', 'DS', 'CAA'
      )

      # Hetzner DNS zone TTL (60-86400 seconds)
      HetznerDnsZoneTtl = Integer.constrained(gteq: 60, lteq: 86400).default(86400)

      # Hetzner DNS record TTL
      HetznerDnsRecordTtl = Integer.constrained(gteq: 60, lteq: 86400)

      # Hetzner snapshot type
      HetznerSnapshotType = String.enum('snapshot')

      # Hetzner PEM certificate validation
      HetznerPemCertificate = String.constructor { |value|
        # Must start with PEM header
        unless value.strip.start_with?('-----BEGIN CERTIFICATE-----')
          raise Dry::Types::ConstraintError, "Certificate must be in PEM format starting with '-----BEGIN CERTIFICATE-----'"
        end

        # Must end with PEM footer
        unless value.strip.end_with?('-----END CERTIFICATE-----')
          raise Dry::Types::ConstraintError, "Certificate must be in PEM format ending with '-----END CERTIFICATE-----'"
        end

        value
      }

      # Hetzner PEM private key validation
      HetznerPemPrivateKey = String.constructor { |value|
        # Accept various private key formats
        valid_headers = [
          '-----BEGIN PRIVATE KEY-----',
          '-----BEGIN RSA PRIVATE KEY-----',
          '-----BEGIN EC PRIVATE KEY-----',
          '-----BEGIN ENCRYPTED PRIVATE KEY-----'
        ]

        unless valid_headers.any? { |header| value.strip.start_with?(header) }
          raise Dry::Types::ConstraintError, "Private key must be in PEM format"
        end

        value
      }

      # Hetzner volume size validation (10-10000 GB)
      HetznerVolumeSize = Integer.constrained(gteq: 10, lteq: 10000)
    end
  end
end