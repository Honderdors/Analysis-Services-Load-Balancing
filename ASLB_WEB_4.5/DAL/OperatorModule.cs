using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.SessionState;
using System.Web.Security;
/// <summary>
/// Summary description for OperatorModule
/// </summary>

public class OperatorModule  : IHttpModule
{
    string Params = string.Empty;
    public void Dispose() { }

    public void Init(HttpApplication context)
    {
        //context.PostAcquireRequestState += new EventHandler(Application_PostAcquireRequestState);
        //context.PostMapRequestHandler += new EventHandler(Application_PostMapRequestHandler);
        context.PostAuthorizeRequest += new EventHandler(context_BeginRequest);
        //context.BeginRequest += new EventHandler(context_BeginRequest);
        //Params = context.Request.QueryString.ToString();
        
    }
    void Application_PostAcquireRequestState(object source, EventArgs e)
    {
        HttpApplication app = (HttpApplication)source;

        OperatorModule_HttpHandler resourceHttpHandler = HttpContext.Current.Handler as OperatorModule_HttpHandler;

        if (resourceHttpHandler != null)
        {
            // set the original handler back
            HttpContext.Current.Handler = resourceHttpHandler.OriginalHandler;
        }

        // -> at this point session state should be available


    }
    void Application_PostMapRequestHandler(object source, EventArgs e)
    {
        HttpApplication app = (HttpApplication)source;

        if (app.Context.Handler is IReadOnlySessionState || app.Context.Handler is IRequiresSessionState)
        {
            // no need to replace the current handler
            return;
        }

        // swap the current handler
        app.Context.Handler = new OperatorModule_HttpHandler(app.Context.Handler);
    }
    void Application_PreAcquireRequestState(object source, EventArgs e)
    {

    }

    void context_BeginRequest(object sender, EventArgs e)
    {
        
        HttpApplication app = sender as HttpApplication;
        
        if (app.Context.Handler is IReadOnlySessionState || app.Context.Handler is IRequiresSessionState)
        {
            // no need to replace the current handler
            return;
        }
        else
        {
            // swap the current handler

            app.Context.Handler = new OperatorModule_HttpHandler(app.Context.Handler);
        }
        bool useHttp = false; /*Need to see if we can change based on requester*/

        string IPAddress = app.Request.UserHostAddress.ToString();

        string UserName = app.User.Identity.Name.ToString();

        // Get key
        string apprequest = app.Request.AppRelativeCurrentExecutionFilePath.ToLower();


        apprequest = apprequest.Substring(2).TrimEnd('/');
        string key = string.Empty;
        string Database = string.Empty;
        if (apprequest != "")
        {
            if (apprequest == "aslbtcp.asmx" || apprequest == "favicon.ico" || apprequest == "default.htm" || apprequest == "state/status.aspx") return;

            key = apprequest.Split('/')[0];
            Database = apprequest.Split('/')[1];
        }
        else
        {
            app.Response.WriteFile("~/state/Status.aspx");
            return;
        }
        // Get Params

        //           if (Params.Length == 0) { Params = Guid.NewGuid().ToString(); }
        Params = app.Request.QueryString.ToString();
        if (app.Context.Session != null)
        {
            if (Params.Length == 0) { Params = app.Session.SessionID; }  else { Params = Guid.NewGuid().ToString(); }
        }

            // Get the URL
            ASLBDataContext DC = new ASLBDataContext();
        
        string URL = "";
        string ResponseBody = "<html><head><title>{2} {3}</title></head><body><h1>{2} {3}</h1><p>See <a href=\"{0}\">{0}</a></p></body></html>";
        try
        {
            DC.GetSession(key, Database, UserName, IPAddress, Params, ref URL, useHttp);
            if (URL == null)
            {
                // No redirect found, send ~/default.htm
                app.Response.StatusCode = 404;
                app.Response.StatusDescription = "Object Not Found";
                app.Response.Output.Write(ResponseBody,
                "Invalid",
                    app.Request.Url,
                    app.Response.StatusCode,
                    app.Response.StatusDescription);
                app.Response.AppendHeader("Location", app.Request.Url.AbsoluteUri);
                //app.Response.WriteFile("~/default.htm");
            }
            else
            {
                if (URL.Contains("http"))
                {
                    //Begin Response
                    app.Response.StatusCode = 307;
                    app.Response.StatusDescription = "Temporary Redirect";
                    app.Response.Output.Write(ResponseBody,
                        URL,
                        app.Request.Url,
                        app.Response.StatusCode,
                        app.Response.StatusDescription);
                    app.Response.AppendHeader("Location", URL);
                    if (!URL.Contains("msmdpump.dll"))
                    {
                        app.Response.Redirect(URL + "?" + Params);
                    }
                }
                else
                {
                    HttpContext.Current.RewritePath(URL,true);
                    
                }
            }
        }
        catch (Exception ex)
        {
            //Begin Response
            app.Response.StatusCode = 500;
            app.Response.StatusDescription = "Internal Server Error";
            app.Response.Output.Write(ResponseBody,
                "Error",
                app.Request.Url,
                app.Response.StatusCode,
                app.Response.StatusDescription);
            app.Response.AppendHeader("Location", URL);
        }
        finally
        {
            app.CompleteRequest();
        }
    }


    // a temp handler used to force the SessionStateModule to load session state
    public class OperatorModule_HttpHandler : IHttpHandler, IRequiresSessionState
    {
        internal readonly IHttpHandler OriginalHandler;

        public OperatorModule_HttpHandler(IHttpHandler originalHandler)
        {
            OriginalHandler = originalHandler;
        }

        public void ProcessRequest(HttpContext context)
        {
            // do not worry, ProcessRequest() will not be called, but let's be safe
            throw new InvalidOperationException("MyHttpHandler cannot process requests.");
        }

        public bool IsReusable
        {
            // IsReusable must be set to false since class has a member!
            get { return false; }
        }
    }

}

