with
     laceOS.Commands,
     lace.Text.all_Lines,
     lace.Text.Cursor;


package body laceOS.Memory
is

   function RAM return long_Integer
   is
      use laceOS.Commands,
          lace.Text,
          lace.Text.Cursor;

      the_Text : constant lace.Text.item        := to_Text (run ("free --bytes"));
      Lines    : constant lace.Text.items_128   := all_Lines.Lines (the_Text);
      C        :          lace.Text.Cursor.item := First (Lines (2)'Access);
      Bytes    : constant long_Integer := C.get_Integer;
   begin
      return Bytes;
   end RAM;


end laceOS.Memory;
