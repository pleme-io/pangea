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

require 'webrick'
require 'json'
require 'tempfile'
require 'pangea'
require 'pangea/compilation/template_compiler'
require 'pangea/resources'

module Pangea
  # HTTP server for compiling Pangea DSL templates to Terraform JSON.
  # Used as a sidecar in the pangea-operator deployment.
  class CompilerServer
    DEFAULT_HOST = '0.0.0.0'
    DEFAULT_PORT = 8082

    def initialize(host: nil, port: nil)
      @host = host || ENV.fetch('COMPILE_HOST', DEFAULT_HOST)
      @port = (port || ENV.fetch('COMPILE_PORT', DEFAULT_PORT)).to_i
      @server = nil
    end

    def start
      @server = WEBrick::HTTPServer.new(
        BindAddress: @host,
        Port: @port,
        Logger: WEBrick::Log.new($stderr, WEBrick::Log::INFO),
        AccessLog: [[File.open('/dev/null', 'w'), WEBrick::AccessLog::COMMON_LOG_FORMAT]]
      )

      mount_routes
      setup_signal_handlers

      puts "Pangea Compiler Server starting on #{@host}:#{@port}"
      @server.start
    end

    def stop
      @server&.shutdown
    end

    private

    def mount_routes
      @server.mount_proc('/health') { |_req, res| handle_health(res) }
      @server.mount_proc('/compile') { |req, res| handle_compile(req, res) }
    end

    def setup_signal_handlers
      %w[INT TERM].each do |signal|
        trap(signal) { stop }
      end
    end

    def handle_health(res)
      res.status = 200
      res.content_type = 'application/json'
      res.body = JSON.generate(status: 'healthy', service: 'pangea-compiler')
    end

    def handle_compile(req, res)
      unless req.request_method == 'POST'
        return error_response(res, 405, 'Method not allowed')
      end

      begin
        body = JSON.parse(req.body)
        template = body['template']
        namespace = body['namespace']
        template_name = body['template_name']

        unless template
          return error_response(res, 400, 'Missing required field: template')
        end

        result = compile_template(template, namespace, template_name)
        success_response(res, result)
      rescue JSON::ParserError => e
        error_response(res, 400, "Invalid JSON: #{e.message}")
      rescue StandardError => e
        error_response(res, 500, "Compilation error: #{e.message}")
      end
    end

    def compile_template(template_source, namespace, template_name)
      # Write template to temp file for compilation
      tempfile = Tempfile.new(['pangea_template', '.rb'])
      begin
        tempfile.write(template_source)
        tempfile.close

        compiler = Pangea::Compilation::TemplateCompiler.new(
          namespace: namespace,
          template_name: template_name
        )
        compiler.compile_file(tempfile.path)
      ensure
        tempfile.unlink
      end
    end

    def success_response(res, result)
      res.status = 200
      res.content_type = 'application/json'
      res.body = JSON.generate(
        success: true,
        terraform_json: result
      )
    end

    def error_response(res, status, message)
      res.status = status
      res.content_type = 'application/json'
      res.body = JSON.generate(
        success: false,
        error: message
      )
    end
  end
end
