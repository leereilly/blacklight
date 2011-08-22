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
      self.facets ||= ActiveSupport::OrderedHash.new
      self.index_fields ||= ActiveSupport::OrderedHash.new
      self.show_fields ||= ActiveSupport::OrderedHash.new
      self.search_fields ||= ActiveSupport::OrderedHash.new
      self.sort_fields ||= ActiveSupport::OrderedHash.new
      self.spell_max ||= 5
    end
    ##
    # Helper method for loading a legacy blacklight configuration into the new style Blacklight::Config
    def self.from_legacy_configuration config
      config = Marshal.load(Marshal.dump(config))
      blacklight_config = Blacklight::Config.new

      config.reject { |key, value| [:facet, :index_fields, :show_fields, :search_fields, :sort_fields].include? key }.each do |key,value|
        blacklight_config.send("#{key}=", (OpenStructWithHashAccess.new(value) if value.is_a? Hash) || value)
      end

      config[:facet][:field_names].each do |x|
        blacklight_config.facets[x.to_sym] = Facet.new(:field => x, :limit => config[:facet][:limits][x], :label => config[:facet][:labels][x])
      end

      config[:index_fields][:field_names].each do |x|
        blacklight_config.index_fields[x.to_sym] = Field.new(:field => x, :label => config[:index_fields][:labels][x])
      end

      config[:show_fields][:field_names].each do |x|
        blacklight_config.show_fields[x.to_sym] = Field.new(:field => x, :label => config[:show_fields][:labels][x])
      end

      config[:search_fields].each do |x|
        blacklight_config.search_fields[x[:key].to_sym] = SearchField.new(x)
      end

      config[:sort_fields].each do |label, sort|
        blacklight_config.sort_fields[sort] = SortField.new(:label => label, :sort => sort)
      end

      blacklight_config
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

    class OpenStructWithHashAccess < OpenStruct
      def []=(key, value)
        send "#{key}=", value
      end

      def [](key)
        send key
      end
    end

    class Facet < OpenStruct; end
    class Field < OpenStruct; end
    class SearchField < OpenStruct; end
    class SortField < OpenStruct; end

    def configure 
      yield self if block_given?
      self
    end

  end
end
