# g5kapi

This application is in charge of providing the core APIs for Grid'5000.

The project is hosted at <https://gitlab.inria.fr/grid5000/g5kapi>.

Please send an email to <support-staff@lists.grid5000.fr> if you cannot access the code,
but if you read this, it's normally good…

## Installation

The app is packaged for Debian jessie and Debian stretch. Therefore installation is as follows:

        $ sudo apt-get update
        $ sudo apt-get install g5k-api

Most configuration file for the application are those in `/opt/g5k-api/config`. They are linked from `/etc/g5k-api`, but should the link be broken, the application will use the version `/opt/g5k-api/config`.

If the database is not configured when the package is installed, you'll need to run migration after it has been setup

       $ sudo g5k-api rake db:migrate

The service's execution environment is built by the `/usr/bin/g5k-api` script, that will source any `.sh` file in `/etc/g5k-api/conf.d/` before calling `/opt/ug5k-api/bin/g5k-api`. This is how bundled gems are setup before execution, and `SECRET_KEY_BASE` is set for production environment.

You can check the installation by running a few commands to gather information about the application's execution environment

        $ sudo g5k-api rake db:migrate:status
        $ sudo g5k-api rake about
        $ sudo g5k-api console #this will drop you in the rails console
        $ sudo g5k-api rake dbconsole #this will drop you in the database's console

## Development

### Development process

* The `master` branch has the code for the stable version of g5k-api. This is the version pushed to api-server-v3 servers on Grid'5000
* The `devel` branch has the code for the development version of g5k-api. This is the version pushed to api-server-devel servers on Grid'5000. It is expected that this branch is regularly rebased on the `master` branch
* New features and fixes are expected to be developped in specific branches, and submitted for inclusion using Merge Requests. Fixes to be pushed to production to the `master` branch, triggering a rebased of the `devel` branch after acceptation. New functionnality to be merge on the `devel` branch

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

        vagrant> bundle exec rake tunnels:setup

### Development environment's access to data

* Setup the database schema:

        vagrant> bundle exec rake db:setup RAILS_ENV=development

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

* Get access to a OAR database, unsing one of the two methods described hereafter:

  * Get your hands on a copy of an active database, and install it. Don't worry about the
    error messages when seeding the development database: most of them come from the fact
	that the database is empty and therefore the drop statements fail.

        $ export OAR_DB_SITE=rennes
		$ ssh oardb.$OAR_DB_SITE.g5kadmin sudo cat /var/backups/dumps/postgresql/oar2.sql.gz > tmp/oar2_$OAR_DB_SITE.sql.gz
        $ gunzip tmp/oar2_$OAR_DB_SITE.sql.gz
        vagrant>SEED=tmp/oar2_rennes.sql RAILS_ENV=development bundle exec rake db:oar:seed

  * Or tunnel your way to a live database (as g5k-api only requires read-only access)
    This is particularly usefull if you want to develop on the UI (but with bad site
    information). You should setup an SSH tunnel between your machine and one of the
    oardb servers of Grid'5000, so that you can access the current jobs:

        $ # In an other shell, create a tunnel from the vagrant machine to Grid'5000
		$ # (done as part of bundle exec rake tunnels:setup)
        vagrant> ssh -NL 15433:oardb.rennes.grid5000.fr:5432 access.grid5000.fr

        $ # edit the development section of config/defaults.yml to
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

        $ HTTP_X_API_USER_CN=dmargery WHOAMI=rennes ./bin/g5k-api server start -e development

* If you want to develop on the UI, using the apache proxy, run your browser on

        $ firefox http://127.0.0.1:8080/ui

* If you want to develop on the UI, interacting directly with the server, run your browser on

        $ firefox http://127.0.0.1:8000/ui

That's it. If you're not too familiar with `rails` 4, have a look at
<http://guides.rubyonrails.org/>.

You can also list the available rake tasks and capistrano tasks to see what's
already automated for you:

    $ bundle exec rake -T
    $ cap -T


## Testing

Assuming you have your development environment setup, the only missing step is
to create a test database, and a fake OAR database.

* Create the test database as follows:

        $ RAILS_ENV=test bundle exec rake db:setup

* Create the fake OAR database as follows:

        $ RAILS_ENV=test bundle exec rake db:oar:create # provisioned by puppet
        $ RAILS_ENV=test bundle exec rake db:oar:seed

* Launch the tests:

        $ RAILS_ENV=test bundle exec rspec spec/ # or `bundle exec autotest` if rake fails (issue with Rails<3.1 and em_mysql2 adapter with evented code).

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

The test OAR2 database is loaded in the test environment using the `RAILS_ENV=test bundle exec rake db:oar:seed` task defined in `lib/tasks/test.rake`. This tasks loads a SQL dump pointed by the SEED environment variable, and defaults to `spec/fixtures/oar2_2011-01-07.sql`

