#!/bin/bash

parallel -j 4 <<-END
curl "http://127.0.0.1:8000/sites/rennes/status?waiting=no"  -o /dev/null
curl "http://127.0.0.1:8000/sites/rennes/jobs/1058738"  -o /dev/null 
curl "http://127.0.0.1:8000/sites/rennes/jobs/1058737"  -o /dev/null 
curl "http://127.0.0.1:8000/sites/rennes/jobs/1058736"  -o /dev/null 
END

