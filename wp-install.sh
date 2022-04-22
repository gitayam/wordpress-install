#!/bin/bash

dval=0
#debug function allows for debugging when echo is uncommented 
debug_function(){
    #toggle comment to display or not
    #echo "$dval $*"
    ((dval++))
}

##define defaults
line="++---------------------------++----------------------------------++"
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
OS=$(uname)


#debug-option
debug_function first

#cycle through all the defined server ips for scp , listing, and command execution
for i in "${ip[@]}";do
  #define key as the section before the colon and the value as the section after the colon
  KEY="${i%%::*}";VALUE="${i##*::}"
  #add each ip to the allDomain variable
  all_domains="$all_domains $VALUE"
done
#debug-option
debug_function end of definitions
print_ssh_function(){
    debug_function "$FUNCNAME"
    #cycle through all the defined ip
    printf "\n"
    for i in "${ip[@]}";do
    #define key as the section before the colon and the value as the section after the colon
    KEY="${i%%::*}";VALUE="${i##*::}"
    #add each ip to the allDomain variable
    printf "%s---\nssh %s@%s\n\n" "$KEY" "$ssh_username" "$VALUE"
    done
}

if [ "$OS" == "Darwin" ];then
    #prevent from running on mac if help menu isn't initiated
    printf "\n%s\nPersonal Computer Detected, server check will not run\nUse -h to see all options\n%s\n" "$line" "$line"
else
    #check if apache or ngnix are already installed on the server 
    nginx_check="$(dpkg --get-selections | grep nginx)" &> /dev/null
    apache_check="$(dpkg --get-selections | grep apache)" &> /dev/null
    server_check_function(){
    debug_function "$FUNCNAME"
    if [[ -z "$nginx_check" && -z "$apache_check" ]];then
        server="none"
    elif [ -z "$nginx_check" ];then
        server="apache"
    elif [ -z "$apache_check" ];then
        server="nginx"
    else
        #assume both servers are installed
        server="both"
    fi
    }
    server_check_function
fi
#debug-option
debug_function after server check
##############Alias creation################################
create_alias_function(){
    debug_function "$FUNCNAME"
    printf '
    alias sddd="sudo"
    '| sudo tee -a /etc/bash.bashrc
    printf '
    upup(){
        sudo apt update --fix-missing
        sudo apt upgrade -y
        fix_WP_permissions_function()
    }
    fix_WP_permissions_function(){
        sudo chown -R www-data:www-data /var/www/*
        sddd adduser %s www-data
        ###fix wordpress permissions
        # reset to safe defaults
        # allow wordpress to manage wp-content
        echo -e "Starting Wordpress Permission Config for : Directories"
        sddd find /var/www/* -type d -exec chmod 770 {} \;
            echo -e "Starting Wordpress Permission Config for : Files"
        sddd find /var/www/* -type f -exec chmod 660 {} \;
        sddd chmod 777 /var/www/*/wp-content
    }
    ' | sudo tee -a /etc/bash.bashrc
}
#debug-option
debug_function aliases creation
#gpg fix https://d.sb/2016/11/gpg-inappropriate-ioctl-for-device-errors
grep "use-agent" "$HOME/.gnupg/gpg.conf" &> /dev/null || echo "use-agentd" >> "$HOME/.gnupg/gpg.conf"
grep "pinentry-mode loopback" "$HOME/.gnupg/gpg.conf" &> /dev/null || echo "pinentry-mode loopback" >> "$HOME/.gnupg/gpg.conf"
grep "allow-loopback-pinentry" "$HOME/.gnupg/gpg-agent.conf" &> /dev/null || echo "allow-loopback-pinentry" >> "$HOME/.gnupg/gpg-agent.conf"
#debug-option
debug_function gpg fix
##############User Input################################

user_input_simple_function(){
    debug_function "$FUNCNAME"
    #The $_SERVER super global is an array typically populated by a web server with information such as 
        #headers, paths, and script locations. PHP CLI doesn’t populate this variable, 
        #nor does WP-CLI, because many of the variable details are meaningless at the command line.

    if [ -z ${url+x} ];then
        echo  "Enter url: [$url]: "
        read -r url
    fi
    domain="${url%.*}"

    #----------Check if nginx is installed-------
    # if nginx is not found then assume Apache2 Server
    ######Use to determine which file path to use
    if [ -z ${path+x} ];then
    
        if  [[ "$server" == "none" || "$server" == "both" ]] ;then
        ###if neither nginx or apache are detected then prompt user to select which one
            echo "server not detected"
            while [ -z ${which_server+x} ];do
                echo "
                ▶1. Use nginx Server
                ▶2. Use Apache2 Server (1 / 2):" 
                read -r which_server
            done 
                if [ "$which_server" == "1" ];then
                    echo "nginx server selected"
                    #if path is not defined by the user above, then path is equal to default
                    path="/var/www/${domain}"
                    elif [ "$which_server" == "2" ];then
                    echo "apache server selected"
                    #if path is not defined by the user above, then path is equal to default
                    path="/var/www/${domain}"
                    fi
        else
        ###if 1 server type is detected, then use the server already installed
            if  [ "$server" == "apache" ];then
                echo "apache  server already installed"
                path="/var/www/${domain}"
            elif [ "$server" == "nginx" ];then
                echo "nginx server already installed"
                path="/var/www/${domain}"
            else
                echo "no server detected"
                install_maria_db_function
            fi
        fi
    
    fi
    #simple input is used for certain functions which don't require the full variable list
    
    db_name="${domain//-/}db"
    admin_email="${domain}@${email_domain}"
    admin_user="${domain}"
    base_pass=$(diceware -n 5)
    #admin_pass=$(printf $base_pass|sha256sum|base64|head -c 22)
    admin_pass=$(diceware -n 5)
    content_path="${path}/wp-content"
    divi_path="${content_path}/themes/Divi.zip"
    #creates the file descriptor which is to be used instead of a (regular) file path, if script crashes file is deleted
    #debug-option
    debug_function simpleinput
}

