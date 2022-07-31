package laceOS.IO
--
-- Provides ability to manipulate files.
--
is
   type Filename is new String;

   procedure store   (in_File : in Filename;   the_Text  : in String);
   procedure append  (to_File : in Filename;   the_Text  : in String);
   procedure replace (in_File : in Filename;   Pattern   : in String;
                                               with_Text : in String);
end laceOS.IO;
