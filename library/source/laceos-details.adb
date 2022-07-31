with
     laceOS.Commands,
     ada.Strings.fixed;


package body laceOS.Details
is

   the_Keymaps : Strings;

   function Keymaps return Strings
   is
   begin
      return the_Keymaps;
   end Keymaps;



   the_Regions : Strings;

   function Regions return Strings
   is
   begin
      return the_Regions;
   end Regions;



   function Timezone return String
   is
      use laceOS.Commands;
   begin
      return run ("curl https://ipapi.co/timezone");
   end Timezone;



   function locale_Code return String
   is
      use ada.Strings.fixed;
      the_Timezone : constant String  := Timezone;
      Slash        : constant Natural := Index (the_Timezone, "/");
      Country      : constant String  := (if Slash = 0 then the_Timezone
                                                       else the_Timezone (1 .. Slash - 1));
   begin
      if    Country      = "US"
        or  Country      = "America"            then   return "en_US";
      elsif Country      = "Australia"          then   return "en_AU";
      elsif Country      = "Brazil"             then   return "pt_BR";
      elsif Country      = "Canada"             then   return "en_CA";
      elsif Country      = "Chile"              then   return "es_CL";
      elsif Country      = "Egypt"              then   return "ar_EG";
      elsif Country      = "Hongkong"           then   return "en_HK";
      elsif Country      = "Iceland"            then   return "is_IS";
      elsif Country      = "Iran"               then   return "az_IR";
      elsif Country      = "Israel"             then   return "he_IL";
      elsif Country      = "Japan"              then   return "ja_JP";
      elsif Country      = "Mexico"             then   return "es_MX";
      elsif Country      = "Netherlands"        then   return "nl_NL";
      elsif Country      = "NZ"                 then   return "en_NZ";
      elsif Country      = "Poland"             then   return "pl_PL";
      elsif Country      = "Portugal"           then   return "pt_PT";
      elsif Country      = "Singapore"          then   return "zh_SG";
      elsif Country      = "Turkey"             then   return "tr_TR";

      elsif the_Timezone = "Europe/Belfast"     then   return "en_GB";
      elsif the_Timezone = "Europe/Berlin"      then   return "de_DE";
      elsif the_Timezone = "Europe/Dublin"      then   return "en_GB";
      elsif the_Timezone = "Europe/London"      then   return "en_GB";
      elsif the_Timezone = "Europe/Madrid"      then   return "es_ES";
      elsif the_Timezone = "Europe/Moscow"      then   return "ru_RU";
      elsif the_Timezone = "Europe/Paris"       then   return "fr_FR";
      elsif the_Timezone = "Europe/Rome"        then   return "it_IT";
      elsif the_Timezone = "Europe/Vatican"     then   return "it_IT";
      elsif the_Timezone = "Europe/Vienna"      then   return "it_IT";

      elsif the_Timezone = "Pacific/Auckland"   then   return "en_NZ";
      elsif the_Timezone = "Pacific/Fiji"       then   return "en_FJ";
      else                                             return "unknown";
      end if;
   end locale_Code;



   function country_Code (Country : in String) return String
   is
   begin
      if    Country = "Australia"            then   return "AU";
      elsif Country = "Belgium"              then   return "BE";
      elsif Country = "Brazil"               then   return "BR";
      elsif Country = "Bulgaria"             then   return "BG";
      elsif Country = "Cambodia"             then   return "KH";
      elsif Country = "Canada"               then   return "CA";
      elsif Country = "Chile"                then   return "CL";
      elsif Country = "China"                then   return "CN";
      elsif Country = "Congo"                then   return "CG";
      elsif Country = "Croatia"              then   return "HR";
      elsif Country = "Cuba"                 then   return "CU";
      elsif Country = "Denmark"              then   return "DK";
      elsif Country = "Ecuador"              then   return "EC";
      elsif Country = "Egypt"                then   return "EG";
      elsif Country = "Ethiopia"             then   return "ET";
      elsif Country = "Fiji"                 then   return "FJ";
      elsif Country = "Finland"              then   return "FI";
      elsif Country = "France"               then   return "FR";
      elsif Country = "Germany"              then   return "DE";
      elsif Country = "Greece"               then   return "GR";
      elsif Country = "Greenland"            then   return "GL";
      elsif Country = "Haiti"                then   return "HT";
      elsif Country = "Hong Kong"            then   return "HK";
      elsif Country = "Hungary"              then   return "HU";
      elsif Country = "Iceland"              then   return "IS";
      elsif Country = "India"                then   return "IN";
      elsif Country = "Indonesia"            then   return "ID";
      elsif Country = "Iran"                 then   return "IR";
      elsif Country = "Iraq"                 then   return "IQ";
      elsif Country = "Ireland"              then   return "IE";
      elsif Country = "Israel"               then   return "IL";
      elsif Country = "Italy"                then   return "IT";
      elsif Country = "Jamaica"              then   return "JM";
      elsif Country = "Japan"                then   return "JP";
      elsif Country = "Korea"                then   return "KP";
      elsif Country = "Kuwait"               then   return "KW";
      elsif Country = "Malaysia"             then   return "MY";
      elsif Country = "Mexico"               then   return "MX";
      elsif Country = "Monaco"               then   return "MC";
      elsif Country = "Mongolia"             then   return "MN";
      elsif Country = "Morocco"              then   return "MA";
      elsif Country = "Nepal"                then   return "NP";
      elsif Country = "Netherlands"          then   return "NL";
      elsif Country = "New Zealand"          then   return "NZ";
      elsif Country = "Norway"               then   return "NO";
      elsif Country = "Pakistan"             then   return "PK";
      elsif Country = "Poland"               then   return "PL";
      elsif Country = "Portugal"             then   return "PT";
      elsif Country = "Qatar"                then   return "QA";
      elsif Country = "Romania"              then   return "RO";
      elsif Country = "Russia"               then   return "RU";
      elsif Country = "Samoa"                then   return "WS";
      elsif Country = "Saudi Arabia"         then   return "SA";
      elsif Country = "Serbia"               then   return "RS";
      elsif Country = "Singapore"            then   return "SG";
      elsif Country = "Slovakia"             then   return "SK";
      elsif Country = "Slovenia"             then   return "SI";
      elsif Country = "Somalia"              then   return "SO";
      elsif Country = "South Africa"         then   return "ZA";
      elsif Country = "Spain"                then   return "ES";
      elsif Country = "Sri Lanka"            then   return "LK";
      elsif Country = "Sudan"                then   return "SD";
      elsif Country = "Sweden"               then   return "SE";
      elsif Country = "Taiwan"               then   return "TW";
      elsif Country = "Thailand"             then   return "TH";
      elsif Country = "Tonga"                then   return "TO";
      elsif Country = "Turkey"               then   return "TR";
      elsif Country = "Uganda"               then   return "UG";
      elsif Country = "Ukraine"              then   return "UA";
      elsif Country = "United Arab Emirates" then   return "AE";
      elsif Country = "Britian"              then   return "GB";
      elsif Country = "America"              then   return "US";
      elsif Country = "Vanuatu"              then   return "VU";
      elsif Country = "Viet Nam"             then   return "VN";
      elsif Country = "Yemen"                then   return "YE";
      elsif Country = "Zambia"               then   return "ZM";
      elsif Country = "Zimbabwe"             then   return "ZW";
      else                                          return "unknown";
      end if;
   end country_Code;