user_creation_function(){
    debug_function "$FUNCNAME"
    user_input_simple_function
    #create user on server based on domain name
    sudo mkdir -p "$path"
    sudo useradd -d "$path" "$domain"
    #make sure new user is using /bin/bash instead of /bin/sh
    #sudo chsh -s /bin/bash $domain
    #add password for user, openssl will create the password has
    #sudo usermod --password $(openssl passwd -1 "$base_pass") $domain
    #allow current non user to own path
    sudo chmod -R 755 "$path"
    #debug-option
    debug_function user creation
}

user_input_full_function(){
    debug_function "$FUNCNAME"
    user_input_simple_function
    if [ -z ${sql_pass+x} ];then
        echo "Enter sql password:[may be found in instance marketplace if using gcp]:"
        read -r sql_passPlain
        sql_pass=$(printf "%s" "$sql_passPlain"|sha256sum|base64|head -c 22)
    fi
    #prompt user for server and url information
    if [ -z ${site_title+x} ];then
        echo "$domain Title: "
        read -r site_title
    fi
    if [ -z ${site_description+x} ];then
        echo "$domain Description (optional): "
        read -r site_description
    fi
    #remove new line from input
    #site_description=${site_description//$'\n'/}
    if [ -z "$site_description" ];then
        site_description="My little Site"
    fi
    if [ -z ${alt_user+x} ];then
        echo "Additional User for $domain (optional): "
        read -r alt_user
    fi
    if [ -z "$alt_user" ];then
        alt_user_set=false
        #if alt_user is still not defined then 
        alt_user="real${domain}"
    else
        alt_user_set=true
    fi
    #alt_userPass=$(printf "$((date)) $(($RANDOM%999999))"|sha256sum|base64|head -c 18)
    alt_userPass=$(diceware -n 5)
    alt_email="${alt_user}@${email_domain}"
    #debug-option
    debug_function   user input full
}
check_simple_input_function(){
    debug_function "$FUNCNAME"
    if [ -z ${path+x} ];then
        user_input_simple_function
    fi
}
#debug-option
debug_function user input defined

fix_WP_permissions_function(){
    debug_function "$FUNCNAME"
    ##simple input only requires url and server type to function
    check_simple_input_function
    sudo chown -R www-data:www-data "$path"
    sudo adduser $ssh_username www-data
    #add domain user to www-data group
    sudo usermod -aG www-data "$domain"
    sudo usermod -aG www-data "$USER"
    sudo usermod -aG www-data www-data
    ###fix wordpress permissions
    # reset to safe defaults
    # allow wordpress to manage wp-content
    echo -e "Starting Wordpress Permission Config for : Directories"
    sudo find "$path" -type d -exec chmod 770 {} \;
    echo -e "Starting Wordpress Permission Config for : Files"
    sudo find "$path" -type f -exec chmod 660 {} \;
    sudo chmod 777 "$path"/wp-content
    #debug-option
    debug_function fix permissions
}
##############Definitions################################
ssh_command_function(){
    debug_function "$FUNCNAME"
    #cycle through all the defined ip and send command
    for i in "${ip[@]}";do
    #define key as the section before the colon and the value as the section after the colon
    KEY="${i%%::*}";VALUE="${i##*::}"
    #add each ip to the allDomain variable
    ssh $ssh_username@"$VALUE" "\"${@:2}\""
    done
    #debug-option
    debug_function ssh command
}

##############Functions################################
scp_send_function(){
    debug_function "$FUNCNAME"
    #scp files can manually be set here
    if [ -z ${2+x} ];then
    #if arguments are not entered with -s then the default script will be sent
    scp_send_function_files="$script_path"
    else
    scp_send_function_files="${@:2}"
    fi   
    #Send this current Script to all other servers to maintain version
    for i in "${ip[@]}";do
    #define key as the section before the colon and the value as the section after the colon
    KEY="${i%%::*}";VALUE="${i##*::}" ##is not needed because this was defined above.
    #add each ip to the allDomain variable
    printf "\nstarting transfer for %s  " "$KEY"
    printf "SSH Information: %s---\nssh %s@%s\n\n" "$KEY" "$ssh_username" "$VALUE"
        #default files to send via scp to ips above
        if [ -z ${2+x} ];then
        scp $scp_send_function_files $ssh_username@"$VALUE":~/
        #using ~ instead of $HOME to prevent local home from being used remotley 
        else
            #loop through the arguments to send all files via scp for every one user
            #####still working
            for scp_send_function_file in "${@:2}"; do
                scp "$scp_send_function_file" $ssh_username@"$VALUE":"$HOME"/
            done
            fi
    done
    
    printf "\nSSH Information to copy and paste:\n"
    print_ssh_function
    printf "\n\n"
    #debug-option
    debug_function scp_send_function
}
cloudflare_cert(){
    debug_function "$FUNCNAME"
    #loop while pem and key are empty until user inputs it
    
    echo "Paste Entire origin-server PEM from https://dash.cloudflare.com: "
    sudo nano /etc/cloudflare/$url.pem
    echo "Paste Entire origin-server KEY from https://dash.cloudflare.com: "
    sudo nano /etc/cloudflare/"$url".key
    #restrict permissions for accessing private key
    sudo chmod 600 /etc/cloudflare/"$url".key
}
make_htaccess_function(){
    debug_function "$FUNCNAME"
    check_simple_input_function
    # allow wordpress to manage .htaccess
    htaccess="${path}/.htaccess"

    sudo touch "$htaccess"
    sudo chmod 664 "$htaccess"
    echo -e "
        # BEGIN WordPress
        RewriteEngine On
        RewriteBase /
        RewriteRule ^index\.php$ - [L]
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule . /index.php [L]

        # END WordPress
        # Setup browser caching
        <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresByType image/jpg "access 1 year"
        ExpiresByType image/jpeg "access 1 year"
        ExpiresByType image/gif "access 1 year"
        ExpiresByType image/png "access 1 year"
        ExpiresByType text/css "access 1 month"
        ExpiresByType application/pdf "access 1 month"
        ExpiresByType text/x-javascript "access 1 month"
        ExpiresByType application/x-shockwave-flash "access 1 month"
        ExpiresByType image/x-icon "access 1 year"
        ExpiresDefault "access 2 days"
        </IfModule>
        "| sudo tee -a "$htaccess"
}


