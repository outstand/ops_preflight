module OpsPreflight
  class Config
    CONFIG_FILE = 'config/preflight.yml'

    def initialize
      config
    end

    def client_args(rails_env)
      str = ''
      config.each do |var, value|
        next if var == :environments

        str << " #{var.to_s.upcase}='#{value}'"
      end

      if config[:environments] && config[:environments][rails_env.to_sym]
        config[:environments][rails_env.to_sym].each do |var, value|
          str << " #{var.to_s.upcase}='#{value}'"
        end
      end

      str
    end

    protected
    def config
      @config ||= begin
        new_config = YAML::load(ERB.new(File.read(CONFIG_FILE)).result)

        symbolize_keys!(new_config)
        symbolize_keys!(new_config[:environments])

        new_config[:environments].each do |env, hash|
          symbolize_keys!(hash)
        end

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
