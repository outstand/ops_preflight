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

        str = ''
        json['env_vars'][app_name][environment].each do |var, value|
          str << "#{var.upcase}=#{value}\n"
        end

        File.open(".env.#{environment}", 'wb') do |f|
          f.write str
        end
      end
    end
  end
end
