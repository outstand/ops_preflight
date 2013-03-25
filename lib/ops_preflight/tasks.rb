namespace :preflight do
  desc 'Prepares the bundle for deploy'
  task :bundle => :environment do
    queue %[
      echo "-----> Preflight: Bundle"
      #{echo_cmd %[tar -zcvf preflight-bundle-#{settings.rails_env!}.tgz -C ./vendor/bundle *]} &&
      #{echo_cmd %[bundle exec preflight-server upload -b #{settings.preflight_bucket!} -f ./preflight-bundle-#{settings.rails_env!}.tgz]}
    ]
  end

  desc 'Precompiles assets for deploy'
  task :assets => :environment do
    queue %[
      echo "-----> Preflight: Assets"
      #{echo_cmd %[tar -zcvf preflight-assets-#{settings.rails_env!}.tgz -C ./public assets]} &&
      #{echo_cmd %[bundle exec preflight-server upload -b #{settings.preflight_bucket!} -f ./preflight-assets-#{settings.rails_env!}.tgz]}
    ]
  end

  desc 'Triggers a deploy'
  task :deploy => :environment do
    queue %[
      echo "-----> Preflight: Deploy"
      #{echo_cmd %[bundle exec preflight-server deploy]}
    ]
  end
end
