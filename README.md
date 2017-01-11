# ubuntu-activedirectory
Collection of shell scripts to help ease configuration of active directory integration in linux.

In order to use SUDO roles in Active Directory, you need to extend the schema. Please reference https://github.com/lbt/sudo/blob/master/doc/schema.ActiveDirectory with a simplified documenation on how to extend for the SUDO object type.

Askubuntu has a reasonable answer on this process as well: http://askubuntu.com/questions/63782/add-ad-domain-user-to-sudoers-from-the-command-line. I've highlighted the relevant portion here:

Grab the latest release of sudo, get the doc/schema.ActiveDirectory file, then import it (make sure to modify the domain path according to your domain name):

ldifde -i -f schema.ActiveDirectory -c "CN=Schema,CN=Configuration,DC=X" "CN=Schema,CN=Configuration,DC=ad,DC=foobar,DC=com" -j .
Verify it with ADSI Edit: open the Schema naming context and look for the sudoRole class.

Now create the sudoers OU on your domain root, this OU will hold all the sudo settings for all your Linux workstations. Under this OU, create a sudoRole object. To create the sudoRole object you have to use ADSI Edit, but once created, you can use Active Directory Users and Computers to modify it.

Let's assume I have a computer named foo32linux, a user called stewie.griffin and I want to let him run all commands with sudo on that comp. In this case, I create a sudoRole object under the sudoers OU. For the sudoRole you can use any name you want - I stick with the computer name since I use per-computer rules. Now set its attributes as follows:

sudoHost: foo32linux
sudoCommand: ALL
sudoUser: stewie.griffin
For commands you can use specific entries as well, like /bin/less or whatever.

