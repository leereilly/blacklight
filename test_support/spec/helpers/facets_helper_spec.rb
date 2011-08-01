require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
describe FacetsHelper do
  describe "render_facets_partials" do
    before do
      assign(:response, RSolr::Ext::Response::Base.new({ :response => { :docs => [] }, 'facet_counts' => { 'facet_fields' => { 'facet_field' => ['a', 1, 'b', 2], 'facet_field_2' => ['c', '5', 'd', 24] } }, :responseHeader => { :params => { :rows => 0 } } }, nil, nil))
    end

    it "should render facet limit blocks for every facet" do
      helper.stub!(:facet_field_names).and_return(["facet_field", "facet_field_2"])

      arr = []
      helper.stub(:render_facet_limit) { |facet_field| arr << facet_field.name }
      
      helper.render_facets_partials

      arr.should include("facet_field")
      arr.should include("facet_field_2")
    end

    it "should not render facets if no items are provide" do
      helper.stub!(:facet_field_names).and_return(["facet_field", "facet_field_3"])
      arr = []
      helper.stub(:render_facet_limit) { |facet_field| arr << facet_field.name }

      helper.render_facets_partials

      arr.should include("facet_field")
      arr.should_not include("facet_field_3")
    end

  end

  describe "render_facet_limit" do
    it "should render the facet limit block with a layout" do
      helper.stub(:facet_partial_hash).and_return({})
      facet_field = Object.new
      facet_field.stub(:name).and_return('facet_field')
      helper.should_receive(:render).with(hash_including(:partial => 'catalog/facet_limit', :layout => 'facet_container'))
      helper.render_facet_limit(facet_field)
    end

    it "should allow the facet_partial_hash to configure the facet name to partial mapping" do
      helper.stub(:facet_partial_hash).and_return({:facet_field => 'catalog/my_custom_facet_limit'})
      helper.should_receive(:render).with(hash_including(:partial => 'catalog/my_custom_facet_limit'))

      facet_field = Object.new
      facet_field.stub(:name).and_return('facet_field')
      helper.render_facet_limit(facet_field)
    end

    it "should allow render options to be provided by the callee" do
      helper.stub(:render) do |options| 
        options.should include(:partial => 'custom/facet_limit')
        options.should include(:locals)
        options[:locals].should include(:a, :facet_field)
      end
      facet_field = Object.new
      facet_field.stub(:name).and_return('facet_field')
      helper.render_facet_limit(facet_field, :partial => 'custom/facet_limit', :locals => { :a => 1})
    end
  end

  describe "add_facet_params" do
    before do
      @params_no_existing_facet = {:q => "query", :search_field => "search_field", :per_page => "50"}
      @params_existing_facets = {:q => "query", :search_field => "search_field", :per_page => "50", :f => {"facet_field_1" => ["value1"], "facet_field_2" => ["value2", "value2a"]}}
    end

    it "should add facet value for no pre-existing facets" do
      helper.stub!(:params).and_return(@params_no_existing_facet)

      result_params = helper.add_facet_params("facet_field", "facet_value")
      result_params[:f].should be_a_kind_of(Hash)
      result_params[:f]["facet_field"].should be_a_kind_of(Array)
      result_params[:f]["facet_field"].should == ["facet_value"]
    end

    it "should add a facet param to existing facet constraints" do
      helper.stub!(:params).and_return(@params_existing_facets)
      
      result_params = helper.add_facet_params("facet_field_2", "new_facet_value")

      result_params[:f].should be_a_kind_of(Hash)

      @params_existing_facets[:f].each_pair do |facet_field, value_list|
        result_params[:f][facet_field].should be_a_kind_of(Array)
        
        if facet_field == 'facet_field_2'
          result_params[:f][facet_field].should == (@params_existing_facets[:f][facet_field] | ["new_facet_value"])
        else
          result_params[:f][facet_field].should ==  @params_existing_facets[:f][facet_field]
        end        
      end
    end
    it "should leave non-facet params alone" do
      [@params_existing_facets, @params_no_existing_facet].each do |params|
        helper.stub!(:params).and_return(params)

        result_params = helper.add_facet_params("facet_field_2", "new_facet_value")

        params.each_pair do |key, value|
          next if key == :f
          result_params[key].should == params[key]
        end        
      end
    end    
  end

  describe "add_facet_params_and_redirect" do
    before do
      catalog_facet_params = {:q => "query", 
                :search_field => "search_field", 
                :per_page => "50",
                :page => "5",
                :f => {"facet_field_1" => ["value1"], "facet_field_2" => ["value2", "value2a"]},
                Blacklight::Solr::FacetPaginator.request_keys[:offset] => "100",
                Blacklight::Solr::FacetPaginator.request_keys[:sort] => "index",
                :id => 'facet_field_name'
      }
      helper.stub!(:params).and_return(catalog_facet_params)
    end
    it "should redirect to 'index' action" do
      params = helper.add_facet_params_and_redirect("facet_field_2", "facet_value")

      params[:action].should == "index"
    end
    it "should not include request parameters used by the facet paginator" do
      params = helper.add_facet_params_and_redirect("facet_field_2", "facet_value")

      bad_keys = Blacklight::Solr::FacetPaginator.request_keys.values + [:id]
      bad_keys.each do |paginator_key|
        params.keys.should_not include(paginator_key)        
      end
    end
    it 'should remove :page request key' do
      params = helper.add_facet_params_and_redirect("facet_field_2", "facet_value")

      params.keys.should_not include(:page)
    end
    it "should otherwise do the same thing as add_facet_params" do
      added_facet_params = helper.add_facet_params("facet_field_2", "facet_value")
      added_facet_params_from_facet_action = helper.add_facet_params_and_redirect("facet_field_2", "facet_value")

      added_facet_params_from_facet_action.each_pair do |key, value|
        next if key == :action
        value.should == added_facet_params[key]
      end      
    end
  end

  describe "remove_facet_params" do

  end

  describe "facet_in_params?" do

  end
  
end
