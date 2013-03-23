module OpsPreflight
  class Client < Thor
    include Thor::Actions
    include ExitCode

    namespace :default

    desc "init", "Initialize application to work with preflight"
    def init
      copy_file OpsPreflight.root_path('data', 'deploy.rb'), 'config/deploy.rb'
    end

    desc "setup [<MINA_ARGS>]", "Set up the server's preflight environment; accepts any arguments mina supports"
    def setup(*args)
      run "bundle exec mina setup #{args.join(' ')}"
    end

    desc "deploy <rails_env> [<MINA_ARGS>]", "Deploys to the specified app environment; accepts any arguments mina supports"
    def deploy(rails_env, *args)
      run "bundle exec mina deploy RAILS_ENV=#{rails_env} #{args.join(' ')}"
    end

    # Fixes thor's banners when used with :default namespace
    def self.banner(command, namespace = nil, subcommand = false)
      "#{basename} #{command.formatted_usage(self, false, subcommand)}"
    end

    class Deploy < Thor
      include ExitCode

      namespace :deploy

      desc "production [<MINA_ARGS>]", "Deploys to production; accepts any arguments mina supports"
      def production(*args)
        run "bundle exec mina deploy:production #{args.join(' ')}"
      end

      desc "staging [<MINA_ARGS>]", "Deploys to staging; accepts any arguments mina supports"
      def staging(*args)
        run "bundle exec mina deploy:staging #{args.join(' ')}"
      end
    end
  end
end
