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


require 'pangea/resources/base'
require 'pangea/resources/aws_efs_access_point/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Creates an AWS EFS Access Point for application-specific file system access
      # 
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Access point configuration
      # @return [ResourceReference] Reference to the created access point
      def aws_efs_access_point(name, attributes = {})
        validated_attrs = AWS::Types::Types::EfsAccessPointAttributes.new(attributes)
        
        resource_attributes = {
          file_system_id: validated_attrs.file_system_id,
          tags: validated_attrs.tags
        }
        
        # Add POSIX user configuration if specified
        if validated_attrs.posix_user
          resource_attributes[:posix_user] = [validated_attrs.posix_user]
        end
        
        # Add root directory configuration if specified
        if validated_attrs.root_directory
          root_dir = validated_attrs.root_directory.dup
          
          # Ensure path defaults to "/"
          root_dir[:path] = "/" unless root_dir[:path]
          
          resource_attributes[:root_directory] = [root_dir]
        end
        
        resource(:aws_efs_access_point, name, resource_attributes)
        
        ResourceReference.new(
          type: :aws_efs_access_point,
          name: name,
          attributes: validated_attrs,
          outputs: {
            id: "${aws_efs_access_point.#{name}.id}",
            arn: "${aws_efs_access_point.#{name}.arn}",
            file_system_arn: "${aws_efs_access_point.#{name}.file_system_arn}",
            file_system_id: "${aws_efs_access_point.#{name}.file_system_id}",
            owner_id: "${aws_efs_access_point.#{name}.owner_id}",
            root_directory_arn: "${aws_efs_access_point.#{name}.root_directory_arn}",
            root_directory_path: "${aws_efs_access_point.#{name}.root_directory[0].path}",
            posix_user_uid: "${aws_efs_access_point.#{name}.posix_user[0].uid}",
            posix_user_gid: "${aws_efs_access_point.#{name}.posix_user[0].gid}",
            tags_all: "${aws_efs_access_point.#{name}.tags_all}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)