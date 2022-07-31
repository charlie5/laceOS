with
     laceOS.Containers;


package laceOS.Details
--
-- Provides information about the operating system.
--
is
   use laceOS.Containers;

   function Keymaps return Strings;
   function Regions return Strings;

   function  Timezone                           return String;     -- Returns the timezone based on the IP address location.
   function   locale_Code                       return String;     -- Returns an empty string if the locale cannot be determined from the IP address location.
   function  country_Code (Country : in String) return String;     -- Returns 'Unknown' if the country is not known.

end laceOS.Details;
