# Deploy Repo for Ruby Mad Science

This code is currently under a proprietary license, please do not
redistribute.  Except, obviously, for those off-the-shelf open-source
components that are downloaded for use, such as existing Chef cookbooks. They
should not be checked into the Git repository, and exist under their normal
licenses.

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

Providers for AWS and Linode coming soon.
