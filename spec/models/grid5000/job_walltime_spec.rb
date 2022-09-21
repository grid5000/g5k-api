# Copyright (c) 2022 Samir Noir, INRIA Grenoble - Rhône-Alpes
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

describe Grid5000::JobWalltime do
  describe 'validation' do
    it 'should fail with error when walltime is not present in params Hash' do
      job_walltime = Grid5000::JobWalltime.new(force: true)
      expect(job_walltime.valid?).to eq(false)
      expect(job_walltime.errors).to eq(['you must give a new walltime'])
    end

    it 'should fail with error when walltime is not a String' do
      job_walltime = Grid5000::JobWalltime.new(walltime: 3600)
      expect(job_walltime.valid?).to eq(false)
      expect(job_walltime.errors).to eq(['new walltime must be a String'])
    end

    it 'should fail with error when timeout is not an Integer' do
      job_walltime = Grid5000::JobWalltime.new(walltime: "2:0:0", timeout: "1:0:0")
      expect(job_walltime.valid?).to eq(false)
      expect(job_walltime.errors).to eq(['timeout must be an Integer'])
    end

    Grid5000::JobWalltime::YES_NO_ATTRIBUTES.each do |attr|
      it "should transform true to String for '#{attr}' attribute" do
        job_walltime = Grid5000::JobWalltime.new(walltime: '+03h', attr => true)
        expect(job_walltime.valid?).to eq(true)
        expect(job_walltime.instance_variable_get("@#{attr}")).to eq('yes')
      end

      it "should transform false to String for '#{attr}' attribute" do
        job_walltime = Grid5000::JobWalltime.new(walltime: '+03h', attr => false)
        expect(job_walltime.valid?).to eq(true)
        expect(job_walltime.instance_variable_get("@#{attr}")).to eq('no')
      end

      it "should keep values as is for 'yes' String for '#{attr}' attribute" do
        job_walltime = Grid5000::JobWalltime.new(walltime: '+03h', attr => 'yes')
        expect(job_walltime.valid?).to eq(true)
        expect(job_walltime.instance_variable_get("@#{attr}")).to eq('yes')
      end

      it "should keep values as is for 'no' String for '#{attr}' attribute" do
        job_walltime = Grid5000::JobWalltime.new(walltime: '+03h', attr => 'no')
        expect(job_walltime.valid?).to eq(true)
        expect(job_walltime.instance_variable_get("@#{attr}")).to eq('no')
      end

      it "should fail with error when '#{attr}' is nor a boolean nor 'yes/no'" do
        job_walltime = Grid5000::JobWalltime.new(walltime: '+03h', attr => 'notok')
        expect(job_walltime.valid?).to eq(false)
        expect(job_walltime.errors).to eq(["#{Grid5000::JobWalltime::YES_NO_ATTRIBUTES.join(', ')} must be a Boolean"])
      end
    end
  end
end
