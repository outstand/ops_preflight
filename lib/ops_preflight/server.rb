module OpsPreflight
  class Server < Thor
    desc "upload", "Upload preflight files to S3"
    option :bucket, :aliases => '-b', :required => true, :type => :string, :banner => "<S3_BUCKET>"
    option :file, :aliases => '-f', :required => true, :type => :string, :banner => "<FILE>"
    def upload
      raise Thor::Error, "Specified file not found: #{options[:file]}" unless File.exists?(options[:file])

      connection = Fog::Storage::AWS.new :use_iam_profile => true
      directory = connection.directories.get(options[:bucket])

      basename = File.basename(options[:file])

      remote_file = directory.files.head(basename)
      remote_file.destroy if remote_file

      directory.files.create(
        :key => basename,
        :body => File.open(options[:file]),
        :public => false
      )
    end

    desc "download", "Downloads preflight files from S3"
    option :bucket, :aliases => '-b', :required => true, :type => :string, :banner => "<S3_BUCKET>"
    option :file, :aliases => '-f', :required => true, :type => :string, :banner => "<FILE>"
    def download
      connection = Fog::Storage::AWS.new :use_iam_profile => true
      directory = connection.directories.get(options[:bucket])

      basename = File.basename(options[:file])

      remote_file = directory.files.get(basename)
      File.open(options[:file], 'w') do |local_file|
        local_file.write(remote_file.body)
      end
    end

    private
    def self.exit_on_failure?
      true
    end
  end
end
