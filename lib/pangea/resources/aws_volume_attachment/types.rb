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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS EBS Volume Attachment resources
      # Provides an AWS EBS Volume Attachment as a top level resource, to attach and detach EBS volumes from EC2 instances.
      class VolumeAttachmentAttributes < Dry::Struct
        # Device name to expose to the instance (required)
        # Linux: /dev/sdf through /dev/sdp, /dev/xvdf through /dev/xvdp
        # Windows: xvdf through xvdp
        attribute :device_name, Resources::Types::String.constrained(
          format: /\A(?:\/dev\/(?:sd[f-p]|xvd[f-p])|xvd[f-p])\z/
        )
        
        # ID of the instance to attach the volume to (required)
        attribute :instance_id, Resources::Types::String
        
        # ID of the volume to attach (required)
        attribute :volume_id, Resources::Types::String
        
        # Force detach on destroy (optional, default false)
        attribute :force_detach, Resources::Types::Bool.default(false)
        
        # Skip destroying volume attachment on destroy (optional, default false)
        attribute :skip_destroy, Resources::Types::Bool.default(false)
        
        # Stop instance before detaching (optional, default false)
        attribute :stop_instance_before_detaching, Resources::Types::Bool.default(false)
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate device name format based on platform conventions
          device_name = attrs.device_name
          
          # Check for valid device name patterns
          if device_name.match?(/\A\/dev\/sd[a-e]\z/)
            raise Dry::Struct::Error, "Device names /dev/sda through /dev/sde are reserved by AWS"
          end
          
          if device_name.match?(/\Axvd[a-e]\z/)
            raise Dry::Struct::Error, "Device names xvda through xvde are reserved by AWS"
          end
          
          # Warn about potential conflicts with common naming
          if device_name == '/dev/sdf' || device_name == 'xvdf'
            # This is fine, but first additional volume
          end
          
          attrs
        end
        
        # Check if using Linux device naming convention
        def linux_device_naming?
          device_name.start_with?('/dev/')
        end
        
        # Check if using Windows device naming convention
        def windows_device_naming?
          device_name.match?(/\Axvd[f-p]\z/)
        end
        
        # Get normalized device name (convert Linux to Windows format)
        def normalized_device_name
          if linux_device_naming?
            device_name.sub('/dev/', '')
          else
            device_name
          end
        end
        
        # Get Linux device name format
        def linux_device_name
          if windows_device_naming?
            "/dev/#{device_name}"
          else
            device_name
          end
        end
        
        # Check if this is the first additional volume (commonly used)
        def first_additional_volume?
          normalized_device_name == 'sdf' || normalized_device_name == 'xvdf'
        end
        
        # Get device letter (f, g, h, etc.)
        def device_letter
          normalized_device_name.match(/[f-p]/).to_s
        end
        
        # Check if device name follows recommended practices
        def follows_naming_best_practices?
          # AWS recommends /dev/sd[f-p] for Linux, xvd[f-p] for Windows
          linux_device_naming? || windows_device_naming?
        end
        
        # Get next available device name suggestion
        def suggest_next_device_name(platform: :linux)
          current_letter = device_letter
          return nil unless current_letter
          
          next_letter = (current_letter.ord + 1).chr
          return nil if next_letter > 'p'
          
          if platform == :linux
            "/dev/sd#{next_letter}"
          else
            "xvd#{next_letter}"
          end
        end
        
        # Check if attachment allows force detach
        def supports_force_detach?
          true # All volume attachments support force detach
        end
        
        # Check if this attachment configuration is safe for production
        def production_safe?
          # In production, generally avoid force_detach and stop_instance_before_detaching
          !force_detach && !stop_instance_before_detaching
        end
        
        # Get detachment behavior summary
        def detachment_behavior
          behaviors = []
          behaviors << "force_detach" if force_detach
          behaviors << "skip_destroy" if skip_destroy
          behaviors << "stop_instance_before_detaching" if stop_instance_before_detaching
          behaviors.empty? ? "standard" : behaviors.join(", ")
        end
        
        # Validate device name compatibility with common OS types
        def validate_device_name_for_os(os_type)
          case os_type.to_sym
          when :linux, :ubuntu, :debian, :centos, :rhel, :amazon_linux
            unless linux_device_naming?
              return "Linux instances expect device names in format /dev/sd[f-p], got: #{device_name}"
            end
          when :windows
            unless windows_device_naming?
              return "Windows instances expect device names in format xvd[f-p], got: #{device_name}"
            end
          else
            return "Unknown OS type: #{os_type}"
          end
          
          nil # No validation errors
        end
      end
    end
      end
    end
  end
end