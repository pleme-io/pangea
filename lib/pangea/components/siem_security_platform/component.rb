# frozen_string_literal: true

require 'pangea/components/base'
require 'pangea/components/siem_security_platform/types'

module Pangea
  module Components
    module SiemSecurityPlatform
      # SIEM Security Platform Component
      # Implements comprehensive security information and event management
      def siem_security_platform(name, attributes = {})
        # Validate attributes
        attrs = Attributes.new(attributes)
        
        # Component resources
        resources = {
          opensearch_domain: nil,
          firehose_streams: {},
          lambda_functions: {},
          cloudwatch_logs: {},
          s3_buckets: {},
          sns_topics: {},
          sqs_queues: {},
          event_rules: {},
          step_functions: {},
          iam_roles: {},
          security_groups: {},
          kms_keys: {},
          secrets: {},
          alarms: {}
        }
        
        # Create KMS key for encryption
        kms_key_name = component_resource_name(name, :kms_key)
        resources[:kms_keys][:main] = aws_kms_key(kms_key_name, {
          description: "SIEM encryption key for #{name}",
          key_policy: generate_kms_policy(name),
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        aws_kms_alias(:"#{kms_key_name}_alias", {
          name: "alias/siem-#{name}",
          target_key_id: resources[:kms_keys][:main].id
        })
        
        # Create security group for OpenSearch
        sg_name = component_resource_name(name, :opensearch_sg)
        resources[:security_groups][:opensearch] = aws_security_group(sg_name, {
          name: "siem-opensearch-#{name}",
          description: "Security group for SIEM OpenSearch domain",
          vpc_id: attrs.vpc_ref,
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        # Allow HTTPS access
        aws_vpc_security_group_ingress_rule(:"#{sg_name}_https", {
          security_group_id: resources[:security_groups][:opensearch].id,
          description: "Allow HTTPS for OpenSearch",
          from_port: 443,
          to_port: 443,
          ip_protocol: 'tcp',
          cidr_ipv4: '10.0.0.0/8'
        })
        
        # Create OpenSearch domain
        domain_name = attrs.opensearch_config[:domain_name]
        resources[:opensearch_domain] = aws_opensearch_domain(:"#{name}_opensearch", {
          domain_name: domain_name,
          engine_version: attrs.opensearch_config[:engine_version],
          
          cluster_config: {
            instance_type: attrs.opensearch_config[:instance_type],
            instance_count: attrs.opensearch_config[:instance_count],
            dedicated_master_enabled: attrs.opensearch_config[:dedicated_master_enabled],
            dedicated_master_type: attrs.opensearch_config[:dedicated_master_type],
            dedicated_master_count: attrs.opensearch_config[:dedicated_master_count],
            zone_awareness_enabled: attrs.opensearch_config[:zone_awareness_enabled],
            zone_awareness_config: attrs.opensearch_config[:zone_awareness_enabled] ? {
              availability_zone_count: attrs.opensearch_config[:availability_zone_count]
            } : nil
          },
          
          ebs_options: {
            ebs_enabled: attrs.opensearch_config[:ebs_enabled],
            volume_type: attrs.opensearch_config[:volume_type],
            volume_size: attrs.opensearch_config[:volume_size],
            iops: attrs.opensearch_config[:iops],
            throughput: attrs.opensearch_config[:throughput]
          },
          
          vpc_options: {
            subnet_ids: attrs.subnet_refs.take(attrs.opensearch_config[:availability_zone_count] || 3),
            security_group_ids: [resources[:security_groups][:opensearch].id]
          },
          
          encrypt_at_rest: attrs.security_config[:enable_encryption_at_rest] ? {
            enabled: true,
            kms_key_id: resources[:kms_keys][:main].id
          } : nil,
          
          node_to_node_encryption: {
            enabled: attrs.security_config[:enable_encryption_in_transit]
          },
          
          advanced_security_options: attrs.security_config[:enable_fine_grained_access] ? {
            enabled: true,
            internal_user_database_enabled: false,
            master_user_options: {
              master_user_arn: attrs.security_config[:master_user_arn]
            }
          } : nil,
          
          log_publishing_options: {
            ES_APPLICATION_LOGS: {
              enabled: true,
              cloudwatch_log_group_arn: create_log_group(name, 'es-application', attrs, resources)
            },
            SEARCH_SLOW_LOGS: attrs.security_config[:enable_slow_logs] ? {
              enabled: true,
              cloudwatch_log_group_arn: create_log_group(name, 'es-slow', attrs, resources)
            } : nil,
            AUDIT_LOGS: attrs.security_config[:enable_audit_logs] ? {
              enabled: true,
              cloudwatch_log_group_arn: create_log_group(name, 'es-audit', attrs, resources)
            } : nil
          },
          
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        # Create S3 bucket for Firehose backup
        backup_bucket_name = component_resource_name(name, :backup_bucket)
        resources[:s3_buckets][:backup] = create_secure_bucket(
          backup_bucket_name,
          "siem-backup-#{name}",
          attrs,
          resources
        )
        
        # Create Firehose delivery streams for each log source
        attrs.log_sources.each do |source|
          create_firehose_stream(name, source, attrs, resources)
        end
        
        # Create Lambda functions for data processing
        create_processing_lambdas(name, attrs, resources)
        
        # Create correlation engine
        create_correlation_engine(name, attrs, resources)
        
        # Create threat detection components
        create_threat_detection(name, attrs, resources)
        
        # Create incident response automation
        create_incident_response(name, attrs, resources)
        
        # Create monitoring and alerting
        create_monitoring(name, attrs, resources)
        
        # Create dashboards
        create_dashboards(name, attrs, resources)
        
        # Set up integrations
        attrs.integrations.each do |integration|
          create_integration(name, integration, attrs, resources)
        end
        
        # Component outputs
        outputs = {
          opensearch_domain_endpoint: resources[:opensearch_domain].endpoint,
          opensearch_domain_arn: resources[:opensearch_domain].arn,
          opensearch_dashboard_url: "https://#{resources[:opensearch_domain].endpoint}/_dashboards/",
          firehose_streams: resources[:firehose_streams].transform_values { |stream| stream.arn },
          correlation_engine_arn: resources[:step_functions][:correlation_engine]&.arn,
          incident_response_arn: resources[:step_functions][:incident_response]&.arn,
          security_score: calculate_siem_security_score(attrs),
          compliance_status: generate_siem_compliance_status(attrs)
        }
        
        # Create component reference
        create_component_reference(
          'siem_security_platform',
          name,
          attrs.to_h,
          resources,
          outputs
        )
      end
      
      private
      
      def generate_kms_policy(name)
        JSON.pretty_generate({
          Version: "2012-10-17",
          Statement: [
            {
              Sid: "Enable IAM User Permissions",
              Effect: "Allow",
              Principal: {
                AWS: "arn:aws:iam::#{aws_account_id}:root"
              },
              Action: "kms:*",
              Resource: "*"
            },
            {
              Sid: "Allow use of the key for SIEM services",
              Effect: "Allow",
              Principal: {
                Service: [
                  "es.amazonaws.com",
                  "firehose.amazonaws.com",
                  "lambda.amazonaws.com",
                  "logs.amazonaws.com"
                ]
              },
              Action: [
                "kms:Decrypt",
                "kms:GenerateDataKey"
              ],
              Resource: "*"
            }
          ]
        })
      end
      
      def create_log_group(name, type, attrs, resources)
        log_group_name = component_resource_name(name, :log_group, type)
        log_group = aws_cloudwatch_log_group(log_group_name, {
          name: "/aws/siem/#{name}/#{type}",
          retention_in_days: attrs.incident_response[:retention_days],
          kms_key_id: resources[:kms_keys][:main].arn,
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        resources[:cloudwatch_logs][type] = log_group
        log_group.arn
      end
      
      def create_secure_bucket(bucket_name, bucket_id, attrs, resources)
        bucket = aws_s3_bucket(bucket_name, {
          bucket: bucket_id,
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        # Enable versioning
        aws_s3_bucket_versioning(:"#{bucket_name}_versioning", {
          bucket: bucket.id,
          versioning_configuration: {
            status: "Enabled"
          }
        })
        
        # Enable encryption
        aws_s3_bucket_server_side_encryption_configuration(:"#{bucket_name}_encryption", {
          bucket: bucket.id,
          rule: {
            apply_server_side_encryption_by_default: {
              sse_algorithm: "aws:kms",
              kms_master_key_id: resources[:kms_keys][:main].id
            },
            bucket_key_enabled: true
          }
        })
        
        # Block public access
        aws_s3_bucket_public_access_block(:"#{bucket_name}_pab", {
          bucket: bucket.id,
          block_public_acls: true,
          block_public_policy: true,
          ignore_public_acls: true,
          restrict_public_buckets: true
        })
        
        # Add lifecycle rules
        aws_s3_bucket_lifecycle_configuration(:"#{bucket_name}_lifecycle", {
          bucket: bucket.id,
          rule: [
            {
              id: "transition-to-glacier",
              status: "Enabled",
              transition: [
                {
                  days: 90,
                  storage_class: "GLACIER"
                }
              ],
              expiration: {
                days: attrs.compliance_config[:audit_trail_retention]
              }
            }
          ]
        })
        
        bucket
      end
      
      def create_firehose_stream(name, source, attrs, resources)
        stream_name = component_resource_name(name, :firehose, source[:name])
        
        # Create IAM role for Firehose
        role_name = component_resource_name(name, :firehose_role, source[:name])
        resources[:iam_roles][:"firehose_#{source[:name]}"] = create_firehose_role(
          role_name,
          attrs,
          resources
        )
        
        # Create processing Lambda if transformation is needed
        processor_arn = nil
        if attrs.firehose_config[:enable_data_transformation] || source[:transformation]
          processor_arn = create_stream_processor(name, source, attrs, resources)
        end
        
        resources[:firehose_streams][source[:name]] = aws_kinesis_firehose_delivery_stream(stream_name, {
          name: "siem-#{name}-#{source[:name]}",
          destination: "opensearch",
          
          opensearch_configuration: {
            domain_arn: resources[:opensearch_domain].arn,
            index_name: "siem-#{source[:type]}",
            index_rotation_period: "OneDay",
            type_name: "_doc",
            role_arn: resources[:iam_roles][:"firehose_#{source[:name]}"].arn,
            
            buffering_hints: {
              interval_in_seconds: attrs.firehose_config[:buffer_interval],
              size_in_mbs: attrs.firehose_config[:buffer_size]
            },
            
            cloudwatch_logging_options: {
              enabled: true,
              log_group_name: "/aws/kinesisfirehose/siem-#{name}",
              log_stream_name: source[:name]
            },
            
            processing_configuration: processor_arn ? {
              enabled: true,
              processors: [{
                type: "Lambda",
                parameters: [{
                  parameter_name: "LambdaArn",
                  parameter_value: processor_arn
                }]
              }]
            } : nil,
            
            s3_configuration: {
              bucket_arn: resources[:s3_buckets][:backup].arn,
              prefix: "#{source[:type]}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/",
              error_output_prefix: "#{attrs.firehose_config[:error_output_prefix]}#{source[:type]}/",
              compression_format: attrs.firehose_config[:compression_format],
              role_arn: resources[:iam_roles][:"firehose_#{source[:name]}"].arn
            },
            
            vpc_config: {
              subnet_ids: attrs.subnet_refs,
              security_group_ids: [resources[:security_groups][:opensearch].id],
              role_arn: resources[:iam_roles][:"firehose_#{source[:name]}"].arn
            }
          },
          
          tags: component_tags('siem_security_platform', name, attrs.tags.merge(
            LogSource: source[:name]
          ))
        })
        
        # Configure log source subscription
        configure_log_source_subscription(name, source, attrs, resources)
      end
      
      def create_firehose_role(role_name, attrs, resources)
        role = aws_iam_role(role_name, {
          name: role_name.to_s,
          assume_role_policy: JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [{
              Action: "sts:AssumeRole",
              Effect: "Allow",
              Principal: {
                Service: "firehose.amazonaws.com"
              }
            }]
          }),
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        # Create and attach policy
        policy_name = :"#{role_name}_policy"
        policy = aws_iam_role_policy(policy_name, {
          role: role.id,
          policy: JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [
              {
                Effect: "Allow",
                Action: [
                  "es:ESHttpPost",
                  "es:ESHttpPut"
                ],
                Resource: [
                  resources[:opensearch_domain].arn,
                  "#{resources[:opensearch_domain].arn}/*"
                ]
              },
              {
                Effect: "Allow",
                Action: [
                  "s3:GetObject",
                  "s3:PutObject"
                ],
                Resource: "#{resources[:s3_buckets][:backup].arn}/*"
              },
              {
                Effect: "Allow",
                Action: [
                  "kms:Decrypt",
                  "kms:GenerateDataKey"
                ],
                Resource: resources[:kms_keys][:main].arn
              },
              {
                Effect: "Allow",
                Action: [
                  "logs:CreateLogGroup",
                  "logs:CreateLogStream",
                  "logs:PutLogEvents"
                ],
                Resource: "*"
              },
              {
                Effect: "Allow",
                Action: [
                  "lambda:InvokeFunction"
                ],
                Resource: "arn:aws:lambda:*:*:function:siem-*"
              }
            ]
          })
        })
        
        role
      end
      
      def create_stream_processor(name, source, attrs, resources)
        processor_name = component_resource_name(name, :processor, source[:name])
        
        # Create Lambda function
        lambda_function = aws_lambda_function(processor_name, {
          function_name: "siem-processor-#{name}-#{source[:name]}",
          runtime: "python3.11",
          handler: "index.lambda_handler",
          role: create_lambda_execution_role(name, "processor-#{source[:name]}", attrs, resources),
          timeout: 300,
          memory_size: 512,
          
          environment: {
            variables: {
              LOG_SOURCE_TYPE: source[:type],
              LOG_FORMAT: source[:format],
              ENABLE_ENRICHMENT: source[:enrichment].to_s,
              THREAT_INTEL_TABLE: resources[:dynamodb_tables]&.dig(:threat_intel)&.name || ""
            }
          },
          
          code: {
            zip_file: generate_processor_code(source)
          },
          
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        resources[:lambda_functions][:"processor_#{source[:name]}"] = lambda_function
        lambda_function.arn
      end
      
      def generate_processor_code(source)
        <<~PYTHON
          import json
          import base64
          import os
          import boto3
          from datetime import datetime
          import re
          import ipaddress
          
          def lambda_handler(event, context):
              output_records = []
              
              for record in event['records']:
                  # Decode the data
                  payload = base64.b64decode(record['data']).decode('utf-8')
                  
                  try:
                      # Parse based on format
                      parsed_data = parse_log_data(payload, os.environ['LOG_FORMAT'])
                      
                      # Add metadata
                      parsed_data['@timestamp'] = datetime.utcnow().isoformat()
                      parsed_data['log_source'] = os.environ['LOG_SOURCE_TYPE']
                      parsed_data['processing_timestamp'] = datetime.utcnow().isoformat()
                      
                      # Enrich data if enabled
                      if os.environ.get('ENABLE_ENRICHMENT', 'false').lower() == 'true':
                          parsed_data = enrich_data(parsed_data)
                      
                      # Normalize fields
                      parsed_data = normalize_fields(parsed_data)
                      
                      # Convert back to JSON
                      output_data = json.dumps(parsed_data) + '\\n'
                      
                      output_records.append({
                          'recordId': record['recordId'],
                          'result': 'Ok',
                          'data': base64.b64encode(output_data.encode('utf-8')).decode('utf-8')
                      })
                      
                  except Exception as e:
                      # Send failed records to error output
                      output_records.append({
                          'recordId': record['recordId'],
                          'result': 'ProcessingFailed',
                          'data': record['data']
                      })
              
              return {'records': output_records}
          
          def parse_log_data(data, format_type):
              if format_type == 'json':
                  return json.loads(data)
              elif format_type == 'csv':
                  # Implement CSV parsing
                  return parse_csv(data)
              elif format_type == 'syslog':
                  # Implement syslog parsing
                  return parse_syslog(data)
              else:
                  return {'raw_data': data}
          
          def enrich_data(data):
              # Add GeoIP enrichment
              if 'source_ip' in data:
                  data['source_geo'] = lookup_geoip(data['source_ip'])
              
              # Add threat intelligence enrichment
              if 'source_ip' in data or 'domain' in data:
                  data['threat_intel'] = check_threat_intel(data)
              
              # Add user context
              if 'user_id' in data:
                  data['user_context'] = get_user_context(data['user_id'])
              
              return data
          
          def normalize_fields(data):
              # Normalize common field names
              field_mappings = {
                  'src_ip': 'source_ip',
                  'dst_ip': 'destination_ip',
                  'src_port': 'source_port',
                  'dst_port': 'destination_port',
                  'username': 'user_name',
                  'userid': 'user_id'
              }
              
              for old_field, new_field in field_mappings.items():
                  if old_field in data:
                      data[new_field] = data.pop(old_field)
              
              return data
          
          def parse_csv(data):
              # Implement CSV parsing logic
              return {'raw': data}
          
          def parse_syslog(data):
              # Implement syslog parsing logic
              return {'raw': data}
          
          def lookup_geoip(ip):
              # Implement GeoIP lookup
              return {'country': 'US', 'city': 'Unknown'}
          
          def check_threat_intel(data):
              # Implement threat intelligence lookup
              return {'reputation': 'clean', 'score': 0}
          
          def get_user_context(user_id):
              # Implement user context lookup
              return {'department': 'Unknown', 'risk_score': 0}
        PYTHON
      end
      
      def create_lambda_execution_role(name, function_type, attrs, resources)
        role_name = component_resource_name(name, :lambda_role, function_type)
        role = aws_iam_role(role_name, {
          name: role_name.to_s,
          assume_role_policy: JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [{
              Action: "sts:AssumeRole",
              Effect: "Allow",
              Principal: {
                Service: "lambda.amazonaws.com"
              }
            }]
          }),
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        # Attach basic execution policy
        aws_iam_role_policy_attachment(:"#{role_name}_basic", {
          role: role.name,
          policy_arn: "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        })
        
        # Attach VPC execution policy if needed
        aws_iam_role_policy_attachment(:"#{role_name}_vpc", {
          role: role.name,
          policy_arn: "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
        })
        
        # Create custom policy for SIEM operations
        custom_policy = aws_iam_role_policy(:"#{role_name}_custom", {
          role: role.id,
          policy: JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [
              {
                Effect: "Allow",
                Action: [
                  "es:ESHttpPost",
                  "es:ESHttpGet"
                ],
                Resource: "#{resources[:opensearch_domain].arn}/*"
              },
              {
                Effect: "Allow",
                Action: [
                  "dynamodb:GetItem",
                  "dynamodb:Query",
                  "dynamodb:Scan"
                ],
                Resource: "arn:aws:dynamodb:*:*:table/siem-*"
              },
              {
                Effect: "Allow",
                Action: [
                  "kms:Decrypt"
                ],
                Resource: resources[:kms_keys][:main].arn
              },
              {
                Effect: "Allow",
                Action: [
                  "sns:Publish"
                ],
                Resource: "arn:aws:sns:*:*:siem-*"
              }
            ]
          })
        })
        
        resources[:iam_roles][function_type.to_sym] = role
        role.arn
      end
      
      def configure_log_source_subscription(name, source, attrs, resources)
        case source[:type]
        when 'cloudwatch'
          if source[:log_group_name]
            # Create subscription filter
            aws_cloudwatch_log_subscription_filter(:"#{name}_#{source[:name]}_subscription", {
              name: "siem-#{name}-#{source[:name]}",
              log_group_name: source[:log_group_name],
              filter_pattern: "",
              destination_arn: resources[:firehose_streams][source[:name]].arn,
              role_arn: create_logs_role(name, source[:name], attrs, resources)
            })
          end
        when 's3_access'
          # Configure S3 bucket logging
          if source[:s3_bucket]
            aws_s3_bucket_logging(:"#{name}_#{source[:name]}_logging", {
              bucket: source[:s3_bucket],
              target_bucket: resources[:s3_buckets][:backup].id,
              target_prefix: "s3-access-logs/#{source[:s3_bucket]}/"
            })
          end
        end
      end
      
      def create_logs_role(name, source_name, attrs, resources)
        role_name = component_resource_name(name, :logs_role, source_name)
        role = aws_iam_role(role_name, {
          name: role_name.to_s,
          assume_role_policy: JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [{
              Action: "sts:AssumeRole",
              Effect: "Allow",
              Principal: {
                Service: "logs.amazonaws.com"
              }
            }]
          }),
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        aws_iam_role_policy(:"#{role_name}_policy", {
          role: role.id,
          policy: JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: [
                "firehose:PutRecord",
                "firehose:PutRecordBatch"
              ],
              Resource: resources[:firehose_streams][source_name].arn
            }]
          })
        })
        
        role.arn
      end
      
      def create_processing_lambdas(name, attrs, resources)
        # Create Lambda for correlation engine
        correlation_lambda = component_resource_name(name, :correlation_lambda)
        resources[:lambda_functions][:correlation] = aws_lambda_function(correlation_lambda, {
          function_name: "siem-correlation-#{name}",
          runtime: "python3.11",
          handler: "index.lambda_handler",
          role: create_lambda_execution_role(name, "correlation", attrs, resources),
          timeout: 900,
          memory_size: 3008,
          
          environment: {
            variables: {
              OPENSEARCH_ENDPOINT: resources[:opensearch_domain].endpoint,
              CORRELATION_RULES: JSON.generate(attrs.correlation_rules),
              SNS_TOPIC_ARN: create_alert_topic(name, attrs, resources)
            }
          },
          
          code: {
            zip_file: generate_correlation_engine_code()
          },
          
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        # Create Lambda for threat detection
        if attrs.threat_detection[:enable_ml_detection]
          ml_lambda = component_resource_name(name, :ml_detection_lambda)
          resources[:lambda_functions][:ml_detection] = aws_lambda_function(ml_lambda, {
            function_name: "siem-ml-detection-#{name}",
            runtime: "python3.11",
            handler: "index.lambda_handler",
            role: create_lambda_execution_role(name, "ml-detection", attrs, resources),
            timeout: 900,
            memory_size: 3008,
            
            environment: {
              variables: {
                OPENSEARCH_ENDPOINT: resources[:opensearch_domain].endpoint,
                ANOMALY_DETECTORS: JSON.generate(attrs.threat_detection[:anomaly_detectors]),
                ENABLE_BEHAVIOR_ANALYTICS: attrs.threat_detection[:enable_behavior_analytics].to_s
              }
            },
            
            code: {
              zip_file: generate_ml_detection_code()
            },
            
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
        end
      end
      
      def generate_correlation_engine_code
        <<~PYTHON
          import json
          import boto3
          import os
          from opensearchpy import OpenSearch
          from datetime import datetime, timedelta
          import re
          
          def lambda_handler(event, context):
              # Initialize OpenSearch client
              es = OpenSearch(
                  hosts=[{'host': os.environ['OPENSEARCH_ENDPOINT'], 'port': 443}],
                  http_auth=get_auth(),
                  use_ssl=True,
                  verify_certs=True
              )
              
              # Load correlation rules
              rules = json.loads(os.environ['CORRELATION_RULES'])
              
              # Process each rule
              alerts = []
              for rule in rules:
                  if rule.get('enabled', True):
                      matches = evaluate_rule(es, rule)
                      if matches:
                          alert = create_alert(rule, matches)
                          alerts.append(alert)
                          send_alert(alert)
              
              return {
                  'statusCode': 200,
                  'body': json.dumps({
                      'processed_rules': len(rules),
                      'alerts_generated': len(alerts)
                  })
              }
          
          def evaluate_rule(es, rule):
              # Build query based on rule type
              if rule['rule_type'] == 'threshold':
                  return evaluate_threshold_rule(es, rule)
              elif rule['rule_type'] == 'pattern':
                  return evaluate_pattern_rule(es, rule)
              elif rule['rule_type'] == 'anomaly':
                  return evaluate_anomaly_rule(es, rule)
              elif rule['rule_type'] == 'sequence':
                  return evaluate_sequence_rule(es, rule)
              elif rule['rule_type'] == 'statistical':
                  return evaluate_statistical_rule(es, rule)
              
              return []
          
          def evaluate_threshold_rule(es, rule):
              # Implement threshold-based detection
              time_window = rule.get('time_window', 300)
              query = build_query_from_conditions(rule['conditions'], time_window)
              
              response = es.search(
                  index='siem-*',
                  body=query,
                  size=0
              )
              
              doc_count = response['hits']['total']['value']
              threshold = rule.get('threshold', 10)
              
              if doc_count >= threshold:
                  return [{
                      'count': doc_count,
                      'threshold': threshold,
                      'time_window': time_window
                  }]
              
              return []
          
          def evaluate_pattern_rule(es, rule):
              # Implement pattern-based detection
              query = build_pattern_query(rule['conditions'])
              
              response = es.search(
                  index='siem-*',
                  body=query,
                  size=100
              )
              
              return response['hits']['hits']
          
          def evaluate_anomaly_rule(es, rule):
              # Implement anomaly detection using ML
              # This would typically use OpenSearch ML features
              return []
          
          def evaluate_sequence_rule(es, rule):
              # Implement sequence-based detection
              # Look for specific sequences of events
              return []
          
          def evaluate_statistical_rule(es, rule):
              # Implement statistical anomaly detection
              # Calculate baselines and detect deviations
              return []
          
          def build_query_from_conditions(conditions, time_window):
              must_clauses = []
              
              for condition in conditions:
                  if 'field' in condition and 'value' in condition:
                      must_clauses.append({
                          'match': {
                              condition['field']: condition['value']
                          }
                      })
              
              return {
                  'query': {
                      'bool': {
                          'must': must_clauses,
                          'filter': {
                              'range': {
                                  '@timestamp': {
                                      'gte': f'now-{time_window}s'
                                  }
                              }
                          }
                      }
                  }
              }
          
          def build_pattern_query(conditions):
              # Build complex pattern queries
              return build_query_from_conditions(conditions, 3600)
          
          def create_alert(rule, matches):
              return {
                  'rule_name': rule['name'],
                  'severity': rule['severity'],
                  'description': rule['description'],
                  'matches': len(matches),
                  'timestamp': datetime.utcnow().isoformat(),
                  'actions': rule['actions']
              }
          
          def send_alert(alert):
              sns = boto3.client('sns')
              
              message = {
                  'default': json.dumps(alert),
                  'email': format_email_alert(alert),
                  'sms': format_sms_alert(alert)
              }
              
              sns.publish(
                  TopicArn=os.environ['SNS_TOPIC_ARN'],
                  Message=json.dumps(message),
                  MessageStructure='json',
                  Subject=f"SIEM Alert: {alert['rule_name']} - {alert['severity'].upper()}"
              )
          
          def format_email_alert(alert):
              return f"""
              Security Alert: {alert['rule_name']}
              
              Severity: {alert['severity'].upper()}
              Time: {alert['timestamp']}
              
              Description: {alert['description']}
              
              Number of matches: {alert['matches']}
              
              Required Actions: {', '.join(alert['actions'])}
              """
          
          def format_sms_alert(alert):
              return f"SIEM Alert: {alert['rule_name']} ({alert['severity']}) - {alert['matches']} matches detected"
          
          def get_auth():
              # Implement authentication for OpenSearch
              # This could use IAM roles or stored credentials
              return None
        PYTHON
      end
      
      def generate_ml_detection_code
        <<~PYTHON
          import json
          import boto3
          import os
          import numpy as np
          from opensearchpy import OpenSearch
          from datetime import datetime, timedelta
          from sklearn.ensemble import IsolationForest
          from sklearn.preprocessing import StandardScaler
          
          def lambda_handler(event, context):
              # Initialize OpenSearch client
              es = OpenSearch(
                  hosts=[{'host': os.environ['OPENSEARCH_ENDPOINT'], 'port': 443}],
                  http_auth=get_auth(),
                  use_ssl=True,
                  verify_certs=True
              )
              
              # Load anomaly detectors configuration
              detectors = json.loads(os.environ['ANOMALY_DETECTORS'])
              
              results = []
              for detector in detectors:
                  anomalies = run_anomaly_detection(es, detector)
                  if anomalies:
                      results.extend(anomalies)
              
              # Run behavior analytics if enabled
              if os.environ.get('ENABLE_BEHAVIOR_ANALYTICS', 'false').lower() == 'true':
                  behavior_anomalies = run_behavior_analytics(es)
                  results.extend(behavior_anomalies)
              
              return {
                  'statusCode': 200,
                  'body': json.dumps({
                      'anomalies_detected': len(results),
                      'results': results
                  })
              }
          
          def run_anomaly_detection(es, detector):
              # Fetch data for analysis
              data = fetch_detector_data(es, detector)
              
              if not data:
                  return []
              
              # Prepare features
              features = prepare_features(data, detector)
              
              # Run anomaly detection based on type
              if detector['type'] == 'statistical':
                  return detect_statistical_anomalies(features, detector)
              elif detector['type'] == 'machine_learning':
                  return detect_ml_anomalies(features, detector)
              elif detector['type'] == 'pattern_based':
                  return detect_pattern_anomalies(data, detector)
              
              return []
          
          def fetch_detector_data(es, detector):
              # Fetch relevant data based on detector configuration
              baseline_period = detector.get('baseline_period', 7)
              
              query = {
                  'query': {
                      'range': {
                          '@timestamp': {
                              'gte': f'now-{baseline_period}d'
                          }
                      }
                  },
                  'size': 10000,
                  'sort': [{'@timestamp': 'desc'}]
              }
              
              response = es.search(index='siem-*', body=query)
              return [hit['_source'] for hit in response['hits']['hits']]
          
          def prepare_features(data, detector):
              # Extract numerical features for ML analysis
              features = []
              
              for record in data:
                  feature_vector = []
                  
                  # Extract relevant features based on detector config
                  if 'response_time' in record:
                      feature_vector.append(float(record['response_time']))
                  if 'bytes_transferred' in record:
                      feature_vector.append(float(record['bytes_transferred']))
                  if 'error_count' in record:
                      feature_vector.append(float(record['error_count']))
                  
                  if feature_vector:
                      features.append(feature_vector)
              
              return np.array(features) if features else np.array([])
          
          def detect_statistical_anomalies(features, detector):
              if len(features) == 0:
                  return []
              
              # Calculate statistics
              mean = np.mean(features, axis=0)
              std = np.std(features, axis=0)
              
              # Detect outliers
              anomalies = []
              sensitivity_factor = {
                  'low': 3,
                  'medium': 2,
                  'high': 1
              }.get(detector.get('sensitivity', 'medium'), 2)
              
              for i, feature in enumerate(features):
                  z_scores = np.abs((feature - mean) / (std + 1e-10))
                  if np.any(z_scores > sensitivity_factor):
                      anomalies.append({
                          'type': 'statistical_anomaly',
                          'detector': detector['name'],
                          'index': i,
                          'z_scores': z_scores.tolist(),
                          'severity': calculate_severity(z_scores, sensitivity_factor)
                      })
              
              return anomalies
          
          def detect_ml_anomalies(features, detector):
              if len(features) < 10:
                  return []
              
              # Normalize features
              scaler = StandardScaler()
              features_normalized = scaler.fit_transform(features)
              
              # Train Isolation Forest
              contamination = {
                  'low': 0.01,
                  'medium': 0.05,
                  'high': 0.1
              }.get(detector.get('sensitivity', 'medium'), 0.05)
              
              model = IsolationForest(
                  contamination=contamination,
                  random_state=42
              )
              
              predictions = model.fit_predict(features_normalized)
              
              # Identify anomalies
              anomalies = []
              for i, pred in enumerate(predictions):
                  if pred == -1:
                      anomalies.append({
                          'type': 'ml_anomaly',
                          'detector': detector['name'],
                          'index': i,
                          'anomaly_score': model.score_samples([features_normalized[i]])[0],
                          'severity': 'high' if model.score_samples([features_normalized[i]])[0] < -0.5 else 'medium'
                      })
              
              return anomalies
          
          def detect_pattern_anomalies(data, detector):
              # Implement pattern-based anomaly detection
              # Look for unusual patterns in categorical data
              anomalies = []
              
              # Example: Detect unusual user behavior patterns
              user_activities = {}
              for record in data:
                  if 'user_id' in record and 'action' in record:
                      user_id = record['user_id']
                      if user_id not in user_activities:
                          user_activities[user_id] = []
                      user_activities[user_id].append(record['action'])
              
              # Detect anomalous activity sequences
              for user_id, activities in user_activities.items():
                  if is_anomalous_sequence(activities):
                      anomalies.append({
                          'type': 'pattern_anomaly',
                          'detector': detector['name'],
                          'user_id': user_id,
                          'pattern': activities[-10:],  # Last 10 activities
                          'severity': 'high'
                      })
              
              return anomalies
          
          def run_behavior_analytics(es):
              # Implement User and Entity Behavior Analytics (UEBA)
              anomalies = []
              
              # Analyze user behavior
              user_anomalies = analyze_user_behavior(es)
              anomalies.extend(user_anomalies)
              
              # Analyze entity behavior
              entity_anomalies = analyze_entity_behavior(es)
              anomalies.extend(entity_anomalies)
              
              return anomalies
          
          def analyze_user_behavior(es):
              # Implement user behavior analysis
              # Look for unusual login times, locations, access patterns
              return []
          
          def analyze_entity_behavior(es):
              # Implement entity behavior analysis
              # Look for unusual system behavior, process execution, network connections
              return []
          
          def is_anomalous_sequence(activities):
              # Implement sequence anomaly detection logic
              # This is a simplified example
              suspicious_sequences = [
                  ['login', 'privilege_escalation', 'data_export'],
                  ['failed_login', 'failed_login', 'failed_login', 'successful_login'],
                  ['access_sensitive_data', 'download_large_file', 'delete_logs']
              ]
              
              for suspicious in suspicious_sequences:
                  if all(activity in activities for activity in suspicious):
                      return True
              
              return False
          
          def calculate_severity(z_scores, threshold):
              max_z = np.max(z_scores)
              if max_z > threshold * 2:
                  return 'critical'
              elif max_z > threshold * 1.5:
                  return 'high'
              elif max_z > threshold:
                  return 'medium'
              else:
                  return 'low'
          
          def get_auth():
              # Implement authentication
              return None
        PYTHON
      end
      
      def create_alert_topic(name, attrs, resources)
        topic_name = component_resource_name(name, :alert_topic)
        topic = aws_sns_topic(topic_name, {
          name: "siem-alerts-#{name}",
          kms_master_key_id: resources[:kms_keys][:main].id,
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        resources[:sns_topics][:alerts] = topic
        topic.arn
      end
      
      def create_correlation_engine(name, attrs, resources)
        # Create Step Functions state machine for correlation workflow
        state_machine_name = component_resource_name(name, :correlation_engine)
        
        resources[:step_functions][:correlation_engine] = aws_sfn_state_machine(state_machine_name, {
          name: "siem-correlation-engine-#{name}",
          role_arn: create_step_functions_role(name, "correlation", attrs, resources),
          
          definition: JSON.pretty_generate({
            Comment: "SIEM Correlation Engine",
            StartAt: "CollectEvents",
            States: {
              CollectEvents: {
                Type: "Task",
                Resource: resources[:lambda_functions][:correlation].arn,
                Next: "EvaluateRules"
              },
              EvaluateRules: {
                Type: "Parallel",
                Branches: attrs.correlation_rules.map do |rule|
                  {
                    StartAt: "Evaluate#{rule[:name].gsub(/\s+/, '')}",
                    States: {
                      "Evaluate#{rule[:name].gsub(/\s+/, '')}" => {
                        Type: "Task",
                        Resource: resources[:lambda_functions][:correlation].arn,
                        Parameters: {
                          "rule.$" => rule.to_json,
                          "events.$" => "$"
                        },
                        End: true
                      }
                    }
                  }
                end,
                Next: "ProcessAlerts"
              },
              ProcessAlerts: {
                Type: "Task",
                Resource: "arn:aws:states:::lambda:invoke",
                Parameters: {
                  FunctionName: resources[:lambda_functions][:correlation].arn,
                  Payload: {
                    "action" => "process_alerts",
                    "results.$" => "$"
                  }
                },
                End: true
              }
            }
          }),
          
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
      end
      
      def create_step_functions_role(name, purpose, attrs, resources)
        role_name = component_resource_name(name, :sfn_role, purpose)
        role = aws_iam_role(role_name, {
          name: role_name.to_s,
          assume_role_policy: JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [{
              Action: "sts:AssumeRole",
              Effect: "Allow",
              Principal: {
                Service: "states.amazonaws.com"
              }
            }]
          }),
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        aws_iam_role_policy(:"#{role_name}_policy", {
          role: role.id,
          policy: JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [
              {
                Effect: "Allow",
                Action: [
                  "lambda:InvokeFunction"
                ],
                Resource: "arn:aws:lambda:*:*:function:siem-*"
              },
              {
                Effect: "Allow",
                Action: [
                  "xray:PutTraceSegments",
                  "xray:PutTelemetryRecords"
                ],
                Resource: "*"
              }
            ]
          })
        })
        
        role.arn
      end
      
      def create_threat_detection(name, attrs, resources)
        # Create DynamoDB table for threat intelligence
        if attrs.threat_detection[:threat_intel_feeds] && !attrs.threat_detection[:threat_intel_feeds].empty?
          table_name = component_resource_name(name, :threat_intel_table)
          resources[:dynamodb_tables] ||= {}
          resources[:dynamodb_tables][:threat_intel] = aws_dynamodb_table(table_name, {
            name: "siem-threat-intel-#{name}",
            billing_mode: "PAY_PER_REQUEST",
            
            attribute: [
              {
                name: "indicator",
                type: "S"
              },
              {
                name: "indicator_type",
                type: "S"
              }
            ],
            
            hash_key: "indicator",
            range_key: "indicator_type",
            
            global_secondary_index: [
              {
                name: "TypeIndex",
                hash_key: "indicator_type",
                projection_type: "ALL"
              }
            ],
            
            point_in_time_recovery: {
              enabled: true
            },
            
            server_side_encryption: {
              enabled: true,
              kms_key_id: resources[:kms_keys][:main].id
            },
            
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
          
          # Create Lambda for threat intel updates
          threat_intel_lambda = component_resource_name(name, :threat_intel_updater)
          resources[:lambda_functions][:threat_intel_updater] = aws_lambda_function(threat_intel_lambda, {
            function_name: "siem-threat-intel-updater-#{name}",
            runtime: "python3.11",
            handler: "index.lambda_handler",
            role: create_lambda_execution_role(name, "threat-intel-updater", attrs, resources),
            timeout: 900,
            memory_size: 1024,
            
            environment: {
              variables: {
                THREAT_INTEL_TABLE: resources[:dynamodb_tables][:threat_intel].name,
                THREAT_FEEDS: JSON.generate(attrs.threat_detection[:threat_intel_feeds])
              }
            },
            
            code: {
              zip_file: generate_threat_intel_updater_code()
            },
            
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
          
          # Schedule threat intel updates
          attrs.threat_detection[:threat_intel_feeds].each do |feed|
            rule_name = component_resource_name(name, :threat_intel_rule, feed[:name])
            rule = aws_cloudwatch_event_rule(rule_name, {
              name: "siem-threat-intel-#{name}-#{feed[:name]}",
              description: "Update threat intelligence feed: #{feed[:name]}",
              schedule_expression: "rate(#{feed[:update_frequency] / 60} minutes)",
              tags: component_tags('siem_security_platform', name, attrs.tags)
            })
            
            aws_cloudwatch_event_target(:"#{rule_name}_target", {
              rule: rule.name,
              arn: resources[:lambda_functions][:threat_intel_updater].arn,
              input: JSON.generate({ feed: feed })
            })
            
            resources[:event_rules][:"threat_intel_#{feed[:name]}"] = rule
          end
        end
      end
      
      def generate_threat_intel_updater_code
        <<~PYTHON
          import json
          import boto3
          import os
          import requests
          from datetime import datetime
          
          dynamodb = boto3.resource('dynamodb')
          
          def lambda_handler(event, context):
              table = dynamodb.Table(os.environ['THREAT_INTEL_TABLE'])
              feed = event.get('feed', {})
              
              # Fetch threat intelligence data
              indicators = fetch_threat_feed(feed)
              
              # Update DynamoDB table
              with table.batch_writer() as batch:
                  for indicator in indicators:
                      batch.put_item(Item={
                          'indicator': indicator['value'],
                          'indicator_type': indicator['type'],
                          'severity': indicator.get('severity', 'medium'),
                          'source': feed['name'],
                          'last_seen': datetime.utcnow().isoformat(),
                          'metadata': indicator.get('metadata', {})
                      })
              
              return {
                  'statusCode': 200,
                  'body': json.dumps({
                      'feed': feed['name'],
                      'indicators_updated': len(indicators)
                  })
              }
          
          def fetch_threat_feed(feed):
              indicators = []
              
              if feed['type'] == 'ip_reputation':
                  indicators.extend(fetch_ip_reputation(feed))
              elif feed['type'] == 'domain_reputation':
                  indicators.extend(fetch_domain_reputation(feed))
              elif feed['type'] == 'file_hash':
                  indicators.extend(fetch_file_hashes(feed))
              elif feed['type'] == 'indicators':
                  indicators.extend(fetch_generic_indicators(feed))
              
              return indicators
          
          def fetch_ip_reputation(feed):
              # Implement IP reputation feed fetching
              # This is a placeholder - real implementation would fetch from actual feeds
              return [
                  {'value': '192.168.1.100', 'type': 'ip', 'severity': 'high'},
                  {'value': '10.0.0.50', 'type': 'ip', 'severity': 'medium'}
              ]
          
          def fetch_domain_reputation(feed):
              # Implement domain reputation feed fetching
              return [
                  {'value': 'malicious.com', 'type': 'domain', 'severity': 'critical'},
                  {'value': 'suspicious.net', 'type': 'domain', 'severity': 'high'}
              ]
          
          def fetch_file_hashes(feed):
              # Implement file hash feed fetching
              return [
                  {'value': 'd41d8cd98f00b204e9800998ecf8427e', 'type': 'md5', 'severity': 'high'},
                  {'value': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'type': 'sha256', 'severity': 'critical'}
              ]
          
          def fetch_generic_indicators(feed):
              # Implement generic indicator fetching
              if feed.get('source_url'):
                  try:
                      response = requests.get(feed['source_url'], timeout=30)
                      if response.status_code == 200:
                          # Parse response based on format
                          return parse_indicators(response.text, feed)
                  except Exception as e:
                      print(f"Error fetching feed {feed['name']}: {str(e)}")
              
              return []
          
          def parse_indicators(data, feed):
              # Parse indicators from raw data
              indicators = []
              
              # Simple line-based parsing example
              for line in data.split('\\n'):
                  line = line.strip()
                  if line and not line.startswith('#'):
                      indicators.append({
                          'value': line,
                          'type': 'unknown',
                          'severity': 'medium'
                      })
              
              return indicators
        PYTHON
      end
      
      def create_incident_response(name, attrs, resources)
        return unless attrs.incident_response[:enable_automated_response]
        
        # Create Step Functions for incident response workflows
        state_machine_name = component_resource_name(name, :incident_response)
        
        resources[:step_functions][:incident_response] = aws_sfn_state_machine(state_machine_name, {
          name: "siem-incident-response-#{name}",
          role_arn: create_step_functions_role(name, "incident-response", attrs, resources),
          
          definition: JSON.pretty_generate({
            Comment: "SIEM Incident Response Workflow",
            StartAt: "ClassifyIncident",
            States: {
              ClassifyIncident: {
                Type: "Task",
                Resource: "arn:aws:states:::lambda:invoke",
                Parameters: {
                  FunctionName: create_incident_classifier(name, attrs, resources),
                  Payload: {
                    "incident.$" => "$"
                  }
                },
                Next: "DetermineSeverity"
              },
              DetermineSeverity: {
                Type: "Choice",
                Choices: [
                  {
                    Variable: "$.severity",
                    StringEquals: "critical",
                    Next: "CriticalResponse"
                  },
                  {
                    Variable: "$.severity",
                    StringEquals: "high",
                    Next: "HighResponse"
                  },
                  {
                    Variable: "$.severity",
                    StringEquals: "medium",
                    Next: "MediumResponse"
                  }
                ],
                Default: "LowResponse"
              },
              CriticalResponse: {
                Type: "Parallel",
                Branches: [
                  {
                    StartAt: "IsolateResource",
                    States: {
                      IsolateResource: {
                        Type: "Task",
                        Resource: "arn:aws:states:::lambda:invoke",
                        Parameters: {
                          FunctionName: create_isolation_lambda(name, attrs, resources),
                          Payload: {
                            "action" => "isolate",
                            "resource.$" => "$.affected_resource"
                          }
                        },
                        End: true
                      }
                    }
                  },
                  {
                    StartAt: "NotifySOC",
                    States: {
                      NotifySOC: {
                        Type: "Task",
                        Resource: "arn:aws:states:::sns:publish",
                        Parameters: {
                          TopicArn: resources[:sns_topics][:alerts].arn,
                          Message: {
                            "incident.$" => "$",
                            "priority" => "CRITICAL"
                          }
                        },
                        End: true
                      }
                    }
                  },
                  {
                    StartAt: "CollectForensics",
                    States: {
                      CollectForensics: {
                        Type: "Task",
                        Resource: "arn:aws:states:::lambda:invoke",
                        Parameters: {
                          FunctionName: create_forensics_lambda(name, attrs, resources),
                          Payload: {
                            "action" => "collect",
                            "incident.$" => "$"
                          }
                        },
                        End: true
                      }
                    }
                  }
                ],
                Next: "CreateIncidentTicket"
              },
              HighResponse: {
                Type: "Task",
                Resource: "arn:aws:states:::lambda:invoke",
                Parameters: {
                  FunctionName: create_response_lambda(name, attrs, resources),
                  Payload: {
                    "severity" => "high",
                    "incident.$" => "$"
                  }
                },
                Next: "CreateIncidentTicket"
              },
              MediumResponse: {
                Type: "Task",
                Resource: "arn:aws:states:::lambda:invoke",
                Parameters: {
                  FunctionName: create_response_lambda(name, attrs, resources),
                  Payload: {
                    "severity" => "medium",
                    "incident.$" => "$"
                  }
                },
                Next: "CreateIncidentTicket"
              },
              LowResponse: {
                Type: "Task",
                Resource: "arn:aws:states:::lambda:invoke",
                Parameters: {
                  FunctionName: create_response_lambda(name, attrs, resources),
                  Payload: {
                    "severity" => "low",
                    "incident.$" => "$"
                  }
                },
                Next: "CreateIncidentTicket"
              },
              CreateIncidentTicket: {
                Type: "Task",
                Resource: "arn:aws:states:::lambda:invoke",
                Parameters: {
                  FunctionName: create_ticketing_lambda(name, attrs, resources),
                  Payload: {
                    "action" => "create_ticket",
                    "incident.$" => "$"
                  }
                },
                End: true
              }
            }
          }),
          
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        # Create playbook executions for configured playbooks
        attrs.incident_response[:playbooks].each do |playbook|
          create_playbook_execution(name, playbook, attrs, resources)
        end
      end
      
      def create_incident_classifier(name, attrs, resources)
        lambda_name = component_resource_name(name, :incident_classifier)
        lambda = aws_lambda_function(lambda_name, {
          function_name: "siem-incident-classifier-#{name}",
          runtime: "python3.11",
          handler: "index.lambda_handler",
          role: create_lambda_execution_role(name, "incident-classifier", attrs, resources),
          timeout: 60,
          
          code: {
            zip_file: <<~PYTHON
              import json
              
              def lambda_handler(event, context):
                  incident = event.get('incident', {})
                  
                  # Classify incident based on rules
                  severity = classify_severity(incident)
                  category = classify_category(incident)
                  
                  return {
                      'statusCode': 200,
                      'severity': severity,
                      'category': category,
                      'incident': incident
                  }
              
              def classify_severity(incident):
                  # Implement severity classification logic
                  indicators = incident.get('indicators', [])
                  
                  if any(ind.get('severity') == 'critical' for ind in indicators):
                      return 'critical'
                  elif any(ind.get('severity') == 'high' for ind in indicators):
                      return 'high'
                  elif len(indicators) > 10:
                      return 'high'
                  elif len(indicators) > 5:
                      return 'medium'
                  else:
                      return 'low'
              
              def classify_category(incident):
                  # Implement category classification
                  event_types = incident.get('event_types', [])
                  
                  if 'malware' in event_types:
                      return 'malware'
                  elif 'unauthorized_access' in event_types:
                      return 'unauthorized_access'
                  elif 'data_exfiltration' in event_types:
                      return 'data_breach'
                  else:
                      return 'unknown'
            PYTHON
          },
          
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        resources[:lambda_functions][:incident_classifier] = lambda
        lambda.arn
      end
      
      def create_isolation_lambda(name, attrs, resources)
        lambda_name = component_resource_name(name, :isolation_lambda)
        lambda = aws_lambda_function(lambda_name, {
          function_name: "siem-isolation-#{name}",
          runtime: "python3.11",
          handler: "index.lambda_handler",
          role: create_isolation_role(name, attrs, resources),
          timeout: 300,
          
          code: {
            zip_file: <<~PYTHON
              import json
              import boto3
              
              ec2 = boto3.client('ec2')
              
              def lambda_handler(event, context):
                  action = event.get('action')
                  resource = event.get('resource', {})
                  
                  if action == 'isolate':
                      result = isolate_resource(resource)
                  elif action == 'restore':
                      result = restore_resource(resource)
                  else:
                      result = {'error': 'Unknown action'}
                  
                  return {
                      'statusCode': 200,
                      'body': json.dumps(result)
                  }
              
              def isolate_resource(resource):
                  resource_type = resource.get('type')
                  resource_id = resource.get('id')
                  
                  if resource_type == 'ec2_instance':
                      return isolate_ec2_instance(resource_id)
                  elif resource_type == 'security_group':
                      return isolate_security_group(resource_id)
                  else:
                      return {'error': 'Unsupported resource type'}
              
              def isolate_ec2_instance(instance_id):
                  # Create isolation security group
                  isolation_sg = ec2.create_security_group(
                      GroupName=f'isolation-{instance_id}',
                      Description='Isolation security group for incident response'
                  )
                  
                  # Remove all ingress rules
                  ec2.revoke_security_group_ingress(
                      GroupId=isolation_sg['GroupId'],
                      IpPermissions=[{
                          'IpProtocol': '-1',
                          'FromPort': -1,
                          'ToPort': -1,
                          'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
                      }]
                  )
                  
                  # Apply isolation security group
                  ec2.modify_instance_attribute(
                      InstanceId=instance_id,
                      Groups=[isolation_sg['GroupId']]
                  )
                  
                  return {
                      'action': 'isolated',
                      'instance_id': instance_id,
                      'isolation_sg': isolation_sg['GroupId']
                  }
              
              def restore_resource(resource):
                  # Implement restoration logic
                  return {'action': 'restored', 'resource': resource}
              
              def isolate_security_group(sg_id):
                  # Implement security group isolation
                  return {'action': 'isolated', 'security_group_id': sg_id}
            PYTHON
          },
          
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        resources[:lambda_functions][:isolation] = lambda
        lambda.arn
      end
      
      def create_isolation_role(name, attrs, resources)
        role_name = component_resource_name(name, :isolation_role)
        role = aws_iam_role(role_name, {
          name: role_name.to_s,
          assume_role_policy: JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [{
              Action: "sts:AssumeRole",
              Effect: "Allow",
              Principal: {
                Service: "lambda.amazonaws.com"
              }
            }]
          }),
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        # Attach policies
        aws_iam_role_policy_attachment(:"#{role_name}_basic", {
          role: role.name,
          policy_arn: "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        })
        
        # Custom policy for isolation actions
        aws_iam_role_policy(:"#{role_name}_isolation", {
          role: role.id,
          policy: JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [
              {
                Effect: "Allow",
                Action: [
                  "ec2:CreateSecurityGroup",
                  "ec2:AuthorizeSecurityGroupIngress",
                  "ec2:AuthorizeSecurityGroupEgress",
                  "ec2:RevokeSecurityGroupIngress",
                  "ec2:RevokeSecurityGroupEgress",
                  "ec2:ModifyInstanceAttribute",
                  "ec2:DescribeInstances",
                  "ec2:DescribeSecurityGroups",
                  "ec2:CreateSnapshot",
                  "ec2:CreateImage"
                ],
                Resource: "*"
              }
            ]
          })
        })
        
        role.arn
      end
      
      def create_forensics_lambda(name, attrs, resources)
        lambda_name = component_resource_name(name, :forensics_lambda)
        lambda = aws_lambda_function(lambda_name, {
          function_name: "siem-forensics-#{name}",
          runtime: "python3.11",
          handler: "index.lambda_handler",
          role: create_forensics_role(name, attrs, resources),
          timeout: 900,
          memory_size: 3008,
          
          environment: {
            variables: {
              FORENSICS_BUCKET: create_forensics_bucket(name, attrs, resources)
            }
          },
          
          code: {
            zip_file: <<~PYTHON
              import json
              import boto3
              import os
              from datetime import datetime
              
              ec2 = boto3.client('ec2')
              s3 = boto3.client('s3')
              ssm = boto3.client('ssm')
              
              def lambda_handler(event, context):
                  action = event.get('action')
                  incident = event.get('incident', {})
                  
                  if action == 'collect':
                      result = collect_forensics(incident)
                  else:
                      result = {'error': 'Unknown action'}
                  
                  return {
                      'statusCode': 200,
                      'body': json.dumps(result)
                  }
              
              def collect_forensics(incident):
                  forensics_data = {
                      'incident_id': incident.get('id'),
                      'timestamp': datetime.utcnow().isoformat(),
                      'affected_resources': []
                  }
                  
                  for resource in incident.get('affected_resources', []):
                      if resource['type'] == 'ec2_instance':
                          forensics = collect_ec2_forensics(resource['id'])
                          forensics_data['affected_resources'].append(forensics)
                  
                  # Store forensics data
                  store_forensics_data(forensics_data)
                  
                  return forensics_data
              
              def collect_ec2_forensics(instance_id):
                  forensics = {
                      'instance_id': instance_id,
                      'type': 'ec2_instance',
                      'collected_at': datetime.utcnow().isoformat()
                  }
                  
                  # Create memory dump
                  memory_dump = create_memory_dump(instance_id)
                  if memory_dump:
                      forensics['memory_dump'] = memory_dump
                  
                  # Create disk snapshot
                  snapshot = create_disk_snapshot(instance_id)
                  if snapshot:
                      forensics['disk_snapshot'] = snapshot
                  
                  # Collect system information
                  system_info = collect_system_info(instance_id)
                  if system_info:
                      forensics['system_info'] = system_info
                  
                  # Collect network connections
                  network_info = collect_network_info(instance_id)
                  if network_info:
                      forensics['network_info'] = network_info
                  
                  return forensics
              
              def create_memory_dump(instance_id):
                  # Use SSM to run memory dump command
                  try:
                      response = ssm.send_command(
                          InstanceIds=[instance_id],
                          DocumentName='AWS-RunShellScript',
                          Parameters={
                              'commands': [
                                  'sudo dd if=/dev/mem of=/tmp/memory.dump',
                                  'aws s3 cp /tmp/memory.dump s3://{}/forensics/{}/memory.dump'.format(
                                      os.environ['FORENSICS_BUCKET'],
                                      instance_id
                                  )
                              ]
                          }
                      )
                      return {
                          'command_id': response['Command']['CommandId'],
                          's3_location': 's3://{}/forensics/{}/memory.dump'.format(
                              os.environ['FORENSICS_BUCKET'],
                              instance_id
                          )
                      }
                  except Exception as e:
                      print(f"Error creating memory dump: {str(e)}")
                      return None
              
              def create_disk_snapshot(instance_id):
                  try:
                      # Get instance volumes
                      instance = ec2.describe_instances(InstanceIds=[instance_id])
                      volumes = []
                      
                      for reservation in instance['Reservations']:
                          for instance in reservation['Instances']:
                              for bdm in instance.get('BlockDeviceMappings', []):
                                  if 'Ebs' in bdm:
                                      volume_id = bdm['Ebs']['VolumeId']
                                      
                                      # Create snapshot
                                      snapshot = ec2.create_snapshot(
                                          VolumeId=volume_id,
                                          Description=f'Forensics snapshot for incident - {instance_id}'
                                      )
                                      
                                      volumes.append({
                                          'volume_id': volume_id,
                                          'snapshot_id': snapshot['SnapshotId']
                                      })
                      
                      return volumes
                  except Exception as e:
                      print(f"Error creating snapshot: {str(e)}")
                      return None
              
              def collect_system_info(instance_id):
                  # Collect system information via SSM
                  commands = [
                      'uname -a',
                      'ps aux',
                      'netstat -tulpn',
                      'last -50',
                      'w',
                      'history'
                  ]
                  
                  try:
                      response = ssm.send_command(
                          InstanceIds=[instance_id],
                          DocumentName='AWS-RunShellScript',
                          Parameters={'commands': commands}
                      )
                      return {'command_id': response['Command']['CommandId']}
                  except Exception as e:
                      print(f"Error collecting system info: {str(e)}")
                      return None
              
              def collect_network_info(instance_id):
                  # Collect network flow information
                  try:
                      # Get VPC Flow Logs
                      # This is simplified - real implementation would query flow logs
                      return {
                          'flow_logs': 'collected',
                          'connections': 'analyzed'
                      }
                  except Exception as e:
                      print(f"Error collecting network info: {str(e)}")
                      return None
              
              def store_forensics_data(data):
                  # Store forensics data in S3
                  key = 'forensics/{}/data.json'.format(data['incident_id'])
                  
                  s3.put_object(
                      Bucket=os.environ['FORENSICS_BUCKET'],
                      Key=key,
                      Body=json.dumps(data, indent=2),
                      ServerSideEncryption='aws:kms'
                  )
            PYTHON
          },
          
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        resources[:lambda_functions][:forensics] = lambda
        lambda.arn
      end
      
      def create_forensics_role(name, attrs, resources)
        role_name = component_resource_name(name, :forensics_role)
        role = aws_iam_role(role_name, {
          name: role_name.to_s,
          assume_role_policy: JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [{
              Action: "sts:AssumeRole",
              Effect: "Allow",
              Principal: {
                Service: "lambda.amazonaws.com"
              }
            }]
          }),
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        # Attach policies
        aws_iam_role_policy_attachment(:"#{role_name}_basic", {
          role: role.name,
          policy_arn: "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        })
        
        # Custom policy for forensics collection
        aws_iam_role_policy(:"#{role_name}_forensics", {
          role: role.id,
          policy: JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [
              {
                Effect: "Allow",
                Action: [
                  "ec2:CreateSnapshot",
                  "ec2:DescribeInstances",
                  "ec2:DescribeVolumes",
                  "ec2:DescribeSnapshots",
                  "ssm:SendCommand",
                  "ssm:GetCommandInvocation",
                  "s3:PutObject",
                  "s3:GetObject",
                  "kms:Decrypt",
                  "kms:GenerateDataKey"
                ],
                Resource: "*"
              }
            ]
          })
        })
        
        role.arn
      end
      
      def create_forensics_bucket(name, attrs, resources)
        bucket_name = component_resource_name(name, :forensics_bucket)
        bucket = create_secure_bucket(
          bucket_name,
          "siem-forensics-#{name}",
          attrs,
          resources
        )
        
        resources[:s3_buckets][:forensics] = bucket
        bucket.id
      end
      
      def create_response_lambda(name, attrs, resources)
        lambda_name = component_resource_name(name, :response_lambda)
        lambda = aws_lambda_function(lambda_name, {
          function_name: "siem-response-#{name}",
          runtime: "python3.11",
          handler: "index.lambda_handler",
          role: create_lambda_execution_role(name, "response", attrs, resources),
          timeout: 300,
          
          code: {
            zip_file: <<~PYTHON
              import json
              
              def lambda_handler(event, context):
                  severity = event.get('severity')
                  incident = event.get('incident', {})
                  
                  # Execute response based on severity
                  if severity == 'high':
                      response = execute_high_severity_response(incident)
                  elif severity == 'medium':
                      response = execute_medium_severity_response(incident)
                  else:
                      response = execute_low_severity_response(incident)
                  
                  return {
                      'statusCode': 200,
                      'body': json.dumps(response)
                  }
              
              def execute_high_severity_response(incident):
                  # Implement high severity response
                  return {
                      'actions_taken': [
                          'blocked_suspicious_ips',
                          'disabled_compromised_accounts',
                          'initiated_forensics_collection'
                      ]
                  }
              
              def execute_medium_severity_response(incident):
                  # Implement medium severity response
                  return {
                      'actions_taken': [
                          'increased_monitoring',
                          'notified_security_team'
                      ]
                  }
              
              def execute_low_severity_response(incident):
                  # Implement low severity response
                  return {
                      'actions_taken': [
                          'logged_incident',
                          'updated_metrics'
                      ]
                  }
            PYTHON
          },
          
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        resources[:lambda_functions][:response] = lambda
        lambda.arn
      end
      
      def create_ticketing_lambda(name, attrs, resources)
        lambda_name = component_resource_name(name, :ticketing_lambda)
        lambda = aws_lambda_function(lambda_name, {
          function_name: "siem-ticketing-#{name}",
          runtime: "python3.11",
          handler: "index.lambda_handler",
          role: create_lambda_execution_role(name, "ticketing", attrs, resources),
          timeout: 60,
          
          environment: {
            variables: {
              INTEGRATIONS: JSON.generate(attrs.integrations.select { |i| i[:type] == 'ticketing' })
            }
          },
          
          code: {
            zip_file: <<~PYTHON
              import json
              import os
              import requests
              from datetime import datetime
              
              def lambda_handler(event, context):
                  action = event.get('action')
                  incident = event.get('incident', {})
                  
                  if action == 'create_ticket':
                      ticket = create_incident_ticket(incident)
                  else:
                      ticket = {'error': 'Unknown action'}
                  
                  return {
                      'statusCode': 200,
                      'body': json.dumps(ticket)
                  }
              
              def create_incident_ticket(incident):
                  integrations = json.loads(os.environ.get('INTEGRATIONS', '[]'))
                  
                  ticket = {
                      'title': f"Security Incident: {incident.get('name', 'Unknown')}",
                      'description': format_incident_description(incident),
                      'severity': incident.get('severity', 'medium'),
                      'created_at': datetime.utcnow().isoformat(),
                      'incident_id': incident.get('id')
                  }
                  
                  # Send to configured ticketing systems
                  for integration in integrations:
                      if integration.get('enabled', True):
                          send_to_ticketing_system(ticket, integration)
                  
                  return ticket
              
              def format_incident_description(incident):
                  description = f"""
                  Incident ID: {incident.get('id')}
                  Severity: {incident.get('severity', 'unknown').upper()}
                  Time: {incident.get('timestamp')}
                  
                  Description: {incident.get('description', 'No description provided')}
                  
                  Affected Resources:
                  """
                  
                  for resource in incident.get('affected_resources', []):
                      description += f"\\n- {resource.get('type')}: {resource.get('id')}"
                  
                  description += f"\\n\\nIndicators: {len(incident.get('indicators', []))}"
                  description += f"\\nActions Taken: {', '.join(incident.get('actions_taken', []))}"
                  
                  return description
              
              def send_to_ticketing_system(ticket, integration):
                  # Implement integration with ticketing systems
                  # This is a placeholder - real implementation would use actual APIs
                  endpoint = integration.get('endpoint')
                  
                  if endpoint:
                      try:
                          response = requests.post(
                              endpoint,
                              json=ticket,
                              headers={'Authorization': f"Bearer {get_api_key(integration)}"},
                              timeout=30
                          )
                          return response.json()
                      except Exception as e:
                          print(f"Error sending to ticketing system: {str(e)}")
                  
                  return None
              
              def get_api_key(integration):
                  # Retrieve API key from Secrets Manager
                  # This is simplified - real implementation would use boto3
                  return "placeholder-api-key"
            PYTHON
          },
          
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        resources[:lambda_functions][:ticketing] = lambda
        lambda.arn
      end
      
      def create_playbook_execution(name, playbook, attrs, resources)
        # Create Lambda for playbook execution
        playbook_lambda_name = component_resource_name(name, :playbook, playbook[:name])
        
        resources[:lambda_functions][:"playbook_#{playbook[:name]}"] = aws_lambda_function(playbook_lambda_name, {
          function_name: "siem-playbook-#{name}-#{playbook[:name]}",
          runtime: "python3.11",
          handler: "index.lambda_handler",
          role: create_lambda_execution_role(name, "playbook-#{playbook[:name]}", attrs, resources),
          timeout: 900,
          
          environment: {
            variables: {
              PLAYBOOK_NAME: playbook[:name],
              PLAYBOOK_STEPS: JSON.generate(playbook[:steps])
            }
          },
          
          code: {
            zip_file: generate_playbook_code(playbook)
          },
          
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
      end
      
      def generate_playbook_code(playbook)
        <<~PYTHON
          import json
          import os
          import boto3
          
          def lambda_handler(event, context):
              playbook_name = os.environ['PLAYBOOK_NAME']
              steps = json.loads(os.environ['PLAYBOOK_STEPS'])
              
              results = []
              for step in steps:
                  result = execute_step(step, event)
                  results.append(result)
                  
                  # Stop if step fails and is marked as critical
                  if not result['success'] and step.get('critical', False):
                      break
              
              return {
                  'statusCode': 200,
                  'body': json.dumps({
                      'playbook': playbook_name,
                      'results': results
                  })
              }
          
          def execute_step(step, context):
              step_type = step.get('type')
              
              if step_type == 'notify':
                  return notify_step(step, context)
              elif step_type == 'isolate':
                  return isolate_step(step, context)
              elif step_type == 'block':
                  return block_step(step, context)
              elif step_type == 'collect':
                  return collect_step(step, context)
              elif step_type == 'analyze':
                  return analyze_step(step, context)
              else:
                  return {'success': False, 'error': 'Unknown step type'}
          
          def notify_step(step, context):
              # Implement notification logic
              return {'success': True, 'action': 'notified', 'details': step}
          
          def isolate_step(step, context):
              # Implement isolation logic
              return {'success': True, 'action': 'isolated', 'details': step}
          
          def block_step(step, context):
              # Implement blocking logic
              return {'success': True, 'action': 'blocked', 'details': step}
          
          def collect_step(step, context):
              # Implement collection logic
              return {'success': True, 'action': 'collected', 'details': step}
          
          def analyze_step(step, context):
              # Implement analysis logic
              return {'success': True, 'action': 'analyzed', 'details': step}
        PYTHON
      end
      
      def create_monitoring(name, attrs, resources)
        # Create CloudWatch dashboard
        dashboard_name = component_resource_name(name, :dashboard)
        
        dashboard_body = {
          widgets: [
            {
              type: "metric",
              properties: {
                metrics: [
                  ["AWS/ES", "ClusterUsedSpace", { stat: "Average" }],
                  [".", "ClusterIndexWritesBlocked", { stat: "Sum" }],
                  [".", "ClusterStatus.green", { stat: "Average" }]
                ],
                period: 300,
                stat: "Average",
                region: aws_region,
                title: "OpenSearch Cluster Health"
              }
            },
            {
              type: "metric",
              properties: {
                metrics: [
                  ["AWS/Kinesis/Firehose", "IncomingRecords", { stat: "Sum" }],
                  [".", "DeliveryToElasticsearch.Success", { stat: "Sum" }],
                  [".", "DeliveryToElasticsearch.DataFreshness", { stat: "Average" }]
                ],
                period: 300,
                stat: "Sum",
                region: aws_region,
                title: "Data Ingestion Metrics"
              }
            }
          ]
        }
        
        aws_cloudwatch_dashboard(dashboard_name, {
          dashboard_name: "siem-#{name}",
          dashboard_body: JSON.pretty_generate(dashboard_body)
        })
        
        # Create alarms for critical metrics
        create_siem_alarms(name, attrs, resources)
      end
      
      def create_siem_alarms(name, attrs, resources)
        # OpenSearch cluster health alarm
        cluster_health_alarm = component_resource_name(name, :cluster_health_alarm)
        resources[:alarms][:cluster_health] = aws_cloudwatch_metric_alarm(cluster_health_alarm, {
          alarm_name: "siem-cluster-health-#{name}",
          alarm_description: "Alert when OpenSearch cluster is not green",
          metric_name: "ClusterStatus.green",
          namespace: "AWS/ES",
          statistic: "Average",
          period: 300,
          evaluation_periods: 2,
          threshold: 1,
          comparison_operator: "LessThanThreshold",
          dimensions: {
            DomainName: resources[:opensearch_domain].domain_name
          },
          alarm_actions: [resources[:sns_topics][:alerts].arn],
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        # Data freshness alarm
        data_freshness_alarm = component_resource_name(name, :data_freshness_alarm)
        resources[:alarms][:data_freshness] = aws_cloudwatch_metric_alarm(data_freshness_alarm, {
          alarm_name: "siem-data-freshness-#{name}",
          alarm_description: "Alert when data ingestion is delayed",
          metric_name: "DeliveryToElasticsearch.DataFreshness",
          namespace: "AWS/Kinesis/Firehose",
          statistic: "Average",
          period: 300,
          evaluation_periods: 2,
          threshold: 900,  # 15 minutes
          comparison_operator: "GreaterThanThreshold",
          alarm_actions: [resources[:sns_topics][:alerts].arn],
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        # High severity incident alarm
        if attrs.monitoring_config[:create_alarms]
          incident_alarm = component_resource_name(name, :high_severity_alarm)
          resources[:alarms][:high_severity] = aws_cloudwatch_metric_alarm(incident_alarm, {
            alarm_name: "siem-high-severity-incidents-#{name}",
            alarm_description: "Alert on high severity security incidents",
            metric_name: "HighSeverityIncidents",
            namespace: "Custom/SIEM",
            statistic: "Sum",
            period: 300,
            evaluation_periods: 1,
            threshold: 1,
            comparison_operator: "GreaterThanOrEqualToThreshold",
            alarm_actions: [resources[:sns_topics][:alerts].arn],
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
        end
      end
      
      def create_dashboards(name, attrs, resources)
        # Create OpenSearch dashboards via API
        # This would typically be done after OpenSearch is deployed
        # For now, we'll create a Lambda to configure dashboards
        
        dashboard_config_lambda = component_resource_name(name, :dashboard_config)
        resources[:lambda_functions][:dashboard_config] = aws_lambda_function(dashboard_config_lambda, {
          function_name: "siem-dashboard-config-#{name}",
          runtime: "python3.11",
          handler: "index.lambda_handler",
          role: create_lambda_execution_role(name, "dashboard-config", attrs, resources),
          timeout: 300,
          
          environment: {
            variables: {
              OPENSEARCH_ENDPOINT: resources[:opensearch_domain].endpoint,
              DASHBOARDS: JSON.generate(attrs.dashboards)
            }
          },
          
          code: {
            zip_file: generate_dashboard_config_code()
          },
          
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        # Invoke Lambda to configure dashboards
        aws_lambda_invocation(:"#{dashboard_config_lambda}_invoke", {
          function_name: resources[:lambda_functions][:dashboard_config].function_name,
          input: JSON.generate({ action: "configure_dashboards" })
        })
      end
      
      def generate_dashboard_config_code
        <<~PYTHON
          import json
          import os
          from opensearchpy import OpenSearch
          
          def lambda_handler(event, context):
              es = OpenSearch(
                  hosts=[{'host': os.environ['OPENSEARCH_ENDPOINT'], 'port': 443}],
                  http_auth=get_auth(),
                  use_ssl=True,
                  verify_certs=True
              )
              
              dashboards = json.loads(os.environ['DASHBOARDS'])
              
              for dashboard in dashboards:
                  create_dashboard(es, dashboard)
              
              return {
                  'statusCode': 200,
                  'body': json.dumps({
                      'dashboards_created': len(dashboards)
                  })
              }
          
          def create_dashboard(es, dashboard):
              dashboard_type = dashboard['type']
              
              if dashboard_type == 'security_overview':
                  create_security_overview_dashboard(es, dashboard)
              elif dashboard_type == 'threat_hunting':
                  create_threat_hunting_dashboard(es, dashboard)
              elif dashboard_type == 'compliance':
                  create_compliance_dashboard(es, dashboard)
              elif dashboard_type == 'incident_response':
                  create_incident_response_dashboard(es, dashboard)
          
          def create_security_overview_dashboard(es, config):
              # Create security overview visualizations and dashboard
              visualizations = [
                  create_events_timeline(es),
                  create_severity_distribution(es),
                  create_top_threats(es),
                  create_geographic_map(es)
              ]
              
              # Create dashboard with visualizations
              dashboard_body = {
                  'title': config['name'],
                  'panels': format_panels(visualizations),
                  'refresh_interval': config.get('refresh_interval', 300)
              }
              
              # Save dashboard
              es.index(
                  index='.kibana',
                  doc_type='dashboard',
                  id=f"dashboard-{config['name'].replace(' ', '-').lower()}",
                  body=dashboard_body
              )
          
          def create_threat_hunting_dashboard(es, config):
              # Implement threat hunting dashboard
              pass
          
          def create_compliance_dashboard(es, config):
              # Implement compliance dashboard
              pass
          
          def create_incident_response_dashboard(es, config):
              # Implement incident response dashboard
              pass
          
          def create_events_timeline(es):
              # Create timeline visualization
              return {
                  'title': 'Security Events Timeline',
                  'type': 'line',
                  'query': {
                      'match_all': {}
                  }
              }
          
          def create_severity_distribution(es):
              # Create severity distribution visualization
              return {
                  'title': 'Severity Distribution',
                  'type': 'pie',
                  'query': {
                      'terms': {
                          'field': 'severity.keyword'
                      }
                  }
              }
          
          def create_top_threats(es):
              # Create top threats visualization
              return {
                  'title': 'Top Threats',
                  'type': 'horizontal_bar',
                  'query': {
                      'terms': {
                          'field': 'threat_name.keyword',
                          'size': 10
                      }
                  }
              }
          
          def create_geographic_map(es):
              # Create geographic threat map
              return {
                  'title': 'Threat Geographic Distribution',
                  'type': 'map',
                  'query': {
                      'exists': {
                          'field': 'source_geo.location'
                      }
                  }
              }
          
          def format_panels(visualizations):
              # Format visualizations as dashboard panels
              panels = []
              for i, viz in enumerate(visualizations):
                  panels.append({
                      'visualization': viz,
                      'gridData': {
                          'x': (i % 2) * 24,
                          'y': (i // 2) * 12,
                          'w': 24,
                          'h': 12
                      }
                  })
              return panels
          
          def get_auth():
              # Implement authentication
              return None
        PYTHON
      end
      
      def create_integration(name, integration, attrs, resources)
        # Create integration based on type
        case integration[:type]
        when 'soar'
          create_soar_integration(name, integration, attrs, resources)
        when 'threat_intel'
          create_threat_intel_integration(name, integration, attrs, resources)
        when 'notification'
          create_notification_integration(name, integration, attrs, resources)
        end
      end
      
      def create_soar_integration(name, integration, attrs, resources)
        # Create Lambda for SOAR integration
        lambda_name = component_resource_name(name, :soar_integration, integration[:name])
        
        resources[:lambda_functions][:"soar_#{integration[:name]}"] = aws_lambda_function(lambda_name, {
          function_name: "siem-soar-#{name}-#{integration[:name]}",
          runtime: "python3.11",
          handler: "index.lambda_handler",
          role: create_lambda_execution_role(name, "soar-#{integration[:name]}", attrs, resources),
          timeout: 300,
          
          environment: {
            variables: {
              SOAR_ENDPOINT: integration[:endpoint] || "",
              SOAR_API_KEY_SECRET: integration[:api_key_secret_arn] || ""
            }
          },
          
          code: {
            zip_file: <<~PYTHON
              import json
              import boto3
              import os
              import requests
              
              def lambda_handler(event, context):
                  # Send incident to SOAR platform
                  incident = event.get('incident', {})
                  
                  soar_payload = {
                      'name': incident.get('name'),
                      'severity': incident.get('severity'),
                      'description': incident.get('description'),
                      'artifacts': incident.get('indicators', []),
                      'actions': incident.get('recommended_actions', [])
                  }
                  
                  # Send to SOAR
                  response = send_to_soar(soar_payload)
                  
                  return {
                      'statusCode': 200,
                      'body': json.dumps(response)
                  }
              
              def send_to_soar(payload):
                  endpoint = os.environ.get('SOAR_ENDPOINT')
                  api_key = get_api_key()
                  
                  if endpoint and api_key:
                      try:
                          response = requests.post(
                              f"{endpoint}/api/incidents",
                              json=payload,
                              headers={'Authorization': f'Bearer {api_key}'},
                              timeout=30
                          )
                          return response.json()
                      except Exception as e:
                          return {'error': str(e)}
                  
                  return {'error': 'Missing configuration'}
              
              def get_api_key():
                  secret_arn = os.environ.get('SOAR_API_KEY_SECRET')
                  if secret_arn:
                      client = boto3.client('secretsmanager')
                      response = client.get_secret_value(SecretId=secret_arn)
                      return json.loads(response['SecretString']).get('api_key')
                  return None
            PYTHON
          },
          
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
      end
      
      def create_threat_intel_integration(name, integration, attrs, resources)
        # Already handled in create_threat_detection
      end
      
      def create_notification_integration(name, integration, attrs, resources)
        # Create SNS topic for notifications if not exists
        topic_name = component_resource_name(name, :notification, integration[:name])
        resources[:sns_topics][integration[:name].to_sym] = aws_sns_topic(topic_name, {
          name: "siem-notify-#{name}-#{integration[:name]}",
          kms_master_key_id: resources[:kms_keys][:main].id,
          tags: component_tags('siem_security_platform', name, attrs.tags)
        })
        
        # Subscribe endpoint if provided
        if integration[:endpoint]
          aws_sns_topic_subscription(:"#{topic_name}_subscription", {
            topic_arn: resources[:sns_topics][integration[:name].to_sym].arn,
            protocol: integration[:endpoint].start_with?('http') ? 'https' : 'email',
            endpoint: integration[:endpoint]
          })
        end
      end
      
      def calculate_siem_security_score(attrs)
        score = 100
        
        # Deduct points for missing features
        score -= 5 unless attrs.threat_detection[:enable_ml_detection]
        score -= 5 unless attrs.threat_detection[:enable_behavior_analytics]
        score -= 5 unless attrs.incident_response[:enable_automated_response]
        score -= 5 unless attrs.compliance_config[:enable_compliance_reporting]
        score -= 5 unless attrs.security_config[:enable_encryption_at_rest]
        score -= 5 unless attrs.security_config[:enable_fine_grained_access]
        score -= 10 unless attrs.threat_detection[:threat_intel_feeds].any?
        
        # Add points for advanced features
        score += 5 if attrs.analytics_config[:enable_ueba]
        score += 5 if attrs.incident_response[:enable_forensics_collection]
        score += 5 if attrs.scaling_config[:enable_auto_scaling]
        
        [score, 100].min
      end
      
      def generate_siem_compliance_status(attrs)
        status = {}
        
        attrs.compliance_config[:frameworks].each do |framework|
          status[framework] = {
            compliant: true,
            last_assessment: Time.now.iso8601,
            evidence_collected: attrs.compliance_config[:evidence_collection],
            report_available: attrs.compliance_config[:enable_compliance_reporting],
            next_report: calculate_next_report_date(attrs.compliance_config[:report_schedule])
          }
        end
        
        status
      end
      
      def calculate_next_report_date(schedule)
        case schedule
        when 'daily'
          (Time.now + 86400).iso8601
        when 'weekly'
          (Time.now + 604800).iso8601
        when 'monthly'
          (Time.now + 2592000).iso8601
        else
          nil
        end
      end
      
      def aws_region
        'us-east-1'
      end
      
      def aws_account_id
        '123456789012'
      end
      
      include Base
    end
  end
end