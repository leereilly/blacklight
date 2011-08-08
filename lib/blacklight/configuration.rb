module Blacklight
  module Configuration
    extend ActiveSupport::Concern

    included do
      class_attribute :blacklight_config
      helper_method :blacklight_config
    end

    def self.included base_class
      return unless base_class.respond_to? :blacklight_config=
      if base_class.respond_to?(:blacklight_config) and base_class.blacklight_config
        base_class.blacklight_config = base_class.blacklight_config.inheritable_copy
      else
        base_class.blacklight_config = Blacklight::Config.from_legacy_configuration(Blacklight.config)
      end
    end

  end
end
