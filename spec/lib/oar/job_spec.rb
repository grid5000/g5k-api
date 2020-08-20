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

describe OAR::Job do
  it 'should list the expanded jobs, filtered' do
    jobs = double('jobs')
    expect(OAR::Job).to receive(:expanded).and_return(jobs)
    expect(jobs).to receive(:order).with('job_id DESC').and_return(jobs)
    expect(jobs).to receive(:where).with(job_user: 'crohr').and_return(jobs)
    expect(jobs).to receive(:where).with(job_name: 'whatever').and_return(jobs)
    expect(jobs).to receive(:where).with(queue_name: 'default').and_return(jobs)
    expect(OAR::Job.list(user: 'crohr', name: 'whatever', queue: 'default')).to eq jobs
  end

  it 'should fetch a job, and have the expected methods' do
    job = OAR::Job.first
    %w[user name queue uid state walltime].each do |method|
      expect(job).to respond_to(method.to_sym)
    end
  end

  it 'should fetch the list of active jobs' do
    expect(OAR::Job.active.map(&:uid)).to eq([374_173, 374_179, 374_180, 374_185, 374_186, 374_190, 374_191, 374_192, 374_193, 374_194, 374_195, 374_196, 374_197, 374_198, 374_199, 374_205, 374_210])
  end

  it 'should fetch the list of active jobs being not in Waiting state' do
    expect(OAR::Job.active_not_waiting.map(&:uid)).to eq([374_173, 374_179, 374_180, 374_185, 374_186, 374_190, 374_191, 374_192, 374_193, 374_194, 374_195, 374_196, 374_198, 374_210])
  end

  it 'should fetch the job with the jobid AND match all job parameters' do
    params = {
      job_id: 374_191
    }
    expect(OAR::Job.list(params)).to exist
    result = JSON.parse(
      OAR::Job.expanded.active.list(params).to_json
    )
    expect(result).to eq([{
                           'uid' => 374_191,
                           'user_uid' => 'jgallard',
                           'user' => 'jgallard',
                           'walltime' => 7200,
                           'queue' => 'default',
                           'state' => 'running',
                           'project' => 'default',
                           'types' => ['deploy'],
                           'mode' => 'INTERACTIVE',
                           'command' => '',
                           'submitted_at' => 1_294_395_993,
                           'scheduled_at' => 1_294_395_995,
                           'started_at' => 1_294_395_995,
                           'message' => 'FIFO scheduling OK',
                           'properties' => '((cluster="paramount") AND deploy = "YES") AND maintenance = "NO"',
                           'directory' => '/home/jgallard/stagiaires10/stagiaires-nancy/partiel_from_paracancale_sajith/grid5000',
                           'events' => [
                             {
                               'uid' => 950_608,
                               'created_at' => 1_294_403_214,
                               'type' => 'FRAG_JOB_REQUEST',
                               'description' => 'User root requested to frag the job 374191'
                             },
                             {
                               'uid' => 950_609,
                               'created_at' => 1_294_403_214,
                               'type' => 'WALLTIME',
                               'description' => '[sarko] Job [374191] from 1294395995 with 7200; current time=1294403214 (Elapsed)'
                             },
                             {
                               'uid' => 950_610,
                               'created_at' => 1_294_403_215,
                               'type' => 'SEND_KILL_JOB',
                               'description' => '[Leon] Send kill signal to oarexec on frontend.rennes.grid5000.fr for the job 374191'
                             },
                             {
                               'uid' => 950_611,
                               'created_at' => 1_294_403_225,
                               'type' => 'SWITCH_INTO_ERROR_STATE',
                               'description' => '[bipbip 374191] Ask to change the job state'
                             }
                           ]
                         }])
  end

  it 'should return null if the job does NOT exist' do
    params = {
      job_id: 999_999
    }
    expect(OAR::Job.list(params)).to_not exist
  end

  it 'should fetch the list of resources' do
    resources = OAR::Job.active.first.resources
    expect(resources.map(&:id).sort).to eq([952, 953, 954, 955, 956, 957, 958, 959, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1128, 1129, 1130, 1131, 1132, 1133, 1134, 1135, 1136, 1137, 1138, 1139, 1140, 1141, 1142, 1143, 1144, 1145, 1146, 1147, 1148, 1149, 1150, 1151, 1152, 1153, 1154, 1155, 1156, 1157, 1158, 1159, 1160, 1161, 1162, 1163, 1164, 1165, 1166, 1167, 1184, 1185, 1186, 1187, 1188, 1189, 1190, 1191, 1192, 1193, 1194, 1195, 1196, 1197, 1198, 1199, 1200, 1201, 1202, 1203, 1204, 1205, 1206, 1207, 1208, 1209, 1210, 1211, 1212, 1213, 1214, 1215, 1216, 1217, 1218, 1219, 1220, 1221, 1222, 1223, 1224, 1225, 1226, 1227, 1228, 1229, 1230, 1231, 1232, 1233, 1234, 1235, 1236, 1237, 1238, 1239, 1240, 1241, 1242, 1243, 1244, 1245, 1246, 1247, 1256, 1257, 1258, 1259, 1260, 1261, 1262, 1263, 1264, 1265, 1266, 1267, 1268, 1269, 1270, 1271, 1272, 1273, 1274, 1275, 1276, 1277, 1278, 1279, 1280, 1281, 1282, 1283, 1284, 1285, 1286, 1287, 1296, 1297, 1298, 1299, 1300, 1301, 1302, 1303, 1304, 1305, 1306, 1307, 1308, 1309, 1310, 1311, 1312, 1313, 1314, 1315, 1316, 1317, 1318, 1319, 1320, 1321, 1322, 1323, 1324, 1325, 1326, 1327, 1328, 1329, 1330, 1331, 1332, 1333, 1334, 1335, 1336, 1337, 1338, 1339, 1340, 1341, 1342, 1343, 1344, 1345, 1346, 1347, 1348, 1349, 1350, 1351, 1352, 1353, 1354, 1355, 1356, 1357, 1358, 1359, 1360, 1361, 1362, 1363, 1364, 1365, 1366, 1367, 1368, 1369, 1370, 1371, 1372, 1373, 1374, 1375, 1376, 1377, 1378, 1379, 1380, 1381, 1382, 1383, 1384, 1385, 1386, 1387, 1388, 1389, 1390, 1391, 1392, 1393, 1394, 1395, 1396, 1397, 1398, 1399].sort)
  end

  it 'should fetch the predicted start time' do
    expect(OAR::Job.find(374_191).gantt.start_time).to eq(1_294_395_995)
  end

  it 'should fetch the job events' do
    expect(OAR::Job.active.first.events.map(&:type)).to eq(%w[FRAG_JOB_REQUEST SEND_KILL_JOB SWITCH_INTO_ERROR_STATE])
  end

  it 'should dump the job' do
    result = JSON.parse(
      OAR::Job.expanded.active.includes(:gantt, :job_events, :job_types).find(374_191).to_json
    )
    expect(result).to eq({
                           'uid' => 374_191,
                           'user_uid' => 'jgallard',
                           'user' => 'jgallard',
                           'walltime' => 7200,
                           'queue' => 'default',
                           'state' => 'running',
                           'project' => 'default',
                           'types' => ['deploy'],
                           'mode' => 'INTERACTIVE',
                           'command' => '',
                           'submitted_at' => 1_294_395_993,
                           'scheduled_at' => 1_294_395_995,
                           'started_at' => 1_294_395_995,
                           'message' => 'FIFO scheduling OK',
                           'properties' => '((cluster="paramount") AND deploy = "YES") AND maintenance = "NO"',
                           'directory' => '/home/jgallard/stagiaires10/stagiaires-nancy/partiel_from_paracancale_sajith/grid5000',
                           'events' => [
                             {
                               'uid' => 950_608,
                               'created_at' => 1_294_403_214,
                               'type' => 'FRAG_JOB_REQUEST',
                               'description' => 'User root requested to frag the job 374191'
                             },
                             {
                               'uid' => 950_609,
                               'created_at' => 1_294_403_214,
                               'type' => 'WALLTIME',
                               'description' => '[sarko] Job [374191] from 1294395995 with 7200; current time=1294403214 (Elapsed)'
                             },
                             {
                               'uid' => 950_610,
                               'created_at' => 1_294_403_215,
                               'type' => 'SEND_KILL_JOB',
                               'description' => '[Leon] Send kill signal to oarexec on frontend.rennes.grid5000.fr for the job 374191'
                             },
                             {
                               'uid' => 950_611,
                               'created_at' => 1_294_403_225,
                               'type' => 'SWITCH_INTO_ERROR_STATE',
                               'description' => '[bipbip 374191] Ask to change the job state'
                             }
                           ]
                         })
  end

  it 'should return a list of assigned nodes sorted by network_address (nodes)' do
    result = OAR::Job.active.first.assigned_nodes # The unique list of assigned nodes
    # The unique list of assigned nodes should be sorted as below
    expect(result.sort).to eq(['paradent-9.rennes.grid5000.fr', 'paradent-28.rennes.grid5000.fr', 'paradent-31.rennes.grid5000.fr', 'paradent-32.rennes.grid5000.fr', 'paradent-33.rennes.grid5000.fr', 'paradent-34.rennes.grid5000.fr', 'paradent-35.rennes.grid5000.fr', 'paradent-38.rennes.grid5000.fr', 'paradent-39.rennes.grid5000.fr', 'paradent-40.rennes.grid5000.fr', 'paradent-41.rennes.grid5000.fr', 'paradent-42.rennes.grid5000.fr', 'paradent-43.rennes.grid5000.fr', 'paradent-44.rennes.grid5000.fr', 'paradent-45.rennes.grid5000.fr', 'paradent-47.rennes.grid5000.fr', 'paradent-48.rennes.grid5000.fr', 'paradent-49.rennes.grid5000.fr', 'paradent-50.rennes.grid5000.fr', 'paradent-52.rennes.grid5000.fr', 'paradent-53.rennes.grid5000.fr', 'paradent-54.rennes.grid5000.fr', 'paradent-55.rennes.grid5000.fr', 'paradent-56.rennes.grid5000.fr', 'paradent-57.rennes.grid5000.fr', 'paradent-58.rennes.grid5000.fr', 'paradent-59.rennes.grid5000.fr', 'paradent-60.rennes.grid5000.fr', 'paradent-61.rennes.grid5000.fr', 'paradent-62.rennes.grid5000.fr', 'paradent-63.rennes.grid5000.fr', 'paradent-64.rennes.grid5000.fr'].sort)
  end

  # each node in the list should be repeated as many times cores are reserved
  it 'should build a hash of resources indexed by their type [cores]' do
    result = OAR::Job.active.first.resources_by_type
    expect(result.keys).to eq(['cores'])
    expect(result['cores'].sort).to eq(['paradent-9.rennes.grid5000.fr', 'paradent-9.rennes.grid5000.fr', 'paradent-9.rennes.grid5000.fr', 'paradent-9.rennes.grid5000.fr', 'paradent-9.rennes.grid5000.fr', 'paradent-9.rennes.grid5000.fr', 'paradent-9.rennes.grid5000.fr', 'paradent-9.rennes.grid5000.fr', 'paradent-28.rennes.grid5000.fr', 'paradent-28.rennes.grid5000.fr', 'paradent-28.rennes.grid5000.fr', 'paradent-28.rennes.grid5000.fr', 'paradent-28.rennes.grid5000.fr', 'paradent-28.rennes.grid5000.fr', 'paradent-28.rennes.grid5000.fr', 'paradent-28.rennes.grid5000.fr', 'paradent-31.rennes.grid5000.fr', 'paradent-31.rennes.grid5000.fr', 'paradent-31.rennes.grid5000.fr', 'paradent-31.rennes.grid5000.fr', 'paradent-31.rennes.grid5000.fr', 'paradent-31.rennes.grid5000.fr', 'paradent-31.rennes.grid5000.fr', 'paradent-31.rennes.grid5000.fr', 'paradent-32.rennes.grid5000.fr', 'paradent-32.rennes.grid5000.fr', 'paradent-32.rennes.grid5000.fr', 'paradent-32.rennes.grid5000.fr', 'paradent-32.rennes.grid5000.fr', 'paradent-32.rennes.grid5000.fr', 'paradent-32.rennes.grid5000.fr', 'paradent-32.rennes.grid5000.fr', 'paradent-33.rennes.grid5000.fr', 'paradent-33.rennes.grid5000.fr', 'paradent-33.rennes.grid5000.fr', 'paradent-33.rennes.grid5000.fr', 'paradent-33.rennes.grid5000.fr', 'paradent-33.rennes.grid5000.fr', 'paradent-33.rennes.grid5000.fr', 'paradent-33.rennes.grid5000.fr', 'paradent-34.rennes.grid5000.fr', 'paradent-34.rennes.grid5000.fr', 'paradent-34.rennes.grid5000.fr', 'paradent-34.rennes.grid5000.fr', 'paradent-34.rennes.grid5000.fr', 'paradent-34.rennes.grid5000.fr', 'paradent-34.rennes.grid5000.fr', 'paradent-34.rennes.grid5000.fr', 'paradent-35.rennes.grid5000.fr', 'paradent-35.rennes.grid5000.fr', 'paradent-35.rennes.grid5000.fr', 'paradent-35.rennes.grid5000.fr', 'paradent-35.rennes.grid5000.fr', 'paradent-35.rennes.grid5000.fr', 'paradent-35.rennes.grid5000.fr', 'paradent-35.rennes.grid5000.fr', 'paradent-38.rennes.grid5000.fr', 'paradent-38.rennes.grid5000.fr', 'paradent-38.rennes.grid5000.fr', 'paradent-38.rennes.grid5000.fr', 'paradent-38.rennes.grid5000.fr', 'paradent-38.rennes.grid5000.fr', 'paradent-38.rennes.grid5000.fr', 'paradent-38.rennes.grid5000.fr', 'paradent-39.rennes.grid5000.fr', 'paradent-39.rennes.grid5000.fr', 'paradent-39.rennes.grid5000.fr', 'paradent-39.rennes.grid5000.fr', 'paradent-39.rennes.grid5000.fr', 'paradent-39.rennes.grid5000.fr', 'paradent-39.rennes.grid5000.fr', 'paradent-39.rennes.grid5000.fr', 'paradent-40.rennes.grid5000.fr', 'paradent-40.rennes.grid5000.fr', 'paradent-40.rennes.grid5000.fr', 'paradent-40.rennes.grid5000.fr', 'paradent-40.rennes.grid5000.fr', 'paradent-40.rennes.grid5000.fr', 'paradent-40.rennes.grid5000.fr', 'paradent-40.rennes.grid5000.fr', 'paradent-41.rennes.grid5000.fr', 'paradent-41.rennes.grid5000.fr', 'paradent-41.rennes.grid5000.fr', 'paradent-41.rennes.grid5000.fr', 'paradent-41.rennes.grid5000.fr', 'paradent-41.rennes.grid5000.fr', 'paradent-41.rennes.grid5000.fr', 'paradent-41.rennes.grid5000.fr', 'paradent-42.rennes.grid5000.fr', 'paradent-42.rennes.grid5000.fr', 'paradent-42.rennes.grid5000.fr', 'paradent-42.rennes.grid5000.fr', 'paradent-42.rennes.grid5000.fr', 'paradent-42.rennes.grid5000.fr', 'paradent-42.rennes.grid5000.fr', 'paradent-42.rennes.grid5000.fr', 'paradent-43.rennes.grid5000.fr', 'paradent-43.rennes.grid5000.fr', 'paradent-43.rennes.grid5000.fr', 'paradent-43.rennes.grid5000.fr', 'paradent-43.rennes.grid5000.fr', 'paradent-43.rennes.grid5000.fr', 'paradent-43.rennes.grid5000.fr', 'paradent-43.rennes.grid5000.fr', 'paradent-44.rennes.grid5000.fr', 'paradent-44.rennes.grid5000.fr', 'paradent-44.rennes.grid5000.fr', 'paradent-44.rennes.grid5000.fr', 'paradent-44.rennes.grid5000.fr', 'paradent-44.rennes.grid5000.fr', 'paradent-44.rennes.grid5000.fr', 'paradent-44.rennes.grid5000.fr', 'paradent-45.rennes.grid5000.fr', 'paradent-45.rennes.grid5000.fr', 'paradent-45.rennes.grid5000.fr', 'paradent-45.rennes.grid5000.fr', 'paradent-45.rennes.grid5000.fr', 'paradent-45.rennes.grid5000.fr', 'paradent-45.rennes.grid5000.fr', 'paradent-45.rennes.grid5000.fr', 'paradent-47.rennes.grid5000.fr', 'paradent-47.rennes.grid5000.fr', 'paradent-47.rennes.grid5000.fr', 'paradent-47.rennes.grid5000.fr', 'paradent-47.rennes.grid5000.fr', 'paradent-47.rennes.grid5000.fr', 'paradent-47.rennes.grid5000.fr', 'paradent-47.rennes.grid5000.fr', 'paradent-48.rennes.grid5000.fr', 'paradent-48.rennes.grid5000.fr', 'paradent-48.rennes.grid5000.fr', 'paradent-48.rennes.grid5000.fr', 'paradent-48.rennes.grid5000.fr', 'paradent-48.rennes.grid5000.fr', 'paradent-48.rennes.grid5000.fr', 'paradent-48.rennes.grid5000.fr', 'paradent-49.rennes.grid5000.fr', 'paradent-49.rennes.grid5000.fr', 'paradent-49.rennes.grid5000.fr', 'paradent-49.rennes.grid5000.fr', 'paradent-49.rennes.grid5000.fr', 'paradent-49.rennes.grid5000.fr', 'paradent-49.rennes.grid5000.fr', 'paradent-49.rennes.grid5000.fr', 'paradent-50.rennes.grid5000.fr', 'paradent-50.rennes.grid5000.fr', 'paradent-50.rennes.grid5000.fr', 'paradent-50.rennes.grid5000.fr', 'paradent-50.rennes.grid5000.fr', 'paradent-50.rennes.grid5000.fr', 'paradent-50.rennes.grid5000.fr', 'paradent-50.rennes.grid5000.fr', 'paradent-52.rennes.grid5000.fr', 'paradent-52.rennes.grid5000.fr', 'paradent-52.rennes.grid5000.fr', 'paradent-52.rennes.grid5000.fr', 'paradent-52.rennes.grid5000.fr', 'paradent-52.rennes.grid5000.fr', 'paradent-52.rennes.grid5000.fr', 'paradent-52.rennes.grid5000.fr', 'paradent-53.rennes.grid5000.fr', 'paradent-53.rennes.grid5000.fr', 'paradent-53.rennes.grid5000.fr', 'paradent-53.rennes.grid5000.fr', 'paradent-53.rennes.grid5000.fr', 'paradent-53.rennes.grid5000.fr', 'paradent-53.rennes.grid5000.fr', 'paradent-53.rennes.grid5000.fr', 'paradent-54.rennes.grid5000.fr', 'paradent-54.rennes.grid5000.fr', 'paradent-54.rennes.grid5000.fr', 'paradent-54.rennes.grid5000.fr', 'paradent-54.rennes.grid5000.fr', 'paradent-54.rennes.grid5000.fr', 'paradent-54.rennes.grid5000.fr', 'paradent-54.rennes.grid5000.fr', 'paradent-55.rennes.grid5000.fr', 'paradent-55.rennes.grid5000.fr', 'paradent-55.rennes.grid5000.fr', 'paradent-55.rennes.grid5000.fr', 'paradent-55.rennes.grid5000.fr', 'paradent-55.rennes.grid5000.fr', 'paradent-55.rennes.grid5000.fr', 'paradent-55.rennes.grid5000.fr', 'paradent-56.rennes.grid5000.fr', 'paradent-56.rennes.grid5000.fr', 'paradent-56.rennes.grid5000.fr', 'paradent-56.rennes.grid5000.fr', 'paradent-56.rennes.grid5000.fr', 'paradent-56.rennes.grid5000.fr', 'paradent-56.rennes.grid5000.fr', 'paradent-56.rennes.grid5000.fr', 'paradent-57.rennes.grid5000.fr', 'paradent-57.rennes.grid5000.fr', 'paradent-57.rennes.grid5000.fr', 'paradent-57.rennes.grid5000.fr', 'paradent-57.rennes.grid5000.fr', 'paradent-57.rennes.grid5000.fr', 'paradent-57.rennes.grid5000.fr', 'paradent-57.rennes.grid5000.fr', 'paradent-58.rennes.grid5000.fr', 'paradent-58.rennes.grid5000.fr', 'paradent-58.rennes.grid5000.fr', 'paradent-58.rennes.grid5000.fr', 'paradent-58.rennes.grid5000.fr', 'paradent-58.rennes.grid5000.fr', 'paradent-58.rennes.grid5000.fr', 'paradent-58.rennes.grid5000.fr', 'paradent-59.rennes.grid5000.fr', 'paradent-59.rennes.grid5000.fr', 'paradent-59.rennes.grid5000.fr', 'paradent-59.rennes.grid5000.fr', 'paradent-59.rennes.grid5000.fr', 'paradent-59.rennes.grid5000.fr', 'paradent-59.rennes.grid5000.fr', 'paradent-59.rennes.grid5000.fr', 'paradent-60.rennes.grid5000.fr', 'paradent-60.rennes.grid5000.fr', 'paradent-60.rennes.grid5000.fr', 'paradent-60.rennes.grid5000.fr', 'paradent-60.rennes.grid5000.fr', 'paradent-60.rennes.grid5000.fr', 'paradent-60.rennes.grid5000.fr', 'paradent-60.rennes.grid5000.fr', 'paradent-61.rennes.grid5000.fr', 'paradent-61.rennes.grid5000.fr', 'paradent-61.rennes.grid5000.fr', 'paradent-61.rennes.grid5000.fr', 'paradent-61.rennes.grid5000.fr', 'paradent-61.rennes.grid5000.fr', 'paradent-61.rennes.grid5000.fr', 'paradent-61.rennes.grid5000.fr', 'paradent-62.rennes.grid5000.fr', 'paradent-62.rennes.grid5000.fr', 'paradent-62.rennes.grid5000.fr', 'paradent-62.rennes.grid5000.fr', 'paradent-62.rennes.grid5000.fr', 'paradent-62.rennes.grid5000.fr', 'paradent-62.rennes.grid5000.fr', 'paradent-62.rennes.grid5000.fr', 'paradent-63.rennes.grid5000.fr', 'paradent-63.rennes.grid5000.fr', 'paradent-63.rennes.grid5000.fr', 'paradent-63.rennes.grid5000.fr', 'paradent-63.rennes.grid5000.fr', 'paradent-63.rennes.grid5000.fr', 'paradent-63.rennes.grid5000.fr', 'paradent-63.rennes.grid5000.fr', 'paradent-64.rennes.grid5000.fr', 'paradent-64.rennes.grid5000.fr', 'paradent-64.rennes.grid5000.fr', 'paradent-64.rennes.grid5000.fr', 'paradent-64.rennes.grid5000.fr', 'paradent-64.rennes.grid5000.fr', 'paradent-64.rennes.grid5000.fr', 'paradent-64.rennes.grid5000.fr'].sort)
  end

  it 'should build a hash of resources indexed by their type [disks]' do
    result = OAR::Job.active.find(374_198).resources_by_type
    expect(result.keys.sort).to eq(%w[cores disks])
    expect(result['disks'].sort).to eq(['sdb.parasilo-1.rennes.grid5000.fr', 'sdc.parasilo-1.rennes.grid5000.fr'].sort)
  end

  xit 'should build a hash of resources indexed by their type [vlans]' do
    pending 'job with VLANs'
  end

  xit 'should build a hash of resources indexed by their type [subnets]' do
    pending 'example with SUBNETs'
    raise
  end
end