Updating the OAR2 test db therefore requires either

* Updating the contents of the `spec/fixtures/oar2_2011-01-07.sql` directly
* creating a new dump of the `oar2_test` database running on the vagrant box, and updating `lib/tasks/test.rake` to use that dump a the new seed (be sure to git add it to the repo). As that `oar2_test` database should be a valid oar2 database, its contents should be updatable using oar commands. You'll need to apt-get install oar2 first and configure `oar2.conf` to point to the test database first. If you do so, please consider spending a few minutes to update the puppet provisonning recipes so as to pre-configure the vagrant VM to manage the test database out of the box. Furture developper will thank you for that.

## Packaging

### Use the build infrastructure
The debian package build is done automatically as a stage in gitlab-ci. See `.gitlab-ci.yaml` and https://gitlab.inria.fr/grid5000/g5k-api/pipelines , but only tagged commits get pushed to the packages.grid5000.fr repository.

Tasks described in `lib/tasks/packaging.rake` are available to automatically manage version bumping, changelog generation and package building. If you use these tasks, a tag will be created each time version is bumped. Therefore, the `lib/grid5000/version.rb` file should only be changed using these tasks, at the end of a development cycle (if production has version X.Y.Z running, the file will keep that version during the next development cycle and it will only change at the end of the development cycle).

For this to work properly, you need a working .gitconfig.

- You can copy your main .gitconfig into the vagrant box

        $ cat ~/.gitconfig | vagrant ssh -- 'cat - > ~/.gitconfig'

- Or you can configure the vagrant box to your needs

        vagrant@g5k-local: git config --global user.name "Your Name"
        vagrant@g5k-local: git config --global user.email you@example.com

- You can now name the version you are about to package

        vagrant@g5k-local: bundle exec rake package:bump:patch #replace patch by minor or major when appropriate)

- And then build the debian package

        vagrant@g5k-local: bundle exec rake package:build:debian


The `package:build:debian` rake task has several arguments:

* NO_COMMIT: when bumping version number, do not commit the version file
* NO_TAG: do not tag the current git commit with the built version. Default is to tag. Has no effect with NO_COMMIT

If everything went ok you should have a package like: `pkg/g5k-api_X.Y.Z-<date of last commit>_amd64.deb`

See the `.gitlab-ci.yml` file for the use of the rake package commands in the gitlab pipelines.

### Debug the build infrastructure

From time to time, someone will have to look into `lib/taks/packaging.rake` to understand why `rake package:build:debian` does not do what is expected or to update the way the package is built. This is what happens when you call the rake task

1.  The rake task creates a temporary directory named /tmp/g5k-api_version, and extracts the lasted commited version of your code using `git archive HEAD` to it.
2.  The rake task makes sure the build dependencies are installed using `mk-build-deps`, which in turn uses info in the `debian/control` file.
3.  The changelog in the extracted version of the sources is updated with information from the latest commits.
4.  The rake task finally calls `dpkg-buildpackage -us -uc -d` to generate the package. dpkg-buildpackage then uses the `debian/rules` makefile to go through all the steps needed for packaging. This in turn falls back to `dh` for most steps, using datafiles in the `debian` directory.
    * Most tasks use the default implementation relying on the datafile found in the `debian` directory. Of particular interest are `logrotate`, `g5k-api.service`, `dirs`, `g5k-api.install` and `g5k-api.links`.
	* The magic happens in the `debian/setup_bundle` script. That script handles all the instructions required so that the gems needed by the application are installed and usable on the target system.
	    * It will prime the temporary directory from wich the application is packaged with the developper's bundle
		* It will run bundle install to setup the gems to package
		* It will generate a g5k-api binary so that the application is started in the context of the installed bundle without the user noticing bundler usage. This happens by generating a script to be installed in `/usr/bin` for all ruby executable found in `bin/`
    * `debian/setup_bundle`'s work is completed by lines in `debian/dirs` and `debian/g5k-api.install` to setup the final execution context of the application

## Releasing and Installing and new version

* Once you've packaged the new version, you must release it to the APT
  repository hosted on packages.grid5000.fr. Their is a manual step in gitlab's CI for this.

* If you released on packages.grid5000.fr, then api-server-devel servers will pick it up, but you'll need to change the hiera data for the production versions.

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

        $ RAILS_ENV=test bundle exec rspec spec/
        $ open coverage/index.html


## Maintenance

* <https://www.grid5000.fr/mediawiki/index.php/API_Maintenance>;

## Authors
* Cyril Rohr <cyril.rohr@inria.fr>, David Margery <david.margery@inria.fr> and others
