module Blacklight
  ##
  # Blacklight::Config holds the configuration for a Blacklight::Controller, including
  # fields to display, facets to show, sort options, and search fields.
  #
  # As Blacklight::Config descends from the Hash delegate class, it will respond to all
  # standard Hash methods as well.
  class Config < DelegateClass(Hash)

    ##
    # Initialize a new Blacklight::Config from a legacy Blacklight configuration
    #
    # @param [Hash] hash
    def initialize hash = {}
      @_config = hash
      super(@_config)
      self.compile_methods!
    end

    ##
    # Helper method for loading a legacy blacklight configuration into the new style Blacklight::Config
    def self.from_legacy_configuration config
      Blacklight::Config.new Marshal.load(Marshal.dump(config))
    end

    ##
    # Provide a 'deep copy' of Blacklight::Config that can be modifyed without affecting
    # the original Blacklight::Config instance.
    #
    def inheritable_copy
      Blacklight::Config.new Marshal.load(Marshal.dump(@_config))
    end

    def inspect
      "#<Blacklight::Config #{@_config.inspect}>"
    end

    # 
    # The following methods are taken from ActiveSupport. 
    # Unfortunately, we can't use ActiveSupport::Configurable or 
    # ActiveSupport::OrderedOptions directly 
    #

    # From ActiveSupport::Configurable
    def compile_methods!
      self.class.compile_methods!(keys)
    end

    # compiles reader methods so we don't have to go through method_missing
    def self.compile_methods! keys
      keys.reject { |m| self.class.method_defined?(m) }.each do |key|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{key}; _get(#{key.inspect}); end
        RUBY
      end
    end

    # From ActiveSupport::OrderedOptions
    alias_method :_get, :[] # preserve the original #[] method
    protected :_get # make it protected

    def []=(key, value)
      super(key.to_sym, value)
    end

    def [](key)
      super(key.to_sym)
    end

    def method_missing(name, *args)
      if name.to_s =~ /(.*)=$/
        self[$1] = args.first
      else
        self[name]
      end
    end

    def respond_to?(name)
      true
    end
  end
end
