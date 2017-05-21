using System.Collections.Generic;
using System.ServiceProcess;
using System.Threading.Tasks;
using ASLB_Core.Counters;
using ASLB_Core.Counters.Log;

namespace ASLB_Monitor_Service
{
    public partial class ASLB_Monitor_Service : ServiceBase
    {
        System.Timers.Timer _timer;
        ASLB_Core.DAL.MSSQL.ServiceSettings _serverSettings;

        public ASLB_Monitor_Service()
        {
            InitializeComponent();
        }

        protected override void OnStart(string[] args)
        {
            _timer = new System.Timers.Timer();
            _timer.Elapsed += _timer_Elapsed;
            _timer.Interval = Properties.Settings.Default.CheckInterval;
            _timer.Enabled = true;
            _serverSettings = new ASLB_Core.DAL.MSSQL.ServiceSettings(Properties.Settings.Default.SQLServerConnectionString);
            WriteNewSettings();
        }

        private void WriteNewSettings()
        {
            Properties.Settings.Default.ServerDatabaseList = _serverSettings.Get_Server_List();
            Properties.Settings.Default.PerformanceCounters = _serverSettings.Get_PerformanceCounter_List();
            Properties.Settings.Default.Save();
            Properties.Settings.Default.Reload();
        }

        private void _timer_Elapsed(object sender, System.Timers.ElapsedEventArgs e)
        {
            string servers = Properties.Settings.Default.ServerDatabaseList; //"STG-VA01.eyeblaster.com;Analytics4|STG-VA02.eyeblaster.com;Analytics4";
            string CountersList = Properties.Settings.Default.PerformanceCounters;//"Processor;% Processor Time;_Total|Memory;Available MBytes;|MSAS11:Connection;Current connections|MSAS11:Connection;Failures/sec|MSAS11:Connection;Requests/sec|MSAS11:Connection;Successes/sec|MSAS11:Connection;Current user sessions|MSAS11:Memory;Memory Usage KB|MSAS11:Memory;Memory Limit Low KB|MSAS11:Memory;Memory Limit High KB|MSAS11:Memory;Memory Limit Hard KB";

            string SQLServerConnectionString = Properties.Settings.Default.SQLServerConnectionString; // "Data Source=STG-OLAPDB;Failover Partner=STG-OLAPDB;Initial Catalog=SMK_ASLB;Integrated Security=True";

            int Timeoutvalue = Properties.Settings.Default.CheckTimeout;
            char CountersListChar = '|';
            SortedList<string, Server_Data> ServerDataCollection = new SortedList<string, Server_Data>();

            Task[] taskarray = new Task[servers.Split(CountersListChar).Length];
            for (int i = 0; i < taskarray.Length; i++)
            {
                ServerDataCollection.Add(servers.Split(CountersListChar)[i].Split(';')[0], new Server_Data(servers.Split(CountersListChar)[i].Split(';')[0], servers.Split(CountersListChar)[i].Split(';')[1], CountersList, CountersListChar));

                taskarray[i] = Task.Factory.StartNew(
                    (object obj) => {
                        Server_Data sd = obj as Server_Data;
                        if (sd == null) return;
                        sd.CollectData(Timeoutvalue);
                    }, ServerDataCollection[servers.Split(CountersListChar)[i].Split(';')[0]]
                     );
            }
            Task.WaitAll(taskarray);
            DB_Logger dbl = new DB_Logger(SQLServerConnectionString);

            foreach (Server_Data sd in ServerDataCollection.Values)
            {
                dbl.write_performance_counters(sd.serverdatalog);
            }
            
        }

        protected override void OnStop()
        {
            _timer.Enabled = false;
            _timer.Dispose();
        }
    }
}
