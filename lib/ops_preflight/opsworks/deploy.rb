module OpsPreflight
  module Opsworks
    class Deploy
      attr_accessor :stack_name

      def initialize(stack_name)
        require 'aws-sdk'

        @stack_name = stack_name
      end

      def call
        list_instances
      end

      protected
      def opsworks
        @opsworks ||= AWS::Opsworks.new
      end

      def list_instances
        resp = opsworks.client.describe_stacks
      end

    end
  end
end
