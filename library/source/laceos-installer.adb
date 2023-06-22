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
     shell.Directories,

     lace.Text.forge,
     lace.Text.utility,
     lace.Text.all_Lines,
     lace.Text.Cursor,

     ada.Directories,
     ada.Strings.unbounded,
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
            C.skip_Line;         -- Skip past header lines.
            C.skip_Line;
            C.skip_Line;
            C.skip_Line;
            C.advance (" ");     -- Skip garbage character in 1st line.

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

      procedure install_pacstrap_Packages
      is
         Count : Natural := 0;
      begin
         run ("rsync -av --quiet /root/packages/pacstrap/ /var/cache/pacman/pkg");

         loop
            declare
               use shell.Commands.unsafe;
               the_Command : shell.Commands.unsafe.Command := Forge.to_Command (  "pacstrap -c /mnt base base-devel linux-lts linux-lts-headers linux-firmware nano networkmanager"
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
      end install_pacstrap_Packages;



      procedure install_extra_Packages
      is
         use lace.Text;
         Lines : constant lace.Text.items_64 := all_Lines.Lines (forge.to_Text ("extra_packages"));
      begin
         Dlog ("Installing extra packages.");
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


         -- Install_ bootloader microcode.

         declare
            use CPU;
         begin
            case CPU.Kind
            is
            when AMD =>
               if not ada.Directories.exists ("/mnt/boot/amd-ucode.img")
               then
                  Dlog (run ("pacman -S --noconfirm amd-ucode",
                        in_Chroot => True));
               end if;

            when Intel =>
               if not ada.Directories.exists ("/mnt/boot/intel-ucode.img")
               then
                  Dlog (run ("pacman -S --noconfirm intel-ucode",
                        in_Chroot => True));
               end if;
            end case;
         end;

      end install_extra_Packages;



      procedure install_AUR_Packages
      is
         Success : Boolean;
      begin
         Dlog ("");   Dlog ("");   Dlog ("");   Dlog ("");
         Dlog ("Installing AUR packages.");
         Dlog ("");
         log  (".", new_Line => False);

         Dlog (run ("mkdir -p /mnt/root/packages"));

         Dlog (run ("rsync -av /root/packages/aur     /mnt/root/packages"));     -- TODO: Use 'mv' ?
         Dlog (run ("rsync -av /root/packages/builder /mnt/root/packages"));
         --  Dlog (run ("rsync -av --quiet /root/packages/aur     /mnt/root/packages"));     -- TODO: Use 'mv' ?
         --  Dlog (run ("rsync -av --quiet /root/packages/builder /mnt/root/packages"));


         install_builder_Packages:
         declare
            use shell.Directories,
                ada.Directories,
                ada.Strings.unbounded;

            Packages       :          Strings;
            builder_Folder : constant shell.Directories.Directory := to_Directory ("/root/packages/builder",
                                                                                   recurse => True);
            all_package_Paths : unbounded_String;

         begin
            for Each of builder_Folder
            loop
               if    simple_Name (Each) /= "."
                 and simple_Name (Each) /= ".."
               then
                  append (all_package_Paths, " " & full_Name (Each));
               end if;
            end loop;

            declare
               Success     :          Boolean;
               --  Output      : constant String := run ("pacman -U --noconfirm " & "/root/packages/builder/*.zst",
               --  Output      : constant String := run ("bash -c ""pacman -U --noconfirm " & "/root/packages/builder/*.zst""",
               Output      : constant String := run ("pacman -U --noconfirm" & to_String (all_package_Paths),
                                                     normal_Exit => Success,
                                                     in_Chroot   => True);
            begin
               Dlog (Output);

               if Success
               then
                  log (".", new_Line => False);
                  Dlog ("SUCCESS for 'Builder packages'.");
                  Dlog ("");
               end if;
            end;

         end install_builder_Packages;


         install_other_Packages:
         declare
            use shell.Directories,
                ada.Directories,
                ada.Strings.unbounded;

            Packages       :          Strings;
            aur_Folder : constant shell.Directories.Directory := to_Directory ("/root/packages/aur",
                                                                               recurse => True);
            all_package_Paths : unbounded_String;

         begin
            for Each of aur_Folder
            loop
               if    simple_Name (Each) /= "."
                 and simple_Name (Each) /= ".."
               then
                  append (all_package_Paths, " " & full_Name (Each));
               end if;
            end loop;

            if Length (all_package_Paths) > 0
            then
               declare
                  Success     :          Boolean;
                  Output      : constant String := run ("pacman -U --noconfirm" & to_String (all_package_Paths),
                                                        normal_Exit => Success,
                                                        in_Chroot   => True);
               begin
                  Dlog (Output);

                  if Success
                  then
                     log (".", new_Line => False);
                     Dlog ("SUCCESS for 'AUR packages'.");
                     Dlog ("");
                  end if;
               end;

            else
               Dlog ("No AUR packages available.");
            end if;
         end install_other_Packages;

      end install_AUR_Packages;



      procedure install_desktop_Backgrounds
      is
      begin
         Dlog ("Installing desktop backgrounds.");
         Dlog ("");

         Dlog (run ("rsync -av --quiet --mkpath custom/usr/share/backgrounds/ /mnt/usr/share/backgrounds"));
      end install_desktop_Backgrounds;



      procedure install_ada_Documents
      is
      begin
         Dlog ("Installing Ada documents.");
         Dlog ("");

         Dlog (run ("rsync -av --quiet --mkpath custom/usr/share/doc/ada/ /mnt/usr/share/doc/ada"));
      end install_ada_Documents;


   begin
      run ("mount -o remount,size=8G /run/archiso/cowspace");                      -- Increase the size of cowspace.
      run ("rsync -av --quiet custom/var/cache/pacman/pkg /var/cache/pacman");     -- Add the pacman cache.

      install_pacstrap_Packages;
      install_extra_Packages;
      install_AUR_Packages;
      install_desktop_Backgrounds;
      install_ada_Documents;
   end install_Packages;



   procedure rid_unwanted_Packages
   is
   begin
      Dlog (run ("pacman -R --noconfirm parole",
            in_Chroot => True));
   end rid_unwanted_Packages;



   procedure tailor_applications_Menu
   is
      use ada.Characters.latin_1,
          ada.Directories;
   begin
      if not exists ("/mnt/usr/share/applications/draw.io.desktop")
      then
         return;    -- AUR packages have not been installed yet.
      end if;


      -- DrawIO Desktop
      --
      IO.replace (in_File   => "/mnt/usr/share/applications/draw.io.desktop",
                  Pattern   => "Name=drawio",
                  with_Text => "Name=DrawIO");

      IO.replace (in_File   => "/mnt/usr/share/applications/draw.io.desktop",
                  Pattern   => "Comment=draw.io desktop",
                  with_Text => "Comment=Diagram Editor");

      IO.replace (in_File   => "/mnt/usr/share/applications/draw.io.desktop",
                  Pattern   => "Categories=Graphics",
                  with_Text => "Categories=Development");

      -- Electron
      --
--      IO.append  (to_File   => "/mnt/usr/share/applications/electron.desktop",
--                  the_Text  => "NoDisplay=true");

      -- Xfce4 Terminal
      --
      IO.replace (in_File   => "/mnt/usr/share/applications/xfce4-terminal.desktop",
                  Pattern   => "Actions=preferences;",
                  with_Text => "Actions=preferences;" & LF &
                               "NoDisplay=true;");
   end tailor_applications_Menu;



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

         Filename : constant String := "/mnt/var/swapfile";

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
            Dlog (run ("swapon /var/swapfile",
                       in_Chroot => True));

            IO.store (in_File  => "/mnt/etc/sysctl.d/99-swappiness.conf",
                      the_Text => "vm.swappiness = 5");
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
         use ada.Characters;
      begin
         Dlog (run ("rsync -av --quiet custom/etc/ /mnt/etc"));

         Dlog (run ("chmod --recursive u+x /mnt/etc/skel/Desktop/study/ada/1983"));
         Dlog (run ("chmod --recursive u+x /mnt/etc/skel/Desktop/study/ada/1995"));
         Dlog (run ("chmod --recursive u+x /mnt/etc/skel/Desktop/study/ada/2005"));
         Dlog (run ("chmod --recursive u+x /mnt/etc/skel/Desktop/study/ada/2012"));
         Dlog (run ("chmod --recursive u+x /mnt/etc/skel/Desktop/study/ada/2022"));
         Dlog (run ("chmod --recursive u+x /mnt/etc/skel/Desktop/study/python"));

         IO.append (to_File  => "/mnt/etc/pam.d/system-login",
                    the_Text => latin_1.LF & "auth optional pam_faildelay.so delay=5000000");
      end add_custom_Files_to_etc;



      procedure add_custom_Files_to_usr
      is
      begin
         Dlog (run ("rsync -av --quiet custom/usr/ /mnt/usr"));
      end add_custom_Files_to_usr;



      procedure create_the_User
      is
      begin
         Dlog (run ("chmod u+x /mnt/etc/skel/Desktop/Awesome\ Ada.desktop"));
         Dlog (run ("chmod u+x /mnt/etc/skel/Desktop/Wikipedia.desktop"));
         Dlog (run ("chmod u+x /mnt/etc/skel/Desktop/Wiktionary.desktop"));

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
         --- Lightdm login manager.
         --
         Dlog (run ("systemctl enable lightdm.service",
                    in_Chroot => True));

         IO.replace (in_File   => "/mnt/etc/lightdm/lightdm.conf",
                     Pattern   => "#greeter-session=example-gtk-gnome",
                     with_Text => "greeter-session=lightdm-slick-greeter");

         --- Uncomplicated firewall.
         --
         Dlog (run ("systemctl enable ufw.service",
                    in_Chroot => True));

      end enable_Services;



      procedure configure_Packages
      is
      begin
         --- Pkgfile.
         --
         Dlog (run ("pkgfile --update",
                    in_Chroot => True));

         --- Uncomplicated Firewall.
         --
         Dlog (run ("ufw enable",
                    in_Chroot => True));
      end configure_Packages;



      procedure configure_root_Access
      is
      begin
         Dlog (run ("passwd --lock root",
                    in_Chroot => True));

         IO.replace (in_File   => "/mnt/etc/ssh/sshd_config",
                     Pattern   => "#PermitRootLogin prohibit-password",
                     with_Text => "PermitRootLogin no");
      end configure_root_Access;



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
         Dlog (run ("rsync -av --quiet custom/boot/grub/ada-2.png /mnt/boot/grub"));

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


   begin
      log ("");
      log ("");
      log ("Configuring the system.");

      Dlog ("");
      Dlog ("Generating the 'fstab'.");

      create_Swapfile;

      IO.store (in_File  => "/mnt/etc/fstab",
                the_Text => run ("genfstab -U /mnt"));

      configure_the_Time;
      configure_the_Locale;
      set_the_keyboard_Layout;
      add_custom_Files_to_etc;
      add_custom_Files_to_usr;
      configure_the_Network;
      create_the_User;
      enable_Services;
      configure_Packages;
      configure_root_Access;
      install_the_boot_Loader;

      Dlog (run ("swapoff /var/swapfile", in_Chroot => True));
      run ("umount -R /mnt");
   end configure_the_System;



   procedure abort_Install
   is
   begin
      Dlog (run ("swapoff /var/swapfile", in_Chroot => True));
      Dlog (run ("umount -R /mnt"));
   end abort_Install;


end laceOS.Installer;
