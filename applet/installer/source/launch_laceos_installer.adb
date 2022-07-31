with
     laceOS.Console,
     laceOS.Storage,
     laceOS.Details,
     laceOS.Commands,
     laceOS.Installer,
     laceOS.Logger,
     laceOS.Containers,

     lace.Text.forge,
     lace.Text.utility,

     gnat.formatted_String,
     gnat.Ctrl_C,

     ada.Directories,
     ada.Characters.handling,
     ada.Exceptions,
     ada.Text_IO;


procedure launch_laceOS_Installer
is
   use laceOS,
       laceOS.Console,
       laceOS.storage,
       laceOS.Logger,
       laceOS.Containers,

       lace.Text,
       lace.Text.forge,

       ada.Exceptions;

   Ctrl_C_Error : exception;

   procedure Ctrl_C_abort
   is
   begin
      Installer.abort_Install;

      log ("");
      log ("Install aborted by user.");

      delay 1.0;
      raise Ctrl_C_Error;
   end Ctrl_C_abort;


   use type laceOS.Storage.boot_Mode_t;

   keyboard_Layout : lace.Text.item_32;
   use_entire_Disk : Boolean;
   the_Disk        : laceOS.storage.Disk;
   root_Partition  : laceOS.storage.Partition;

   hostName    : lace.Text.item_32;
   userName    : lace.Text.item_32;
   Password    : lace.Text.item_32;
   locale_Code : lace.Text.item_16;

