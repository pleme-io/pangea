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
require 'terraform-synthesizer'
require 'pangea/resources/aws_kinesis_analytics_application/resource'

RSpec.describe 'aws_kinesis_analytics_application synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }
  let(:service_role_arn) { 'arn:aws:iam::123456789012:role/kinesis-analytics-role' }
  let(:kinesis_stream_arn) { 'arn:aws:kinesis:us-east-1:123456789012:stream/my-stream' }
  let(:firehose_arn) { 'arn:aws:firehose:us-east-1:123456789012:deliverystream/my-delivery' }

  describe 'terraform synthesis' do
    it 'synthesizes basic Flink application' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_analytics_application(:processor, {
          name: 'stream-processor',
          runtime_environment: 'FLINK-1_15',
          service_execution_role: 'arn:aws:iam::123456789012:role/kinesis-analytics-role',
          application_configuration: {
            application_code_configuration: {
              code_content: {
                s3_content_location: {
                  bucket_arn: 'arn:aws:s3:::my-app-bucket',
                  file_key: 'flink-app.jar'
                }
              },
              code_content_type: 'ZIPFILE'
            },
            flink_application_configuration: {
              checkpoint_configuration: {
                configuration_type: 'DEFAULT'
              },
              monitoring_configuration: {
                configuration_type: 'DEFAULT'
              },
              parallelism_configuration: {
                configuration_type: 'DEFAULT'
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      app = result[:resource][:aws_kinesisanalyticsv2_application][:processor]

      expect(app[:name]).to eq('stream-processor')
      expect(app[:runtime_environment]).to eq('FLINK-1_15')
    end

    it 'synthesizes Flink application with custom parallelism' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_analytics_application(:high_throughput, {
          name: 'high-throughput-processor',
          runtime_environment: 'FLINK-1_15',
          service_execution_role: 'arn:aws:iam::123456789012:role/kinesis-analytics-role',
          application_configuration: {
            application_code_configuration: {
              code_content: {
                s3_content_location: {
                  bucket_arn: 'arn:aws:s3:::my-app-bucket',
                  file_key: 'flink-app.jar'
                }
              },
              code_content_type: 'ZIPFILE'
            },
            flink_application_configuration: {
              checkpoint_configuration: {
                configuration_type: 'CUSTOM',
                checkpointing_enabled: true,
                checkpoint_interval: 60000
              },
              monitoring_configuration: {
                configuration_type: 'CUSTOM',
                log_level: 'INFO',
                metrics_level: 'APPLICATION'
              },
              parallelism_configuration: {
                configuration_type: 'CUSTOM',
                parallelism: 8,
                parallelism_per_kpu: 2,
                auto_scaling_enabled: true
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      app = result[:resource][:aws_kinesisanalyticsv2_application][:high_throughput]

      flink_config = app[:application_configuration][:flink_application_configuration]
      expect(flink_config[:parallelism_configuration][:parallelism]).to eq(8)
      expect(flink_config[:parallelism_configuration][:auto_scaling_enabled]).to be true
      expect(flink_config[:checkpoint_configuration][:checkpointing_enabled]).to be true
    end

    it 'synthesizes SQL application with input and output' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_analytics_application(:sql_app, {
          name: 'sql-analytics',
          runtime_environment: 'SQL-1_0',
          service_execution_role: 'arn:aws:iam::123456789012:role/kinesis-analytics-role',
          application_configuration: {
            sql_application_configuration: {
              inputs: [
                {
                  name_prefix: 'SOURCE_SQL_STREAM',
                  input_schema: {
                    record_columns: [
                      { name: 'event_id', sql_type: 'VARCHAR' },
                      { name: 'event_time', sql_type: 'TIMESTAMP' },
                      { name: 'value', sql_type: 'DOUBLE' }
                    ],
                    record_format: {
                      record_format_type: 'JSON',
                      mapping_parameters: {
                        json_mapping_parameters: {
                          record_row_path: '$'
                        }
                      }
                    },
                    record_encoding: 'UTF-8'
                  },
                  kinesis_streams_input: {
                    resource_arn: 'arn:aws:kinesis:us-east-1:123456789012:stream/input-stream'
                  }
                }
              ],
              outputs: [
                {
                  name: 'OUTPUT_STREAM',
                  destination_schema: {
                    record_format_type: 'JSON'
                  },
                  kinesis_firehose_output: {
                    resource_arn: 'arn:aws:firehose:us-east-1:123456789012:deliverystream/output-delivery'
                  }
                }
              ]
            }
          }
        })
      end

      result = synthesizer.synthesis
      app = result[:resource][:aws_kinesisanalyticsv2_application][:sql_app]

      expect(app[:runtime_environment]).to eq('SQL-1_0')
      sql_config = app[:application_configuration][:sql_application_configuration]
      expect(sql_config[:input]).to be_an(Array)
      expect(sql_config[:output]).to be_an(Array)
    end

    it 'synthesizes application with VPC configuration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_analytics_application(:vpc_app, {
          name: 'vpc-processor',
          runtime_environment: 'FLINK-1_15',
          service_execution_role: 'arn:aws:iam::123456789012:role/kinesis-analytics-role',
          application_configuration: {
            application_code_configuration: {
              code_content: {
                s3_content_location: {
                  bucket_arn: 'arn:aws:s3:::my-app-bucket',
                  file_key: 'flink-app.jar'
                }
              },
              code_content_type: 'ZIPFILE'
            },
            flink_application_configuration: {
              checkpoint_configuration: { configuration_type: 'DEFAULT' },
              monitoring_configuration: { configuration_type: 'DEFAULT' },
              parallelism_configuration: { configuration_type: 'DEFAULT' }
            },
            vpc_configuration: {
              subnet_ids: ['subnet-12345678', 'subnet-87654321'],
              security_group_ids: ['sg-12345678']
            }
          }
        })
      end

      result = synthesizer.synthesis
      app = result[:resource][:aws_kinesisanalyticsv2_application][:vpc_app]

      vpc_config = app[:application_configuration][:vpc_configuration]
      expect(vpc_config[:subnet_ids]).to include('subnet-12345678')
      expect(vpc_config[:security_group_ids]).to include('sg-12345678')
    end

    it 'synthesizes application with environment properties' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_analytics_application(:env_app, {
          name: 'env-processor',
          runtime_environment: 'FLINK-1_15',
          service_execution_role: 'arn:aws:iam::123456789012:role/kinesis-analytics-role',
          application_configuration: {
            application_code_configuration: {
              code_content: {
                s3_content_location: {
                  bucket_arn: 'arn:aws:s3:::my-app-bucket',
                  file_key: 'flink-app.jar'
                }
              },
              code_content_type: 'ZIPFILE'
            },
            flink_application_configuration: {
              checkpoint_configuration: { configuration_type: 'DEFAULT' },
              monitoring_configuration: { configuration_type: 'DEFAULT' },
              parallelism_configuration: { configuration_type: 'DEFAULT' }
            },
            environment_properties: {
              property_groups: [
                {
                  property_group_id: 'FlinkApplicationProperties',
                  property_map: {
                    'input.stream.name' => 'my-input-stream',
                    'output.stream.name' => 'my-output-stream'
                  }
                }
              ]
            }
          }
        })
      end

      result = synthesizer.synthesis
      app = result[:resource][:aws_kinesisanalyticsv2_application][:env_app]

      env_props = app[:application_configuration][:environment_properties]
      expect(env_props[:property_group]).to be_an(Array)
    end

    it 'synthesizes application with auto-start enabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_analytics_application(:auto_start, {
          name: 'auto-start-processor',
          runtime_environment: 'FLINK-1_15',
          service_execution_role: 'arn:aws:iam::123456789012:role/kinesis-analytics-role',
          start_application: true,
          application_configuration: {
            application_code_configuration: {
              code_content: {
                s3_content_location: {
                  bucket_arn: 'arn:aws:s3:::my-app-bucket',
                  file_key: 'flink-app.jar'
                }
              },
              code_content_type: 'ZIPFILE'
            },
            flink_application_configuration: {
              checkpoint_configuration: { configuration_type: 'DEFAULT' },
              monitoring_configuration: { configuration_type: 'DEFAULT' },
              parallelism_configuration: { configuration_type: 'DEFAULT' }
            }
          }
        })
      end

      result = synthesizer.synthesis
      app = result[:resource][:aws_kinesisanalyticsv2_application][:auto_start]

      expect(app[:start_application]).to be true
    end

    it 'synthesizes application with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_analytics_application(:tagged, {
          name: 'tagged-processor',
          runtime_environment: 'FLINK-1_15',
          service_execution_role: 'arn:aws:iam::123456789012:role/kinesis-analytics-role',
          application_configuration: {
            application_code_configuration: {
              code_content: {
                s3_content_location: {
                  bucket_arn: 'arn:aws:s3:::my-app-bucket',
                  file_key: 'flink-app.jar'
                }
              },
              code_content_type: 'ZIPFILE'
            },
            flink_application_configuration: {
              checkpoint_configuration: { configuration_type: 'DEFAULT' },
              monitoring_configuration: { configuration_type: 'DEFAULT' },
              parallelism_configuration: { configuration_type: 'DEFAULT' }
            }
          },
          tags: { Environment: 'production', Team: 'data-platform' }
        })
      end

      result = synthesizer.synthesis
      app = result[:resource][:aws_kinesisanalyticsv2_application][:tagged]

      expect(app[:tags][:Environment]).to eq('production')
      expect(app[:tags][:Team]).to eq('data-platform')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_analytics_application(:test, {
          name: 'test-processor',
          runtime_environment: 'FLINK-1_15',
          service_execution_role: 'arn:aws:iam::123456789012:role/kinesis-analytics-role',
          application_configuration: {
            application_code_configuration: {
              code_content: {
                s3_content_location: {
                  bucket_arn: 'arn:aws:s3:::my-app-bucket',
                  file_key: 'flink-app.jar'
                }
              },
              code_content_type: 'ZIPFILE'
            },
            flink_application_configuration: {
              checkpoint_configuration: { configuration_type: 'DEFAULT' },
              monitoring_configuration: { configuration_type: 'DEFAULT' },
              parallelism_configuration: { configuration_type: 'DEFAULT' }
            }
          }
        })
      end

      expect(ref.outputs[:arn]).to eq('${aws_kinesisanalyticsv2_application.test.arn}')
      expect(ref.outputs[:name]).to eq('${aws_kinesisanalyticsv2_application.test.name}')
      expect(ref.outputs[:id]).to eq('${aws_kinesisanalyticsv2_application.test.id}')
    end
  end

  describe 'terraform validation' do
    it 'produces valid terraform structure' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_analytics_application(:test, {
          name: 'test-processor',
          runtime_environment: 'FLINK-1_15',
          service_execution_role: 'arn:aws:iam::123456789012:role/kinesis-analytics-role',
          application_configuration: {
            application_code_configuration: {
              code_content: {
                s3_content_location: {
                  bucket_arn: 'arn:aws:s3:::my-app-bucket',
                  file_key: 'flink-app.jar'
                }
              },
              code_content_type: 'ZIPFILE'
            },
            flink_application_configuration: {
              checkpoint_configuration: { configuration_type: 'DEFAULT' },
              monitoring_configuration: { configuration_type: 'DEFAULT' },
              parallelism_configuration: { configuration_type: 'DEFAULT' }
            }
          }
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result[:resource]).to be_a(Hash)
      expect(result[:resource][:aws_kinesisanalyticsv2_application]).to be_a(Hash)
      expect(result[:resource][:aws_kinesisanalyticsv2_application][:test]).to be_a(Hash)
    end
  end

  describe 'resource composition' do
    it 'creates complete stream processing infrastructure' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        # Input stream
        aws_kinesis_stream(:input, {
          name: 'input-events',
          shard_count: 2
        })

        # Flink processor
        aws_kinesis_analytics_application(:processor, {
          name: 'event-processor',
          runtime_environment: 'FLINK-1_15',
          service_execution_role: 'arn:aws:iam::123456789012:role/kinesis-analytics-role',
          application_configuration: {
            application_code_configuration: {
              code_content: {
                s3_content_location: {
                  bucket_arn: 'arn:aws:s3:::my-app-bucket',
                  file_key: 'processor.jar'
                }
              },
              code_content_type: 'ZIPFILE'
            },
            flink_application_configuration: {
              checkpoint_configuration: { configuration_type: 'DEFAULT' },
              monitoring_configuration: { configuration_type: 'DEFAULT' },
              parallelism_configuration: {
                configuration_type: 'CUSTOM',
                parallelism: 4,
                auto_scaling_enabled: true
              }
            }
          }
        })

        # Output stream
        aws_kinesis_stream(:output, {
          name: 'output-events',
          shard_count: 4
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:aws_kinesis_stream]).to have_key(:input)
      expect(result[:resource][:aws_kinesis_stream]).to have_key(:output)
      expect(result[:resource][:aws_kinesisanalyticsv2_application]).to have_key(:processor)
    end
  end
end
