require 'spec_helper'

describe GlobalController do
  render_views

  describe "GET /global" do
    it "should get the correct collection of items" do
      get :index, :format => :json
      expect(response.status).to eq 200
      expect(json['total']).to eq 4
      expect(json['items'].length).to eq 4
      expect(json['items']['sites']).to be_a(Hash)
      expect(json['items']['environments']).to be_a(Hash)
    end

    it "should get the correct collection of sites" do
      get :index, :format => :json
      expect(response.status).to eq 200
      expect(json['items']['sites'].length).to eq 4
      expect(json['items']['sites']['bordeaux'].length).to eq 14
      expect(json['items']['sites']['bordeaux']).to be_a(Hash)
      expect(json['items']['sites']['bordeaux']['uid']).to eq 'bordeaux'
    end

    it "should be the correct version" do
      get :index, :format => :json
      expect(response.status).to eq 200
      expect(json['version']).to eq '8a562420c9a659256eeaafcfd89dfa917b5fb4d0'
    end
  end

  describe "GET /global/sites/{{site_id}}" do
    it "should get the correct collection for one site" do
      get :show_site, params: { :site_id => 'rennes', :format => :json }
      expect(response.status).to eq 200
      expect(json['total']).to eq 14
      expect(json['items'].length).to eq 14
      expect(json['items']['clusters']).to be_a(Hash)
      expect(json['items']['clusters']['paravent']['uid']).to eq 'paravent'
    end
  end

  describe "GET /global/sites/{{site_id}}/jobs/{{job_id}}" do
    it "should get the correct nodes collection for a job" do
      get :show_job, params: { :site_id => 'rennes', :job_id => '374191', :format => :json }
      expect(response.status).to eq 200
      expect(json['total']).to eq 3
      expect(json['items'].length).to eq 3
      expect(json['items']['clusters']).to be_a(Hash)
      expect(json['items']['clusters']['paramount']['uid']).to eq 'paramount'
      expect(json['items']['clusters']['paramount']['nodes'].length).to eq 4
      expect(json['version']).to eq '5b02702daa827f7e39ebf7396af26735c9d2aacd'
    end
  end
end
