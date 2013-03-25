module OpsPreflight
  class Config
    CONFIG_FILE = 'config/preflight.yml'

    def initialize
      config
    end

    def client_args
      str = ''
      config.each do |var, value|
        next if var == :opsworks

        str << " #{var.to_s.upcase}='#{value}'"
      end

      if config[:opsworks] && !config[:opsworks].empty?
        config[:opsworks].each do |var, value|
          str << " OPSWORKS_#{var.to_s.upcase}='#{value}'"
        end
      end

      str
    end

    protected
    def config
      @config ||= begin
        new_config = YAML::load(ERB.new(File.read(CONFIG_FILE)).result)

        symbolize_keys!(new_config)
        symbolize_keys!(new_config[:opsworks])

        new_config.freeze
      end
    end

    def symbolize_keys!(hash)
      hash.keys.each do |key|
        hash[(key.to_sym rescue key) || key] = hash.delete(key)
      end
      hash
    end
  end
end
