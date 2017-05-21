using System;
using System.Collections.Generic;

namespace ASLB_Core.Counters
{
    public class Server_Data_Log
    {
        public string Server_Name;
        public string Database_Name;
        public Guid collectionguid = Guid.NewGuid();
        public DateTime collectiontime = DateTime.UtcNow;
        public SortedList<string, float> PerformanceCounters = new SortedList<string, float>();
        public DateTime StartTime;
        private DateTime endTime;
        /// <summary>
        /// 
        /// </summary>
        public DateTime EndTime
        {
            get
            {
                if (endTime < StartTime)
                {
                    endTime = DateTime.UtcNow;
                }
                return endTime;
            }

            set
            {
                endTime = value;
            }
        }
    }


}

