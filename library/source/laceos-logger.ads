--  with
--       ada.Containers.indefinite_Vectors;


package laceOS.Logger
--
-- Provides a for logging messages.
--
is
   procedure  log (Message : in String;   new_Line : in Boolean := True);     -- Log user  messages.
   procedure Dlog (Message : in String;   new_Line : in Boolean := True);     -- Log debug messages.

end laceOS.Logger;
