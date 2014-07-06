name             'rails_server'
maintainer       'YOUR_COMPANY_NAME'
maintainer_email 'YOUR_EMAIL'
license          'All rights reserved'
description      'Installs/Configures rails_server'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

# This cookbook is normally 100% local - it assumes basic config like
# creating users and groups has already been taken care of.
#
# It's really the same cookbook as basic_config, just separated
# into two so they can run both before and after stock cookbooks
# like MySQL, NGinX, etc without specifying all the JSON parameters
# inline in Ruby.
