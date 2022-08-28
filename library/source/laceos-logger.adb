with
     ada.Text_IO;


package body laceOS.Logger
is

   procedure  log (Message : in String;   new_Line : in Boolean := True)
   is
      use ada.Text_IO;
   begin
      if new_Line
      then
         put_Line (Message);
      else
         put (Message);
      end if;
   end log;



    Debug : constant Boolean := True;
   --  Debug : constant Boolean := False;

   procedure Dlog (Message : in String;   new_Line : in Boolean := True)
   is
   begin
      if Debug
      then
         log (Message, new_Line);
      end if;
   end Dlog;


end laceOS.Logger;
