
# Setting a Facebook app on Heroku

## Software Installation and Configuration (1)

### Mac

* Install Xcode from the install DVD or Apple website.

* Install Homebrew (package manager).

      curl https://gist.github.com/raw/323731/install_homebrew.rb > /tmp/install_homebrew.rb
      ruby /tmp/install_homebrew.rb

* Install Git (source code manager).

      brew install git

* Install database. You may pick anything Rails support, but since
  Heroku uses PostgreSQL, we recommend to use the same software.

      brew install postgresql
      initdb /usr/local/var/postgres
      pg_ctl -D /usr/local/var/postgres start
      createuser --createdb YourProject

* Setup postgres with auto-starting after booted.

      cp `brew --prefix postgresql`/org.postgresql.postgres.plist ~/Library/LaunchAgents/
      launchctl load -w ~/Library/LaunchAgents/org.postgresql.postgres.plist

* or start up postgres manually:

      pg_ctl -D /usr/local/var/postgres start

* Install Ruby 1.9.2 (via Homebrew, but if you prefer RVM, it's fine).

      brew install ruby

### Ubuntu

* Install various tools

      sudo apt-get install gcc g++ make libssl-dev zlib1g-dev libreadline5-dev libyaml-dev libxml2-dev

* Install Git (source code manger).

      sudo apt-get install git

* Install database. You may pick anything Rails support, but since
  Heroku uses PostgreSQL, we recommend to use the same software.

      sudo apt-get install postgresql libpq-dev
      sudo /etc/init.d/postgresql restart
      sudo -u postgres createuser --createdb YourProject

  You might need to edit `pg_hba.conf` to make sure _YourProject_ has the
  access to your local database. For example, has the following line:

      local all YourProject trust

* Install Ruby 1.9.2

      bash < <( curl http://rvm.beginrescueend.com/releases/rvm-install-head )
      echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"' >> ~/.bash_profile
      source $HOME/.rvm/scripts/rvm
      rvm install 1.9.2
      rvm use 1.9.2

### Windows (not tested)

* Install Git <http://code.google.com/p/msysgit/downloads/list>
* Install Ruby 1.9.2 <http://rubyinstaller.org/downloads/>
* Install PostgreSQL <http://www.postgresql.org/download/>

## Software Installation and Configuration (2)

### General (OS-independent)

* Configure Git (~/.gitconfig)

      git config --global user.name  'Your Name'
      git config --global user.email 'your@email.com'

* Install gems (sudo or not is depending on the OS or your choice)

      echo 'gem: --no-ri --no-rdoc' >> ~/.gemrc
      gem install rails pg heroku

  Note: if pg failed to install, try this:

      env ARCHFLAGS='-arch x86_64' gem install pg

* Generate RSA keys and upload to Heroku

      ssh-keygen -t rsa -C 'your@email.com'
      heroku keys:add ~/.ssh/id_rsa.pub

## Creating an application on Heroku

* Rails 3 project

      rails new 'YourProject'
      cd 'YourProject'

* Git initialization

      git init
      git add .
      git commit -m 'first commit'

* Switch to PostgreSQL. Change `gem 'sqlite3'` to `gem 'pg'` and run:

      bundle check
      git add Gemfile Gemfile.lock
      git commit -m 'switch to postgresql'

* Heroku application

      heroku create 'YourProject'

* Pusing to Heroku

      git push heroku master:master

* Take a look at yourproject.heroku.com. If you have terminal browser lynx
  installed, you can run this:

      lynx yourproject.heroku.com

  Otherwise, just use your favorite browser to view it.

## Run it on your computer, too

* Edit `config/database.yml` with following:

      development:
        adapter: postgresql
        username: YourProject
        database: YourProject_development

      test:
        adapter: postgresql
        username: YourProject
        database: YourProject_test

* Setup local database

      rake db:create
      rake db:migrate
      rake db:schema:dump  # update schema.rb for reference
      rake db:test:prepare

* Run Ruby server (WEBrick)

      rails server

* or Run Thin server (need to update Gemfile with `gem 'thin'`)

      gem install thin
      rails server thin

## Building a Facebook Application

* <http://devcenter.heroku.com/articles/facebook>

## Using rest-graph

### Tutorial

* <https://github.com/cardinalblue/samplergthree>
