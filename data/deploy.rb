require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
# require 'mina/rvm'    # for rvm support. (http://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :user, 'ec2-user'    # Username in the server to SSH to.
set :domain, 'preflight.example.com'
set :deploy_to, "/home/#{settings.user!}/preflight"
set :repository, 'git@github.com:user/repo.git'
set :branch, 'master'

set :rbenv_path, '/usr/local/rbenv'
set :preflight_bucket, 'org-preflight'
settings.delete(:rails_env)

set :app_uses_turbo_sprockets, true
set :app_uses_env_file, true

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, generate_shared_paths

# Optional settings:
#   set :port, '30000'     # SSH port number.

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .rbenv-version to your repository.
  queue %{export RBENV_ROOT=#{rbenv_path}}
  invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use[ruby-1.9.3-p125@default]'
  unless settings.rails_env?
    if ENV['RAILS_ENV']
      set :rails_env, ENV['RAILS_ENV']
    else
      print_error(unindent(%[
        Application environment must be specified.
        Use either deploy:<environment> or deploy RAILS_ENV=<environment>
      ]))
      die(2)
    end
  end
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  queue! %[mkdir -p "#{deploy_to}/shared/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config"]

  if settings.app_users_turbo_sprockets
    queue! %[mkdir -p "#{deploy_to}/shared/public/assets"]
    queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/public/assets"]

    queue! %[touch "#{deploy_to}/shared/public/assets/sources_manifest.yml"]
  end

  if settings.app_uses_env_file
    queue! %[touch "#{deploy_to}/shared/.env"]
    queue  %[echo "-----> Be sure to edit 'shared/.env'."]
  end

  queue! %[touch "#{deploy_to}/shared/config/database.yml"]
  queue  %[echo "-----> Be sure to edit 'shared/config/database.yml'."]
end

namespace :deploy do
  desc 'Deploys to production'
  task :production do
    set :rails_env, 'production'
    invoke :deploy
  end

  desc 'Deploys to staging'
  task :staging do
    set :rails_env, 'staging'
    invoke :deploy
  end
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    # invoke :'rails:db_migrate'

    if settings.app_users_turbo_sprockets
      invoke :'rails:assets_precompile:force' # Defer to turbo sprockets
    else
      invoke :'rails:assets_precompile'
    end

    to :launch do
      invoke :'preflight:bundle'
      invoke :'preflight:assets'
    end
  end
end

namespace :preflight do
  desc 'Prepares the bundle for deploy'
  task :bundle => :environment do
    queue %[
      echo "-----> Preflight: Bundle"
      tar -zcvf preflight-bundle-#{settings.rails_env!}.tgz -C ./vendor/bundle *
      bundle exec preflight-server upload -b #{settings.preflight_bucket!} -f ./preflight-bundle-#{settings.rails_env!}.tgz
    ]
  end

  desc 'Precompiles assets for deploy'
  task :assets => :environment do
    queue %[
      echo "-----> Preflight: Assets"
      tar -zcvf preflight-assets-#{settings.rails_env!}.tgz -C ./public assets
      bundle exec preflight-server upload -b #{settings.preflight_bucket!} -f ./preflight-assets-#{settings.rails_env!}.tgz
    ]
  end
end

def generate_shared_paths
  path = ['config/database.yml', 'log']

  if settings.app_uses_turbo_sprockets
    path << 'public/assets/sources_manifest.yml'
  end

  if settings.app_uses_env_file
    path << '.env'
  end

  path
end

# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers

