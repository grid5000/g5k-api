## HEAD
* `/platforms/{{platform_id}}/sites/{{site_id}}/status` is no longer a collection. 
  Instead, there is now a `nodes` key which returns a hash with `{hostname => {:soft => soft_state, :hard => hard_state, :reservations => [...]}}`

## 2.x
Previously split into lots of small APIs. Changelog will start from here.
