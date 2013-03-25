module OpsPreflight
  class S3Transfer
    attr_accessor :bucket
    attr_accessor :file

    def initialize(bucket, file)
      @bucket = bucket
      @file = file
    end

    def upload
      basename = File.basename(file)

      remote_file = directory.files.head(basename)
      remote_file.destroy if remote_file

      directory.files.create(
        :key => basename,
        :body => File.open(file),
        :public => false
      )
    end

    def download
      basename = File.basename(file)

      remote_file = directory.files.get(basename)
      File.open(file, 'w') do |local_file|
        local_file.write(remote_file.body)
      end
    end

    protected
    def connection
      Fog::Storage::AWS.new :use_iam_profile => true
    end

    def directory
      connection.directories.get(bucket)
    end
  end
end
