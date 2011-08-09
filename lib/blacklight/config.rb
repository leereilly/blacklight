module Blacklight
  ##
  # Blacklight::Config holds the configuration for a Blacklight::Controller, including
  # fields to display, facets to show, sort options, and search fields.
  class Config < OpenStruct
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
      Marshal.load(Marshal.dump(self))
    end

    def []=(key, value)
      send "#{key}=", value
    end

    def [](key)
      send key
    end
  end
end
