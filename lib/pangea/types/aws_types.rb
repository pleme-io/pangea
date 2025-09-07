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
  module Types
    module AWSTypes
      AWS_REGIONS = %w[
        us-east-1 us-east-2 us-west-1 us-west-2
        eu-west-1 eu-west-2 eu-west-3 eu-central-1
        ap-northeast-1 ap-northeast-2 ap-southeast-1 ap-southeast-2
        ap-south-1 ca-central-1 sa-east-1
      ].freeze
      
      def self.register_all(registry)
        # AWS Region Type
        registry.register :aws_region, String do
          enum AWS_REGIONS
        end
        
        # AWS Availability Zone Type
        registry.register :aws_availability_zone, String do
          format /\A[a-z]{2}-[a-z]+-\d[a-z]\z/
        end
        
        # AWS ARN Type
        registry.register :aws_arn, String do
          format /\Aarn:aws:[a-z0-9\-]+:[a-z0-9\-]*:\d*:[a-z0-9\-\/\:\_\.]*\z/
        end
        
        # AWS Instance Type
        registry.register :aws_instance_type, String do
          format /\A[a-z]\d+[a-z]*\.[a-z0-9]+\z/
        end
        
        # AWS Tag Key Type
        registry.register :aws_tag_key, String do
          format /\A[\w\s\-\.\/\:\@\+\=]{1,128}\z/
          max_length 128
        end
        
        # AWS Tag Value Type
        registry.register :aws_tag_value, String do
          format /\A[\w\s\-\.\/\:\@\+\=\*]{0,256}\z/
          max_length 256
        end
        
        # AWS Tags Type
        registry.register :aws_tags, Hash do
          # Special handling for hash types
        end
      end
    end
  end
end