#!/usr/bin/ruby -w

require 'cute'
require 'pp'

g5k = Cute::G5K::API.new(:uri => "http://192.168.2.10:8080", :version => "", :username => 'dmargery')
JOB_NAME = 'reproduce_bug_9467'
G5K_SITE = 'rennes'
G5K_ENV = 'debian9-x64-min' # environment to deploy
NODES = 1
WALLTIME = '00:40:00'

job=nil
g5k.get_my_jobs(G5K_SITE, ['waiting', 'running']).each do |j|
  pp j
  if j["name"] == JOB_NAME
    job=j
    break
  end
end

if job==nil
  puts "No job named #{JOB_NAME} found in #{G5K_SITE} for you. Creating one"
  job = g5k.reserve(:site => G5K_SITE, :nodes => NODES, :walltime => WALLTIME, :type => :deploy, :wait => false,
                    :name => JOB_NAME,
                    :cmd => 'sleep 64600'
                   )
  puts "Job #{job['uid']} created. Monitor its status with e.g.: oarstat -fj #{job['uid']}"
end

# for better output, redirect stderr to stdout, make stdout a synchronized output stream
STDERR.reopen(STDOUT)
STDOUT.sync = true

while job['state'] !~ /unning/
  msg=''
  if job.has_key?('scheduled_at')
    msg=". Scheduled start is #{Time.at(job['scheduled_at'])}"
  end
  puts "Waiting for job #{job['uid']} of current status #{job['state']}#{msg}"
  sleep 1
  job=g5k.get_job(G5K_SITE, job['uid'])
end

pp job

nodes = job['assigned_nodes']
puts "Running on: #{nodes.join(' ')}"

# deploying all nodes, waiting for the end of deployment
g5k.deploy(job, :env => G5K_ENV, :wait => true)

raise "Deployment ended with error" if ((job['deploy'].last['status'] == 'error') or (not job['deploy'].last['result'].to_a.all? { |e| e[1]['state'] == 'OK' }))
