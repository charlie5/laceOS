package laceOS.Commands
--
-- Provides the ability to run operating system commands.
--
is
   function  run (command_Line : in String;
                  Input        : in String  := "";
                  in_Chroot    : in Boolean := False) return String;     -- Returns the command line output.

   procedure run (command_Line : in String;
                  Input        : in String  := "";
                  in_Chroot    : in Boolean := False);

   function  run (command_Line : in     String;
                  in_Chroot    : in     Boolean := False;
                  normal_Exit  :    out Boolean) return String;          -- Returns the command line output.

end laceOS.Commands;
