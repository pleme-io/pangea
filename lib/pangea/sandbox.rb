###############################################################################
# sandbox
#
# modules need an execution space which I'm naming sandboxes
# sandboxes will contain the ruby interpreter, associated packages
# and pangea DSL code for the execution of a single module
###############################################################################

class SandboxRuby
  attr_reader(*%i[base_dir name gemset version])

  def initialize(base_dir:, name:, gemset:, version:)
    @base_dir = base_dir
    @version  = version
    @name     = name
    @gemset   = gemset
  end
end

class SandBox
  attr_reader(*%i[base_dir name rubies])

  def initialize(
    name:,
    base_dir: %(~/.pangea/sandbox),
    rubies: []
  )
    @base_dir = base_dir
    @name     = name
    @rubies   = rubies

    @rubies_dir = File.join(@base_dir, @name, %(rubies))

    @ruby_build_cmd = %(ruby-build)
  end

  def prepare_sandbox
    ensure_base_dir_exists
    ensure_rubies_directories_exist
    check_ruby_build_installed
    ensure_rubies_installed
  end

  def clean_sandbox
    system %(rm -rf #{base_dir})
  end

  private

  def ensure_base_dir_exists
    system %(mkdir -p #{base_dir}) unless Dir.exist?(base_dir)
  end

  def ensure_rubies_directories_exist
    rubies.each do |ruby|
      ruby_dir = File.join(@rubies_dir, ruby.version, ruby.gemset, ruby.name)
      system %(mkdir -p #{ruby_dir}) unless Dir.exist?(ruby_dir)
    end
  end

  def command_exists_on_path?(cmd)
    system("which #{cmd} > /dev/null 2>&1")
  end

  def ruby_build_installed?
    command_exists_on_path?(@ruby_build_cmd)
  end

  def ensure_rubies_installed
    rubies.each do |ruby|
      ruby_dir = File.join(@rubies_dir, ruby.version, ruby.gemset, ruby.name)
      system %(#{@ruby_build_cmd} #{ruby.version} #{ruby_dir}) unless File.exist?(
        File.join(
          ruby_dir,
          %(.installed_by_pangea)
        )
      )
      system %(touch #{File.join(ruby_dir, %(.installed_by_pangea))}) unless File.exist?(
        File.join(
          ruby_dir,
          %(.installed_by_pangea)
        )
      )
    end
  end

  def check_ruby_build_installed
    raise %(ruby-build not installed) unless ruby_build_installed?
  end
end
