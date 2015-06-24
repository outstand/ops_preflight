module OpsPreflight
  module OpsWorks
    class Base
      attr_accessor :region
      attr_accessor :stack_name

      def initialize(region, stack_name)
        require 'aws-sdk'

        @region = region
        @stack_name = stack_name
      end

      protected
      def opsworks
        @opsworks ||= Aws::OpsWorks::Client.new(region: @region)
      end

      def stack_id
        @stack_id ||= begin
          resp = opsworks.describe_stacks
          stack = resp[:stacks].find {|stack| stack[:name] == stack_name }

          raise "OpsWorks stack not found!" if stack.nil?

          stack[:stack_id]
        end
      end
    end
  end
end
