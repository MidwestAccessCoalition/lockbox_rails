# MAC Lockbox

The MAC lockbox is a system for tracking MAC cash at partners across the Midwest. For a detailed list of app functionality, see [docs/roadmap.md](https://github.com/MidwestAccessCoalition/lockbox_rails/blob/master/docs/roadmap.md)

## Local Dev Environment

### Requirements

Technical requirements for this project. See below for step-by-step first-time setup.

| Tool       | Version  |
| ---------- | -------- |
| Ruby       | v2.6.5   |
| Bundler    | v2.1.1   |
| Rails      | 6.0.2.1  |
| PostgreSQL | v11.3    |
| Node       | v10.15.3 |

### Environment Setup

Clone the repo:

```sh
git clone git@github.com:MidwestAccessCoalition/lockbox_rails
# Or if you don't have an SSH key setup with Github:
# git clone https://github.com/MidwestAccessCoalition/lockbox_rails.git
```

This setup assumes you are using [Homebrew](https://brew.sh/) on a Mac. For other environments, reach out to [@bintLopez](https://github.com/BintLopez) (Nicole).

#### Ruby

If you don't have a Ruby version manager, you'll want to install `rbenv`. If you already have `rbenv` or `rvm` installed, skip this step.
**DO NOT INSTALL BOTH RVM AND RBENV ON THE SAME MACHINE**.

To find out if they're already installed, in a terminal run `which rbenv rvm`. If they're both "not found" or there's no output at all, install `rbenv`.

```sh
brew install rbenv # https://github.com/rbenv/rbenv for more info
```

_If you don't have Homebrew installed, or are using a PC or Linux machine, talk to Nicole (@bintLopez) about getting your dev env setup._

To get the correct Ruby version, you can run the following from the project root to get the ruby version specified in the `.ruby-version` file.

```sh
ruby_version=$(cat .ruby-version)
ruby_version=${ruby_version#ruby-} # Remove "ruby-" if prefixed to version number
# Install Ruby via rbenv
rbenv install $ruby_version
# OR if you're using RVM
# rvm install $ruby_version
```

#### Rails

```sh
gem install bundler -v 2.1.1
bundle install # Make sure you're in the lockbox-rails root directory
```

#### PostgreSQL & DB setup

See if you have PostgreSQL:

```sh
which psql
```

If not, install and run it using Homebrew:

```sh
brew install postgresql
brew services start postgresql
```

Setup DB:

```sh
# From project root:
bundle exec rake db:setup # runs `rake db:create db:schema:load db:seed
```

_If you have issues at this step, see this [PostgreSQL Setup](https://github.com/MidwestAccessCoalition/jane_point_oh/blob/master/docs/db_setup.md) doc. But while going through it, wherever you see the string `admin_app`, replace it with `lockbox_rails`. (This includes instances like `admin_app_development` => `lockbox_rails_development`.)_

#### Mailcatcher

```sh
# This is done outside of the Gemfile because it is an
# external tool used outside of the app environment.
gem install mailcatcher
```

#### Webpack

```sh
bundle exec rails webpacker:install
```

### Local Development

```sh
yarn dev
```
The above command will do the following:
* run the `predev` script in `package.json` which calls the bin script [`dev_setup`](./bin/dev_setup).
  * the setup script will `bundle install` and `yarn install`
* run the `dev:assets` script in `package.json` which will start `webpack` in watch mode (with a few other flags set for development purposes)
* run the `dev:rails` script in `package.json` which will start the Rails server on port 3000.

If you just need individual parts of the above, here is the manual startup process that you can tweak as needed:
```sh
# Start the dev Webpack server
yarn # if necessary
./bin/webpack --watch --colors --progress --display-error-details # or `yarn run dev:assets`
# Open a new terminal pane/tab/window
bundle install # if necessary
bundle exec rails s # or `yarn run dev:rails`
# If testing email sending functionality, start mailcatcher
mailcatcher # This will run on localhost:1080
```

#### Redis

You'll need redis for sidekiq to work

```sh
brew install redis
brew services start redis
```

#### Ports in use

* 3000: Rails server
* 3035: Webpack server
* 6379: Redis server
* 1080: Mailcatcher (if applicable)

### Login

#### Fund Admin

Username: `cats@test.com`
Password: `password1234`

#### Lockbox Partner

Username: `fluffy@catsclinic.com`
Password: `heytherefancypants4321`

### Security Scans

We use several automated scans to check for known vulnerabilities both in our code
and our dependencies. To run all of the scans at one time:

```sh
yarn scan:all
```

There are also scripts that can be run for each individual scan or grouped by language
(see `package.json > scripts` for more specifics). Every scan is configured to automatically
print its output to the terminal as well as a log file in the `tmp/security-scans`
directory. These scans are integrated as part of the CI build-and-test process.

Note that some of the scans can find issues that are not severe enough to be considered
`errors` but should still be attended to. Brakeman especially highlights low, moderate,
and high level `warnings` that may need to be addressed to ensure the highest level
of AppSec confidence.

#### Brakeman

We use Brakeman to check for security vulnerabilities in our project's codebase.
Brakeman can also be run locally:

```sh
yarn scan:brakeman
```

For more control over the process, you can also run `brakeman` manually from the 
terminal to get more detailed output or to ignore for lower-level warnings, in which case 
[Brakeman's usage options](https://github.com/presidentbeef/brakeman/blob/master/OPTIONS.md)
may be useful.

#### Bundler Audit

We use `bundler-audit` to check for security vulnerabilities in our project's gem dependencies.
This check runs in CircleCI and any output from the scan is saved in the Artifacts
tab under `security-scans/bundler-audit.log`. `bundler-audit` can also be run locally:

```sh
yarn scan:bundler-audit
```

Any non-critical vulnerabilities that cannot be fixed immediately can be temporarily
ignored by adding the CVE ID to the root-level `.bundler-audit.ignore` file.

#### `lockfile-check`

This is a custom script that ensures `yarn` and `bundle` have both been run
successfully and that `npm i` has not also been run. To run locally:

```sh
yarn scan:lockfiles
```

#### Snyk

Snyk is simmilar to `bundler-audit` except that it checks our project's Javascript
package dependencies for vulnerabilities. To run locally:

```sh
yarn scan:snyk
```
