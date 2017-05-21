using System;
using System.Data.Sql;
using System.Data.SqlClient;
using System.Data.SqlTypes;

namespace ASLB_Core.DAL.MSSQL
{
    public class ServiceSettings
    {
        private string _ConnectionString = string.Empty;
        private SqlConnection _sqlcon;
        private int _timeout = 60000;

        public ServiceSettings(string Connection)
        {
            _ConnectionString = Connection;
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

        public string Get_Server_List()
        {
            string result = string.Empty;
            SqlDataReader sqldr;
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
            sqlcommand.CommandText = "[setup].[serverlist]";
            try
            {
                sqldr = sqlcommand.ExecuteReader();
                if (sqldr.HasRows)
                {
                    while (sqldr.Read())
                    {
                        result = sqldr.GetValue(0).ToString();
                    }
                }
                sqldr.Close();
                
            }
            catch (SqlException sqlex)
            {

            }

            return result;
        }

        public string Get_PerformanceCounter_List()
        {
            string result = string.Empty;
            SqlDataReader sqldr;
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
            sqlcommand.CommandText = "[setup].[performancecounterlist]";
            try
            {
                sqldr = sqlcommand.ExecuteReader();
                if (sqldr.HasRows)
                {
                    while (sqldr.Read())
                    {
                        result = sqldr.GetValue(0).ToString();
                    }
                }
                sqldr.Close();

            }
            catch (SqlException sqlex)
            {

            }

            return result;
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
