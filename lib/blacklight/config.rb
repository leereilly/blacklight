module Blacklight
  ##
  # Blacklight::Config holds the configuration for a Blacklight::Controller, including
  # fields to display, facets to show, sort options, and search fields.
  #
  # ActiveSupport::OrderedOptions is documented at http://api.rubyonrails.org/classes/ActiveSupport/OrderedOptions.html
  class Config < ActiveSupport::OrderedOptions
    ##
    # Initialize a new Blacklight::Config from a legacy Blacklight configuration
    #
    # @param [Hash] hash
    def initialize hash = {}
      @_config = hash
      super(@_config)
      self.class.compile_methods!(keys)
    end

    ##
    # Helper method for loading a legacy blacklight configuration into the new style Blacklight::Config
    def self.from_legacy_configuration config
      Blacklight::Config.new Marshal.load(Marshal.dump(config))
    end

    ## 
    # Rather than relying on method_missing or otherwise, bake configuration accessors into the class
    def self.compile_methods! keys
      keys.reject { |m| self.class.method_defined?(m) }.each do |key|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{key}; _get(#{key.inspect}); end
        RUBY
      end
    end

    ##
    # Provide a 'deep copy' of Blacklight::Config that can be modifyed without affecting
    # the original Blacklight::Config instance.
    #
    def inheritable_copy
      Blacklight::Config.new Marshal.load(Marshal.dump(@_config))
    end
  end
end
