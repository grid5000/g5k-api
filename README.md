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

* The `master` branch is the main development branch, from which stable release are generated and pushed to api-server-devel first, and then api-server-v3, on Grid'5000
* New features and fixes are expected to be developped in specific branches, and submitted for inclusion using Merge Requests.

### Development environment

* This app comes with a Vagrant box used for development, testing and packaging.

  By default, the vagrant box will provision a proxy, to get access to the live status
	of sites and to the home directory of users, except on one site where status will be
	served locally through a tunnel to that site's oardb.

  For users with a working installation of vagrant and virtualbox, setting up a
  working environement starts with a simple

        $ DEVELOPER=dmargery OAR_DB_SITE=rennes vagrant up --provision
        $ vagrant ssh
        vagrant> cd /vagrant

  The vagrant provisionning script will attempt to configure the VM's root and vagrant
  accounts to be accessible by ssh. By default, it will copy your authorized_keys, but you
  can control the keypair used with SSH_KEY=filename_of_private_key

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

* Get access to a OAR database, using one of the two methods described hereafter:

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

        $ bundle exec ./bin/g5k-api rails server -e development

* If you require traces on the shell, use

        $ bundle exec ./bin/g5k-api rails server -V -e development

* If you need to be authenticated for some development, use:

        $ HTTP_X_API_USER_CN=dmargery WHOAMI=rennes bundle exec ./bin/g5k-api rails server -e development

That's it. If you're not too familiar with `rails`, have a look at
<http://guides.rubyonrails.org/>.

You can also list the available rake tasks to see what's already automated for you:

    $ bundle exec rake -T

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

* Update reference-repository used for tests

Data used for tests live in the spec/fixtures/reference-repository/
directory. Before any tests, the testing script renames the git.rename
directory to .git, so that spec/fixtures/reference-repository becomes
a valid git repository. It undoes that change at the end of tests.

To update the test reference-repository with fresh real datas, remove old
repository and copy the new one:

    $ rm -rf spec/fixtures/reference-repository
    $ cp -r ~/git/reference-repository/data/

The repository can be quite heavy, so to limit the import size into g5k-api we
can only keep the `data` directory and rewrite the git history.

The tool [git-filter-repo](https://github.com/newren/git-filter-repo) can be
used to do that:

    $ cd spec/fixtures/reference-repository
    $ /usr/libexec/git-core/git-filter-repo --path data
    $ git gc --aggressive

Some rspec tests require to add a symlink inside the repository, because this
aspect is not used inside our reference-repository (we don't use links at all).

For example:

    $ rm data/grid5000/sites/nancy/servers/grcinq-srv-3.json
    $ ln -s data/grid5000/sites/nancy/servers/grcinq-srv-2.json data/grid5000/sites/nancy/servers/grcinq-srv-3.json

Commit the change, and then move the `.git`:

    $ mv .git git.rename
    $ cd ../../..

Update the `@latest_commit` variable:

    $ sed -ri "s/(\@latest_commit = ).*/\1 \'$(cat spec/fixtures/reference-repository/git.rename/refs/heads/master)\'/g" spec/spec_help.rb

Then, changes are to be applied manually, because some resources might not exist
anymore, and some might have been added, e.g.:
* the number and name of sites
* the clusters
* nodes inside a clusters
* servers on sites
* network_equipments
* …

However, sed can be usefull to help and save time. Here to replace inside tests
a site (`bordeaux`) and a cluster (`bordemer`) which don't exist anymore:

    $ find spec/ -type f -exec sed -ri 's/bordeaux/grenoble/g' {} \;
    $ find spec/ -type f -exec sed -ri 's/bordemer/dahu/g' {} \;

* Adding data to the test OAR2 database

The test OAR2 database is loaded in the test environment using the `RAILS_ENV=test bundle exec rake db:oar:seed` task defined in `lib/tasks/test.rake`. This tasks loads a SQL dump pointed by the SEED environment variable, and defaults to `spec/fixtures/oar2_2011-01-07.sql`

Updating the OAR2 test db therefore requires either

* Updating the contents of the `spec/fixtures/oar2_2011-01-07.sql` directly
* creating a new dump of the `oar2_test` database running on the vagrant box, and updating `lib/tasks/test.rake` to use that dump a the new seed (be sure to git add it to the repo). As that `oar2_test` database should be a valid oar2 database, its contents should be updatable using oar commands. You'll need to apt-get install oar2 first and configure `oar2.conf` to point to the test database first. If you do so, please consider spending a few minutes to update the puppet provisonning recipes so as to pre-configure the vagrant VM to manage the test database out of the box. Furture developper will thank you for that.

## Packaging

### Use the build infrastructure
The debian package build is done automatically as a stage in gitlab-ci. See `.gitlab-ci.yaml` and https://gitlab.inria.fr/grid5000/g5k-api/pipelines , but only tagged commits get pushed to the packages.grid5000.fr repository.

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

* <https://www.grid5000.fr/w/API_Maintenance>;

## Authors
* Cyril Rohr <cyril.rohr@inria.fr>, David Margery <david.margery@inria.fr> and others
