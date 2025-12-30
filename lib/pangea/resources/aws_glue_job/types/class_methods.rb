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

module Pangea
  module Resources
    module AWS
      module Types
        # Class methods for AWS Glue Job attributes
        module GlueJobClassMethods
          # Generate common default arguments based on job type
          def default_arguments_for_job_type(job_type, options = {})
            case job_type.to_s
            when 'etl'
              etl_default_arguments
            when 'streaming'
              streaming_default_arguments(options)
            when 'pythonshell'
              pythonshell_default_arguments(options)
            else
              base_default_arguments
            end
          end

          # Generate worker configuration recommendations
          def worker_recommendations_for_workload(workload_type, _data_size_gb = nil)
            recommendations = {
              'small_etl' => { worker_type: 'G.1X', number_of_workers: 2 },
              'medium_etl' => { worker_type: 'G.1X', number_of_workers: 10 },
              'large_etl' => { worker_type: 'G.2X', number_of_workers: 20 },
              'memory_intensive' => { worker_type: 'Z.2X', number_of_workers: 10 },
              'streaming' => { worker_type: 'G.1X', number_of_workers: 2 },
              'python_shell' => {}
            }
            recommendations[workload_type.to_s] || { worker_type: 'G.1X', number_of_workers: 5 }
          end

          private

          def base_default_arguments
            {
              '--job-language' => 'python',
              '--enable-metrics' => '',
              '--enable-continuous-cloudwatch-log' => 'true'
            }
          end

          def etl_default_arguments
            base_default_arguments.merge(
              '--enable-job-insights' => 'true',
              '--enable-auto-scaling' => 'true'
            )
          end

          def streaming_default_arguments(options)
            base_default_arguments.merge(
              '--enable-metrics' => '',
              '--continuous-log-logStream' => options[:log_stream] || 'glue-streaming-job',
              '--window-size' => options[:window_size] || '100',
              '--checkpoint-location' => options[:checkpoint_location] || 's3://bucket/checkpoints/'
            )
          end

          def pythonshell_default_arguments(options)
            {
              '--job-language' => 'python',
              '--python-modules-installer-option' => options[:python_modules] || ''
            }
          end
        end
      end
    end
  end
end
