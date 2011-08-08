module Blacklight
  class Config < DelegateClass(Hash)
    alias_method :_get, :[] # preserve the original #[] method
    protected :_get # make it protected

    def initialize hash 
      @_config = hash
      super(@_config)
      self.class.compile_methods!(keys)
    end

    def self.from_legacy_configuration config
      Blacklight::Config.new Marshal.load(Marshal.dump(config))
    end

    def self.compile_methods! keys
      keys.reject { |m| self.class.method_defined?(m) }.each do |key|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{key}; _get(#{key.inspect}); end
        RUBY
      end
    end

    def inheritable_copy
      Blacklight::Config.new Marshal.load(Marshal.dump(@_config))
    end
  end
end
