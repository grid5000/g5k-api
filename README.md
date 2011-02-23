# g5kapi
This application is in charge of providing the core APIs for Grid'5000.

The project is hosted at <ssh://git.grid5000.fr/srv/git/repos/g5kapi>. 
Please send an email to <cyril.rohr@inria.fr> if you cannot access the code.

## Installation
* The app requires `ruby1.9.1-full`. You can get them from the lenny-backports. You should add the following to `/etc/apt/sources.list`:

        deb http://Backports.Debian.Org/debian-backports lenny-backports main contrib non-free
        deb-src http://Backports.Debian.Org/debian-backports lenny-backports main contrib non-free

  Then:

        sudo apt-get update
        sudo apt-get install ruby1.9.1-full git-core

* Install `bundler` dependency:

        wget http://git.grid5000.fr/pub/rubygem-bundler


## Development
* You MUST have a working installation of `ruby` 1.9.2+.
* You MUST have the `bundler` gem installed (1.0.0+):
  
        $ gem install bundler --no-ri --no-rdoc

* From the application root, install the application dependencies:

        $ bundle install

* Adapt the configuration files located in `config/options/`.

* [optional] Setup the database:

        $ bundle exec rake db:create RACK_ENV=development
        $ bundle exec rake db:migrate RACK_ENV=development

* If you're not too familiar with `rails` 3, have a look at <http://guides.rubyonrails.org/>.
* Look up the list of available rake tasks:

        $ bundle exec rake -T

## Testing
* You must have a working MySQL installation.

* Source the file in `spec/fixtures/oar2_2011-01-07.sql` in a local database (e.g. `oar2`, see `config/defaults.yml`). 
  Must be done only once to create a replica of the OAR database with production data.
  
* If not already done, create the application test database with:

        $ bundle exec rake db:reset RACK_ENV=test`

* Launch the tests:

        $ bundle exec rake

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

        $ bundle exec rake test:rcov
        $ open coverage/index.html
        
## Packaging
In the following, we assume you have SSH access to a machine with the debian packaging tools. Let's call it `debian-build`.

* Since we're using `bundler` in our app, let's create a package for the `bundler` gem (to be done only once):

        $ gem install fpm
        $ fpm -s gem -t deb bundler

* Bump the version number (a new changelog entry is automatically generated in `debian/changelog`):

        $ rake package:bump:patch # or package:bump:minor or package:bump:major
  
* Add an entry to the changelog (`debian/changelog`).
* Now, let's package the app:

        $ rake package:remote_build

This will copy the project to the `debian-build` machine, and launch the build. 
The generated `.deb` will be copied back at the end of the process in `pkg/`.

## Authors
* Cyril Rohr <cyril.rohr@inria.fr>
