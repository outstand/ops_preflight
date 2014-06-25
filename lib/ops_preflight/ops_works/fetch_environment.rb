require 'yaml'

module OpsPreflight
  module OpsWorks
    require 'ops_preflight/ops_works/base'

    class FetchEnvironment < Base
      attr_accessor :app_name
      attr_accessor :environment

      def initialize(environment, stack_name, app_name)
        super stack_name

        @environment = environment
        @app_name = app_name
      end

      def call
        resp = opsworks.client.describe_stacks(:stack_ids => [stack_id])

        require 'multi_json'

        json = MultiJson.load(resp[:stacks].first[:custom_json])

        File.open("config/application.yml", 'wb') do |f|
          f.write json['env_vars'][app_name].to_yaml
        end
      end
    end
  end
end
