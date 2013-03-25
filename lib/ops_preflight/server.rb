module OpsPreflight
  class Server < Thor
    include ExitCode

    namespace :default

    desc "upload", "Upload preflight files to S3"
    option :bucket, :aliases => '-b', :required => true, :type => :string, :banner => "<S3_BUCKET>"
    option :file, :aliases => '-f', :required => true, :type => :string, :banner => "<FILE>"
    def upload
      raise Thor::Error, "Specified file not found: #{options[:file]}" unless File.exists?(options[:file])

      S3Transfer.new(options[:bucket], options[:file]).upload
    end

    desc "download", "Downloads preflight files from S3"
    option :bucket, :aliases => '-b', :required => true, :type => :string, :banner => "<S3_BUCKET>"
    option :file, :aliases => '-f', :required => true, :type => :string, :banner => "<FILE>"
    def download
      S3Transfer.new(options[:bucket], options[:file]).upload
    end

    desc "deploy", "Deploys the application to opsworks"
    def deploy
      Opsworks::Deploy.new.call
    end

    # Fixes thor's banners when used with :default namespace
    def self.banner(command, namespace = nil, subcommand = false)
      "#{basename} #{command.formatted_usage(self, false, subcommand)}"
    end
  end
end
