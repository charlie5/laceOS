with
     laceOS.Storage;


package laceOS.Installer
is
   no_wifi_Devices           : exception;
   no_wifi_Networks          : exception;
   unable_to_connect_to_WIFI : exception;

   procedure setup_Networking;
   procedure update_the_system_Clock;
   procedure install_Packages;
   procedure rid_unwanted_Packages;
   procedure configure_the_System (hostName : in String;
                                   userName : in String;
                                   Password : in String;
                                   the_locale_Code     : in String;
                                   the_keyboard_Layout : in String;
                                   the_root_Partition  : in storage.Partition);
   procedure abort_Install;

end laceOS.Installer;
