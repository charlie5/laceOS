--  with
--       ada.Containers.indefinite_Vectors;


package laceOS with Pure
--
-- Provides a namespace and core types for the Lace Operating System (laceOS).
--
is
   kibiBytes : constant := 1024;
   mebiBytes : constant := 1024 * kibiBytes;
   gibiBytes : constant := 1024 * mebiBytes;
   tebiBytes : constant := 1024 * gibiBytes;
   pebiBytes : constant := 1024 * tebiBytes;
   exbiBytes : constant := 1024 * pebiBytes;
   zebiBytes : constant := 1024 * exbiBytes;
   yobiBytes : constant := 1024 * zebiBytes;


   Error : exception;


   function is_valid_Hostname (Name : in String) return Boolean;
   function is_valid_Username (Name : in String) return Boolean;
   function is_valid_Password (Name : in String) return Boolean;

end laceOS;
