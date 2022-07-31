with
     lace.Text.utility,
     lace.Text.forge,
     ada.Text_IO;


package body laceOS.IO
is

   procedure store (in_File : in Filename;   the_Text : in String)
   is
      use ada.Text_IO;
      the_File : File_type;
   begin
      create (the_File, out_File, String (in_File));
      put    (the_File, the_Text);
      close  (the_File);
   end store;



   procedure append (to_File : in Filename;   the_Text : in String)
   is
      use ada.Text_IO;
      the_File : File_type;
   begin
      create (the_File, append_File, String (to_File));
      put    (the_File, the_Text);
      close  (the_File);
   end append;



   procedure replace (in_File : in Filename;   Pattern   : in String;
                                               with_Text : in String)
   is
      use lace.Text,
          lace.Text.utility;

      the_Text : constant String         := forge.to_String (forge.Filename (in_File));
      new_Text :          lace.Text.item := to_Text (the_Text,
                                                     Capacity => 2 * the_Text'Length);

   begin
      replace (new_Text, Pattern => Pattern,
                         By      => with_Text);

      store (in_File, +new_Text);
   end replace;


end laceOS.IO;
