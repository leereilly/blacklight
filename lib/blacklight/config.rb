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
      self.default_search_field = nil
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

      # SolrHelper#default_solr_parameters needs to iterate over the keys, so this can't be a Struct
      blacklight_config.default_solr_params = config[:default_solr_params].dup

      config[:facet][:field_names].each do |x|
        blacklight_config.facet :field => x, :limit => config[:facet][:limits][x], :label => config[:facet][:labels][x]
      end

      config[:index_fields][:field_names].each do |x|
        blacklight_config.index_field :field => x, :label => config[:index_fields][:labels][x]
      end

      config[:show_fields][:field_names].each do |x|
        blacklight_config.show_field :field => x, :label => config[:show_fields][:labels][x]
      end

      config[:search_fields].each do |x|
        unless x.is_a? Hash
          x = { :display_label => x[0], :key => x[1], :qt => x[1]}
        end

        blacklight_config.search_field x
      end

      config[:sort_fields].each do |label, sort|
        blacklight_config.sort_field :label => label, :sort => sort
      end

      config.reject { |key, value| [:default_solr_params, :facet, :index_fields, :show_fields, :search_fields, :sort_fields].include? key }.each do |key,value|
        blacklight_config.send("#{key}=", (OpenStructWithHashAccess.new(value) if value.is_a? Hash) || value)
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

    def facet facet_or_hash
      facet_or_hash = Facet.new(facet_or_hash) if facet_or_hash.is_a? Hash
      facets[facet_or_hash.field] = facet_or_hash
    end

    def index_field field_or_hash
      field_or_hash = Field.new(field_or_hash) if field_or_hash.is_a? Hash
      index_fields[field_or_hash.field] = field_or_hash
    end

    def show_field field_or_hash
      field_or_hash = Field.new(field_or_hash) if field_or_hash.is_a? Hash
      show_fields[field_or_hash.field] = field_or_hash
    end

    def search_field field_or_hash
      field_or_hash = SearchField.new(field_or_hash) if field_or_hash.is_a? Hash
      raise Exception.new("Search field config is missing ':key' => #{field_or_hash.inspect}") unless field_or_hash.key

      # If no display_label was provided, turn the :key into one.      
      field_or_hash.display_label ||= field_or_hash.key.titlecase
      field_or_hash.qt ||= default_solr_params[:qt] if default_solr_params

      search_fields[field_or_hash.key] = field_or_hash 
    end

    def sort_field field_or_hash
      field_or_hash = SortField.new(field_or_hash) if field_or_hash.is_a? Hash
      sort_fields[field_or_hash.field] = field_or_hash
    end


    def configure 
      yield self if block_given?
      self
    end

  end
end
