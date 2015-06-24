module OpsPreflight
  module OpsWorks
    require 'ops_preflight/ops_works/base'

    class Deploy < Base
      attr_accessor :app_name

      def initialize(region, stack_name, app_name)
        super region, stack_name

        @app_name = app_name
      end

      def call(release_num = nil)
        instances = instance_ids
        puts "Triggering deploy of v#{release_num} to #{instances.size} instance#{'s' if instances.size != 1}"

        resp = opsworks.create_deployment({
          :stack_id => stack_id,
          :app_id => app_id,
          :instance_ids => instances,
          :command => {
            :name => 'deploy'
          },
          :comment => release_num.nil? ? 'Preflight Deployment' : "Preflight Release v#{release_num}"
        })
      end

      protected
      def app_id
        @app_id ||= begin
          resp = opsworks.describe_apps(:stack_id => stack_id)
          app = resp[:apps].find {|app| app[:name] == app_name}

          raise "OpsWorks app not found!" if app.nil?

          app[:app_id]
        end
      end

      def instance_ids
        resp = opsworks.describe_instances(:stack_id => stack_id)
        ids = []
        resp[:instances].each {|instance| ids << instance[:instance_id] if instance[:status] == 'online' }

        ids
      end

    end
  end
end
