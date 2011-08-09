module Blacklight
  ##
  # Blacklight::Config holds the configuration for a Blacklight::Controller, including
  # fields to display, facets to show, sort options, and search fields.
  class Config < OpenStruct
    def initialize(*args)
      super(*args)
      initialize_default_values!
    end


    def initialize_default_values!
      self.default_solr_params ||= {}
      self.show ||= {}
      self.index||= {}
      self.facet ||= []
      self.index_fields ||= []
      self.show_fields ||= []
      self.search_fields ||= []
      self.sort_fields ||= []
      self.spell_max ||= 5
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
      Marshal.load(Marshal.dump(self))
    end

    def []=(key, value)
      send "#{key}=", value
    end

    def [](key)
      send key
    end

    def facets  # for some reason, alias_method doesn't work right
      @_facets ||= facet[:field_names].map { |x| Facet.new :field => x, :limit => facet[:limits][x], :label => facet[:labels][x] } if facet.respond_to? :key? and facet.key? :field_names

      @_facets || facet
    end
    class Facet < OpenStruct; end

    def configure 
      yield self if block_given?
      self
    end

  end
end
