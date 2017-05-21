using System;
using System.Diagnostics;
using System.Threading;

namespace ASLB_Core.Counters.Counters
{
    class Windows
    {
        public int WindowsPerformanceCounters(string ServerName,string CategoryName,string CounterName,string InstanceName, out float CounterValue, out string Description)
        {
            int returncode = 0;
            Description = "";
            CounterValue = -1;
            try
            {
                PerformanceCounter cpuCounter = new PerformanceCounter();

                cpuCounter.CategoryName = CategoryName;
                cpuCounter.CounterName = CounterName;
                cpuCounter.InstanceName = InstanceName;
                cpuCounter.MachineName = ServerName;

                CounterValue = cpuCounter.NextValue();
                Thread.Sleep(1000);
                CounterValue = cpuCounter.NextValue();
                cpuCounter.Close();
                Description = cpuCounter.CounterHelp;
            }
            catch (Exception ex)
            {
                returncode = 6;
                Description = ex.Message;
                CounterValue = -1;
            }
            return returncode;
        }
    }
}
