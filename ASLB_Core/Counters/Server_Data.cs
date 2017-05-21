using System;

using System.Linq;

using System.Threading.Tasks;

namespace ASLB_Core.Counters
{
    public class Server_Data
    {
        string[] ASLB_Categories = {"ASLB","ASLB:Service"};
        private Server_Data_Log _SDL = new Server_Data_Log();
        private Counters.Counter_Data _CD; 
        private Task[] taskarray;

        private int _Timeout;
        private DateTime _starttime;
        /// <summary>
        /// 
        /// </summary>
        /// <param name="Server_Name"></param>
        /// <param name="CounterList"></param>
        /// <param name="CounterListSplit"></param>
        public Server_Data(string Server_Name,string CounterList,char CounterListSplit)
        {
            _SDL.Server_Name = Server_Name;
            _CD = new Counters.Counter_Data(CounterList, CounterListSplit);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="Server_Name"></param>
        /// <param name="Server_Database"></param>
        public Server_Data(string Server_Name,string Server_Database, string CounterList, char CounterListSplit)
        {
            _SDL.Server_Name = Server_Name;
            _SDL.Database_Name = Server_Database;
            _CD = new Counters.Counter_Data(CounterList, CounterListSplit);

        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="Timeout"></param>
        public void CollectData(int Timeout)
        {
            string consolestring = string.Empty;
            taskarray = new Task[_CD.GetNumberOfCounters];
            _Timeout = Timeout;
            _starttime = DateTime.UtcNow;

            Task.Factory.StartNew(() => HandleTimer()).Wait(Timeout);
            //TODO: write to log
        }
        /// <summary>
        /// get a populated set of server log data
        /// </summary>
        public Server_Data_Log serverdatalog
        {
            get { return _SDL; }
        }

        private float getperformancecounter(string CategoryName,string CounterName,string InstanceName)
        {
            float CounterValue;
            string Description;
            Counters.Windows wpc = new Counters.Windows();
            Counters.ASLB aslbpc = new Counters.ASLB();
            if (ASLB_Categories.Contains(CategoryName) == false)
            {
                wpc.WindowsPerformanceCounters(_SDL.Server_Name, CategoryName, CounterName, InstanceName, out CounterValue, out Description);
            }
            else
            {
                aslbpc.ASLBPerformanceCounters(_SDL.Server_Name, CategoryName, CounterName, InstanceName, out CounterValue, out Description);
            }
            return CounterValue;
        }
        /// <summary>
        /// LowMemoryLimit	
        /// For multidimensional instances, a lower threshold at which the server first begins releasing memory allocated to infrequently used objects.
        /// Memory Limit High KB
        /// 
        /// HardMemoryLimit	
        /// Another threshold at which Analysis Services begins rejecting requests outright due to memory pressure.
        /// </summary>
        /// <returns></returns>
        private void HandleTimer()
        {

            _SDL.StartTime = DateTime.UtcNow;
            for(int i =0; i< taskarray.Length; i++)
            {
                if (i < taskarray.Length)
                {
                    taskarray[i] = Task.Factory.StartNew(
                            (object obj) =>
                            {
                                Counters.Counter_Data CounterData = obj as Counters.Counter_Data;
                                if (CounterData == null) return;
                                _SDL.PerformanceCounters.Add(CounterData.CounterKey(0), getperformancecounter(CounterData.CategoryName(0), CounterData.CounterName(0), CounterData.InstanceName(0)));
                            }
                            ,
                             new Counters.Counter_Data(_CD.CounterKey(i))
                            
                            );
                }
            }

            SetWaitTime();

            Task.WaitAll(taskarray);
            _SDL.EndTime = DateTime.UtcNow;

        }

        private void SetWaitTime()
        {
            foreach (Task t in taskarray)
            {
                t.Wait(_Timeout);
            }
        }



    }
}
