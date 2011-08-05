module Blacklight
  module Configuration
    extend ActiveSupport::Concern

    included do
      class_attribute :blacklight_config
      helper_method :blacklight_config

      self.blacklight_config = Blacklight.config.dup
    end
  end
end
