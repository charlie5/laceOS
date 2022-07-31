with
     laceOS.Logger,
     shell.Commands.unsafe,
     ada.Characters.latin_1;


package body laceOS.Commands
is

   function trim (Source : in String) return String     -- TODO: Modify aShell to rid any trailing linefeed (LF) characters.
   is
      use ada.Characters.latin_1;
   begin
      if         Source /= ""
        and then Source (Source'Last) = LF
      then
         return Source (Source'First .. Source'Last - 1);
      end if;

      return Source;
   end Trim;



   function run (command_Line : in String;
                 Input        : in String  := "";
                 in_Chroot    : in Boolean := False) return String
   is
      use laceOS.Logger,
          Shell,
          shell.Commands,
          shell.Commands.unsafe;

      Results    : constant command_Results := run ((if in_Chroot then "arch-chroot /mnt " & command_Line
                                                                  else command_Line),
                                                    +Input);

      the_Output : constant String := +shell.Commands.Output_of (Results);
      the_Errors : constant String := +shell.Commands.Errors_Of (Results);
   begin
      Dlog ("");
      Dlog ("Command line: " & (if in_Chroot then "(chroot) " else "") & "'" & command_Line & "'");

      if the_Output /= ""
      then
         Dlog ("   output: ");
         Dlog ("'" & the_Output & "'");
      end if;

      if the_Errors /= ""
      then
         Dlog ("   errors: '" & the_Errors & "'");
      end if;

      Dlog ("");

      return trim (the_Output);
   end run;



   procedure run (command_Line : in String;
                  Input        : in String  := "";
                  in_Chroot    : in Boolean := False)
   is
      the_Output : constant String := run (command_Line, Input, in_Chroot) with Unreferenced;
   begin
      null;
   end run;



   function  run (command_Line : in     String;
                  in_Chroot    : in     Boolean := False;
                  normal_Exit  :    out Boolean) return String
   is
      use laceOS.Logger,
          Shell,
          shell.Commands,
          shell.Commands.unsafe;

      the_command_Line : constant String    := (if in_Chroot then "arch-chroot /mnt " & command_Line
                                                             else command_Line);
      the_Command      : unsafe.Command     := forge.to_Command (the_command_Line);

      Results    : constant Command_Results := the_Command.run;
      the_Output : constant String          := +shell.Commands.Output_of (Results);
      the_Errors : constant String          := +shell.Commands.Errors_Of (Results);

   begin
      Dlog ("");
      Dlog ("Command line: " & (if in_Chroot then "(chroot) " else "") & "'" & command_Line & "'");

      if the_Output /= ""
      then
         Dlog ("   output: ");
         Dlog ("'" & the_Output & "'");
      end if;

      if the_Errors /= ""
      then
         Dlog ("   errors: '" & the_Errors & "'");
      end if;

      Dlog ("");

      normal_Exit := the_Command.normal_Exit;
      return trim (the_Output);
   end run;


end laceOS.Commands;
