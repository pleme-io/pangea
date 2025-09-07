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
require 'pangea/types'

module Pangea
  module Execution
    # Manages Pangea workspace directories and files
    class WorkspaceManager
      attr_reader :base_dir
      
      def initialize(base_dir: nil)
        @base_dir = base_dir || File.join(Dir.home, '.pangea')
        ensure_base_directory!
      end
      
      # Get workspace directory for a namespace/project
      def workspace_for(namespace:, project: nil, site: nil)
        parts = [@base_dir, 'workspaces', namespace]
        parts << site if site
        parts << project if project
        
        path = File.join(*parts.compact)
        ensure_directory!(path)
        path
      end
      
      # Create or update terraform files in workspace
      def write_terraform_json(workspace:, content:, filename: 'main.tf.json')
        ensure_directory!(workspace)
        
        file_path = File.join(workspace, filename)
        
        # Pretty print JSON for readability
        json_content = JSON.pretty_generate(content)
        
        File.write(file_path, json_content)
        file_path
      end
      
      # Read terraform JSON from workspace
      def read_terraform_json(workspace:, filename: 'main.tf.json')
        file_path = File.join(workspace, filename)
        
        return nil unless File.exist?(file_path)
        
        content = File.read(file_path)
        JSON.parse(content, symbolize_names: true)
      rescue JSON::ParserError => e
        raise WorkspaceError, "Invalid JSON in #{file_path}: #{e.message}"
      end
      
      # Check if workspace has been initialized
      def initialized?(workspace)
        terraform_dir = File.join(workspace, '.terraform')
        lock_file = File.join(workspace, '.terraform.lock.hcl')
        
        Dir.exist?(terraform_dir) || File.exist?(lock_file)
      end
      
      # Clean workspace (remove generated files)
      def clean(workspace)
        return unless Dir.exist?(workspace)
        
        # Remove terraform working files
        FileUtils.rm_rf(File.join(workspace, '.terraform'))
        FileUtils.rm_f(File.join(workspace, '.terraform.lock.hcl'))
        FileUtils.rm_f(Dir.glob(File.join(workspace, '*.tfplan')))
        FileUtils.rm_f(Dir.glob(File.join(workspace, '*.tfstate*')))
      end
      
      # Remove entire workspace
      def remove(workspace)
        FileUtils.rm_rf(workspace) if Dir.exist?(workspace)
      end
      
      # List all workspaces
      def list_workspaces
        workspaces_dir = File.join(@base_dir, 'workspaces')
        return [] unless Dir.exist?(workspaces_dir)
        
        # Find all directories with terraform files
        Dir.glob(File.join(workspaces_dir, '**', '*.tf.json')).map do |file|
          File.dirname(file).sub("#{workspaces_dir}/", '')
        end.uniq.sort
      end
      
      # Get workspace metadata
      def workspace_metadata(workspace)
        metadata_file = File.join(workspace, '.pangea-metadata.json')
        
        return {} unless File.exist?(metadata_file)
        
        JSON.parse(File.read(metadata_file), symbolize_names: true)
      rescue JSON::ParserError
        {}
      end
      
      # Save workspace metadata
      def save_metadata(workspace:, metadata:)
        ensure_directory!(workspace)
        
        metadata_file = File.join(workspace, '.pangea-metadata.json')
        
        # Add timestamp
        metadata[:updated_at] = Time.now.iso8601
        
        File.write(metadata_file, JSON.pretty_generate(metadata))
      end
      
      # Get cache directory
      def cache_dir
        path = File.join(@base_dir, 'cache')
        ensure_directory!(path)
        path
      end
      
      # Get modules directory
      def modules_dir
        path = File.join(@base_dir, 'modules')
        ensure_directory!(path)
        path
      end
      
      # Create a temporary workspace
      def temp_workspace
        require 'tmpdir'
        
        Dir.mktmpdir('pangea-workspace-') do |dir|
          yield dir if block_given?
        end
      end
      
      private
      
      def ensure_base_directory!
        ensure_directory!(@base_dir)
        ensure_directory!(File.join(@base_dir, 'workspaces'))
      end
      
      def ensure_directory!(path)
        FileUtils.mkdir_p(path) unless Dir.exist?(path)
      end
    end
    
    # Workspace-related errors
    class WorkspaceError < StandardError; end
  end
end