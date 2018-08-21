# Copyright (c) 2018 David Margery, INRIA Rennes - Bretagne Atlantique
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe ApplicationController do
  render_views

  describe "continue_if!" do
    it "Should log a message if http's status is between 400 and 599" do
      expected_url="https://fake.server/oar/jobs"
      stub_request(:post, expected_url).to_return(
        :status=>400,
        :body => "Bad Request")
      http=EM::HttpRequest.new(expected_url).post()
      expect(http.response_header.status).to eq 400
      expect(Rails.logger).to receive(:error).with("Request to #{expected_url} failed with status 400: Bad Request")
      expect { subject.send(:continue_if!, http, :is => [201,202]) }.to raise_exception ApplicationController::BadRequest
    end
  end
end

