require 'stringio'
include Java
java_import org.jenkinsci.plugins.tokenmacro.TokenMacro

class NvmWrapper < Jenkins::Tasks::BuildWrapper
  display_name "Run the build in an NVM managed environment"

  DEFAULT_VERSION = ''

  transient :launcher, :nvm_path

  attr_accessor :version

  def initialize(attrs)
    @version = fix_empty(attrs['version']) || DEFAULT_VERSION
  end

  def nvm_path
    @nvm_path ||= ["~/.nvm/nvm.sh", "/usr/local/nvm/nvm.sh"].find do |path|
      @launcher.execute("bash", "-c", "test -f #{path}") == 0
    end
  end

  def nvm_installed?
    ! nvm_path.nil?
  end

  def setup(build, launcher, listener)
    @launcher = launcher
    nvm_string = TokenMacro.expandAll(build.native, listener.native, @version)

    listener << "Capturing environment variables produced by 'nvm use #{nvm_string}'\n"

    before = StringIO.new()
    if launcher.execute("bash", "-c", "export", {:out => before}) != 0 then
      listener << "Failed to fork bash\n"
      listener << before.string
      build.abort
    end

    if !nvm_installed?
      listener << "Installing NVM\n"
      installer = build.workspace + "nvm-installer"
      installer.native.copyFrom(java.net.URL.new("https://raw.github.com/creationix/nvm/master/install.sh"))
      installer.chmod(0755)
      launcher.execute(installer.realpath, {:out => listener})
    end

    if launcher.execute("bash","-c"," source #{nvm_path} && nvm install #{version} && nvm use #{version} && export > nvm.env", :out => listener, :chdir => build.workspace) != 0 then
      build.abort "Failed to setup NVM environment"
    end

    bh = to_hash(before.string, listener)
    ah = to_hash((build.workspace + "nvm.env").read, listener)

    ah.each do |k,v|
      bv = bh[k]

      next if %w(HUDSON_COOKIE JENKINS_COOKIE).include? k # cookie Jenkins uses to track process tree. ignore.
      next if bv == v  # no change in value

      if k == "PATH" then
        # look for PATH components that include ".nvm" and pick those up
        path = v.split(File::PATH_SEPARATOR).find_all{|p| p =~ /[\\\/]\.nvm[\\\/]/ }.join(File::PATH_SEPARATOR)
        build.env["PATH+NVM"] = path
        #listener.debug "Adding PATH+NVM=#{path}"
      else
        #listener.debug "Adding #{k}=#{v}"
        build.env[k] = v
      end
    end
  end

  private

  def fix_empty(s)
    s == "" ? nil : s
  end

  def to_hash(export, listener)
    r = {}
    export.split("\n").each do |l|
      if l.start_with? "declare -x " then
        l = l[11..-1]  # trim off "declare -x "
        k,v = l.split("=", 2)
        if v then
          r[k] = (v[0] == ?" || v[0] == ?') ? v[1..-2] : v # trim off the quote surrounding it
        end
      end
    end
    r
  end
end
