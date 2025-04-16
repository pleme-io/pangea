require 'pangea/utils'
require 'yaml'

module Pangea
  module Config
    class << self
      # Public: Returns a memoized configuration Hash.
      # The configuration is lazily loaded and deep-merged so that:
      # - Keys in pangea.yml override keys in ~/.config/pangea/config.yml
      # - Keys in ~/.config/pangea/config.yml override keys in /etc/pangea/config.yml
      def config
        @config ||= load_config
      end

      # File paths in increasing order of priority.
      CONFIG_PATHS = [
        '/etc/pangea/config.yml',
        File.expand_path('~/.config/pangea/config.yml'),
        'pangea.yml'
      ].freeze

      # Loads and deep-merges available YAML configuration files.
      def load_config
        merged = {}
        CONFIG_PATHS.each do |file_path|
          if File.exist?(file_path)
            data = YAML.load_file(file_path)
            merged = Pangea::Utils.deep_merge(merged, data) if data.is_a?(Hash)
          end
        end
        merged
      end
    end
  end
end
