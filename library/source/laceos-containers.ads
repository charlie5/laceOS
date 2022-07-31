with
     ada.Containers.indefinite_Vectors;


package laceOS.Containers
--
-- Provides commonly used containers.
--
is
   package String_vectors is new ada.Containers.indefinite_Vectors (Positive, String);
   subtype Strings        is String_vectors.Vector;

end laceOS.Containers;
