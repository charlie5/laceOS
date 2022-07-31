private
with
     lace.Text.forge;


package laceOS.Storage
--
-- Provides details of disks, partitions and file systems.
--
is
   type partition_table_Kind is (Unknown,
                                 MBR,     -- Master boot record.
                                 GPT);    -- GUID partition table.
   ---------------
   --- Filesystems
   --
   type Filesystem is (Unknown,
                       None,
                       Bcachefs,
                       Btrfs,
                       exFAT,
                       ext2,
                       ext3,
                       ext4,
                       F2FS,
                       FAT32,
                       HFS,
                       HFSplus,
                       JFS,
                       LVM2,
                       Minix,
                       NILFS2,
                       NTFS,
                       Reiser4,
                       ReiserFS,
                       Swap,
                       UDF,
                       vFAT,
                       XFS,
                       ZFS);

   type Filesystems is array (Positive range <>) of Filesystem;



   --------------
   --- Partitions
   --
   type Partition  is private;
   type Partitions is array (Positive range <>) of Partition;

   overriding
   function "="             (Left,
                             Right     : in storage.Partition) return Boolean;
   function  Exists         (Partition : in storage.Partition) return Boolean;
   function  Path_of        (Partition : in storage.Partition) return String;
   function  Label_of       (Partition : in storage.Partition) return String;
   function  type_Name_of   (Partition : in storage.Partition) return String;
   function  Filesystem_of  (Partition : in storage.Partition) return Filesystem;

   function  Size_of        (Partition : in storage.Partition) return long_Integer;    -- In bytes.
   function  Used_in        (Partition : in storage.Partition) return long_Integer;    -- In bytes.
   function  Free_in        (Partition : in storage.Partition) return long_Integer;    -- In bytes.

   function  is_Mounted     (Partition : in storage.Partition) return Boolean;
   function  mount_Point_of (Partition : in storage.Partition) return String;
   procedure mount          (Partition : in storage.Partition;   mount_Point : in String);
   procedure unmount        (Partition : in storage.Partition);

   null_Partition : constant Partition;



   ---------
   --- Disks
   --
   type Disk  is private;
   type Disks is array (Positive range <>) of Disk;


   overriding
   function "="           (Left,
                           Right : in storage.Disk) return Boolean;
   function table_Kind_of (Disk  : in storage.Disk) return partition_table_Kind;
   function Partitions_of (Disk  : in storage.Disk) return Partitions;
   function Path_of       (Disk  : in storage.Disk) return String;
   function Size_of       (Disk  : in storage.Disk) return long_Integer;     -- In bytes.
   function Model_of      (Disk  : in storage.Disk) return String;


   type disk_Transport is (Unknown, Ata, Sata, NVME, Usb);

   function Transport_of (Disk : in storage.Disk) return disk_Transport;


   type boot_Mode_t is (BIOS, UEFI);

   procedure create_Partition_Table (Disk : in out storage.Disk);
   procedure create_EFI_Partition   (Disk : in     storage.Disk);
   function  create_root_Partition  (Disk : in     storage.Disk) return Partition;

   procedure mount_root_Partition   (Disk : in     storage.Disk);
   procedure mount_EFI_Partition    (Disk : in     storage.Disk);


   function  EFI_boot_Partition_of  (Disk : in     storage.Disk) return Partition;



   --------------
   --- OS Details
   --
   function current_Disks return Disks;
   function boot_Mode     return boot_Mode_t;



private

   type Partition is
      record
         Path       : lace.Text.item_32;         -- Device path.
      end record;


   type Disk is
      record
         Path      : lace.Text.item_32;          -- Device path.
         Size      : long_Integer;               -- In bytes.
         Model     : lace.Text.item_64;
         Transport : disk_Transport;
      end record;


   null_Partition : constant Partition := (Path => lace.Text.forge.to_Text_32 (""));


end laceOS.Storage;
