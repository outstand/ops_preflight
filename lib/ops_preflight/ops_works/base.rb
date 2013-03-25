module OpsPreflight
  module OpsWorks
    class Base
      attr_accessor :stack_name

      def initialize(stack_name)
        require 'aws-sdk'

        @stack_name = stack_name
      end

      protected
      def opsworks
        @opsworks ||= AWS::OpsWorks.new
      end

      def stack_id
        @stack_id ||= begin
          resp = opsworks.client.describe_stacks
          stack = resp[:stacks].find {|stack| stack[:name] == stack_name }

          raise "OpsWorks stack not found!" if stack.nil?

          stack[:stack_id]
        end
      end
    end
  end
end
