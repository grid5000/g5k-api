#
# Regular cron jobs for the g5kapi package
#
0 4	* * *	root	[ -x /usr/bin/g5kapi_maintenance ] && /usr/bin/g5kapi_maintenance
