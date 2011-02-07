require 'digest/sha1'

Factory.sequence(:uid) do |n|
  Digest::SHA1.hexdigest("uid-#{n}")
end

Factory.define(:deployment, :class => Grid5000::Deployment) do |e|
  e.uid { Factory.next(:uid) }
  e.environment "lenny-x64-base"
  e.nodes ["paradent-1.rennes.grid5000.fr", "parapluie-1.rennes.grid5000.fr"]
  e.user_uid "crohr"
  e.site_uid "rennes"
end
