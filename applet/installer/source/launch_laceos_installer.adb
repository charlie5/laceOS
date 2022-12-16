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

     ada.Text_IO,
     ada.command_Line,
     ada.Directories,
     ada.Characters.handling,
     ada.Exceptions;


procedure launch_laceOS_Installer
is
   use laceOS,
       laceOS.Console,
       laceOS.Commands,
       laceOS.storage,
       laceOS.Logger,
       laceOS.Containers,

       lace.Text,
       lace.Text.forge,

       ada.command_Line,
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

   final_Install : Boolean := False;


begin
   for i in 1 .. argument_Count
   loop
      declare
         the_Argument : constant String := Argument (i);
      begin
         if the_Argument = "final"
         then
            final_Install := True;

         elsif the_Argument = "debug"
         then
            laceOS.Logger.enable_debug_Logging;
         end if;
      end;
   end loop;


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
         use lace.Text.utility;

         default_Code : constant String         := Details.locale_Code;
         locale_gen   : constant lace.Text.item := forge.to_Text (Filename => "/etc/locale.gen");
      begin
         if default_Code = "unknown"
         then
            log ("");
            log ("Locale options are in '/etc/locale.gen'.");
            log ("Choose a locale and then close the mousepad window to continue.");

            Dlog (run ("mousepad /etc/locale.gen"));
            log ("");
         end if;

         loop
            declare
               Code : constant String := Query (Question => "Enter your locale code",
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
   declare
      first_Disk  :          Boolean       := True;
      the_Disks   : constant storage.Disks := laceOS.storage.current_Disks;
      Options     :          Strings;
      disk_Choice :          Positive;

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
            if first_Disk
            then
               first_Disk := False;
               Options.append (Details & " (default)");
            else
               Options.append (Details);
            end if;
         end;
      end loop;

      log ("");
      log ("Choose target disk.");

      disk_Choice := Query (Options);
      the_Disk    := the_Disks (disk_Choice);

      log ("Installing to disk '" & Path_of (the_Disk) & "'.");
      log ("");
      use_entire_Disk := Query_yes_or_no ("The entire disk will be erased ... continue ");

      if not use_entire_Disk
      then
         log ("Aborting installation.");

         delay 2.0;
         return;
      end if;

   end choose_target_Disk;


   laceOS.Commands.run ("umount -R /mnt");     -- Ensure /mnt is unmounted, in case of a failed prior install.

   create_Partition_Table (the_Disk);
   create_EFI_Partition   (the_Disk);

   root_Partition := create_root_Partition (the_Disk);

   mount_root_and_boot_Partitions:
   begin
      Dlog ("");
      Dlog ("Mounting the root partition.");
      mount (root_Partition, "/mnt");

      Dlog ("Mounting the EFI boot partition.");
      mount (EFI_boot_Partition_of (the_Disk),
             "/mnt/boot");
   end mount_root_and_boot_Partitions;

   Installer.install_Packages;
   Installer.rid_unwanted_Packages;
   Installer.tailor_applications_Menu;

   Installer.configure_the_System (hostName            => +hostName,
                                   userName            => +userName,
                                   Password            => +Password,
                                   the_locale_Code     => +locale_Code,
                                   the_keyboard_Layout => +keyboard_Layout,
                                   the_root_Partition  => root_Partition);

   if final_Install
   then
      mount (root_Partition, "/mnt");

      Dlog (run ("rm -fr /mnt/var/cache/pacman/pkg"));
      Dlog (run ("rm -fr /mnt/root/packages/aur"));
      Dlog (run ("rm -fr /mnt/root/packages/builder"));

      Dlog (run ("umount -R /mnt"));
   end if;


   log ("");
   log ("Installation is complete.");
   log ("");
   log ("Press <Enter> to close the installer window.");

   declare
      Unusued : String := ada.Text_IO.get_Line with unreferenced;
   begin
      null;
   end;


exception
   when Installer.no_wifi_Devices =>
      log ("No ethernet or WIFI device detected.");
      log ("Aborting install.");
      delay 2.0;

   when Installer.no_wifi_Networks =>
      log ("No WIFI networks available.");
      log ("Aborting install.");
      delay 2.0;

   when Installer.unable_to_connect_to_WIFI =>
      log ("Unable to connect to WIFI.");
      log ("Aborting install.");
      delay 2.0;

   when Ctrl_C_Error =>
      Installer.abort_Install;
      log ("Install aborted by user.");
      delay 2.0;

   when E : others =>
      log (exception_Information (E));
      Installer.abort_Install;
      delay 2.0;

end launch_laceOS_Installer;
