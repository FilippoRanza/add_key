#add_key.sh
Helps you to generate ssh keys for remote hosts.

##Description
This tool helps the user during ssh key generation.

You run the tool an it interactively ask for necessary informations:

1. key name (**must be unuque**)
2. remote host (**must be unuque**)
3. remote host's url or IP 
4. remote host's service port number (**default 22**)
5. remote user name (can be empty)
6. a comment for the new key (can be empty)
7. an emcryption key for new key (can be empty)

By now new keys are put in _$HOME/.ssh_, and key informations in _$HOME/.ssh/config_
Every new is key a **4096 bit RSA** key.


##Usage
Run **bash add_key.sh**, then follow given request. A new  key is generated if 
every argument is correct.

Given _urls_ are checked, the tool tries to ping it, in case of failure ask you to know what to do.


 
