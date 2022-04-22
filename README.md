# wordpress-install
generate mariadb, apache or nginx server, and configure a basic wordpress website or multiple wordpress websites on a server


# Install Configure and Use



# Change Log
#created 20210311
#lastUpdate 20220205
script_name="wp-install-20220415.sh"

########### DATE: date UpdatedBy: name ###########
#modified:
        #
    #added var:
        #
    #added function:
        #
    #removed
        #
########### DATE: 20220205 UpdatedBy: sac ###########
#modified:
        #commented out bw and using diceware instead to generate passphrase 
        #updated script local location and scp for script 
    #added function:
        #function for cloudflare_cert generation
    #removed
        #removed loops for adding cloudflare pem and key as they were not loading properly. User will be directed to a open file and can past and close
########### DATE: 20220122 UpdatedBy: sac ###########
#modified:
        #echo " "> file changed to echo " " | sudo tee -a file
        #~/dir changed to $HOME/dir see: https://github.com/koalaman/shellcheck/wiki/SC2088
        #/dir/path changed to "/dir/path"
        #all variables and function names changed to snake format from camel case
        #changed printf "..$var.." to printf "..%s.." "$var" https://github.com/koalaman/shellcheck/wiki/SC2059
        #functions renamed as function_name_function
        #changed read style from read -p "prompt" name > echo "prompt"\nread -r name
        #change argument from $@ to $* https://github.com/koalaman/shellcheck/wiki/SC2145
        #added quotes on all arguments https://github.com/koalaman/shellcheck/wiki/SC2068

#removed: 
        #user variable removed and replaced with $USER
########### DATE: 20211009 UpdatedBy: Sac ###########
    #added function:
        #added a check in case menu for -u to send update command over ssh if macos is detected
########### DATE: 20210912 UpdatedBy: Sac ###########  
    #modified:
        #installPlugin function now handles all args using loop to iterate through plugins to install
        #exit codes updated to reflect correct standards
            #exit 2 become exit 0 to return without error
            #exit 3 became exit 2
    #removed
        # var for default plugins
########### DATE: 20210905 UpdatedBy: Sac ###########
#modified:
        # nginx function to work with wordpress , still working on it, adding nginx unit
        #fix_WP_permissions_function added to several locations instead of the 
        #modified default menu item link to google search
########### DATE: 20210904 UpdatedBy: Sac ###########
    #modified:
        #$(date) to $((date))
        #change log format
        #commented out ssl prompt for now, working need to create a ssl standalone
        #increased random number gen for password to 999999 and add date
    #added var:
        #email_domain, alt_email, admin_email, script_path, defaultPlugins, defaultThemes
    #added function:
        #check_simple_input_function, create_alias_function
        #update_system_function to update, upgrade system, autoremove , 
            #and loop all /var/www/* updating themes and plugins
        #added debug_function to find issues and increment for quick identification, default is off
        #auto fix for gpg error 
            #https://d.sb/2016/11/gpg-inappropriate-ioctl-for-device-errors
        #create backup of domain information using gpg symmetric with password prompt
            #https://guides.library.illinois.edu/data_encryption/gpgcheatsheet
    #removed
        #script description and dev notes

########### DATE: 20210903 UpdatedBy: Sac ###########
    #updated widget remove
    #created Random Password Generator for base and alternate user account
    #prompt user for cloudflare pem and key prior to configuring apache
    #removed jetpack plugin
    #add and activate plugins honeypot miniorange-2-factor-authentication prevent-direct-access sucuri-scanner
    #adding simple-ssl but not activating
    #script name change
    #updated Divi Theme Link 
    #added $script_path for easier customization
    #unset sql_pass and ssl_key_text for added security

#--------------------/Change Log----------------#