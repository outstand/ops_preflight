set :opsworks_stack_name, ENV['OPSWORKS_STACK_NAME']
set :opsworks_app_name, ENV['OPSWORKS_APP_NAME']

namespace :preflight do
  task :check_env_vars do
    [:opsworks_stack_name, :opsworks_app_name].each do |var|
      if settings[var].nil?
        print_error(unindent(%[
          Setting #{var.to_s} must be specified.
        ]))
        die(2)
      end
    end
  end

  desc 'Fetches the application environment vars'
  task :fetch_environment => :check_env_vars do
    queue %[
      echo "-----> Preflight: Fetch Environment"
      #{echo_cmd %[bundle exec preflight-server fetch_environment #{settings.rails_env!} '#{settings.opsworks_stack_name!}' '#{settings.opsworks_app_name!}']}
    ]
  end

  desc 'Prepares the bundle for deploy'
  task :bundle => :environment do
    queue %[
      echo "-----> Preflight: Bundle"
      #{echo_cmd %[tar -zcvf tmp/preflight-#{settings.app_name!}-bundle-#{settings.rails_env!}.tgz -C #{deploy_to}/#{shared_path} bundle > /dev/null]} &&
      #{echo_cmd %[bundle exec preflight-server upload -b #{settings.preflight_bucket!} -f ./tmp/preflight-#{settings.app_name!}-bundle-#{settings.rails_env!}.tgz]}
    ]
  end

  desc 'Precompiles assets for deploy'
  task :assets => :environment do
    queue %[
      echo "-----> Preflight: Assets"
      #{echo_cmd %[tar -zcvf tmp/preflight-#{settings.app_name!}-assets-#{settings.rails_env!}.tgz -C #{deploy_to}/#{shared_path}/public assets > /dev/null]} &&
      #{echo_cmd %[bundle exec preflight-server upload -b #{settings.preflight_bucket!} -f ./tmp/preflight-#{settings.app_name!}-assets-#{settings.rails_env!}.tgz]}
    ]
  end

  desc 'Triggers a deploy'
  task :deploy => [:environment, :check_env_vars] do
    queue %[
      echo "-----> Preflight: Deploy"
      #{echo_cmd %[bundle exec preflight-server deploy '#{settings.opsworks_stack_name!}' '#{settings.opsworks_app_name!}']}
    ]
  end
end
