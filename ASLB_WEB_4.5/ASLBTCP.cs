using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Services;

/// <summary>
/// Summary description for ASLBTCP
/// </summary>
[WebService(Namespace = "Microsoft.ASLB.ASLBTCP")]
[WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
// To allow this Web Service to be called from script, using ASP.NET AJAX, uncomment the following line. 
// [System.Web.Script.Services.ScriptService]
public class ASLBTCP : System.Web.Services.WebService {

    public ASLBTCP () {

        //Uncomment the following line if using designed components 
        //InitializeComponent(); 
    }

    [WebMethod(EnableSession = true)]
    public string ASLBGetSession(string Service,string DatabaseName, string UserName, string IPAddress, string Params ) {

        try
        {
            //string Service = "CRB";
            // Get the Server Name
            ASLBDataContext DC = new ASLBDataContext();
            string URL = "";
            string URLout = "";
            string[] oDatabaseName = DatabaseName.Split(',');

            foreach (string DB in oDatabaseName)
            {
                URLout = "";
                DC.GetSession(Service,DB, UserName, IPAddress, Params, ref URLout, true);

                if (URL == "")
                    URL = URLout;
                else
                    URL = URL + "," + URLout;
            }

            return URL;
        }
        catch (Exception ex)
        {
            throw (ex);
        }
    }
    
}

