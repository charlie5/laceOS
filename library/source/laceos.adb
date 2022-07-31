package body laceOS
is

   function is_valid_Hostname (Name : in String) return Boolean
   is
   begin
      if        Name = ""
        or else Name (Name'First) = '-'
      then
         return False;
      end if;

      for Each of Name
      loop
         if Each = '.'
         then
            return False;
         end if;

         if not (   Each in 'a' .. 'z'
                 or Each in '0' .. '9'
                 or Each = '-')
         then
            return False;
         end if;
      end loop;

      return True;
   end is_valid_Hostname;



   function is_valid_Username (Name : in String) return Boolean
   is
   begin
      if        Name = ""
        or else Name (Name'First) in '0' .. '9'
      then
         return False;
      end if;

      for Each of Name
      loop
         if Each = '.'
         then
            return False;
         end if;

         if not (   Each in 'A' .. 'Z'
                 or Each in 'a' .. 'z'
                 or Each in '0' .. '9'
                 or Each = '_')
         then
            return False;
         end if;
      end loop;

      return True;
   end is_valid_Username;



   function is_valid_Password (Name : in String) return Boolean
   is
   begin
      if Name'Length < 8
      then
         return False;
      end if;

      return True;
   end is_valid_Password;


end laceOS;
