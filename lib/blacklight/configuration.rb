module Blacklight
  module Configuration
    extend ActiveSupport::Concern

    # Add a blacklight_config method to the class, class instance, and as a helper method
    included do
      class_attribute :blacklight_config
      helper_method :blacklight_config
    end

    ##
    # If Blacklight::Configuration is included explicitly in a class, create a separate copy of the current
    # configuration for use. If it is only loaded implicitly, blacklight_config is used by-reference
    #
    # @param [Class] base_class
    def self.included base_class
      return unless base_class.respond_to? :blacklight_config=
      if base_class.respond_to?(:blacklight_config) and base_class.blacklight_config
        base_class.blacklight_config = base_class.blacklight_config.inheritable_copy
      else
        base_class.blacklight_config = Blacklight::Configuration.default_configuration
      end
    end

    ##
    # The default configuration object, by default it reads from Blacklight.config for backwards
    # compatibility with Blacklight <= 3.1
    def self.default_configuration
      Blacklight::Config.from_legacy_configuration(Blacklight.config)
    end

  end
end
