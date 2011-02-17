## HEAD
* `/platforms/{{platform_id}}/sites/{{site_id}}/status` is no longer a collection. 
  Instead, there is now a `nodes` key which returns a hash with `{hostname => {:soft => soft_state, :hard => hard_state, :reservations => [...]}}`

* Upon creating a job or deployment, the details of the newly created job or deployment are not returned in the response. 
  Only the `Location` header is present, which must be dereferenced to fetch the job or deployment details.

* Deployment notifications now contain the full detail of the deployment. What was previously sent is available in the `result`.

* IN job description:
  `user_uid` is replaced by `user`. `user_uid` is still available but is going to be deprecated and removed in a future revision.
  `site_uid` is removed

## 2.x
Previously split into lots of small APIs. CHANGELOG will start from here.
