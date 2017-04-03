# g5kapi

This application is in charge of providing the core APIs for Grid'5000.

The project is hosted at <https://github.com/grid5000/g5kapi>.

Please send an email to <support-staff@lists.grid5000.fr> if you cannot access the code,
but if you read this, it's normally good…

## Installation

The app is packaged for Debian Jessie. Therefore installation is as follows:

    sudo apt-get update
    sudo apt-get install g5k-api

In particular, runtime dependencies of the app include `ruby2.1.5` and `git-core`.

## Development

### Development environment

* This app comes with a Vagrant box used for development, testing and packaging. 

  By default, the vagrant box will provision a proxy, to get access to the live status
	of sites and to the home directory of users, except on one site where status will be
	served locally through a tunnel to that site's oardb. This is specially useful to
	debug the web ui, but the tunnel to the db is also used for site status information. 

  For users with a working installation of vagrant and virtualbox, setting up a 
  working environement starts with a simple

        $ DEVELOPER=dmargery OAR_DB_SITE=rennes vagrant up --provision
        $ vagrant ssh
        vagrant> cd /vagrant

  The vagrant provisionning script will attempt to configure the VM's root and vagrant
  accounts to be accessible by ssh. By default, it will copy your authorized_keys, but you 
  can control the keypair used with SSH_KEY=filename_of_private_key  

  Of course, reality is a bit more complex. You might have troubles with the insecure
  certificate of the vagrant box provider. In that case, you'll need to start with 

        $ vagrant box add --insecure --name debian-jessie-x64-puppet_4 \
	  https://vagrant.irisa.fr/boxes/irisa_debian-8.2.0_puppet4.box
	  
  And as the application relies on external data sources, you'll need to connect
  it with a reference-repository, an OAR database, a kadeploy3 server, and a jabber server
  to exercice all its functionnality, in addition to its own backend services that
  are already packaged in the Vagrant box. As this is not trivial a requires some compromises,
  the development of this application relies strongly on unit tests.

  A useful set of ssh tunnels is created with
	
        vagrant> rake tunnels:setup

