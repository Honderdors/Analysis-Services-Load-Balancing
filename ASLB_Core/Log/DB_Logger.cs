using System;
using System.Collections.Generic;
using System.Data.Sql;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Threading;
namespace ASLB_Core.Counters.Log
{
    public class DB_Logger
    {
        private string _ConnectionString;
        private SqlConnection _sqlcon;
        private int _timeout =60000;


        public DB_Logger(string ConnectionString)
        {
            _ConnectionString = ConnectionString;
            initialize();
        }

        private void initialize()
        {
            _sqlcon = new SqlConnection(_ConnectionString);
            _sqlcon.InfoMessage += _sqlcon_InfoMessage;
            _sqlcon.StateChange += _sqlcon_StateChange;
            _sqlcon.Disposed += _sqlcon_Disposed;
            serverconnect();
        }

        private void serverconnect()
        {
            try
            {
                _sqlcon.Open();
            }
            catch (SqlException sqlex)
            {
            }
            catch (Exception ex)
            {

            }
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="serverlogdata"></param>
        public void write_performance_counters(Server_Data_Log serverlogdata)
        {
            if(serverlogdata != null)
            {
                write_performance_counters(serverlogdata.Server_Name,serverlogdata.Database_Name,serverlogdata.collectionguid,serverlogdata.collectiontime,serverlogdata.StartTime,serverlogdata.EndTime,serverlogdata.PerformanceCounters);
            }
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="Server_Name"></param>
        /// <param name="Database_Name"></param>
        /// <param name="collectionguid"></param>
        /// <param name="collectiontime"></param>
        /// <param name="StartTime"></param>
        /// <param name="EndTime"></param>
        /// <param name="PerformanceCounters"></param>
        public void write_performance_counters(string Server_Name, string Database_Name, Guid collectionguid, DateTime collectiontime, DateTime StartTime, DateTime EndTime, SortedList<string, float> PerformanceCounters)
        {
            int counter = 0;
            foreach (string pc in PerformanceCounters.Keys)
            {
                if (pc != null)
                {
                    string[] _pc = pc.Split(';');
                    if (_pc.Length == 3)
                    {
                        write_performance_counters(Server_Name, Database_Name, collectionguid, collectiontime, StartTime, EndTime, _pc[0], _pc[1], _pc[2], PerformanceCounters.Values[counter]);
                    }
                    if (_pc.Length == 2)
                    {
                        write_performance_counters(Server_Name, Database_Name, collectionguid, collectiontime, StartTime, EndTime, _pc[0], _pc[1], "", PerformanceCounters.Values[counter]);
                    }
                    if (_pc.Length == 1)
                    {
                        write_performance_counters(Server_Name, Database_Name, collectionguid, collectiontime, StartTime, EndTime, _pc[0], "", "", PerformanceCounters.Values[counter]);
                    }
                }
                counter ++;
            }
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="Server_Name"></param>
        /// <param name="Database_Name"></param>
        /// <param name="collectionguid"></param>
        /// <param name="collectiontime"></param>
        /// <param name="StartTime"></param>
        /// <param name="EndTime"></param>
        /// <param name="categoryname"></param>
        /// <param name="countername"></param>
        /// <param name="instancename"></param>
        /// <param name="countervalue"></param>
        public void write_performance_counters(string Server_Name, string Database_Name, Guid collectionguid, DateTime collectiontime, DateTime StartTime, DateTime EndTime,string categoryname, string countername, string instancename, float countervalue)
        {
            SqlCommand sqlcommand;
            if (_sqlcon.State != System.Data.ConnectionState.Open)
            {
                try
                {
                    serverconnect();
                }
                catch (SqlException sqlex)
                {
                }
            }
            sqlcommand = _sqlcon.CreateCommand();
            sqlcommand.CommandTimeout = _timeout;
            sqlcommand.CommandType = System.Data.CommandType.StoredProcedure;
            sqlcommand.CommandText = "[app].[performance_counters]";
            sqlcommand.Parameters.Add(new SqlParameter("@machinename", Server_Name));
            sqlcommand.Parameters.Add(new SqlParameter("@collection_id", collectionguid.ToString()));
            sqlcommand.Parameters.Add(new SqlParameter("@collection_time", collectiontime));
            sqlcommand.Parameters.Add(new SqlParameter("@categoryname", categoryname));
            sqlcommand.Parameters.Add(new SqlParameter("@countername", countername));
            sqlcommand.Parameters.Add(new SqlParameter("@instancename", instancename));
            sqlcommand.Parameters.Add(new SqlParameter("@countervalue", countervalue));
            try
            {
                sqlcommand.ExecuteNonQuery();
            }
            catch (SqlException sqlex)
            {

            }
        }


        private void _sqlcon_Disposed(object sender, EventArgs e)
        {
            throw new NotImplementedException();
        }

        private void _sqlcon_StateChange(object sender, System.Data.StateChangeEventArgs e)
        {
            throw new NotImplementedException();
        }

        private void _sqlcon_InfoMessage(object sender, SqlInfoMessageEventArgs e)
        {
            throw new NotImplementedException();
        }
    }
}
