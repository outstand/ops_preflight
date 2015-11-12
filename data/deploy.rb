require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
# require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
# require 'mina/rvm'    # for rvm support. (http://rvm.io)
require 'ops_preflight/tasks'
require 'ops_preflight/ember_tasks'

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :user, ENV['USER']    # Username in the server to SSH to.
set :domain, ENV['DOMAIN']
set :app_name, ENV['APP_NAME']
set :deploy_to, lambda { "/home/#{settings.user!}/preflight/#{settings.app_name!}-#{settings.rails_env!}" }
set :repository, ENV['REPOSITORY']
set :branch, ENV['BRANCH']
set :remove_git_dir, false
set :deploy_rails, true
set :deploy_ember, false

# set :rbenv_path, '/usr/local/rbenv'
set :preflight_bucket, ENV['PREFLIGHT_BUCKET']
settings.delete(:rails_env)

set :run_db_migrate, ENV['RUN_DB_MIGRATE']
set :use_turbo_sprockets, ENV['USE_TURBO_SPROCKETS']
set :use_env_file, ENV['USE_ENV_FILE']

set :skip_opsworks_deploy, (ENV['SKIP_OPSWORKS_DEPLOY'].nil? ? 'false' : ENV['SKIP_OPSWORKS_DEPLOY'])

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, lambda { generate_shared_paths }

# Optional settings:
#   set :port, '30000'     # SSH port number.

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .rbenv-version to your repository.
  # queue %{export RBENV_ROOT=#{rbenv_path}}
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use[ruby-1.9.3-p125@default]'

  unless settings.rails_env?
    if ENV['RAILS_ENV']
      set :rails_env, ENV['RAILS_ENV']
    elsif ENV['RACK_ENV']
      set :rails_env, ENV['RACK_ENV']
    else
      print_error(unindent(%[
        Application environment must be specified.
        Use deploy RAILS_ENV=<environment> or deploy RACK_ENV=<environment>
        Preflight supports this with `preflight deploy <environment>`
      ]))
      die(2)
    end
  end

  [:user, :domain, :app_name, :repository, :branch, :preflight_bucket, :use_turbo_sprockets, :use_env_file].each do |var|
    if settings[var].nil?
      print_error(unindent(%[
        Setting #{var.to_s} must be specified.
      ]))
      die(2)
    end
  end

  if ENV['DEPLOY_EMBER'] == 'true'
    set :deploy_ember, true
  end

  if ENV['EMBER_ONLY'] == 'true'
    set :deploy_ember, true
    set :deploy_rails, false
  end
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  # Ember
  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/node_modules"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/node_modules"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/bower_components"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/bower_components"]

  # Rails
  queue! %[mkdir -p "#{deploy_to}/shared/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  queue! %[mkdir -p "#{deploy_to}/shared/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config"]

  if settings.use_turbo_sprockets! == 'true'
    queue! %[mkdir -p "#{deploy_to}/shared/public/assets"]
    queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/public/assets"]
  end

  queue! %[touch "#{deploy_to}/shared/config/database.yml"]
  queue! %[touch "#{deploy_to}/shared/config/env.deploy.production"]

  queue  %[echo "-----> Please add ForwardAgent yes to your ssh config for #{settings.domain!}"]
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    if !settings.deploy_rails && !settings.deploy_ember
      print_error('Nothing to deploy')
      die(2)
    end

    deploy_message = []
    if settings.deploy_rails
      deploy_message << %[Rails]
    end
    if settings.deploy_ember
      deploy_message << %[Ember]
    end
    print_status('Deploying ' + deploy_message.join(', '))

    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'ember:link_config' if settings.deploy_ember

    invoke :'bundle:install' if settings.deploy_rails
    invoke :'ember:install' if settings.deploy_ember

    if settings.use_env_file! == 'true' && settings.deploy_rails
      invoke :'preflight:fetch_environment'
    end

    if settings.deploy_rails
      if settings.run_db_migrate! == 'true'
        invoke :'rails:db_migrate'
      end

      if settings.use_turbo_sprockets! == 'true'
        invoke :'rails:assets_precompile:force' # Defer to turbo sprockets change tracking instead of mina
      else
        invoke :'rails:assets_precompile'
      end
    end

    invoke :'ember:deploy' if settings.deploy_ember

    to :launch do
      if settings.deploy_rails
        invoke :'preflight:bundle'
        invoke :'preflight:assets'
        invoke :'preflight:deploy'
      end
      if settings.deploy_ember
        invoke :'ember:activate_deploy'
      end
    end
  end
end

def generate_shared_paths
  path = ['log']

  if settings.use_turbo_sprockets! == 'true'
    path << 'public/assets'
  end

  path
end

# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers

