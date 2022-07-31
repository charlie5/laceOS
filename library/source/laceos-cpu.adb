with
     laceOS.Commands,
     laceOS.Logger,

     lace.Text.Cursor,

     ada.Strings.fixed,
     ada.Characters.latin_1;


package body laceOS.CPU
is

   the_Kind : CPU.CPU_Kind;

   function Kind return CPU_Kind
   is
   begin
      return the_Kind;
   end Kind;


begin
   declare
      use lace.Text,
          lace.Text.Cursor,
          Commands;

      Output : constant String := run ("lscpu");
      Text   : aliased  lace.Text.item := +Output;
      C      :          lace.Text.Cursor.item := First (Text'Access);
   begin
      C.advance ("Vendor ID:");
      declare
         use ada.Strings.fixed;
         Vendor_Id : constant String := C.next_Token (Delimiter => ada.Characters.latin_1.LF,
                                                      Trim      => True);
      begin
         Logger.Dlog ("'" & Vendor_Id & "'");

         if    Index (Vendor_Id, "AMD")   /= 0 then   the_Kind := AMD;
         elsif Index (Vendor_Id, "Intel") /= 0 then   the_Kind := Intel;
         else
            raise Error with "Unknown CPU Kind: '" & Vendor_Id & "'.";
         end if;
      end;
   end;
end laceOS.CPU;
