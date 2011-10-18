# g5kapi

This application is in charge of providing the core APIs for Grid'5000.

The project is hosted at <ssh://git.grid5000.fr/srv/git/repos/g5kapi>. 
Please send an email to <cyril.rohr@inria.fr> if you cannot access the code.


## Installation

The app is packaged for Debian Squeeze. Therefore installation is as follows:

    sudo apt-get update
    sudo apt-get install g5k-api

In particular, runtime dependencies of the app include `ruby1.9.1-full` and `git-core`.


## Development

* This app does not work with `ruby` 1.8. Therefore you need to have a working
  installation of `ruby` 1.9.2+. We recommend using `rvm` to manage your ruby
  installations.

* As with every Rails app, it uses the `bundler` gem to manage dependencies:

        $ gem install bundler --no-ri --no-rdoc

  Note: in the next sections we'll run `rake` or `cap` executables. If you're
  using an old version of bundler and are not using `rvm` to manage your ruby
  installations, you will probably need to prefix every executable with
  `bundle exec`. E.g. `rake -T` will become `bundle exec rake -T`.

* From the application root, install the application dependencies:

        $ bundle install

* Adapt the configuration files located in `config/options/`.

* [optional] Setup the database:

        $ rake db:create RACK_ENV=development
        $ rake db:migrate RACK_ENV=development

  Note that if you don't want to install a mysql server and other dependencies
  on your machine, you can use one of the `capistrano` tasks that are bundled
  with the app.
  
  For instance, doing a `cap develop` will launch and configure a machine on
  Grid'5000 with everything required to have a working development
  environment (adapt the `database.yml` file in consequence).

* If you're not too familiar with `rails` 3, have a look at
  <http://guides.rubyonrails.org/>.

* Look up the list of available rake tasks:

        $ rake -T


## Testing

Assuming you have your development environment setup, the only missing step is
to create a test database, and a fake OAR database.

* Create the test database as follows:

        $ RACK_ENV=test rake db:create
        $ RACK_ENV=test rake db:migrate

* Create the fake OAR database as follows:

        $ RACK_ENV=test rake db:oar:setup
  
  or `RACK_ENV=test rake db:oar:seed` if the OAR database already exists.

* Launch the tests:

        $ RACK_ENV=test rake
        
## Packaging

* Bumping the version number is done as follows (a new changelog entry is
  automatically generated in `debian/changelog`):

        $ rake package:bump:patch # or: package:bump:minor, package:bump:major

* Building the `.deb` package is easy, since we kindly provide a `capistrano`
  recipe that will automatically reserve a machine on Grid'5000, deploy a
  squeeze-based image, upload the latest committed code (`HEAD`) in the
  current branch, generate a `.deb` package, and download the generated
  package back to your machine, in the `pkg/` directory.

  Just execute:

        $ cap package

  You can also pass a specific HOST if you wish (in this case it won't reserve
  a node on Grid'5000):

        $ cap package HOST=...


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

## Maintenance

* <https://www.grid5000.fr/mediawiki/index.php/API_Maintenance>;

* There exist monit recipes that send emails when an alert is raised. At the
  time of writing (2011-10-18), these alerts are sent to
  <cyril.rohr@irisa.fr>. You might want to change that.


## Authors
* Cyril Rohr <cyril.rohr@inria.fr>
