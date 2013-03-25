module OpsPreflight
  class Client < Thor
    include Thor::Actions
    include ExitCode

    namespace :default

    source_root OpsPreflight.root_path

    class_option :verbose, :aliases => '-v', :type => :boolean
    class_option :simulate, :aliases => '-S', :type => :boolean
    class_option :trace, :aliases => '-t', :type => :boolean
    class_option :file, :aliases => '-f', :type => :string, :banner => '<CUSTOM DEPLOY FILE>'
    class_option :version, :aliases => '-V', :type => :boolean

    desc "init", "Initialize application to work with preflight"
    def init
      copy_file 'data/deploy.rb', 'config/deploy.rb'
    end

    desc "setup", "Set up the server's preflight environment; accepts any arguments mina supports"
    def setup(*args)
      run "bundle exec mina setup #{args.join(' ')}"
    end

    desc "deploy <RAILS_ENV>", "Deploys to the specified app environment; accepts any arguments mina supports"
    def deploy(rails_env, *args)
      run "bundle exec mina deploy RAILS_ENV=#{rails_env} #{args.join(' ')}"
    end

    # Fixes thor's banners when used with :default namespace
    def self.banner(command, namespace = nil, subcommand = false)
      "#{basename} #{command.formatted_usage(self, false, subcommand)}"
    end
  end
end
