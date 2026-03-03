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


require 'fileutils'
require 'json'
require 'pangea/backends/base'

module Pangea
  module Backends
    # Local file backend for Terraform state storage
    class Local < Base
      LOCK_FILE_EXTENSION = '.lock'
      
      def initialize(config = {})
        super
        @config[:path] ||= 'terraform.tfstate'
      end
      
      # Initialize the backend (ensure directory exists)
      def initialize!
        ensure_directory_exists!
        true
      end
      
      # Check if backend is properly configured
      def configured?
        true # Local backend is always configured
      end
      
      # Lock state for exclusive access
      def lock(lock_id:, info: {})
        lock_file = lock_file_path
        
        # Try to create lock file atomically
        return false if File.exist?(lock_file)
        
        lock_data = {
          id: lock_id,
          info: info,
          created: Time.now.iso8601,
          pid: Process.pid
        }
        
        begin
          File.open(lock_file, File::WRONLY | File::CREAT | File::EXCL) do |f|
            f.write(JSON.pretty_generate(lock_data))
          end
          true
        rescue Errno::EEXIST
          false
        end
      end
      
      # Unlock state
      def unlock(lock_id:)
        lock_file = lock_file_path
        
        if File.exist?(lock_file)
          # Verify lock ownership
          lock_data = JSON.parse(File.read(lock_file))
          if lock_data['id'] == lock_id
            File.delete(lock_file)
            return true
          end
        end
        
        false
      rescue JSON::ParserError, Errno::ENOENT
        false
      end
      
      # Check if state is locked
      def locked?
        lock_file = lock_file_path
        
        return false unless File.exist?(lock_file)
        
        # Check if lock is stale (process died)
        begin
          lock_data = JSON.parse(File.read(lock_file))
          pid = lock_data['pid']
          
          # Check if process is still alive
          if pid && !process_alive?(pid)
            # Stale lock, remove it
            File.delete(lock_file)
            return false
          end
          
          true
        rescue JSON::ParserError, Errno::ENOENT
          false
        end
      end
      
      # Get lock info
      def lock_info
        lock_file = lock_file_path
        
        return nil unless File.exist?(lock_file)
        
        lock_data = JSON.parse(File.read(lock_file))
        {
          id: lock_data['id'],
          info: lock_data['info'] || {},
          created: Time.parse(lock_data['created']),
          pid: lock_data['pid']
        }
      rescue JSON::ParserError, Errno::ENOENT
        nil
      end
      
      # Convert to Terraform backend configuration
      def to_terraform_config
        { local: { path: @config[:path] } }
      end
      
      protected
      
      def validate_config!
        # Ensure path is safe (skip if path is nil - will be set to default later)
        if @config[:path] && @config[:path].include?('..')
          raise ArgumentError, "Path cannot contain '..': #{@config[:path]}"
        end
      end
      
      private
      
      def lock_file_path
        @config[:path] + LOCK_FILE_EXTENSION
      end
      
      def ensure_directory_exists!
        dir = File.dirname(@config[:path])
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      end
      
      def process_alive?(pid)
        Process.kill(0, pid)
        true
      rescue Errno::ESRCH
        false
      end
    end
  end
end