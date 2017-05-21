using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Threading;
using ASLB_Core.Counters;
using ASLB_Core.Counters.Log;
using ASLB_Core.DAL.MSSQL;
namespace ASLB_Monitor_Console
{
    class Program
    {
        static ServiceSettings _serverSettings;
        static void Main(string[] args)
        {
            Console.Title = ApplicationInfo.ProductName + " Version: " + ApplicationInfo.Version;
            
            Console.WriteLine(ApplicationInfo.ProductName +  " Version: " + ApplicationInfo.Version);
            Console.WriteLine("===========================================================================");

            string SQLServerConnectionString = "Data Source=STG-OLAPDB;Failover Partner=STG-OLAPDB;Initial Catalog=SMK_ASLB;Integrated Security=True";
            _serverSettings = new ServiceSettings(SQLServerConnectionString);

            string servers = _serverSettings.Get_Server_List(); //"STG-VA01.eyeblaster.com|Analytics4;STG-VA02.eyeblaster.com|Analytics4";
            string CountersList = "Processor;% Processor Time;_Total|Memory;Available MBytes;|MSAS11:Connection;Current connections|MSAS11:Connection;Failures/sec|MSAS11:Connection;Requests/sec|MSAS11:Connection;Successes/sec|MSAS11:Connection;Current user sessions|MSAS11:Memory;Memory Usage KB|MSAS11:Memory;Memory Limit Low KB|MSAS11:Memory;Memory Limit High KB|MSAS11:Memory;Memory Limit Hard KB";
            
            

            int Timeoutvalue = 60000;
            char CountersListChar = '|';
            SortedList<string, Server_Data> ServerDataCollection = new SortedList<string, Server_Data>();

            Task[] taskarray = new Task[servers.Split(';').Length];
            for (int i = 0; i < taskarray.Length; i++)
            {
                ServerDataCollection.Add(servers.Split(';')[i].Split('|')[0], new Server_Data(servers.Split(';')[i].Split('|')[0], CountersList, CountersListChar));
                Console.WriteLine("Start Collect Data for : " + servers.Split(';')[i].Split('|')[0]);
                taskarray[i] = Task.Factory.StartNew(
                    (object obj) => {
                            Server_Data sd = obj as Server_Data;
                            if (sd == null) return;
                            sd.CollectData(Timeoutvalue);
                        }, ServerDataCollection[servers.Split(';')[i].Split('|')[0]]
                     );
            }
            Task.WaitAll(taskarray);
            DB_Logger dbl = new DB_Logger(SQLServerConnectionString);
            Console.WriteLine("Logging Data ....");
            foreach (Server_Data sd in ServerDataCollection.Values)
            {
                dbl.write_performance_counters(sd.serverdatalog);
            }
            
            Console.WriteLine("Press any key to exit");
            Console.ReadKey();
        }
    }
}
