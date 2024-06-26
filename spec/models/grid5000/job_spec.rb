# Copyright (c) 2009-2011 Cyril Rohr, INRIA Rennes - Bretagne Atlantique
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

describe Grid5000::Job do
  describe 'normalization' do
    it 'should transform into integers a few properties' do
      now = Time.now.strftime('%Y-%m-%d %H:%M:%S')
      job = Grid5000::Job.new(exit_code: '0', submitted_at: '12345', started_at: '6789', reservation: now, signal: '1', uid: '12321', anterior: '34543', scheduled_at: '56765', walltime: '3600', checkpoint: '7200')
      expect(job.exit_code).to eq(0)
      expect(job.submitted_at).to eq(12_345)
      expect(job.started_at).to eq(6789)
      expect(job.reservation).to eq(now)
      expect(job.signal).to eq(1)
      expect(job.uid).to eq(12_321)
      expect(job.anterior).to eq(34_543)
      expect(job.scheduled_at).to eq(56_765)
      expect(job.walltime).to eq(3600)
      expect(job.checkpoint).to eq(7200)
    end

    it "should keep reservation as 'now'" do
      job = Grid5000::Job.new(exit_code: '0', submitted_at: '12345', started_at: '6789', reservation: 'now', signal: '1', uid: '12321', anterior: '34543', scheduled_at: '56765', walltime: '3600', checkpoint: '7200')
      expect(job.exit_code).to eq(0)
      expect(job.submitted_at).to eq(12_345)
      expect(job.started_at).to eq(6789)
      expect(job.reservation).to eq('now')
      expect(job.signal).to eq(1)
      expect(job.uid).to eq(12_321)
      expect(job.anterior).to eq(34_543)
      expect(job.scheduled_at).to eq(56_765)
      expect(job.walltime).to eq(3600)
      expect(job.checkpoint).to eq(7200)
    end
  end

  describe 'Exporting to a hash' do
    before do
      @job = Grid5000::Job.new(
        'walltime' => 32_304,
        'submitted_at' => 1_258_105_888,
        'mode' => 'INTERACTIVE',
        'events' => [
          {
            type: 'REDUCE_RESERVATION_WALLTIME',
            created_at: 1_258_106_496,
            uid: 2_934_161,
            to_check: 'NO',
            description: 'Change walltime from 32400 to 32304'
          }
        ],
        'uid' => 948_870,
        'user_uid' => 'rchakode',
        'types' => ['deploy'],
        'queue' => 'default',
        'assigned_nodes' => ['genepi-8.grenoble.grid5000.fr'],
        'started_at' => 1_258_106_496,
        'scheduled_at' => 1_258_106_496,
        'directory' => '/home/grenoble/rchakode',
        'command' => '',
        'project' => 'default',
        'properties' => "(deploy = 'YES') AND desktop_computing = 'NO'",
        'state' => 'running'
      )
    end
    it 'should export only non-null attributes' do
      job = Grid5000::Job.new(uid: 123)
      expect(job.to_hash).to eq({ 'uid' => 123 })
    end
    it 'should return all the attributes given at creation in a hash' do
      expect(@job.to_hash).to eq({
                                   'walltime' => 32_304,
                                   'submitted_at' => 1_258_105_888,
                                   'mode' => 'INTERACTIVE',
                                   'events' => [{ type: 'REDUCE_RESERVATION_WALLTIME', created_at: 1_258_106_496, uid: 2_934_161, to_check: 'NO', description: 'Change walltime from 32400 to 32304' }],
                                   'uid' => 948_870,
                                   'user_uid' => 'rchakode',
                                   'types' => ['deploy'],
                                   'queue' => 'default',
                                   'assigned_nodes' => ['genepi-8.grenoble.grid5000.fr'],
                                   'started_at' => 1_258_106_496,
                                   'scheduled_at' => 1_258_106_496,
                                   'directory' => '/home/grenoble/rchakode',
                                   'command' => '',
                                   'project' => 'default',
                                   'properties' => "(deploy = 'YES') AND desktop_computing = 'NO'",
                                   'state' => 'running',
                                   'workdir' => '/home/grenoble/rchakode'
                                 })
    end
    it 'should export to a hash structure valid for submitting a job to the oarapi' do
      reservation = Time.parse('2009-11-10 15:54:56').strftime('%Y-%m-%d %H:%M:%S')
      job = Grid5000::Job.new(resources: '/nodes=1', reservation: reservation, command: 'id', types: %w[deploy idempotent], walltime: 3600, checkpoint: 40)
      expect(job).to be_valid
      expect(job.to_hash(destination: 'oar-2.4-submission')).to eq({
                                                                     'script' => 'id',
                                                                     'checkpoint' => 40,
                                                                     'walltime' => 3600,
                                                                     'reservation' => '2009-11-10 15:54:56',
                                                                     'resource' => '/nodes=1',
                                                                     'type' => %w[deploy idempotent]
                                                                   })
    end
    it 'should not export the type or reservation attribute if nil or empty' do
      job = Grid5000::Job.new(resources: '/nodes=1', reservation: nil, command: 'id', types: nil, walltime: 3600, checkpoint: 40)
      expect(job).to be_valid
      expect(job.to_hash(destination: 'oar-2.4-submission')).to eq({
                                                                     'script' => 'id',
                                                                     'checkpoint' => 40,
                                                                     'walltime' => 3600,
                                                                     'resource' => '/nodes=1'
                                                                   })
    end

    it 'should copy import-job-key-from-file to a hash structure' do
      reservation = Time.parse('2009-11-10 15:54:56').strftime('%Y-%m-%d %H:%M:%S')
      job = Grid5000::Job.new(resources: '/nodes=1', reservation: reservation, command: 'id', types: %w[deploy idempotent], walltime: 3600, checkpoint: 40, 'import-job-key-from-file': 'file://abcd')
      expect(job).to be_valid
      expect(job.to_hash(destination: 'oar-2.4-submission')).to eq({
                                                                     'script' => 'id',
                                                                     'checkpoint' => 40,
                                                                     'walltime' => 3600,
                                                                     'reservation' => '2009-11-10 15:54:56',
                                                                     'resource' => '/nodes=1',
                                                                     'type' => %w[deploy idempotent],
                                                                     'import-job-key-from-file' => 'file://abcd'
                                                                   })
    end
  end

  describe 'Creating for future submission' do
    before do
      @at = (Time.now + 3600).to_i
      @now = Time.now.strftime('%Y-%m-%d %H:%M:%S')
      @valid_properties = { resources: '/nodes=1', reservation: @now, walltime: 3600, command: 'id', directory: '/home/crohr' }
    end
    it 'should correctly define the required entries for a job to be submitted' do
      job = Grid5000::Job.new(@valid_properties)
      expect(job).to be_valid
      expect(job.resources).to eq('/nodes=1')
      expect(job.reservation).to eq(@now)
      expect(job.walltime).to eq(3600)
      expect(job.command).to eq('id')
      expect(job.directory).to eq('/home/crohr')
      expect(job.types).to eq(nil)
    end
    it 'should not be valid if the reservation property is not in correct format' do
      job = Grid5000::Job.new(@valid_properties.merge(reservation: '2009/11/10 15:45:00 GMT+0100'))
      expect(job).not_to be_valid
    end
    it 'should should be valid if no command is passed, but this is a reservation' do
      job = Grid5000::Job.new(@valid_properties.merge(command: ''))
      expect(job).to be_valid
      job = Grid5000::Job.new(@valid_properties.merge(command: nil))
      expect(job).to be_valid
    end
    it 'should not be valid if there is nothing to do on launch, and this is a submission' do
      job = Grid5000::Job.new(@valid_properties.merge(command: '', reservation: nil))
      expect(job).to_not be_valid
      expect(job.errors.first).to eq('you must give a :command to execute on launch')
      job = Grid5000::Job.new(@valid_properties.merge(command: nil, reservation: nil))
      expect(job).to_not be_valid
      expect(job.errors.first).to eq('you must give a :command to execute on launch')
    end
    it 'should correctly export the property attribute, if specified' do
      job = Grid5000::Job.new(@valid_properties.merge(properties: "cluster='genepi'", queue: 'admin'))
      expect(job.properties).to eq("cluster='genepi'")
      expect(job.queue).to eq('admin')
      expect(job.to_hash(destination: 'oar-2.4-submission').values_at('property', 'queue')).to eq(["cluster='genepi'", 'admin'])
    end
    it 'should correctly export the std* attributes, if specified' do
      job = Grid5000::Job.new(@valid_properties.merge(stdout: '/home/crohr/stdout', stderr: '/home/crohr/stderr'))
      expect(job.stdout).to eq('/home/crohr/stdout')
      expect(job.stderr).to eq('/home/crohr/stderr')
      expect(job.to_hash(destination: 'oar-2.4-submission').values_at('stdout', 'stderr')).to eq(['/home/crohr/stdout', '/home/crohr/stderr'])
    end
  end
end
