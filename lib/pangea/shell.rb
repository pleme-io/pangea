require 'open3'
module Pangea
  module Shell
    class << self
      def run(command)
        Open3.popen3(command) do |_stdin, stdout, stderr, wait_thr|
          # Process standard output
          stdout.each_line do |line|
            parsed = JSON.parse(line.strip)
            puts JSON.pretty_generate(parsed)
            puts "\n---\n" # Separator between JSON objects
          rescue JSON::ParserError
            warn "⚠️  Invalid JSON received: #{line.inspect}"
          end

          # Handle standard error
          unless (err = stderr.read).empty?
            warn "\n❌ Command errors:\n#{err}"
          end

          exit_status = wait_thr.value
          warn "\n🔥 Command failed with status #{exit_status.exitstatus}" unless exit_status.success?
        end
      end
    end
  end
end
