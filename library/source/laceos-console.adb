with
     laceOS.Logger,
     ada.Text_IO;


package body laceOS.Console
is

   function Query (Question : in String;
                   Default  : in String := "") return String
   is
      use ada.Text_IO;
   begin
      put (Question);

      if Default /= ""
      then
         put (" (" & Default & ")");
      end if;

      put (": ");

      declare
         Answer : constant String := get_Line;
      begin
         if Answer = ""
         then
            return Default;
         else
            return Answer;
         end if;
      end;
   end Query;



   function Query (Options : in Strings;
                   Default : in Positive := 1) return String
   is
      use laceOS.Logger,
          ada.Text_IO;

      Choice : Positive;
      i      : Natural := 0;
   begin
      log ("");

      for Each of Options
      loop
         i := i + 1;

         if i'Image'Length = 2
         then
            log (" " & i'Image & ") " & Each);
         else
            log (i'Image & ") " & Each);
         end if;
      end loop;

      log ("");
      put ("Choice: ");

      begin
         loop
            declare
               Answer : constant String := get_Line;
            begin
               if Answer = ""
               then
                  Choice := Default;
               else
                  Choice := Positive'Value (Answer);

                  if Choice > Positive (Options.Length)
                  then
                     raise constraint_Error;
                  end if;
               end if;

               exit;

            exception
               when constraint_Error =>
                  null;
            end;
         end loop;
      end;

      return Options (Choice);
   end Query;



   function Query (Options : in Strings;
                   Default : in Positive := 1) return Positive
   is
      use String_vectors;
      Choice : constant String := Query (Options, Default);
   begin
      return find_Index (Options, Choice);
   end Query;



   function Query_yes_or_no (Question : in String) return Boolean
   is
      use ada.Text_IO;
   begin
      put (Question);
      put ("? ");

      loop
         declare
            Answer : constant String := get_Line;
         begin
            if    Answer = "yes"
               or Answer = "y"
            then
               return True;

            elsif Answer = "no"
               or Answer = "n"
            then
               return False;
            end if;
         end;
      end loop;
   end Query_yes_or_no;


end laceOS.Console;
