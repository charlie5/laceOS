with
     laceOS.Commands,
     laceOS.Logger,

     lace.Text.all_Lines,
     lace.Text.Cursor,

     ada.numerics.discrete_Random,
     --  ada.Characters.latin_1,
     ada.Directories;


package body laceOS.Storage
is

   --------------
   --- Partitions
   --

   overriding
   function "=" (Left, Right : in storage.Partition) return Boolean
   is
   begin
      return Path_of (Left) = Path_of (Right);
   end "=";



   function Exists (Partition : in storage.Partition) return Boolean
   is
      use lace.Text;
   begin
      return +Partition.Path /= "";
   end Exists;



   function Path_of (Partition : in storage.Partition) return String
   is
      use lace.Text;
   begin
      return +Partition.Path;
   end Path_of;



   function Size_of (Partition : in storage.Partition) return long_Integer
   is
      use laceOS.Commands;
      Size : constant String := run ("lsblk --noheadings --bytes --ascii --output Size " & Path_of (Partition));
   begin
      return long_Integer'Value (Size);
   end Size_of;



   function is_Mounted (Partition : in storage.Partition) return Boolean
   is
   begin
      return mount_Point_of (Partition) /= "";
   end is_Mounted;



   function mount_Point_of (Partition : in storage.Partition) return String
   is
      use laceOS.Commands;
      mount_Point : constant String := run ("lsblk --noheadings --ascii --output mountPoint " & Path_of (Partition));
   begin
      return mount_Point;
   end mount_Point_of;



   procedure mount (Partition : in storage.Partition;   mount_Point : in String)
   is
      use laceOS.Commands,
          laceOS.Logger;

      partition_Path : constant String := Path_of (Partition);
   begin
      Dlog ("Mounting '"    & partition_Path & "' partition at '" & mount_Point & "'.");
      run ("mount --mkdir " & partition_Path & " "                & mount_Point);
   end mount;



   procedure unmount (Partition : in storage.Partition)
   is
   begin
      if is_Mounted (Partition)
      then
         declare
            use laceOS.Commands,
                laceOS.Logger;

            partition_Path : constant String := Path_of (Partition);
         begin
            Dlog ("Unmounting '" & partition_Path & "' partition at '" & mount_Point_of (Partition) & "'.");
            run  ("umount      " & partition_Path);
         end;
      end if;
   end unmount;



   package random_Integers is new ada.numerics.discrete_Random (long_long_Integer);
   random_Generator : random_Integers.Generator;



   function Value_of (Attribute     : in String;
                      for_Partition : in storage.Partition) return long_Integer
   is
      use ada.Directories;

      was_Mounted : constant Boolean     := is_Mounted (for_Partition);
      Random      : constant String      := random_Integers.Random (random_Generator)'Image;
      mount_Point : constant String      := "/temporary_mount_point_" & Random (2 .. Random'Last);
      Value       :          long_Integer;
   begin
      if not was_Mounted     -- Temporarily mount the partition so we can use 'lsblk' to find the amount used.
      then
         create_Directory (mount_Point);
         mount (for_Partition, mount_Point);
      end if;

      declare
         use laceOS.Commands;
         Output : constant String := run ("lsblk --noheadings --bytes --ascii --output " & Attribute & " " & Path_of (for_Partition));
      begin
         Value := long_Integer'Value (Output);
      end;

      if not was_Mounted
      then
         unmount (for_Partition);
         delete_Directory (mount_Point);
      end if;

      return Value;
   end Value_of;



   function Used_in (Partition : in storage.Partition) return long_Integer
   is
   begin
      return Value_of ("FSUsed", for_Partition => Partition);
   end Used_in;



   function Free_in (Partition : in storage.Partition) return long_Integer
   is
   begin
      return Value_of ("FSAvail", for_Partition => Partition);
   end Free_in;



   function Label_of (Partition : in storage.Partition) return String
   is
      use laceOS.Commands;
      Label : constant String := run ("lsblk --noheadings --bytes --ascii --output PartLabel " & Path_of (Partition));
   begin
      return Label;
   end Label_of;



   function type_Name_of (Partition : in storage.Partition) return String
   is
      use laceOS.Commands;
      Name : constant String := run ("lsblk --noheadings --bytes --ascii --output PartTypeName " & Path_of (Partition));
   begin
      return Name;
   end type_Name_of;



   function Filesystem_of (Partition : in Storage.Partition) return Filesystem
   is
      use laceOS.Commands;
      FS_Name : constant String := run ("lsblk --noheadings --ascii --output FSType " & Path_of (Partition));
   begin
      if    FS_Name = "zfs_member"
      then
         return ZFS;

      elsif FS_Name = "LVM2_member"
      then
         return LVM2;

      elsif FS_Name = ""
      then
         return None;

      else
         return storage.Filesystem'Value (FS_Name);
      end if;

   exception
      when others => raise Error with "Unknown filesystem type: '" & FS_Name & "'.";      -- TODO: Other filesystems..
   end Filesystem_of;



   ---------
   --- Disks
   --

   overriding
   function "=" (Left, Right : in storage.Disk) return Boolean
   is
   begin
      return Path_of (Left) = Path_of (Right);
   end "=";



   function table_Kind_of (Disk : in storage.Disk) return partition_table_Kind
   is
      use laceOS.Commands;
      table_Kind : constant String := run ("lsblk --noheadings --nodeps --ascii --output PTType " & Path_of (Disk));
   begin
      if    table_Kind = "dos" then return MBR;
      elsif table_Kind = "gpt" then return GPT;
      else                          return Unknown;
      end if;
   end table_Kind_of;



   function Partitions_of (Disk : in storage.Disk) return Partitions
   is
      use laceOS.Commands,
          lace.Text;

      the_Partitions  : Partitions (1 .. 50);
      partition_Count : Natural             := 0;
      found_Disk      : Boolean             := False;

      Output : constant String              := run (  "lsblk --noheadings --bytes --pairs --ascii --output Type,Path");
      Lines  : constant lace.Text.items_256 := all_Lines.Lines (+Output);

   begin
      for Each of Lines
      loop
         exit when +Each = "";

         declare
            use lace.Text.Cursor,
                lace.Text.Forge;

            Device : lace.Text.item_8;
            C      : lace.Text.Cursor.item := First (Each'Access);


            function get_Path return lace.Text.item_32
            is
            begin
               C.advance ("PATH=""");
               return to_Text_32 (C.next_Token ('"'));
            end get_Path;


         begin
            C.advance ("TYPE=""");
            Device := to_Text_8 (C.next_Token ('"'));

            if +Device = "disk"
            then
               exit when found_Disk;     -- A different disk has been found, so all partitions for 'Disk' have been added.

               declare
                  disk_Path : constant lace.Text.item_32 := get_Path;
               begin
                  found_Disk := disk_Path = Disk.Path;
               end;

            elsif +Device = "part"
            then
               if found_Disk
               then
                  partition_Count := partition_Count + 1;
                  the_Partitions (partition_Count).Path := get_Path;
               end if;
            end if;
         end;
      end loop;

      return the_Partitions (1 .. partition_Count);
   end Partitions_of;



   function Path_of (Disk : in storage.Disk) return String
   is
      use lace.Text;
   begin
      return +Disk.Path;
   end Path_of;



   function Size_of (Disk : in storage.Disk) return long_Integer
   is
   begin
      return Disk.Size;
   end Size_of;



   function Model_of (Disk : in storage.Disk) return String
   is
      use lace.Text;
   begin
      return +Disk.Model;
   end Model_of;



   function Transport_of (Disk : in storage.Disk) return disk_Transport
   is
   begin
      return Disk.Transport;
   end Transport_of;



   procedure create_Partition_Table (Disk : in out storage.Disk)
   is
      use laceOS.Commands,
          laceOS.Logger,
          lace.Text;

      install_Disk : constant String := +Disk.Path;

   begin
      Dlog ("");
      Dlog ("Adding a GUID Partition Table (GPT).");
      run ("parted --script " & install_Disk & " mklabel gpt");
   end create_Partition_Table;



   procedure create_EFI_Partition (Disk : in storage.Disk)
   is
      use laceOS.Commands,
          laceOS.Logger,
          lace.Text;

      install_Disk : constant String := +Disk.Path;

   begin
      Dlog ("");
      Dlog ("Adding an EFI system partition.");
      run ("parted " & install_Disk & " mkpart ""EFI system partition"" fat32 1MiB 301MiB");

      Dlog ("");
      Dlog ("Making the EFI system partition bootable.");
      run ("parted " & install_Disk & " set 1 esp on");

      Dlog ("");
      Dlog ("Formatting the EFI system partition.");
      run ("mkfs.fat -F 32 " & install_Disk & "1");
   end create_EFI_Partition;



   function create_root_Partition (Disk : in storage.Disk) return Partition
   is
      use laceOS.Commands,
          laceOS.Logger,
          lace.Text;

      install_Disk : constant String   := +Disk.Path;
      Root         :          Partition;
   begin
      Dlog ("");
      Dlog ("Adding the root partition.");
      run  ("parted " & install_Disk & " mkpart ""root partition"" ext4 301MiB 100%");

      Dlog ("");
      Dlog ("Formatting the root partition.");
      run  ("mkfs.ext4 " & install_Disk & "2");

      Root.Path := to_Text (install_Disk & "2",
                            Capacity => Root.Path.Capacity);
      return Root;
   end create_root_Partition;



   procedure mount_root_Partition (Disk : in storage.Disk)
   is
      use laceOS.Commands,
          laceOS.Logger,
          lace.Text;

      install_Disk : constant String := +Disk.Path;

   begin
      Dlog ("");
      Dlog ("Mounting the root partition.");
      run ("mount " & install_Disk & "2 /mnt");
   end mount_root_Partition;



   procedure mount_EFI_Partition (Disk : in storage.Disk)
   is
      use laceOS.Commands,
          laceOS.Logger,
          lace.Text;

      install_Disk : constant String := +Disk.Path;

   begin
      Dlog ("");
      Dlog ("Mounting the EFI boot partition.");
      run ("mount --mkdir " & install_Disk & "1 /mnt/boot");
   end mount_EFI_Partition;



   function EFI_boot_Partition_of (Disk : in storage.Disk) return Partition
   is
      use laceOS.Logger;
   begin
      for Each of Partitions_of (Disk)
      loop
         if    Filesystem_of (Each) = vFAT
           and  type_Name_of (Each) = "EFI System"
         then
            return Each;
         end if;
      end loop;

      Dlog ("Warning: EFI_boot_partition not found.");

      return null_Partition;
   end EFI_boot_Partition_of;



   --------------
   --- OS Details
   --

   function current_Disks return Disks
   is
      use laceOS.Commands,
          lace.Text;

      Disks      : storage.Disks (1 .. 50);
      disk_Count : Natural := 0;

      Output : constant String              := run (  "lsblk --noheadings --bytes --pairs --ascii "
                                                    & "      --output Type,Path,Size,Model,Tran");
      Lines  : constant lace.Text.items_256 := all_Lines.Lines (+Output);

   begin
      for Each of Lines
      loop
         exit when +Each = "";

         declare
            use lace.Text.Cursor,
                lace.Text.Forge;

            Device : lace.Text.item_8;
            C      : lace.Text.Cursor.item := First (Each'Access);

         begin
            C.advance ("TYPE=""");
            Device := to_Text_8 (C.next_Token ('"'));

            if +Device = "disk"
            then
               disk_Count := disk_Count + 1;

               declare
                  the_Disk  : storage.Disk renames Disks (disk_Count);
                  Transport : lace.Text.item_8;
               begin
                  C.advance ("PATH=""");
                  the_Disk.Path := to_Text (C.next_Token ('"'),
                                            Capacity => the_Disk.Path.Capacity);
                  C.advance ("SIZE=""");
                  the_Disk.Size := C.get_Integer;

                  C.advance ("MODEL=""");
                  the_Disk.Model := to_Text_64 (C.next_Token ('"'));

                  C.advance ("TRAN=""");
                  Transport := to_Text_8 (C.next_Token ('"'));

                  if    +Transport = "ata"  then   the_Disk.Transport := Ata;
                  elsif +Transport = "sata" then   the_Disk.Transport := Sata;
                  elsif +Transport = "nvme" then   the_Disk.Transport := NVME;
                  elsif +Transport = "usb"  then   the_Disk.Transport := Usb;
                  elsif +Transport = ""     then   the_Disk.Transport := Unknown;
                  else
                     raise Error with "Unknown disk transport type: '" & (+Transport) & "'.";      -- TODO: Other transports.
                  end if;
               end;

            elsif    +Device = "rom"
                  or +Device = "loop"
                  or +Device = "part"
            then
               null;

            else
               raise Error with "Unknown device type: '" & (+Device) & "'.";        -- TODO: Other device types.
            end if;
         end;
      end loop;


      return Disks (1 .. disk_Count);
   end current_Disks;



   function boot_Mode return boot_Mode_t
   is
      use laceOS.Commands;
      the_Output : constant String := run ("ls /sys/firmware/efi/efivars");
   begin
      if the_Output = "" then return BIOS;
                         else return UEFI;
      end if;
   end boot_Mode;


begin
   random_Integers.reset (random_Generator);
end laceOS.Storage;
