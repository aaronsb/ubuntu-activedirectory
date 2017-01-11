# ubuntu-activedirectory
Collection of shell scripts to help ease configuration of active directory integration in linux. Mostly for my notes, but might be helpful for other folks too.

# Scripts

I'm lazy and sudo -s before running these two bash scripts. Also, you'll probably want to chmod 667 them to run them.

ad-setupprereq.sh executes the necessary updates and adds the various modules (samba, sssd, etc) via apt.

joinadrealm.sh is a way for me to just show the commands, in the order, and the various configuration files that must be modified/updated. Please study and understand what happens before you just run these on a production system of any kind. They are essentially my notes as I understand them from sssd man pages, and several blog sites and help sites I found. 

# Schema Extension
In order to use SUDO roles in Active Directory, you need to extend the schema. Please reference https://github.com/lbt/sudo/blob/master/doc/schema.ActiveDirectory with a simplified documenation on how to extend for the SUDO object type.

Askubuntu has a reasonable answer on this process as well: http://askubuntu.com/questions/63782/add-ad-domain-user-to-sudoers-from-the-command-line. I've highlighted the relevant portion here:

# Line by line - Schema Extension
Grab the latest release of sudo, get the doc/schema.ActiveDirectory file, then import it (make sure to modify the domain path according to your domain name):

ldifde -i -f schema.ActiveDirectory -c "CN=Schema,CN=Configuration,DC=X" "CN=Schema,CN=Configuration,DC=ad,DC=foobar,DC=com" -j .
Verify it with ADSI Edit: open the Schema naming context and look for the sudoRole class.

Now create the sudoers OU on your domain root, this OU will hold all the sudo settings for all your Linux workstations. Under this OU, create a sudoRole object. To create the sudoRole object you have to use ADSI Edit, but once created, you can use Active Directory Users and Computers to modify it.

Let's assume I have a computer named foo32linux, a user called stewie.griffin and I want to let him run all commands with sudo on that comp. In this case, I create a sudoRole object under the sudoers OU. For the sudoRole you can use any name you want - I stick with the computer name since I use per-computer rules. Now set its attributes as follows:

sudoHost: foo32linux
sudoCommand: ALL
sudoUser: stewie.griffin
For commands you can use specific entries as well, like /bin/less or whatever.

