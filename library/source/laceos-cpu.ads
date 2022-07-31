package laceOS.CPU
--
-- Provides details of CPU.
--
is
   type CPU_Kind is (AMD, Intel);

   function Kind return CPU_Kind;


end laceOS.CPU;