update_domain_function(){
    debug_function "$FUNCNAME"
    ##simple input only requires url and server type to function
    check_simple_input_function
    #update URL and Domain on Wordpress
    if [ -z ${url+x} ];then
        echo "Enter url: [$url]: "
        read -r url
    fi
    #add domain URL to wp-config.php file
    #This gets replaced after SSL is installed
    isUrl=$(sudo cat "${path}/wp-config.php"|grep "https://${url} ")

    if [ -z "$isUrl" ];then
        echo -e "domain not found in wp-config file"
        #sudo chmod 777 ${path}/wp-config.php
        #echo -e "define( 'WP_SITEURL', "\'https://${url}\'" );" |sudo tee -a ${path}/wp-config.php
        #echo -e "define( 'WP_HOME', "\'https://${url}\'" );" |sudo tee -a ${path}/wp-config.php
       # sudo chmod 644 ${path}/wp-config.php
    fi

    if [ -z ${ipp+x} ];then
        echo -e "temp"
        #read -p 'Enter ip: [xx.xxx.xx.xxx]:(optional) ' ipp
    fi
        echo -e "temp"
    #sudo wp --allow-root --path=$path search-replace "http://${url}" "https://${url}" 
    #sudo wp --allow-root --path=$path search-replace "$ipp" "https://${url}" 
    #debug-option
    debug_function update domain
}

update_system_function(){
    debug_function "$FUNCNAME"
    ##update and upgrade
    sudo apt update -y && sudo apt --fix-missing
    sudo apt autoremove
    sudo apt upgrade -y
    #update plugins and themes
    for d in /var/www/*;do
        wp --path="$d" plugin update --all
        wp --path="$d" theme update --all
    done
    #debug-option
    debug_function update system
}

install_certs_function(){
    debug_function "$FUNCNAME"
    source /etc/apache2/envvars
    #set sql_password as it is not needed for this command
    ##simple input only requires url and server type to function
    check_simple_input_function
    sudo chmod -R 755 /var/www/
    #make sure url is defined
    if [ -z ${url+x} ];then
        echo "full url: [$url]:"
        read -r url
    fi
    #make sure email is identified
    if [ -z ${admin_email+x} ];then
        echo "Admin Email: [admin@$url]:"
        read -r admin_email
    fi
    #sudo wp --allow-root --path=$path config set "FORCE_SSL_ADMIN" "true"
    apache_certs_function(){
    debug_function "$FUNCNAME"
        #apache server configuration
        echo -e "processing...."
        echo -e "installing the required certbot for apache"
        sudo apt-get install python3-certbot-apache -y &> /dev/null
        sudo certbot --agree-tos --apache -m "$admin_email" -d "$url" -d www."$url"
        #replace domain.conf
        temp_add_function(){
            debug_function "$FUNCNAME"
            echo -e "<VirtualHost *:443>
            ServerName $url
            ServerAlias www.$url
            ServerAdmin $domain@localhost
            DocumentRoot $path
            ErrorLog ${APACHE_LOG_DIR}/error.log
            CustomLog ${APACHE_LOG_DIR}/access.log combined
            </VirtualHost>" 
        }
        #temp_add_function >>/etc/apache2/sites-available/${domain}.conf
        #add virtual host to global apache2 config
        #temp_add_function >>/etc/apache2/apache2.conf
        sudo apache2ctl configtest
        sudo systemctl reload apache2
    }
        nginx_certs_function(){
            debug_function "$FUNCNAME"
            #nginx server configuration
            #guide https://www.nginx.com/blog/using-free-ssltls-certificates-from-lets-encrypt-with-nginx/
            echo "processing...."
            echo "installing the required certbot for nginx"
            sudo apt-get python-certbot-nginx -y 
            sudo certbot --agree-tos --nginx -m "$admin_email" -n -d "$url" -d www."$url" 
            sudo nginx -t && sudo nginx -s reload
        #update domain wp url using function
        #update_domain_function
        }
    #install CertBot
    #make sure certbot is removed classic Certbot is installed
    echo "processing.."
    echo "installing certbot"
    sudo apt install certbot -y &> /dev/null
    #Certbot edit your Apache configuration automatically to serve it
        if [ "$server" == "none" ];then
            echo "no server detected"
        elif [ "$server" == "apache" ];then
            #assume apache server
            echo "apache server detected"
            apache_certs_function
        else
            echo "nginx server detected"
            nginx_certs_function
        fi
}



WP_update_function(){
    debug_function "$FUNCNAME"
    ##simple input only requires url and server type to function
    check_simple_input_function
    echo "starting Wordpress Updates..."
    sudo wp --allow-root --path="$path" plugin update --all
    sudo wp --allow-root --path="$path" theme update --all
    echo "checking for Wordpress Core Update..."
    sudo wp --allow-root --path="$path" core update
}

schedule_updates_function(){
    debug_function "$FUNCNAME"
    #at 0250 every 3day of week (wednesday) run apt update -y
    (crontab -l 2>/dev/null; echo -e "50 02 * * 3 root /usr/bin/apt update -y") | sudo crontab -
    #at 0300 every wednesday run apt upgrade -y
    (crontab -l 2>/dev/null; echo -e "00 03 * * 3 root /usr/bin/apt update -y") | sudo crontab -
}

install_plugins_function(){
    debug_function "$FUNCNAME"
    ####Install Plugins###
    ##simple input only requires url and server type to function
    check_simple_input_function
    #iterate through arguments in to the function
    for p in "honeypot google-site-kit miniorange-2-factor-authentication prevent-direct-access sucuri-scanner really-simple-ssl";do 
        sudo wp --allow-root --path="$path" plugin install "$p" --activate
    done
}

install_divi_function(){
    debug_function "$FUNCNAME"
    ##simple input only requires url and server type to function
    check_simple_input_function
    ##install divi theme
    ##download zip file from google drive

    #main_domain is any domain other than the current domain or html default domain on the server
    main_domain=$(ls /var/www/ |grep -v "$domain"|grep -v "html"|head -n 1)
    if [ -z "$main_domain" ];then
    echo "No other domains located"
    sudo "$HOME"/gdown.pl/gdown.pl "$divi_URL" "$divi_path"
    #activate divi theme
    sudo wp --allow-root --path="$path" theme install "$divi_path" --activate
    else
        cpPath="/var/www/${main_domain}/wp-content/themes/"
        sudo cp -R "$cpPath"/Divi "$content_path"/themes/
    fi

    #########create Child Theme
    #create divi-child theme
    sudo mkdir -p "$cpPath"/divi-child
    #make style sheet
    echo "/*
        Theme Name:     Divi Child
        Theme URI:      https://www.elegantthemes.com/gallery/divi/
        Description:    Divi Child Theme
        Author:         Elegant Themes
        Author URI:     https://www.elegantthemes.com
        Template:       Divi
        Version:        1.0.0
        */
        /* =Theme customization starts here
        ------------------------------------------------------- */
        /* Enter Your Custom CSS Here */
        .header-container, .body-container, .footer-container, .et-main-area, .entry-content, #main-content, .et_pb_text_inner, .et_pb_section,  .et_pb_section_1, .et_section_regular, .left-area
        {
            max-width: 1200px;
            margin: auto ; 
            font-size: 20px;

        }
        /*header*/
        #top-header{
            display:none;
        }

        /*forum*/
        .bbp-forum-title
        {
            font-size:25px;
            text-align: center;
        }
        .bbp-forum-content{
            font-size:20px;
            width:600px
        }
        .bbp-forum-freshness{
            display:none;" >> "$cpPath"/divi-child/style.css

    #make functions.php
    echo "<?php
        function my_theme_enqueue_styles() { 
        wp_enqueue_style( 'parent-style', get_template_directory_uri() . '/style.css' );
    }
        add_action( 'wp_enqueue_scripts', 'my_theme_enqueue_styles' );" >> "$cpPath"/divi-child/functions.php
    
}

