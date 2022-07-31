with
     laceOS.Containers;


package laceOS.Console
--
-- Provides common console subprograms.
--
is
   use laceOS.Containers;

   function Query (Question : in String;
                   Default  : in String := "")  return String;

   function Query (Options  : in Strings;
                   Default  : in Positive := 1) return String;

   function Query (Options  : in Strings;
                   Default  : in Positive := 1) return Positive;

   function Query_yes_or_no
                  (Question : in String)        return Boolean;     -- True if 'yes'.

end laceOS.Console;