begin

   -----------
   --- Keymaps
   --
   the_Keymaps.append ("ANSI (default)");

   the_Keymaps.append ("amiga-de");
   the_Keymaps.append ("amiga-us");

   the_Keymaps.append ("atari-de");
   the_Keymaps.append ("atari-se");
   the_Keymaps.append ("atari-uk-falcon");
   the_Keymaps.append ("atari-us");

   the_Keymaps.append ("sundvorak");
   the_Keymaps.append ("sunkeymap");

   the_Keymaps.append ("sun-pl");
   the_Keymaps.append ("sun-pl-altgraph");

   the_Keymaps.append ("sunt4-es");
   the_Keymaps.append ("sunt4-fi-latin1");
   the_Keymaps.append ("sunt4-no-latin1");

   the_Keymaps.append ("sunt5-cz-us");
   the_Keymaps.append ("sunt5-es");
   the_Keymaps.append ("sunt5-de-latin1");
   the_Keymaps.append ("sunt5-fi-latin1");
   the_Keymaps.append ("sunt5-fr-latin1");
   the_Keymaps.append ("sunt5-ru");
   the_Keymaps.append ("sunt5-uk");
   the_Keymaps.append ("sunt5-us-cz");

   the_Keymaps.append ("sunt6-uk");


end laceOS.Details;
