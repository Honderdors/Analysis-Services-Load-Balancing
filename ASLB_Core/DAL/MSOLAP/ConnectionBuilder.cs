using System;


namespace ASLB_Core.Counters.DAL.MSOLAP
{

    public class ConnectionBuilder
    {
        string _servername = string.Empty;
        string _catalog = string.Empty;
        string _providername = string.Empty;
        string _is = string.Empty;
        string _psi = string.Empty;
        public ConnectionBuilder()
        {
            _servername = "LOCALHOST";
            _providername = "MSOLAP";
            _is = "SSPI";
            _psi = "false";

        }
        public ConnectionBuilder(string ServerName)
        {
            _servername = ServerName;
            _providername = "MSOLAP";
            _is = "SSPI";
            _psi = "false";
        }
        public ConnectionBuilder(string ServerName, string Catalog)
        {
            _servername = ServerName;
            _providername = "MSOLAP";
            _catalog = Catalog;
            _is = "SSPI";
            _psi = "false";
        }
        public string getConnection()
        {


            if (_catalog != null)
            {
                return OlapConnection(_servername, _providername, _is, _psi) + "Initial Catalog=" + _catalog + ";";
            }
            else
            {
                return OlapConnection(_servername, _providername, _is, _psi);
            }
        }
        private static string OlapConnection(string ServerName, string ProviderName, string IS, string PSI)
        {
            return "Provider=" + ProviderName + ";Integrated Security=" + IS + ";Persist Security Info=" + PSI + ";Data Source=" + ServerName + ";Application Name=" + ApplicationInfo.ProductName + ";Workstation ID=" + Environment.MachineName + ";Connect Timeout=" + 60 + ";";
        }

    }
}
