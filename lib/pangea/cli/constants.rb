module Constants
  ARTIFACT_FILE = %(artifact.tf.json).freeze

  CACHE_DIR = File.join(
    Dir.home,
    %(.cache),
    %(pangea)
  ).freeze

  PROJECT_VERSION = %i[version.rb].freeze

  # order of elements matters here
  # projects should be processed
  # by collecting ruby files in exactly
  # this order. changing this can significantly
  # impact how a project is processed.
  PROJECT_SRC_DIRS = %i[
    resources
    post
    lib
    pre
  ].freeze

  # configuration extensions
  EXTENSIONS = %i[
    json
    toml
    yaml
    yml
    nix
    rb
  ].freeze
end
