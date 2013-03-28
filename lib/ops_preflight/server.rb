module OpsPreflight
  class Server < Thor
    include ExitCode

    namespace :default

    desc "upload", "Upload preflight files to S3"
    option :bucket, :aliases => '-b', :required => true, :type => :string, :banner => "<s3_bucket>"
    option :file, :aliases => '-f', :required => true, :type => :string, :banner => "<file>"
    def upload
      raise Thor::Error, "Specified file not found: #{options[:file]}" unless File.exists?(options[:file])

      require 'ops_preflight/s3_transfer.rb'
      S3Transfer.new(options[:bucket], options[:file]).upload
    end

    desc "download", "Downloads preflight files from S3"
    option :bucket, :aliases => '-b', :required => true, :type => :string, :banner => "<s3_bucket>"
    option :file, :aliases => '-f', :required => true, :type => :string, :banner => "<file>"
    def download
      require 'ops_preflight/s3_transfer.rb'
      S3Transfer.new(options[:bucket], options[:file]).download
    end

    desc "deploy <stack_name> <app_name>", "Deploys the application to opsworks"
    option :release, :type => :string, :banner => '<release number>'
    def deploy(stack_name, app_name)
      require 'ops_preflight/ops_works/deploy.rb'

      OpsWorks::Deploy.new(stack_name, app_name).call(options[:release])
    end

    desc "fetch_environment <environment> <stack_name> <app_name>", 'Fetches environment variables from opsworks'
    def fetch_environment(environment, stack_name, app_name)
      require 'ops_preflight/ops_works/fetch_environment.rb'

      OpsWorks::FetchEnvironment.new(environment, stack_name, app_name).call
    end

    # Fixes thor's banners when used with :default namespace
    def self.banner(command, namespace = nil, subcommand = false)
      "#{basename} #{command.formatted_usage(self, false, subcommand)}"
    end
  end
end
