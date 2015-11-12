namespace :ember do
  desc 'Links the ember-cli-deploy dotenv config'
  task link_config: :environment do
    in_directory './ember' do
      queue %[echo "-----> Symlinking ember deploy config"]
      queue! echo_cmd(%{rm -rf "./.env.deploy.production"})
      queue! echo_cmd(%{ln -s "#{deploy_to}/#{shared_path}/config/env.deploy.production" "./.env.deploy.production"})
    end
  end

  desc 'Installs ember-cli and bower'
  task install: :environment do
    in_directory './ember' do
      queue! %[
        ln -sf "#{deploy_to}/#{shared_path}/node_modules" "./node_modules"
        ln -sf "#{deploy_to}/#{shared_path}/bower_components" "./bower_components"
      ]
      queue %[
        echo "-----> Installing ember dependencies"
        #{echo_cmd %[npm install bower ember-cli]} &&
        #{echo_cmd %[npm install]} &&
        #{echo_cmd %[./node_modules/.bin/bower install]}
      ]
    end
  end

  desc 'Runs ember-cli-deploy'
  task deploy: :environment do
    in_directory './ember' do
      queue %[
        echo "-----> Running ember deploy"
        #{echo_cmd %[./node_modules/.bin/ember deploy production | egrep -e "--revision=(.*)$" -o | sed "s/--revision=//" > ember-deploy-revision]}
      ]
    end
  end

  desc 'Activates the deployed revision'
  task activate_deploy: :environment do
    in_directory './ember' do
      queue %[
        echo "-----> Activating ember deploy"
        #{echo_cmd %[./node_modules/.bin/ember deploy:activate production --revision $(cat ember-deploy-revision)]}
      ]
    end
  end
end
