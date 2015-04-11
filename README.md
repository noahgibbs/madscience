# Deploy Repo for Ruby Mad Science

Want to build a custom VM around your Rails app? Want to use all the right
open-source tools like Chef, Capistrano, Librarian, NGinX and RVM? Want to
test it locally and then push exactly the same configuration to real hosting?
You've found the right place.

Here's how you deploy a test app to Vagrant immediately. This will install the
correct versions of Vagrant and Virtualbox on your dev machine and all the
necessary plugins and software.

    > gem install madscience
    > rvmsudo madscience construct  # or sudo madscience construct if no rvm

This will install dev tools locally, clone a repo into the "madscience"
directory under your current, and then deploy a server with a Rails test app
to your VM. It's often a one-line change to make it deploy *your* Rails or
Rack app instead.

This is the open, MIT-licensed source code behind the (commercial) product
"Rails Deploy In An Hour" (http://rails-deploy-in-an-hour.com).

## What Do You Need?

* Ruby
* RubyGems

MadScience is compatible with your version manager of choice, but doesn't
require one on the host machine. You may need to use a different command line
for sudo, as you normally would when running Ruby executables with that
version manager -- for instance, rvm uses "rvmsudo".

It uses RVM on the Guest VM, and doesn't allow other version managers on the
guest.

## To Test and Create a Server

    # Edit the file, change from rails-devise-pundit to your app
    vi nodes/app_server.json.erb
    # Create the server locally and push apps to it
    vagrant up --provision --provider=virtualbox

    # ONLY when you're ready to destroy your VM
    vagrant destroy --force

After testing that, do it for real:

    # Add your credentials to the Digital Ocean file
    vi ~/.deploy_credentials/digital_ocean.json
    vagrant up --provision --provider=digital_ocean

    # ONLY when ready to destroy your (real, on Digital Ocean) VM
    vagrant destroy --force

AWS and Linode work exactly the same way. You'll just replace
"digital_ocean" with "aws" or "linode" above. You'll also need to edit
their JSON files to add credentials, choose instance types and
otherwise do provider-specific configuration. See the JSON files
for documentation links for each provider.

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
MySQL (or optional PostgreSQL)
Optional-but-tested Redis, MemCacheD and other support

This isn't everything, of course.

## Which Tools Aren't Happening?

To pick some popular ones:

* Ansible, SaltStack
* rbenv, chruby (on the guest VM)

These are tools that require extensive changes to the guest VM.  Since
it's very difficult to keep a big constellation of tools tested, that messes
up a lot of the point of this code. "Opinionated" is important.

We do allow a few specific variations and a lot of additions:

* Postgres rather than MySQL
* Adding simple cookbooks, including MemCacheD and Redis
* Storage like MongoDB that is added to MySQL/Postgres rather than replacing

Additions are, in general, much more okay than substitutions. It's
substitutions where you're most likely to see conflicts.

You can also use services that are handled externally and/or by the
app, such as:

* Metrics and monitoring like PingDom or Dead Man's Snitch
* Email via MailGun, SendGrid, Mandrill, etc.
* External logging via Loglly, AppSumo, etc.

You can also configure *more* nodes. Nothing stops you from
configuring, say, a multi-node Cassandra cluster via Chef because it
doesn't interact much with the Rails application server. Instead,
you'll configure Cassandra as normal via Chef on different hosts than
the Rails server. You can configure those nodes via the top-level JSON
files or completely separately.

One strength of MadScience is that it doesn't get in your way when you
migrate off it. You can start with Chef simply until you need more
power. Then you just use Chef like the big companies do by "scraping
off" the top layer of JSON.

## Why Not Docker?

Some day Docker will absolutely be the right tool for this. Right now, it
solves only a few of these problems -- it could replace Chef, kind of, but not
really Capistrano. It could be used by Vagrant, but doesn't replace what
Vagrant does here...

Eventually, Docker will do all of this when combined with other to-be-written
tools. I look forward to it.
