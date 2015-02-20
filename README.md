# Deploy Repo for Ruby Mad Science

Want to build a custom VM around your Rails app? Want to use all the right
open-source tools like Chef, Capistrano, Librarian, NGinX and RVM? Want to
test it locally and then push exactly the same configuration to real hosting?
You've found the right place.

Here's how you deploy a test app to Vagrant immediately. This will install the
correct versions of Vagrant and Virtualbox on your dev machine and all the
necessary plugins and software.

    > gem install madscience
    > rvmsudo madscience setup  # or sudo madscience setup if no rvm
    > git clone https://github.com/noahgibbs/madscience_deploy_repo
    > cd madscience_deploy_repo
    > vagrant up --provision    # create your local server
    > vagrant push development  # push the app(s) to it

This is the open, MIT-licensed source code behind the (commercial) product
"Rails Deploy In An Hour" (http://rails-deploy-in-an-hour.com).

## To Test and Create a Server

    # Edit the file
    vi nodes/all_nodes.json.erb
    # Create the server locally
    vagrant up --provision --provider=virtualbox
    # Push apps to the server
    vagrant push development

    # ONLY when you're ready to destroy your VM
    vagrant destroy --force

After testing that, do it for real:

    # Add your credentials to the Digital Ocean file
    vi ~/.deploy_credentials/digital_ocean.json
    vagrant up --provision --provider=digital_ocean
    vagrant push digital_ocean

    # ONLY when ready to destroy your (real, on Digital Ocean) VM
    vagrant destroy --force

Providers for AWS and Linode coming soon, and they'll work exactly the same
way. You'll just replace "digital_ocean" with "aws" or "linode" above.

## Why Is This Different?

You can find lots of deploy tools and free configurations for Rails servers
online.

How is this different?

* Full-stack - this actually uses a lot of different tools; see below
* Standard tools - write normal cookbooks, tasks, etc.
* Supported - you can buy videos and docs at http://rails-deploy-in-an-hour.com
* No Hosting Fee - no extra hosting fee beyond normal AWS, Digital Ocean, etc.*
* Small top level - use a single JSON file and Cheffile for most config
* Version-locked - all tools locked to specific versions so no bit-rot
* Opinionated - beat combinatorial explosion by saying "use this"

You can absolutely find source code that does everything this repository does
if you're willing to combine several others. In fact, if you combine liberally
you can easily find code to do far, far more than this does.

However, it's very hard to find a simple, turn-key solution that doesn't
require ongoing hosting cost (e.g. Heroku.)

It's also easy to get yourself in trouble, security-wise. RubyMadScience comes
with decent security out of the box and makes it easy to improve it.

## What Tools?

Deployment tools as of this writing include:

Vagrant
  * Chef-Omnibus Plugin
  * Librarian-Chef Plugin
  * Digital Ocean, AWS and Linode plugins
VirtualBox
Chef
  * Librarian-Chef, plus many third-party cookbooks
Capistrano plus standard plugins

On-VM tools as of this writing include:

Ruby, RVM, Bundler
NGinX
Runit (process control and restart)
MySQL
Optional PostgreSQL, Redis, MemCacheD and other support

## Why Not Docker?

Some day Docker will absolutely be the right tool for this. Right now, it
solves only a few of these problems -- it could replace Chef, kind of, but not
really Capistrano. It could be used by Vagrant, but doesn't replace what
Vagrant does here...

Eventually, Docker will do all of this when combined with other to-be-written
tools. I look forward to it.