begin
   gnat.Ctrl_C.install_Handler (Ctrl_C_abort'unrestricted_Access);


   log ("Welcome to laceOS.");
   log ("");

   if laceOS.storage.boot_Mode /= laceOS.storage.UEFI
   then
      log ("Only UEFI boot is supported.");
      delay 3.0;
      return;
   end if;


   ada.Directories.set_Directory ("/root");


   set_console_keyboard_Layout:
   declare
      Keymaps : constant Strings := Details.Keymaps;
   begin
      Dlog ("Setting console keyboard layout.");
      Dlog ("");
      log ("Choose keyboard layout:");

      declare
         use laceOS.Commands;
         Keymap : constant String := Query (Options => Keymaps);
      begin
         if Keymap /= Keymaps (1)
         then
            keyboard_Layout := +Keymap;
            run ("loadkeys " & Keymap);
         end if;
      end;
   end set_console_keyboard_Layout;


   Installer.setup_Networking;


   query_install_Details:
   begin
      log ("");

      loop
         hostName := to_Text_32 (Query ("Enter your hostname"));
         exit when is_valid_Hostname (+hostName);
      end loop;

      loop
         userName := to_Text_32 (Query ("Enter your username"));
         exit when is_valid_Username (+userName);
      end loop;

      loop
         Password := to_Text_32 (Query ("Enter your password"));
         exit when is_valid_Password (+Password);
      end loop;

      query_locale_Code:
      declare
         use laceOS.Commands,
             lace.Text.utility;

         default_Code : constant String         := Details.locale_Code;
         locale_gen   : constant lace.Text.item := forge.to_Text (Filename => "/etc/locale.gen");
      begin
         if default_Code = ""
         then
            log ("");
            log ("Locale options are in '/etc/locale.gen'.");
            log ("Choose a locale and then close the mousepad window to continue.");

            Dlog (run ("mousepad /etc/locale.gen"));
            log ("");
         end if;

         loop
            declare
               Code : constant String := Query (Question => "Enter locale code",
                                                Default  => default_Code);
            begin
               if Code'Length <= locale_Code.Capacity
               then
                  locale_Code := forge.to_Text_16 (Code);

                  exit when     Code /= ""
                            and Contains (locale_gen, "#" & Code);
               end if;
            end;
         end loop;
      end query_locale_Code;

   end query_install_Details;


   Installer.update_the_system_Clock;


   choose_target_Disk:
   loop
      declare
         the_Disks       : storage.Disks := laceOS.storage.current_Disks;
         Options         : Strings;
         disk_Choice     : Positive;
      begin
         for Each of the_Disks
         loop
            declare
               use ada.Characters.handling,
                   gnat.formatted_String;

               Format    : constant formatted_String := +"%-16s      %5d GiB   %-16s   %s";

               Transport : constant String := (if Transport_of (Each) = Unknown then ""
                                                                                else to_Lower (Transport_of (Each)'Image));
               Details   : constant String := -(Format & Path_of (Each)
                                                       & Integer (Size_of (Each) / gibiBytes)
                                                       & Model_of (Each)
                                                       & Transport);
            begin
               Options.append (Details);
            end;
         end loop;

         log ("");
         log ("Choose target disk.");

         disk_Choice := Query (Options);
         the_Disk    := the_Disks (disk_Choice);

         log ("Installing to disk '" & Path_of (the_Disk) & "'.");
         log ("");
         use_entire_Disk := Query_yes_or_no ("Erase and use the entire disk");

         exit choose_target_Disk when use_entire_Disk;


         Dlog (disk_Choice'Image & " " & table_Kind_of (the_Disk)'Image);

         if table_Kind_of (the_Disk) /= GPT
         then
            log ("Only GPT partition tables are supported.");
            log ("");

            declare
               use laceOS.Commands;

               Choice  : Positive;
               Options : Strings;
            begin
               Options.append ("Customise disks");
               Options.append ("Choose a different disk");

               Choice := Query (Options);

               case Choice
               is
                  when 1 =>
                     log  ("");
                     log  ("Running partition editor.");
                     Dlog (run ("gnome-disks"));

                     the_Disks := laceOS.storage.current_Disks;
                     the_Disk  := the_Disks (disk_Choice);

                  when 2 =>
                     null;

                  when others =>
                     raise program_Error with "Illegal choice.";
               end case;
            end;

         else
            choose_root_Partition:
            begin
               loop
                  declare
                     use laceOS.Commands;

                     the_Partitions   : laceOS.storage.Partitions renames Partitions_of (the_Disk);
                     partition_Choice : Positive;
                     Options          : Strings;
                  begin
                     if the_Partitions'Length = 0
                     then
                        log ("");
                        log ("No partitions found on disk '" & Path_of (the_Disk) & "'.");
                     else
                        for Each of the_Partitions
                        loop
                           declare
                              use ada.Characters.handling,
                                  gnat.formatted_String;

                              Format  : constant formatted_String := +"%-16s      %5d GiB   %-20s   %-20s   %s";
                              Details : constant String           := -(  Format & Path_of (Each)
                                                                       & Integer (Size_of (Each) / gibiBytes)
                                                                       & Label_of     (Each)
                                                                       & type_Name_of (Each)
                                                                       & to_Lower (Filesystem_of (Each)'Image));
                              begin
                                 Options.append (Details);
                              end;
                        end loop;
                     end if;

                     Options.append ("Customise partitions");
                     Options.append ("Choose a different disk");

                     log ("");
                     log ("");
                     log ("Choose target partition.");
                     partition_Choice := Query (Options);

                     if partition_Choice = the_Partitions'Length + 1      -- Custom partitioning option.
                     then
                        log  ("");
                        log  ("Running partition editor.");
                        Dlog (run ("gnome-disks"));

                        the_Disks := laceOS.storage.current_Disks;
                        the_Disk  := the_Disks (disk_Choice);

                        Dlog (disk_Choice'Image & " " & table_Kind_of (the_Disk)'Image);

                        if table_Kind_of (the_Disk) /= GPT
                        then
                           log ("Only GPT partition tables are supported.");
                           exit;
                        end if;

                     elsif partition_Choice = the_Partitions'Length + 2   -- Choose a different disk option.
                     then
                        exit;

                     else
                        root_Partition := the_Partitions (partition_Choice);

                        if root_Partition = EFI_boot_Partition_of (the_Disk)
                        then
                           log ("The EFI boot partition may not be used for the root partition.");
                        else
                           exit choose_target_Disk;
                        end if;
                     end if;
                  end;
               end loop;
            end choose_root_Partition;
         end if;

      end;
   end loop choose_target_Disk;


   laceOS.Commands.run ("umount -R /mnt");     -- Ensure /mnt is unmounted, in case of a failed prior install.

   if use_entire_Disk
   then
      create_Partition_Table (the_Disk);
      create_EFI_Partition   (the_Disk);

      root_Partition := create_root_Partition (the_Disk);
   end if;


   if Filesystem_of (root_Partition) = None
   then
      Dlog ("Formatting the root partition to the ext4 filesystem.");
      laceOS.Commands.run ("mkfs.ext4 " & Path_of (root_Partition));
   end if;


   mount_root_and_boot_Partitions:
   declare
      use laceOS.Commands;
   begin
      Dlog ("");
      Dlog ("Mounting the root partition.");

      mount (root_Partition, "/mnt");
      Dlog  (run ("rm -fr /mnt"));     -- Erase the root partition to remove any pre-existing files.

      Dlog ("Mounting the EFI boot partition.");
      mount (EFI_boot_Partition_of (the_Disk),
             "/mnt/boot");
   end mount_root_and_boot_Partitions;

   --  Installer.create_and_mount_the_root_Partition (root_Partition  => root_Partition,
   --                                                 the_Disk        => the_Disk,
   --                                                 use_entire_Disk => use_entire_Disk);
   Installer.install_Packages;
   Installer.configure_the_System (hostName            => +hostName,
                                   userName            => +userName,
                                   Password            => +Password,
                                   the_locale_Code     => +locale_Code,
                                   the_keyboard_Layout => +keyboard_Layout,
                                   the_root_Partition  => root_Partition);
   log ("");
   log ("Installation is complete.");
   log ("Remove the installation media and press <Enter> to shutdown.");

   declare
      use laceOS.Commands;
      Unused : String := ada.Text_IO.get_Line;
   begin
      log ("Shutting down.");
      delay 1.0;
      Dlog (run ("shutdown now"));
   end;

exception
   when Installer.no_wifi_Devices =>
      log ("No ethernet or WIFI device detected.");
      log ("Aborting install.");

   when Installer.no_wifi_Networks =>
      log ("No WIFI networks available.");
      log ("Aborting install.");

   when Installer.unable_to_connect_to_WIFI =>
      log ("Unable to connect to WIFI.");
      log ("Aborting install.");

   when Ctrl_C_Error =>
      null;

   when E : others =>
      log (exception_Information (E));
      Installer.abort_Install;

end launch_laceOS_Installer;
