with
     laceOS.CPU,
     laceOS.Details,
     laceOS.Console,
     laceOS.Memory,
     laceOS.Logger,
     laceOS.Commands,
     laceOS.IO,
     laceOS.Containers,

     shell.Commands.unsafe,
     shell.Directory_iteration,

     lace.Text.forge,
     lace.Text.utility,
     lace.Text.all_Lines,
     lace.Text.Cursor,

     ada.Directories,
     ada.Characters.latin_1,
     ada.Text_IO;


package body laceOS.Installer
is
   use laceOS.Details,
       laceOS.Console,
       laceOS.Commands,
       laceOS.Logger,
       laceOS.Containers,

       lace.Text.forge;


   procedure setup_Networking
   is

      procedure detect_WIFI_Device
      is
      begin
         Dlog ("");
         Dlog ("iwctl device list");

         declare
            use lace.Text;

            the_Text : constant lace.Text.item      := to_Text (run ("iwctl device list"));
            Lines    : constant lace.Text.items_128 := all_Lines.Lines (the_Text);
         begin
            for Each of Lines
            loop
               Dlog ("'" &(+Each) & "'");
            end loop;

            if lace.Text.utility.contains (the_Text, "wlan0")
            then
               Dlog ("Found WIFI device");
            else
               raise no_wifi_Devices;
            end if;
         end;

         Dlog ("");
         Dlog ("iwctl station device scan");
         log (run ("iwctl station wlan0 scan"));
      end detect_WIFI_Device;


      network_Names      : Strings;
      network_Securities : Strings;

      procedure detect_WIFI_Networks
      is
      begin
         Dlog ("");
         Dlog ("iwctl station device get-networks");
         Dlog (run ("iwctl station wlan0 get-networks"));

         declare
            use lace.Text,
                lace.Text.utility,
                lace.Text.Cursor;

            the_Text : aliased  lace.Text.item        := to_Text (run ("iwctl station wlan0 get-networks"));
            C        :          lace.Text.Cursor.item := First (the_Text'Access);

         begin
            C.skip_Line;
            C.skip_Line;
            C.skip_Line;
            C.skip_Line;

            if Contains (+C.peek_Line, "No networks available")
            then
               raise no_wifi_Networks;
            end if;

            while C.has_Element
            loop
               C.skip_White;

               declare
                  the_Line : constant lace.Text.item := +C.peek_Line;

                  Security : constant String := (if    Contains (the_Line, ("open" )) then "open"
                                                 elsif Contains (the_Line, ("wep"  )) then "wep"
                                                 elsif Contains (the_Line, ("psk"  )) then "psk"
                                                 elsif Contains (the_Line, ("8021x")) then "8021x"
                                                 else                                      "unknown");
                  Name     : constant String := C.next_Token (Delimiter => Security, Trim => True);
               begin
                  exit when Name = "";
                  network_Names     .append (Name);
                  network_Securities.append (Security);
               end;

               C.skip_Line;
            end loop;

            Dlog ("Network names:");
            for i in 1 .. Natural (network_Names.Length)
            loop
               Dlog ("'" & network_Names (i) & "'     '" & network_Securities (i) & "'");
            end loop;
            Dlog ("End network names.");
         end;
      end detect_WIFI_Networks;


      procedure connect_to_Wifi
      is                                 -- We create and run a bash script since aShell argument parsing of double-quoted arguments
         use ada.Characters.latin_1;     -- is problematic, atm.     (TODO: Investigate why and fix in aShell.)

         Choice           : constant Positive := Query (Options => network_Names);
         chosen_Network   : constant String   := network_Names      (Choice);
         network_Security : constant String   := network_Securities (Choice);
         Passphrase       : constant String   := (if network_Security = "wep"
                                                  or network_Security = "psk" then Query (Question => "Passphrase")
                                                  else "");
      begin
         Dlog ("Chosen network: " & chosen_Network & " using " & network_Security & ".");
         Dlog ("Passphrase: '"    & Passphrase & "'");

         if Passphrase = ""
         then
            IO.store (in_File  => "/usr/local/bin/start_wifi.sh",
                      the_Text =>   "#!/bin/bash" & LF
                                  & "iwctl station wlan0 connect """ & chosen_Network & """");
         else
            IO.store (in_File  => "/usr/local/bin/start_wifi.sh",
                      the_Text =>   "#!/bin/bash" & LF
                                  & "iwctl --passphrase " & Passphrase & " station wlan0 connect """ & chosen_Network & """");
         end if;

         declare
               --  connect_Command : constant unsafe.Command  := forge.to_Command ("start_wifi.sh");
            Success : Boolean;
            Count   : Natural := 0;
         begin
            loop
               Count := Count + 1;

               Dlog (run (command_Line => "start_wifi.sh",
                          in_Chroot    => False,
                          normal_Exit  => Success));

               exit when Success;

               if Count >= 5
               then
                  raise unable_to_connect_to_WIFI;
               end if;

               delay 0.5;
            end loop;
         end;
      end connect_to_Wifi;


   begin
      Dlog ("");
      Dlog ("Connecting to the internet.");
      Dlog ("Pinging.");

      declare
         use Shell,
             shell.Commands,
             shell.Commands.unsafe;
         ping_OK : Boolean;
      begin
         for i in 1 .. 3     -- Try 3 pinging times.
         loop
            declare
               ping_Command :          unsafe.Command  := forge.to_Command ("ping -W 3 -w 3 -c 1 archlinux.org");
               ping_Results : constant Command_Results := ping_Command.run with Unreferenced;
            begin
               ping_OK := ping_Command.Normal_Exit;
               exit when ping_OK;
            end;
         end loop;


         if not ping_OK     -- No ethernet, so setup wifi.
         then
            detect_WIFI_Device;
            detect_WIFI_Networks;
            connect_to_Wifi;
         end if;
      end;

   end setup_Networking;



   procedure update_the_system_Clock
   is
   begin
      Dlog ("");
      Dlog ("Updating the system clock.");
      run  ("timedatectl set-ntp true");
   end update_the_system_Clock;



   procedure install_Packages
   is

      procedure install_essential_Packages
      is
         Count : Natural := 0;
      begin
         loop
            declare
               use shell.Commands.unsafe;
               the_Command : shell.Commands.unsafe.Command := Forge.to_Command (  "pacstrap -c /mnt base base-devel linux-lts linux-firmware nano networkmanager"
                                                                                & "                 grub os-prober efibootmgr"
                                                                                & "                 xorg xfce4 xfce4-goodies lightdm lightdm-slick-greeter"
                                                                                & "                 network-manager-applet nm-connection-editor");
            begin
               Count := Count + 1;
               Dlog ("");

               if Count = 1
               then
                  log  ("");
                  log  ("Installing packages.");
                  Dlog ("");
               end if;

               Dlog (" ~ Cycle" & Count'Image & ".");

               the_Command.start;

               while not the_Command.Has_Terminated
               loop
                  log (".", new_Line => False);

                  declare
                     use Shell,
                         shell.Commands;
                     Results : constant Command_Results :=  the_Command.Results_Of;
                     Output  : constant String          := +Output_of (Results);
                     Errors  : constant String          := +Errors_of (Results);
                  begin
                     if Output /= ""
                     then
                        Dlog (Output);
                     end if;

                     if Errors /= ""
                     then
                        Dlog ("Errors/Warnings:");
                        Dlog  (Errors);
                     end if;

                     delay 2.0;
                  end;
               end loop;

               exit when the_Command.normal_Exit;
            end;

         end loop;


         Dlog (run ("umount /mnt/dev"));     -- TODO: This is needed to prevent a current error in 'arch-chroot' commands. Remove when error is fixed..
      end install_essential_Packages;



      procedure install_miscellaneous_Packages
      is
         use lace.Text;
         Lines : constant lace.Text.items_64 := all_Lines.Lines (forge.to_Text ("miscellaneous_packages"));
      begin
         Dlog ("Installing miscellaneous packages.");
         Dlog ("");

         log (".", new_Line => False);
         run ("rsync -av --quiet custom/var/cache/pacman/pkg /mnt/var/cache/pacman");

         Dlog (run ("pacman -Syu",             -- TODO: Needed ?
               in_Chroot => True));

         for Each of Lines
         loop
            if         Length   (Each)          >= 2
              and then String' (+Each) (1 .. 2) /= "--"
            then
               Dlog (run ("pacman -S --noconfirm " & (+Each),
                          in_Chroot => True));

               log (".", new_Line => False);
            end if;
         end loop;


         -- TODO: Microde seems to break GRUB. Investigate and find out why.
         --
         -- Install bootloader microcode.
         --
         --  declare
         --     use CPU;
         --  begin
         --     case CPU.Kind
         --     is
         --     when AMD =>
         --        if not ada.Directories.exists ("/mnt/boot/amd-ucode.img")
         --        then
         --           Dlog (run ("pacman -S --noconfirm amd-ucode",
         --                 in_Chroot => True));
         --        end if;
         --
         --     when Intel =>
         --        if not ada.Directories.exists ("/mnt/boot/intel-ucode.img")
         --        then
         --           Dlog (run ("pacman -S --noconfirm intel-ucode",
         --                 in_Chroot => True));
         --        end if;
         --     end case;
         --  end;

      end install_miscellaneous_Packages;



      procedure install_AUR_Packages
      is
      begin
         Dlog ("Installing AUR packages.");
         Dlog ("");
         log  (".", new_Line => False);

         Dlog (run ("rsync -av --quiet /root/aur /mnt/root"));     -- TODO: Use 'mv' ?

         declare
            use String_Vectors,
                shell.Directory_iteration;

            AUR_Folder     : constant Directory := to_Directory ("/root/aur", Recurse => True);
            Packages       :          Strings;
            just_Installed :          Strings;

            recreate_install_Order : Boolean := False;
         begin
            build_the_list_of_AUR_Packages:
            begin
               for Each of AUR_Folder
               loop
                  declare
                     use ada.Directories;
                  begin
                     if    simple_Name (Each) /= ".."
                       and simple_Name (Each) /= "."
                       and Kind        (Each) /= ada.Directories.Directory
                     then
                        Packages.append (full_Name (Each));
                     end if;
                  end;
               end loop;
            end build_the_list_of_AUR_Packages;


            if not ada.Directories.Exists ("aur_install_order")
            then
               recreate_install_Order := True;
            else
               declare
                  use lace.Text.utility;
                  AUR_install_Order : constant lace.Text.item := to_Text (Filename => "aur_install_order");
               begin
                  for Each of Packages
                  loop
                     if not Contains (AUR_install_Order, Each)
                     then
                        Dlog ("Missing package '" & Each & "' in 'aur_install_order'.");
                        recreate_install_Order := True;
                        exit;
                     end if;
                  end loop;
               end;
            end if;

            Dlog ("***************************************");
            Dlog ("***** Recreating the AUR install order: " & recreate_install_Order'Image);
            Dlog ("***************************************");

            if recreate_install_Order
            then
               install_each_AUR_Package:
               declare
                  install_Order : Strings;
               begin
                  while not Packages.is_Empty
                  loop
                     log (".", new_Line => False);

                     for Each of Packages
                     loop
                        declare
                           full_Name   : constant String := ada.Directories.full_Name (Each);
                           Success     :          Boolean;
                           Output      : constant String := run ("pacman -U --noconfirm " & full_Name,
                                                                 Normal_Exit => Success,
                                                                 in_Chroot   => True);
                        begin
                           Dlog (Output);

                           if Success
                           then
                              log (".", new_Line => False);
                              Dlog ("SUCCESS for '" & full_Name & "'");
                              Dlog ("");
                              Dlog ("");
                              Dlog ("");

                              just_Installed.append (full_Name);
                              install_Order .append (full_Name);
                           end if;
                        end;
                     end loop;

                     rid_Packages_just_installed_from_the_AUR_Packages_list:
                     begin
                        for Each of just_Installed
                        loop
                           Packages.delete (Packages.find_Index (Each));
                        end loop;

                        exit_if_no_Packages_were_just_installed_but_the_Packages_list_is_not_empty:
                        begin
                           if    just_Installed.is_Empty
                             and not   Packages.is_Empty
                           then
                              log ("Error: Failed to install the following packages:");

                              for Each of Packages
                              loop
                                 log (Each);
                              end loop;

                              exit;
                           end if;
                        end exit_if_no_Packages_were_just_installed_but_the_Packages_list_is_not_empty;
                     end rid_Packages_just_installed_from_the_AUR_Packages_list;

                     just_Installed.clear;
                  end loop;

                  save_install_Order:
                  declare
                     use ada.Text_IO;
                     File : File_type;
                  begin
                     create (File, out_File, "aur_install_order");

                     for Each of install_Order
                     loop
                        put_Line (File, Each);
                     end loop;

                     close (File);

                     log ("");
                     log ("New AUR install order file created.");
                  end save_install_Order;
               end install_each_AUR_Package;


            else   -- Not recreating the install order.
               declare
                  use lace.Text;
                  the_Text     : constant lace.Text.item     := forge.to_Text (Filename => "aur_install_order");
                  the_Packages : constant lace.Text.items_64 := all_Lines.Lines (the_Text);
               begin
                  for Each of the_Packages
                  loop
                     declare
                        full_Name : constant String := +Each;
                        Success   :          Boolean;
                        Output    : constant String := run ("pacman -U --noconfirm " & full_Name,
                                                            Normal_Exit => Success,
                                                            in_Chroot   => True);
                     begin
                        Dlog (Output);

                        if Success
                        then
                           log (".", new_Line => False);
                           Dlog ("SUCCESS for '" & full_Name & "'");
                           Dlog ("");
                           Dlog ("");
                           Dlog ("");
                        end if;
                     end;
                  end loop;
               end;
            end if;
         end;

         Dlog (run ("ln -s /usr/lib/libcrypt.so.2 /usr/lib/libcrypt.so.1", in_Chroot => True));     -- Create a link so gnatstudio bin can run.
      end install_AUR_Packages;



      procedure install_desktop_Backgrounds
      is
         use lace.Text;
         Lines : constant lace.Text.items_64 := all_Lines.Lines (forge.to_Text ("miscellaneous_packages"));
      begin
         Dlog ("Installing desktop backgrounds.");
         Dlog ("");

         Dlog (run ("rsync -av --quiet --mkpath custom/usr/share/backgrounds/ /mnt/usr/share/backgrounds"));
      end install_desktop_Backgrounds;



      procedure install_ada_Documents
      is
         use lace.Text;
         Lines : constant lace.Text.items_64 := all_Lines.Lines (forge.to_Text ("miscellaneous_packages"));
      begin
         Dlog ("Installing Ada documents.");
         Dlog ("");

         Dlog (run ("rsync -av --quiet --mkpath custom/usr/share/doc/ada/ /mnt/usr/share/doc/ada"));
      end install_ada_Documents;


   begin
      run ("mount -o remount,size=8G /run/archiso/cowspace");                      -- Increase the size of cowspace.
      run ("rsync -av --quiet custom/var/cache/pacman/pkg /var/cache/pacman");     -- Add the pacman cache for use by 'pacstrap -c' below.

      install_essential_Packages;
      install_miscellaneous_Packages;
      install_AUR_Packages;
      install_desktop_Backgrounds;
      install_ada_Documents;
   end install_Packages;



   procedure configure_the_System (hostName : in String;
                                   userName : in String;
                                   Password : in String;
                                   the_locale_Code     : in String;
                                   the_keyboard_Layout : in String;
                                   the_root_Partition  : in storage.Partition)
   is

      procedure create_Swapfile
      is
         use laceOS.Storage;

         Filename : constant String := "/mnt/laceOS/swapfile";

         -- Swapfile size is set to the same as RAM size.
         Free  : constant long_Integer := Free_in (the_root_Partition);
         RAM   : constant long_Integer := Memory.RAM;
         Size  : constant long_Integer := long_Integer'Min ((Free - 10 * gibiBytes) / 10,     -- 10 GiB is the approximate OS usage.
                                                            RAM);
         Count : constant long_Integer := Size / mebiBytes;
         Image : constant String       := Count'Image;

      begin
         if Size > 2 * gibiBytes
         then
            Dlog (run ("dd if=/dev/zero of=" & Filename & " bs=1M count=" & Image (2 .. Image'Last)));
            Dlog (run ("chmod 0600         " & Filename));
            Dlog (run ("mkswap -U clear    " & Filename));
            Dlog (run ("swapon /laceOS/swapfile",
                       in_Chroot => True));
         end if;
      end create_Swapfile;



      procedure configure_the_Time
      is
      begin
         Dlog ("");
         Dlog ("Setting the timezone.");
         declare
            the_Timezone : constant String := Timezone;
            Filename     : constant String := "/usr/share/zoneinfo/" & the_Timezone;
         begin
            Dlog ("Timezone: " & the_Timezone);
            run ("ln -sf "    & Filename & " /etc/localtime", in_Chroot => True);
         end;

         Dlog ("");
         Dlog ("Generating /etc/adjtime.");
         run ("hwclock --systohc", in_Chroot => True);
      end configure_the_Time;



      procedure configure_the_Locale
      is
      begin
         Dlog ("");
         Dlog ("Generating locale.");

         Dlog ("");
         IO.replace (in_File   => "/mnt/etc/locale.gen",
                     Pattern   => "#" & the_locale_Code,
                     with_Text => the_locale_Code);

         IO.replace (in_File   => "/mnt/etc/locale.gen",
                     Pattern   => "#en_US ISO-8859-1",
                     with_Text =>  "en_US ISO-8859-1");

         IO.replace (in_File   => "/mnt/etc/locale.gen",
                     Pattern   => "#en_US.UTF-8 UTF-8",
                     with_Text =>  "en_US.UTF-8 UTF-8");

         Dlog (run ("locale-gen", in_Chroot => True));

         Dlog ("");
         Dlog ("Creating 'locale.conf'.");

         IO.store (in_File  => "/mnt/etc/locale.conf",
                   the_Text => "LANG=" & the_locale_Code & ".UTF-8");
      end configure_the_Locale;



      procedure set_the_keyboard_Layout
      is
      begin
         if the_keyboard_Layout /= ""
         then
            Dlog ("");
            Dlog ("Setting keyboard console layout.");

            IO.store (in_File  => "/mnt/etc/vconsole.conf",
                      the_Text => "KEYMAP=" & the_keyboard_Layout);
         end if;
      end set_the_keyboard_Layout;



      procedure configure_the_Network
      is
      begin
         Dlog ("");
         Dlog ("Configuring the network.");

         IO.store (in_File  => "/mnt/etc/hostname",     -- TODO: What about /etc/hosts ?
                   the_Text => hostName);

         Dlog ("");
         Dlog ("Configuring the /etc/hosts.");

         IO.replace (in_File   => "/mnt/etc/hosts",
                     Pattern   => "$My_Hostname",
                     with_Text => hostName);

         Dlog ("");
         Dlog ("Enabling the network manager.");
         Dlog (run ("systemctl enable NetworkManager.service", in_Chroot => True));
      end configure_the_Network;



      procedure add_custom_Files_to_etc
      is
      begin
         Dlog (run ("rsync -av --quiet custom/etc/ /mnt/etc"));

         Dlog (run ("chmod --recursive u+x /mnt/etc/skel/Desktop/study/ada/1983"));
         Dlog (run ("chmod --recursive u+x /mnt/etc/skel/Desktop/study/ada/1995"));
         Dlog (run ("chmod --recursive u+x /mnt/etc/skel/Desktop/study/ada/2005"));
         Dlog (run ("chmod --recursive u+x /mnt/etc/skel/Desktop/study/ada/2012"));
         Dlog (run ("chmod --recursive u+x /mnt/etc/skel/Desktop/study/ada/2022"));
      end add_custom_Files_to_etc;



      procedure create_the_User
      is
      begin
         Dlog ("Setting the user name and password.");

         declare
            use ada.Characters;
         begin
            Dlog (run ("useradd -m -G wheel -s /bin/bash " & userName,
                       in_Chroot => True));

            -- Set the user password.
            --
            Dlog (run ("passwd " & userName,
                       Input     =>   Password & latin_1.LF
                                    & Password & latin_1.LF,
                       in_Chroot => True));

            -- Set the root password.
            --
            Dlog (run ("passwd",
                        Input     =>   Password & latin_1.LF
                                     & Password & latin_1.LF,
                        in_Chroot => True));

            -- Allow the user to run 'sudo' without entering a password.
            --
            IO.replace (in_File   => "/mnt/etc/sudoers",
                        Pattern   => "# %wheel ALL=(ALL:ALL) NOPASSWD: ALL",
                        with_Text =>   "%wheel ALL=(ALL:ALL) NOPASSWD: ALL");

            IO.store (in_File  => IO.Filename ("/mnt/home/" & userName & "/.xinitrc"),
                      the_Text => "exec startxfce4");
         end;
      end create_the_User;



      procedure enable_Services
      is
      begin
         --- Lightdm login manager
         --
         Dlog (run ("systemctl enable lightdm.service",
               in_Chroot => True));

         IO.replace (in_File   => "/mnt/etc/lightdm/lightdm.conf",
                     Pattern   => "#greeter-session=example-gtk-gnome",
                     with_Text => "greeter-session=lightdm-slick-greeter");
      end enable_Services;



      procedure install_the_boot_Loader
      is
         use laceOS.storage;
         Id : Natural := 0;
      begin
         Dlog ("");
         Dlog ("Installing the bootloader.");
         Dlog ("");

         -- Allow probing for other operating systems.
         --
         IO.replace (in_File   => "/mnt/etc/default/grub",
                     Pattern   => "#GRUB_DISABLE_OS_PROBER=false",
                     with_Text =>  "GRUB_DISABLE_OS_PROBER=false");

         IO.replace (in_File   => "/mnt/etc/default/grub",
                     Pattern   => "GRUB_DISTRIBUTOR=""Arch""",
                     with_Text => "GRUB_DISTRIBUTOR=""laceOS""");

         for each_Disk of current_Disks
         loop
            for each_Partition of Partitions_of (each_Disk)
            loop
               if not is_Mounted (each_Partition)
               then
                  Id := Id + 1;
                  declare
                     Id_Image : String := Id'Image;
                  begin
                     Id_Image (1) := '/';
                     Dlog (run ("mount --mkdir " & Path_of (each_Partition) & " /mnt" & Id_Image,
                                in_Chroot => True));
                  end;
               end if;
            end loop;
         end loop;

         Dlog (run ("grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB", in_Chroot => True));
         Dlog (run ("rsync -av --quiet custom/boot/grub/ada-mascot.png /mnt/boot/grub"));

         if not ada.Directories.exists ("/mnt/boot/amd-ucode.img")
         then
            Dlog (run ("pacman -S --noconfirm amd-ucode",
                       in_Chroot => True));
         end if;

         Dlog (run ("grub-mkconfig -o /boot/grub/grub.cfg",
                    in_Chroot => True));

         for i in 1 .. Id
         loop
            declare
               Id_Image : String := i'Image;
            begin
               Id_Image (1) := '/';
               Dlog (run ("umount /mnt" & Id_Image, in_Chroot => True));
               Dlog (run ("rmdir  /mnt" & Id_Image, in_Chroot => True));
            end;
         end loop;
      end install_the_boot_Loader;


      use ada.Directories;

   begin
      log ("");
      log ("");
      log ("Configuring the system.");

      Dlog ("");
      Dlog ("Generating the 'fstab'.");

      create_Directory ("/mnt/laceOS");
      create_Swapfile;

      IO.store (in_File  => "/mnt/etc/fstab",
                the_Text => run ("genfstab -U /mnt"));

      configure_the_Time;
      configure_the_Locale;
      set_the_keyboard_Layout;
      add_custom_Files_to_etc;
      configure_the_Network;
      create_the_User;
      enable_Services;
      install_the_boot_Loader;

      Dlog (run ("swapoff /laceOS/swapfile", in_Chroot => True));
      run ("umount -R /mnt");
   end configure_the_System;



   procedure abort_Install
   is
   begin
      Dlog (run ("swapoff /laceOS/swapfile", in_Chroot => True));
      Dlog (run ("umount -R /mnt"));
   end abort_Install;


end laceOS.Installer;