* For those of you that prefer working with the more classical rvm approach, you'll 
  need 
  
  * a working installation of `ruby` 2.1 We recommend using `rvm` to manage your ruby
  installations.
  
  * As with every Rails app, it uses the `bundler` gem to manage dependencies:
  
        $ gem install bundler --no-ri --no-rdoc
  
  Note: in the next sections we'll run `rake` or `cap` executables. If you're
  using an old version of bundler and are not using `rvm` to manage your ruby
  installations, you will probably need to prefix every executable with
  `bundle exec`. E.g. `rake -T` will become `bundle exec rake -T`.
  
  * From the application root, install the application dependencies,
  For nokogiri see
  [Nokogiri](http://nokogiri.org/tutorials/installing_nokogiri.html):

        $ sudo apt-get install libmysqlclient-dev  # needed for the mysql2 gem
        $ sudo apt-get install libpq-dev           # needed for the pg gem
        $ bundle install
  
### Development environment's access to data

* Setup the database schema:

        vagrant> rake db:setup RAILS_ENV=development

* Give access to reference data to expose. The scripts expect you
  have a checkout version of the reference-repository in a sibling directory
  to this code that is mounted on /home/vagrant/reference-repository in the
  vagrant box.

        (g5k-api) $ cd ..
        (..) $ git clone ssh://g5kadmin@git.grid5000.fr/srv/git/repos/reference-repository.git reference-repository
  
  You might not have admin access to Grid'5000's reference repository. in this case, you 
  could duplicate the fake repository used for tests, in the 
  spec/fixtures/reference-repository directory. 

        (g5k-api) $ cp -r spec/fixtures/reference-repository ..
        (g5k-api) $ mv ../reference-repository/git.rename ../reference-repository/.git

  Do not attempt to use the directory directly, as unit test play with the git.rename dir.

* Get access to a OAR database
  
  * Get your hands on a copy of an active database
   
        $ ssh oardb.reims.g5kadmin sudo cat /var/backups/all_db.sql.gz > all_db.sql.gz
        $ gunzip all_db.sqp
        vagrant>SEED=all_db.sqp RAILS_ENV=development rake db:oar:seed
  
  * Or tunnel your way to a live database (as g5k-api only requires read-only access)
    This is particularly usefull if you want to develop on the UI (but with bad site 
    information). You should setup an SSH tunnel between your machine and one of the 
    oardb servers of Grid'5000, so that you can access the current jobs:

        $ #first create a reverse port from the vagrant machine to your own machine
        $ vagrant ssh -- -R 15433:localhost:15433

        $ #In an other shell, create a tunnel from your machine to Grid'5000 
        $ ssh -NL 15433:oardb.rennes.grid5000.fr:5432 access.grid5000.fr

        $ #finally, edit the development section of config/defaults.yml to 
                                  oar:
                                    <<: *oar
                                    host: 127.0.0.1
                                    port: 15433
                                    username: oarreader
                                    password: read
                                    database: oar2
				

### Wrapping it up to run the server

* To run the server, just enter:

        $ ./bin/g5k-api server start -e development

* If you require traces on the shell, use

        $ ./bin/g5k-api server -V start -e development

* If you need to be authenticated for some development, use:

        $ HTTP_X_API_USER_CN=dmargery ./bin/g5k-api server start -e development

* If you want to develop on the UI, using the apache proxy, run your browser on 
        
				$ firefox http://127.0.0.1:8080/ui

* If you want to develop on the UI, interacting directly with the server, run your browser on 
        
				$ firefox http://127.0.0.1:8000/ui

That's it. If you're not too familiar with `rails` 3, have a look at
<http://guides.rubyonrails.org/>.

You can also list the available rake tasks and capistrano tasks to see what's
already automated for you:

    $ rake -T
    $ cap -T


## Testing

Assuming you have your development environment setup, the only missing step is
to create a test database, and a fake OAR database.

* Create the test database as follows:

        $ RAILS_ENV=test rake db:setup

* Create the fake OAR database as follows:

        $ RAILS_ENV=test rake db:oar:seed

* Launch the tests:

        $ RAILS_ENV=test rspec spec/ # or `bundle exec autotest` if rake fails (issue with Rails<3.1 and em_mysql2 adapter with evented code).

* Adding data to the reference repository used for tests

Data used for tests live in the spec/fixtures/reference-repository/
directory. Before any tests, the testing script renames the git.rename
directory to .git, so that spec/fixtures/reference-repository becomes
a valid git repository. It undoes that change at the end of tests.
As the g5k-api code relies on a library that
navigates git objects directly, the only data visible to the tests is
data commited to that repository. Therefore, to change data used for
tests, you must

        $ cd spec/fixtures/reference-repository/
        $ mv git.rename .git
		$ #make changes to files or the directory structure
		$ git commit -a -m "Updates to the test date to ....."
		$ mv .git git.rename
        $ git commit -a -m "Updates to the test date to ....." #IMPORTANT : you must add the changed test data to the global git repository so it can be picked up by other developpers.

After these changes, a lot of tests will fail as they rely on the hash of the latest git commit. Test code needs improved here, but until now, this has been solved with a search and replace.

* Adding data to the test OAR2 database

The test OAR2 database is loaded in the test environment using the `RAILS_ENV=test rake db:oar:seed` task defined in `lib/tasks/test.rake`. This tasks loads a SQL dump pointed by the SEED environment variable, and defaults to `spec/fixtures/oar2_2011-01-07.sql`

Updating the OAR2 test db therefore requires either

* Updating the contents of the `spec/fixtures/oar2_2011-01-07.sql` directly
* creating a new dump of the `oar2_test` database running on the vagrant box, and updating `lib/tasks/test.rake` to use that dump a the new seed (be sure to git add it to the repo). As that `oar2_test` database should be a valid oar2 database, its contents should be updatable using oar commands. You'll need to apt-get install oar2 first and configure `oar2.conf` to point to the test database first. If you do so, please consider spending a few minutes to update the puppet provisonning recipes so as to pre-configure the vagrant VM to manage the test database out of the box. Furture developper will thank you for that. 

## Packaging

* Bumping the version number is done as follows (a new changelog entry is
  automatically generated in `debian/changelog`):

        $ rake package:bump:patch # or: package:bump:minor, package:bump:major

* Building the `.deb` package is easy, since we kindly provide a rake task 
  to run in the vagrant box, that will copy the latest committed code 
  (`HEAD`) in /tmp/g5k-api, generate a `.deb` package, and move the generated
  package to the `pkg/` directory.

  Just execute from the host machine:

        $ vagrant ssh -- "cd /vagrant ; rake package:build:debian"

## Releasing and Installing and new version

* Once you've packaged the new version, you must release it to the APT
  repository hosted on apt.grid5000.fr. There is Capistrano task for this:
  By default it will release to g5k-api-devel repository hosted by apt.grid5000.fr

        $ REMOTE_USER=g5kadmin cap release

  The system does not support different keys for the gateway and the remote node.
  In this case, the following might work for you

        $ SSH_KEY=~/.ssh/id_rsa_grid5000_g5k NOPROXY=true REMOTE_USER=g5kadmin cap release

  Note that you can use the same task to release on a different host (for
  testing purposes for example), by setting the HOST environment variable to
  another server (a Grid'5000 node for instance).

  To release to stable API, you will need to set PROD_REPO before running the task

	$ REMOTE_USER=g5kadmin PROD_REPO=true cap release

* If you released on apt.grid5000.fr, then you are now able to install the new
  version on any server by launching the following commands:
  	  
	puppet-repo $ cap cmd HOST="api-server-devel.[sites]" CMD='sudo apt-get update && sudo apt-get install -y -o Dpkg::Options::="--force-confold" g5k-api'
        
  A more flexible mechanism can be used base on the script/puppet-repo-custom.rb file

	puppet-repo $ bundle exec cap shell ROLES=devel
        cap> sudo apt-get update && sudo apt-get install g5k-api -y && sudo puppetd -t

  For this command to work, you should have a look in the
  `script/puppet-repo-custom.rb` file, which in my case was dropped into the
  `config/` directory of the `puppet-repo` repository.

  Then you can check that every server has the correct version running by
  grepping through the processlist to check the version numbers:

        puppet-repo $ bundle exec cap shell ROLES=devel
        cap> ps aux | grep g5k-api | grep -v grep
        [establishing connection(s) to api-server-devel.bordeaux.grid5000.fr, api-server-devel.grenoble.grid5000.fr, api-server-devel.lille.grid5000.fr, api-server-devel.lyon.grid5000.fr, api-server-devel.luxembourg.grid5000.fr, api-server-devel.nancy.grid5000.fr, api-server-devel.reims.grid5000.fr, api-server-devel.rennes.grid5000.fr, api-server-devel.orsay.grid5000.fr, api-server-devel.sophia.grid5000.fr, api-server-devel.toulouse.grid5000.fr]
         ** [out :: api-server-devel.bordeaux.grid5000.fr] g5k-api  26110  0.3 13.9 246432 72840 ?        Sl   Nov20  14:43 thin server (0.0.0.0:8000) [g5k-api-3.0.16]
         ** [out :: api-server-devel.grenoble.grid5000.fr] g5k-api  18510  0.3  7.5 249072 78620 ?        Sl   Nov18  22:48 thin server (0.0.0.0:8000) [g5k-api-3.0.16]
         ** [out :: api-server-devel.luxembourg.grid5000.fr] g5k-api  13384  0.1 13.6 203396 71184 ?        Sl   Nov22   1:29 thin server (0.0.0.0:8000) [g5k-api-3.0.16]
         ** [out :: api-server-devel.nancy.grid5000.fr] g5k-api  12702  0.3 26.9 312236 69704 ?        Sl   Nov20  17:27 thin server (0.0.0.0:8000) [g5k-api-3.0.16]
         ** [out :: api-server-devel.sophia.grid5000.fr] g5k-api  19366  0.2 16.2 325972 84864 ?        Sl   Nov18  21:03 thin server (0.0.0.0:8000) [g5k-api-3.0.16]
         ** [out :: api-server-devel.rennes.grid5000.fr] g5k-api  19353  0.9  7.2 246492 76220 ?        Sl   05:53   4:38 thin server (0.0.0.0:8000) [g5k-api-3.0.16]
         ** [out :: api-server-devel.lille.grid5000.fr] g5k-api  18563  0.2 35.3 262788 92760 ?        Sl   Nov18  19:43 thin server (0.0.0.0:8000) [g5k-api-3.0.16]
         ** [out :: api-server-devel.orsay.grid5000.fr] g5k-api  30348  0.3 27.4 244552 71028 ?        Sl   Nov22   4:57 thin server (0.0.0.0:8000) [g5k-api-3.0.16]
         ** [out :: api-server-devel.toulouse.grid5000.fr] g5k-api   3825  0.3 32.3 259840 83660 ?        Sl   Nov18  23:54 thin server (0.0.0.0:8000) [g5k-api-3.0.16]
         ** [out :: api-server-devel.reims.grid5000.fr] g5k-api   1749  0.8 31.9 324736 82696 ?        Sl   Nov18  65:08 thin server (0.0.0.0:8000) [g5k-api-3.0.16]
         ** [out :: api-server-devel.lyon.grid5000.fr] g5k-api   9940  0.5 33.9 329864 87796 ?        Sl   Nov18  40:32 thin server (0.0.0.0:8000) [g5k-api-3.0.16]


## Statistics

* Generate general statistics:

        $ bundle exec rake stats

  Example of output you'll get on the STDOUT:

        +----------------------+-------+-------+---------+---------+-----+-------+
        | Name                 | Lines |   LOC | Classes | Methods | M/C | LOC/M |
        +----------------------+-------+-------+---------+---------+-----+-------+
        | Controllers          |   447 |   352 |      14 |      31 |   2 |     9 |
        | Helpers              |    54 |    26 |       0 |       5 |   0 |     3 |
        | Models               |   351 |   288 |       7 |      25 |   3 |     9 |
        | Libraries            |     3 |     3 |       0 |       0 |   0 |     0 |
        | Model specs          |   340 |   315 |       0 |       0 |   0 |     0 |
        | Controller specs     |   550 |   523 |       0 |       0 |   0 |     0 |
        | Helper specs         |    15 |     3 |       0 |       0 |   0 |     0 |
        +----------------------+-------+-------+---------+---------+-----+-------+
        | Total                |  1760 |  1510 |      21 |      61 |   2 |    22 |
        +----------------------+-------+-------+---------+---------+-----+-------+
          Code LOC: 669     Test LOC: 841     Code to Test Ratio: 1:1.3

* Generate the test coverage:

        $ RAILS_ENV=test rspec spec/
        $ open coverage/index.html


## Maintenance

* <https://www.grid5000.fr/mediawiki/index.php/API_Maintenance>;

* There exist monit recipes that send emails when an alert is raised. At the
  time of writing (2011-10-18), these alerts are sent to
  <cyril.rohr@irisa.fr>. You might want to change that.

## Kadeploy update process

Since Kadeploy3 uses DRb to communicate with clients, and that a lot of code is
shared between the client and server, clients must have the whole kadeploy3 code
accessible. So, each time a new version of Kadeploy is released and installed on
the Grid5000 sites, you MUST remember to update the kadeploy-common package.

## Authors
* Cyril Rohr <cyril.rohr@inria.fr>, David Margery <david.margery@inria.fr> and others
