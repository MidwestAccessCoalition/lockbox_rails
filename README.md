# MAC Lockbox

The MAC lockbox is a system for tracking MAC cash at partners across the Midwest.
For a detailed list of app functionality, see
[docs/roadmap.md](https://github.com/MidwestAccessCoalition/lockbox_rails/blob/master/docs/roadmap.md)

## Local Dev Environment

### Requirements

Technical requirements for this project. See below for step-by-step first-time setup.

| Tool       | Version  |
| ---------- | -------- |
| Ruby       | v2.7.2   |
| Bundler    | v2.1.x   |
| Rails      | 6.1      |
| PostgreSQL | v11.x    |
| Node       | v14.15.x |
| Yarn       | v1.22.x  |

### Environment Setup

Clone the repo:

```sh
git clone git@github.com:MidwestAccessCoalition/lockbox_rails
```

Alternately, if you don't already have an SSH key setup with Github:
```sh
git clone https://github.com/MidwestAccessCoalition/lockbox_rails.git
```

This setup assumes you are using [Homebrew](https://brew.sh/) on a Mac. For other
environments, reach out to [@bintLopez](https://github.com/BintLopez) (Nicole).

#### Ruby

If you don't have a Ruby version manager, you'll want to install `rbenv`. If you
already have `rbenv` or `rvm` installed, skip this step.

To find out if you already have one of them installed, in a terminal run
```sh
which rbenv rvm
```

If you're using `zsh` and you get the following, install `rbenv`:
```sh
rbenv not found
rvm not found
```

If you're using `bash` and there's no output at all, that means you don't have
either version manager installed, and you should install `rbenv`.

**DO NOT INSTALL BOTH RVM AND RBENV ON THE SAME MACHINE OR YOU WILL HAVE A VERY BAD TIME!**

_Note: if you have `rvm` installed but would like to switch to `rbenv` (recommended), 
just run the following before installing `rbenv`:_
```sh
rvm implode
```

**Install `rbenv`** (see https://github.com/rbenv/rbenv for more info)
```sh
brew install rbenv
```

_Note: if you don't have Homebrew installed, or are using a PC or Linux machine and need
help at this point, talk to Nicole (@bintLopez) about getting your dev env setup._

Both `rbenv` and `rvm` will automatically try to use the version specified in a
local `.ruby-version` file if it exists. If the version specified in `.ruby-version`
is not installed, simply run:
```sh
rbenv install
```
Or for RVM:
```sh
rvm install
```

#### Rails

```sh
gem install bundler -v 2.1.1
bundle install # Make sure you're in the lockbox_rails root directory
```

#### Javascript
You will need Yarn `v1.22.x`, a Node version manager (if you don't already have one, `nvm` is receommended), and Node `v11.x`.

```sh
brew install nvm yarn
nvm install && nvm use # This will install and use the version in the project's `.nvmrc` file
```

#### PostgreSQL & DB setup

See if you have PostgreSQL:

```sh
psql --version
```

If it's not installed, or the version isn't >=11.0, install and run it using Homebrew:

```sh
brew install postgresql@11
brew services stop postgresql
brew services start postgresql@11
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

#### Redis

You'll need `redis` in order for `sidekiq` to work.

```sh
brew install redis
brew services start redis
```

#### Ports in use

* 3000: Rails server
* 3035: Webpack server
* 6379: Redis server
* 1080: Mailcatcher (if applicable)

## Local Development

```sh
yarn dev
```
The above command will do the following:
* run the `predev` script in `package.json` which calls the bin script [`dev_setup`](./bin/dev_setup).
  * the setup script will `bundle install` and `yarn install`
* run the `dev:assets` script in `package.json` which will start `webpack` in watch mode (with a few other flags set for development purposes)
* run the `dev:rails` script in `package.json` which will start the Rails server on port `3000`.

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

### Login

#### As a fund admin
Username: `cats@test.com`  
Password: `password1234`

#### As a lockbox partner
Username: `fluffy@catsclinic.com`  
Password: `heytherefancypants4321`

### Working on MFA/Authy
If you need to work on part of the MFA (Authy) workflow, you will need to add two
env vars to your `config/local_env.yml` file:
```yml
AUTHY_MFA_ENABLED: 1
AUTHY_API_KEY: You'll have to get this token from Nicole
```

If you don't have a `config/local_env.yml` file, see the `config/local_env.sample.yml`
file for instructions on creating one. `config/local_env.yml` is not tracked by `git`, so it's
safe to put secrets, API keys, and other credentials in it.

You will have to ask Nicole (@bintLopez) for the API token (but note that this cannot
be sent via email, text, or Slack for security reasons, so to receive it you will need some
sort of secure method for sending messages e.g. LastPass, Signal, etc.).

### Working on error pages
By default, in development most errors result in a `better_errors` page response
which provides a more advanced interface for troubleshooting (e.g. a stack trace, 
global and local variables, a console scoped to the point that the error occurred).

If you need to work on an error page, you will have to temporarily disable this
functionality. To do so, open `config/environments/development.rb` and find the 
following line
```rb
  config.consider_all_requests_local = true
```
and flip the `true` to `false`. This change won't take effect until the Rails server
is restarted. 

Be sure to revert this change before merging your PR.

## Security Scans

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

### Brakeman

We use Brakeman to check for security vulnerabilities in our project's codebase.
Brakeman can also be run locally:

```sh
yarn scan:brakeman
```

For more control over the process, you can also run `brakeman` manually from the 
terminal to get more detailed output or to ignore for lower-level warnings, in which case 
[Brakeman's usage options](https://github.com/presidentbeef/brakeman/blob/master/OPTIONS.md)
may be useful.

### Bundler Audit

We use `bundler-audit` to check for security vulnerabilities in our project's gem dependencies.
This check runs in CircleCI and any output from the scan is saved in the Artifacts
tab under `security-scans/bundler-audit.log`. `bundler-audit` can also be run locally:

```sh
yarn scan:bundler-audit
```

Any non-critical vulnerabilities that cannot be fixed immediately can be temporarily
ignored by adding the CVE ID to the root-level `.bundler-audit.ignore` file.

### `lockfile-check`

This is a custom script that ensures `yarn` and `bundle` have both been run
successfully and that `npm i` has not also been run. To run locally:

```sh
yarn scan:lockfiles
```

### Snyk

Snyk is simmilar to `bundler-audit` except that it checks our project's Javascript
package dependencies for vulnerabilities. To run locally:

```sh
yarn scan:snyk
```
