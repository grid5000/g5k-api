## HEAD

* New media types: All responses are now either
  `application/vnd.grid5000.collection+json` or
  `application/vnd.grid5000.item+json` (this is still JSON formatted payload).
  When you POST or PUT content, you can use `application/json` format or
  `application/x-www-form-urlencoded`.

* `/sites/{{site_id}}/status` is no longer a collection. Instead, there is now
  a `nodes` key which returns a hash with `{hostname => {:soft => soft_state,
  :hard => hard_state, :reservations => [...]}}`

* Upon creating a job or deployment, the details of the newly created job or
  deployment are not returned in the response. Only the `Location` header is
  present, which must be dereferenced to fetch the job or deployment details.

* Deployment notifications now contain the full detail of the deployment. What
  was previously sent is available in the `result`.

* In `/sites/{{site_id}}/jobs`, a lot more details are returned for each job.

* In job description: `user_uid` is replaced by `user`. `user_uid` is still
  available but is going to be deprecated and removed in a future revision.
  `site_uid` is removed. A `resources_by_type` property is now available,
  whici is a dictionary of the resources assigned to the job (nodes, vlans,
  subnets), grouped by the type of the resource.

* JSON payloads are no longer pretty by default. Use `?pretty=yes` or add the
  HTTP headers `X-Rack-PrettyJSON: yes` to your requests if you want pretty
  output.

* Notifications API is now available. This lets you send notifications via
  SMTP (email), XMPP (jabber), or HTTP. The Deployments API uses that API to
  send you notifications when a deployments ends. You can now use it for
  yourself.

      $ curl -kni https://api.grid5000.fr/sid/notifications -d "to[]=mailto:cyril.rohr@inria.fr&body=My Message"

* Internally, API is now released as a Debian package, for easy installation.

* Latest stable API is now available under the https://api.grid5000.fr/stable
  alias.

## 2.x

Previously split into lots of small APIs. CHANGELOG will start from here.
