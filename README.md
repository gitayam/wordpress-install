# wordpress-install
generate mariadb, apache or nginx server, and configure a basic wordpress website or multiple wordpress websites on a server


# Install Configure and Use
## Install 
Make sure `git` is installed and use the following command:
`git clone https://github.com/gitayam/wordpress-install.git && ./wordpress-install/wp-install.sh`

## Configure
You may update the following within the script
    ssh_username="base_username_here"
    email_domain="base_email_domain_here"
    script_path="/path/${script_name}"
    #link to divi theme used to download Divi from Elegant Themes
    divi_URL=""
    #define ip addresses
    ip=(
        "Label_server1"::"99.99.99.99"
        "Label_server2"::"88.88.88.88"
    )
These variables and makeshift arrays are used to manage multiple servers
## Use
Receive prompts for all attributes 
`sudo ./wp-install`

Identify Domain
`sudo ./wp-install website.com`

Fix Permissions for Wordpress
`sudo ./wp-install website.com -p` or `sudo ./wp-install website.com --permissions`

Update servers and all wordpress plugins and themes for all domains
`sudo ./wp-install website.com -u` or `sudo ./wp-install website.com --update`