plugin_theme_config_function(){
    debug_function "$FUNCNAME"
    if [ -z ${path+x} ];then
        for path in /var/www/*;do
        ##simple input only requires url and server type to function
        check_simple_input_function
        #activate all plugins
        sudo wp --allow-root --path="$path" plugin --all activate
        #delete twenty themes
        sudo wp --allow-root --path="$path" theme delete twentynineteen twentytwenty
        #update remaining themes
        sudo wp --allow-root --path="$path" theme update --all
        #delete plugins
        sudo wp --allow-root --path="$path" plugin delete akismet hello
        install_plugins_function 

        done
    else
        ##simple input only requires url and server type to function
        check_simple_input_function
        #activate all plugins
        sudo wp --allow-root --path="$path" plugin --all activate
        #delete twenty themes
        sudo wp --allow-root --path="$path" theme delete twentynineteen twentytwenty
        #update remaining themes
        sudo wp --allow-root --path="$path" theme update --all
        #delete plugins
        sudo wp --allow-root --path="$path" plugin delete akismet hello
        install_plugins_function 

    fi
    
}

delete_comments_function(){
    debug_function "$FUNCNAME"
    ##simple input only requires url and server type to function
    check_simple_input_function
    #delete default page, post and comments
    sudo wp --allow-root --path="$path" comment delete "$(sudo wp --allow-root --path="$path"  comment list --format=ids)" 
}
delete_widgets_function(){
    debug_function "$FUNCNAME"
    ##simple input only requires url and server type to function
    check_simple_input_function
    #delete default widgets
    #sudo wp --allow-root --path=$path widget delete $(sudo wp --allow-root --path=$path widget list  --format=ids)
    #sudo wp --allow-root --path=$path widget reset --all
    sudo wp --allow-root --path="$path" widget delete block-5 block-6 block-4 block-1
}
apache_install_function(){
    debug_function "$FUNCNAME"
    #required installs
    echo -e "processing...."
    echo -e "installing apache2 libapache2-mod-php "
    sudo apt install apache2 libapache2-mod-php -y &> /dev/null
    sudo ufw allow in "WWW Full"
    sudo systemctl enable apache2
    source /etc/apache2/envvars
    chmod 666 /etc/apache2/mods-enabled/dir.conf
    echo -e "<IfModule mod_dir.c>
    DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
    </IfModule>" |sudo tee -a /etc/apache2/mods-enabled/dir.conf
    sudo systemctl reload apache2
    #creates user group will changing ownership
    #gives apache the ability to write to path
    fix_WP_permissions_function
    #prompt user for cloudflare certs
    cloudflare_cert
    #create apache configuration files for website including SSL information
    sudo touch /etc/apache2/sites-available/"${domain}".conf
    sudo chmod 666 /etc/apache2/sites-available/"${domain}".conf
        echo -e "<VirtualHost *:80>
        ServerName $url
        ServerAlias www.$url
        ServerAdmin $domain@localhost
        DocumentRoot $path
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        </VirtualHost>
        
        <VirtualHost *:443>
        ServerAdmin webmaster@$url
        ServerName $url
        ServerAlias www.$url
        DocumentRoot $path
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

        SSLEngine on
        SSLCertificateFile /etc/cloudflare/$url.pem
        SSLCertificateKeyFile /etc/cloudflare/$url.key

        </VirtualHost>
        " | sudo tee -a /etc/apache2/sites-available/"${domain}".conf

        echo -e "<VirtualHost *:80>
        ServerName $url
        ServerAlias www.$url
        ServerAdmin $domain@localhost
        DocumentRoot $path
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        </VirtualHost>"|sudo tee -a /etc/apache2/apache2.conf

    sudo a2ensite "$domain"
    sudo a2dissite 000-default
    sudo chmod 666 /etc/php/*/apache2/php.ini
    #https://quadlayers.com/fix-divi-builder-timeout-error/
    sudo sed -i "/^memory_limit/s/128M/256M/g" /etc/php/7.3/apache2/php.ini && sudo sed -i "/^upload_max_filesize/s/2M/128M/g" /etc/php/7.3/apache2/php.ini && sudo sed -i "/^max_file_uploads/s/20/45/g" /etc/php/7.3/apache2/php.ini
    #https://www.wpbeginner.com/wp-tutorials/how-to-fix-the-link-you-followed-has-expired-error-in-wordpress/
    sudo sed -i "/^max_execution_time/s/30/300/g" /etc/php/7.3/apache2/php.ini && sudo sed -i "/^post_max_size/s/8M/128M/g" /etc/php/7.3/apache2/php.ini&& sudo sed -i "/^;max_input_vars/s/;//g" /etc/php/7.3/apache2/php.ini
   #to enable wordpress permalink feature for url management
    sudo a2enmod rewrite
    #required mod for ssl
    sudo a2enmod ssl
    sudo apache2ctl configtest
    sudo systemctl reload apache2
    server="apache"
}

