require 'thor'

module OpsPreflight
  ROOT = File.expand_path('../../', __FILE__)

  require "ops_preflight/version"

  autoload :ExitCode, 'ops_preflight/exit_code.rb'
  autoload :Server, 'ops_preflight/server.rb'
  autoload :Client, 'ops_preflight/client.rb'
  autoload :Config, 'ops_preflight/config.rb'

  def self.root_path(*a)
    File.join ROOT, *a
  end
end
