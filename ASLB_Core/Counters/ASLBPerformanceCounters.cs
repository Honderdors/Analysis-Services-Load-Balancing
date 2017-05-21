using System;

using Microsoft.AnalysisServices;

namespace ASLB_Core.Counters.Counters
{
    class ASLB
    {

        private Server _server;
        public int ASLBPerformanceCounters(string ServerName, string CategoryName, string CounterName, string InstanceName, out float CounterValue, out string Description)
        {
            int returncode = 0;
            CounterValue = -2;
            Description = "";
            /*
             * ASLB:Service;Server
             */
            if (CategoryName == "ASLB:Service" && CounterName == "Server")
            {
                CounterValue = ASLB_Service(ServerName, InstanceName, out Description);

            }
            return returncode;
        }
        private float ASLB_Service(string ServerName, string Database, out string Description)
        {
            int returncode = 0;
            Description = "";
            {
                try
                {
                    using (Server svr = new Server())
                    {
                        svr.Connect(new DAL.MSOLAP.ConnectionBuilder(ServerName).getConnection() );
                        if (svr.Databases.FindByName(Database) != null)
                        {
                            returncode = 0;
                            Description = svr.Version.ToString();
                        }
                        else
                        {
                            returncode = 6;
                            Description = "Catalog Not Found";
                        }
                        svr.Disconnect();
                    }

                }
                catch (Exception ex)
                {
                    returncode = 5;
                    Description = ex.Message;
                }
                return returncode;

            }
        }
    }
}