nginx_install_function(){
    debug_function "$FUNCNAME"
    #remove default apache file  and disable apache if needed
    sudo rm -rf /var/www/html
    #sudo systemctl stop apache2
    #sudo systemctl disable apache2
    sudo apt-get install -y unit-php
    sudo service unit restart
    #required installs
    echo "processing...."
    echo "installing nginx "
    # Install the NGINX repository
    echo "adding nginx to /etc/apt/sources.list.d"
    if [ ! -f /etc/apt/sources.list.d/nginx.list ]; then
        echo "▶ Installing NGINX repository"
        #curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
        echo -e "deb http://nginx.org/packages/mainline/debian/ buster nginx
        deb-src http://nginx.org/packages/mainline/debian/ buster nginx" > /etc/apt/sources.list.d/nginx.list
    fi 
    echo "installing nginx"
    sudo apt-get remove nginx-common -y
    sudo apt update -y 
    wget http://nginx.org/keys/nginx_signing.key
    sudo apt-key add nginx_signing.key &> /dev/null
    sudo apt-get install -y nginx 
    sudo nginx -v
    echo " starting nginx"
    sudo nginx
    /etc/init.d/nginx start
    sudo ufw allow in "Nginx Full"
    sudo systemctl enable nginx
    #move default to be template
    sudo mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.template
    sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.template

    #install certbot and nginx
    #echo "installing certbot"
    #sudo apt install -y certbot python3-certbot-nginx &> /dev/null
    
    echo "Configuring nginx.."
    #create server config file for domain
    sudo touch /etc/nginx/sites-available/"${domain}".conf
    fix_WP_permissions_function

    #to test locally
    #/etc/hosts add
    #127.0.0.1               site1.com
    #127.0.0.1               site2.com 

    #The $request_uri is a variable and is present there to ensure that it is fully redirected
    #$scheme is another variable that will ensure that the request gets routed to HTTP or HTTPS
    echo -e "user  www-data;
    worker_processes  1;
    error_log  /var/log/nginx/error.log warn;
    pid        /var/run/nginx.pid;

    events {
        worker_connections  1024;
    }

    http {
    include            /etc/nginx/mime.types;
    default_type       application/octet-stream;
    log_format         main  '$remote_addr - $remote_user - [$time_local] - $document_root - $document_uri - '
                       '$request - $status - $body_bytes_sent - $http_referer';

    access_log         /var/log/nginx/access.log  main;
    sendfile           on;
    keepalive_timeout  65;
    client_max_body_size 13m;
    index              index.php index.html index.htm;
    upstream php {
        server 127.0.0.1:9000;
    }
    include /etc/nginx/conf.d/*.conf;
    } " |sudo tee -a /etc/nginx/nginx.conf
    
    #https://websiteforstudents.com/install-wordpress-on-ubuntu-16-04-lts-with-nginx-mariadb-and-php-7-1-support/
    echo -e '
    {
    "listeners": {
        "127.0.0.1:8090": {
            "application": "script_index_php"
        },
        "127.0.0.1:8091": {
            "application": "direct_php"
        }
    },

    "applications": {
        "script_index_php": {
            "type": "php",
            "processes": {
                "max": 20,
                "spare": 5
            },
            "user": "www-data",
            "group": "www-data",
            "root": "%s",
            "script": "index.php"
        },
        "direct_php": {
            "type": "php",
            "processes": {
                "max": 5,
                "spare": 0
            },
            "user": "www-data",
            "group": "www-data",
            "root": "%s",
            "index": "index.php"
        }
    }
    }
    ' "$path" "$path"|sudo tee -a /etc/nginx/sites-available/"${domain}".conf

    #create a copy and ln in sites available
    sudo ln /etc/nginx/sites-available/"${domain}".conf /etc/nginx/sites-enabled/

    #enable the domain by linking it to the sites-enabled
    #sudo ln -s /etc/nginx/conf.d/${domain}.conf /etc/nginx/sites-enabled/
    
    #uncomment out https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-debian-10
    #^ was not used because an indent is present
    sudo chmod 666 /etc/nginx/nginx.conf
    sudo sed -i "/#*server_names_hash_bucket_size*/s/#//" /etc/nginx/nginx.conf
    #changing the default search file to prevent default.txt from loading
    #sudo sed -i 's#include /etc/nginx/sites-enabled/\*;#include /etc/nginx/sites-enabled/\*.conf;#g' /etc/nginx/nginx.conf
    sudo nginx -t && sudo nginx -s reload
    sudo systemctl restart nginx
    sudo systemctl restart php7.3-fpm
    server="nginx"

    #https://www.nginx.com/blog/installing-wordpress-with-nginx-unit/
    #debug-option
    debug_function nginx creation
    
}

install_maria_db_function(){
    debug_function "$FUNCNAME"
    #path, domain, admin_user, sql_pass all defined in appacheAttribute function
    user_input_simple_function
    if [ -z ${sql_pass+x} ];then
        echo "Enter sql password: [may be found in instance marketplace if using gcp]:"
        read -p sql_passPlain
        sql_pass=$(printf "%s" "$sql_passPlain"|sha256sum|base64|head -c 22)
    fi
    #---------------required installs
    echo -e "processing...."
    echo -e "installing mariadb-server ufw php php7.3-mysql "
    sudo apt install mariadb-server ufw php php7.3-mysql -y &> /dev/null
    echo -e "installing fail2ban"
    sudo apt install fail2ban -y &> /dev/null

    #security settings
    echo -e "US/Eastern" |sudo tee -a /etc/timezone
    dpkg-reconfigure -f noninteractive tzdata
    #detect php version
    phpVersion=$(php -v |cut -d " " -f 2|cut -d "~" -f 1|head -n 1)
    #define the timezone to the php.ini for security 
    sudo chmod 666 /etc/php/*/apache2/php.ini
    sudo sed -i "s/\;date.timezone =/date.timezone = US\/Eastern/" /etc/php/7.3/apache2/php.ini
    sudo systemctl enable mariadb.service
    echo -e "processing...."
    #all www traffic
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow ssh
    sudo ufw limit ssh
    sudo ufw --force enable
    sudo systemctl start ufw

    ##database creation
    #server hardening script Requires user input
    #sudo mysql_secure_installation
    #-e allows passing of commands , sudo allows running as root user
    sudo mariadb -e "CREATE DATABASE $db_name DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
    sudo mariadb -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$domain'@'localhost' IDENTIFIED BY '$sql_pass';"
    sudo mariadb -e "FLUSH PRIVILEGES;"
    ##---------- Dynamic Server Creation
    if  [[ "$server" == "none" || "$server" == "both" ]] ;then
    ###if neither nginx or apache are detected then prompt user to select which one
        echo "server not detected"
        while [ -z ${which_server+x} ];do
            echo "
            ▶1. Use nginx Server
            ▶2. Use Apache2 Server (1 / 2):"
            read -r which_server
        done 
            if [ "$which_server" == "1" ];then
                echo "nginx server selected"
                path="/var/www/${domain}"
                nginx_install_function
            elif [ "$which_server" == "2" ];then
                echo "apache server selected"
                apache_install_function
            fi
    else
    ###if 1 server type is detected, then use the server already installed
        if  [ "$server" == "apache" ];then
            echo "apache  server already installed"
            apache_install_function
        elif [ "$server" == "nginx" ];then
            echo "nginx server already installed"
            path="/var/www/${domain}"
            nginx_install_function
        else
            echo "nothing detected"
        fi
    fi
    
}

install_requirements_function(){
    debug_function "$FUNCNAME"
    ##############Installs################################
    ##perform update
    echo -e "Updating Distro"
    echo "visit https://dash.cloudflare.com/ and set up domain and origin-server , under SSL/TLS"
    sudo apt autoremove -y
    sudo apt update --fix-missing -y &> /dev/null;
    #install diceware
    sudo apt install diceware
    #install bitwarden
    #curl -Lso bitwarden.sh https://go.btwrdn.co/bw-sh && chmod 700 bitwarden.sh && ./bitwarden.sh install
    #install password store
    #sudo apt install -y pass
    #install keepass cli
    #sudo apt-get install -y kpcli
    echo -e "installing php7.3-curl php7.3-gd php7.3-mbstring php7.3-xml php7.3-xmlrpc php7.3-soap php7.3-intl php7.3-zip"
    sudo apt install php7.3 php7.3-common -y &> /dev/null
    echo "Installation complete: php base"
    #may take a while
    #split up installation into different batches to catch errors and stout to null
    echo "php pkgs install begining..."
    required_installs="php7.3-fpm php7.3-recode php7.3-tidy php7.3-bcmath php7.3-opcache php7.3-fpm php7.3-zip php7.3-curl php7.3-xml php7.3-xmlrpc php7.3-json php7.3-mysql php7.3-pdo php7.3-gd php7.3-imagick php7.3-ldap php7.3-imap php7.3-mbstring php7.3-intl php7.3-cli php7.3-curl php7.3-json php7.3-gd php7.3-mbstring php7.3-intl php7.3-bcmath php7.3-bz2 php7.3-readline php7.3-zip"
    for pkg in "$required_installs";do
        sudo apt install -y $pkg &> /dev/null;
    done

    #make sure cloudflare directory is created
    sudo mkdir -p /etc/cloudflare

    echo -e "wp-cli is being installed"
    if ! command -v wp &> /dev/null ;then
    #wp not installed
        cd ~ || exit
        sudo apt install curl -y
        echo "wp-cli is being installed"
        curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar --output ./wp-cli.phar 
        #make downloaded file executable 
        sudo chmod +x ./wp-cli.phar
        sudo mv ./wp-cli.phar /usr/local/bin/wp
        #installing wp completion plugin and adding to source
        curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.4.0/utils/wp-completion.bash --output ./wp-completion.bash
        sudo chmod +x ./wp-completion.bash
        sudo mv ./wp-completion.bash /usr/local/bin/wp-completion
        touch ./.bash_profile
        source /usr/local/bin/wp-completion
        source ./.bash_profile
    fi

    #git google downloader
    #use for downloading from gdrive
    if [ -d "$HOME"/gdown.pl ];then
    echo -e "gdownloader installed"
    else
    echo -e "processing...."
    echo -e "installing requirements for gdown: git and wget"
    sudo apt install git wget -y &> /dev/null
    cd ~ || exit
    sudo git clone https://github.com/circulosmeos/gdown.pl.git &> /dev/null
    fi

    #intall 7zip-full
    if ! command -v 7z &> /dev/null; then
        echo -e "processing...."
        echo -e "installing 7zip full"
        sudo apt install p7zip-full -y &> /dev/null
    fi
    #install too long didn't read
    if ! command -v tldr &> /dev/null; then
    sudo apt install tldr -y &> /dev/null
    fi

    #if ! command -v tldr &> /dev/null; then
    #https://www.digitalocean.com/community/tutorials/how-to-protect-an-apache-server-with-fail2ban-on-ubuntu-14-04
    #    echo -e "installing fail2ban"
    #    sudo apt install -y fail2ban &> /dev/null
    #       sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

}

WP_install_function(){
    debug_function "$FUNCNAME"
    #download wordpress
    sudo wp --allow-root --path="$path" core download

    #create sql database
    sudo wp --allow-root --path="$path" config create --dbname="$db_name" --dbuser="$domain" --dbpass="$sql_pass" --url="$url" --extra-php <<PHP
define( 'WP_MEMORY_LIMIT', '128M');
define( 'WP_MAX_MEMORY_LIMIT', '256M' );
define( 'WP_ALLOW_REPAIR', false);
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_DISPLAY', false );
PHP

    #install wordpress   
    sudo wp --allow-root --path="$path" core install --url="$url" --admin_user="$admin_user" --admin_password="$admin_pass" --title="$site_title" --admin_email="$admin_email"
    #remove sample wp-config    
    sudo rm -rf  "${path}"/wp-config-sample.php
    #unsetSQL
    unset sql_pass
}
configure_WP_function(){
    debug_function "$FUNCNAME"
    #configure wordpress wordpress
    #update blogname title
    sudo wp --allow-root --path="$path" option update blogname "$site_title"
    sudo wp --allow-root --path="$path" option update blogdescription "$site_description" 
    #update timezone to Eastern
    sudo wp --allow-root --path="$path" option update timezone_string "America/New_York"
    #permalinks
    #sudo wp --allow-root --path=$path rewrite flush
    #sudo wp --allow-root --path=$path option update permalink_structure '/%postname%/'
    #turn off comments
    sudo wp --allow-root --path="$path" option update default_comment_status closed
    sudo wp --allow-root --path="$path" option update default_ping_status closed
    #create user
    sudo wp --allow-root --path="$path"  user create "$alt_user" "${alt_email}" --role=administrator --user_pass="$alt_userPass"
    sudo wp --allow-root --path="$path"  user create "$admin_user" "${admin_email}" --role=administrator --user_pass="$admin_pass"
    sudo wp --allow-root --path="$path"  user create $ssh_username "${admin_email}" --role=administrator --user_pass="$admin_pass"
    ##plugin and theme func
}

migrate_WP_function(){
    debug_function "$FUNCNAME"
    user_input_full_function
    user_creation_function
    ##############Wordpress Configuration################################
    WP_install_function
    #fix permissions 
    fix_WP_permissions_function
    configure_WP_function

    #sudo wp --allow-root --path=$path db import $dbLocation --dbname="$db_name" --dbuser="$domain" --dbpass="$sql_pass" --url="$url"
}
setup_WP_function(){
    debug_function "$FUNCNAME"
    user_input_full_function
    ##############Wordpress Configuration################################
    WP_install_function

    #fix permissions 
    fix_WP_permissions_function

    configure_WP_function

    install_divi_function
    plugin_theme_config_function
    delete_comments_function
    delete_widgets_function
    #delete default pages, running here as this would delete future pages if placed in function
    sudo wp --allow-root --path="$path" post delete "$(sudo wp --allow-root --path="$path" --force post list --post_type="page" --format=ids)"
    #create page
    sudo wp --allow-root --path="$path" post create --post_type=page --post_status=publish --post_author="$alt_user" --post_title="${site_title} Landing" --post_content="${site_title} is coming soon!"
    sudo wp --allow-root --path="$path" post create --post_type=page --post_status=publish --post_author="$alt_user" --post_title="${site_title} Blog"
    #create primary Menu
    sudo wp --allow-root --path="$path" menu create "main menu"
    if [ "$alt_user_set" == false ];then
        sudo wp --allow-root --path="$path" menu item add-custom main-menu "$domain socials" "https://www.google.com/search?q=${domain}+instagram+OR+facebook+OR+twitter+OR+reddit+OR+photos"
    else
    #assume alt_user was defined and user alt User as the query
    sudo wp --allow-root --path="$path" menu item add-custom main-menu "$domain socials" "https://www.google.com/search?q=${alt_user}+instagram+OR+facebook+OR+twitter+OR+reddit+OR+photos+${domain}"
    fi
    #assign created menu as primary
    sudo wp --allow-root --path="$path" menu location assign main-menu primary-menu
    #install all plugins
    install_plugins_function
    ####################Closing Commands#################

    ##update all before finishing
    WP_update_function

    ####################SSL Certs Installed or Not#################

    #read -p "Ready to install SSL certs? (y/n): " readyForCerts
    #if [[ "$readyForCerts" == "y" || "$readyForCerts" == "yes" ]]; then
    #install_certs_function
    #else
    #echo -e "Run this script with \' $script_name -ssl\' to install ssl certs"
    #fi

    ####################Print out User Information#################
    #print out user list
    sudo wp --allow-root --path="$path" user list 
    #print out credentials
    printf "Credentials for %s \nusername: %s \npassword: %s\n" "$url" "$admin_user" "$admin_pass"
    printf "alt_user: %s \nalt_user Password: %s\n" "$alt_user" "$alt_userPass"
    printf "Go to: %s/wp-admin and log in with the credentials above\n" "$url"
}
#debug-option
debug_function end of functions

create_backup_function(){
    debug_function "$FUNCNAME"
    ####################Create encrypted backup#################
    printf "$line\nInformation used for debugging\n\ndomain:$domain\nurl:$url\npath: $path
    USER: $USER\nsql pass:$sql_passPlain\ndb name:$db_name\nsql pass:$sql_pass\nadmin_user:$admin_user
    admin pass: $admin_pass\nalter user:$alt_user\nalt pass:$alt_userPass\nsite title:$site_title
    site description :$site_description\n$line\n" | gpg -c > "$HOME/$domain.gpg"
}
############## Menu ################################
#if a '-' or '--' is used begin the menu listed below
while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -h | --help )
    printf "\nRun this script as sudo {{ sudo $HOME/%s }}\n\n%s
    -a or --aliases will create aliases to server to be ran with default user
    -d or --domain will update domain to https and replace all links
    -divi or --install-divi will install Divi Theme
    -inpl or --install-plugins will install several selected plugins and activate them
    -m or --migrate will download a fresh wordpress folder
    -p or --permissions will run the permission script
    -pt or --plugintheme will config themes and plugins
    -s or --ssh-send will send this script to appropriate servers
    -sc or --send-ssh-command sends the same command to all servers
    -ssl or --https will update the site url to be https
    -ssh print a list of ssh commands base don the servers for copy and paste
    -u or --update will update server and all wordpress plugins and themes\n" "$script_name" $line
    exit 0
    ;;
    -a | --aliases )
    create_alias_function; exit 0
    ;;
    -d | --domain )
    update_domain_function; exit 0
    ;;
    -divi | --install-divi )
    url="$2"
    install_divi_function; exit 0
    ;;
    -inpl | --install-plugins )
    install_plugins_function ; exit 0
    ;;
    -m | --migrate )
        url="$2"
        migrate_WP_function; exit 0
        ;;
   -p | --permissions )
        url="$2"
        fix_WP_permissions_function; exit 0
        ;;
   -pt | --plugintheme )
        url="$2"
        plugin_theme_config_function; exit 0
        ;;
        -s | --ssh-send )
        scp_send_function; exit 0
        ;;
    -ssl | --https )
        url="$2"
        user_input_simple_function
        install_certs_function; exit 0
        ;;
    -ssh | --ssh )
        print_ssh_function; exit 0
        ;;
        -sc | --send-ssh-command )
        ssh_command_function; exit 0
        ;;
    -u | --update )
        #if script is ran from mac (not server), then send update command via ssh
        if [ "$OS" == "Darwin" ];then
            #prevent from running on mac if help menu isn't initiated
            #print ssh information on mac
            for i in "${ip[@]}";do
                #define key as the section before the colon and the value as the section after the colon
                KEY="${i%%::*}";VALUE="${i##*::}"
                #add each ip to the allDomain variable
                #ssh $ssh_username@$VALUE 'for d in /var/www/*;do wp --path=$d plugin update --all && wp --path=$d theme update --all;done'
                ssh $ssh_username@"$VALUE" 'sudo apt update && sudo apt -y upgrade'
            done
            exit 2
        else
            url="$2"
            update_system_function; exit 0
        fi
        ;;
esac; shift; done
if [[ "$1" == "--" ]]; then shift; fi
#debug-option
debug_function end of script menu

#debug-option
debug_function encryption

if [ "$OS" == "Darwin" ];then
    #prevent from running on mac if help menu isn't initiated
    #print ssh information on mac
    case $option in 
        
    print_ssh_function
    exit 2
else
    #if not mac and menu not initiated start the process by running functions
    
    #create_alias_function 
    install_requirements_function
    if [ -z "$1" ]; then
        user_input_simple_function
        user_creation_function
        install_maria_db_function
        setup_WP_function
        create_backup_function
    elif [ "$1" == "wordpress" ];then
        url="$2"
        user_input_simple_function
        user_creation_function
        setup_WP_function
        create_backup_function
    elif [ "$1" == "server" ];then
        url="$2"
        user_input_simple_function
        user_creation_function
        install_maria_db_function
    else
        url="$1"
        user_input_simple_function
        user_creation_function
        install_maria_db_function
        setup_WP_function
        create_backup_function
        
    fi
   echo "none"
fi
#debug-option
debug_function end of script