<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Status.aspx.cs" Inherits="Microsoft.ASLB.State.Status" %>

<%@ Register assembly="System.Web.DataVisualization, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" namespace="System.Web.UI.DataVisualization.Charting" tagprefix="asp" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Status Page</title>
</head>
<body>
    <form id="Status" runat="server">
    <div>
    
        <asp:SqlDataSource ID="ASLB" runat="server" ConnectionString="<%$ ConnectionStrings:ASLBConnectionString %>" SelectCommand="SELECT * FROM [setup].[v_services] ORDER BY [service_name],[server_name_fqdn], [database_name]"></asp:SqlDataSource>
        <asp:FormView ID="FormView1" runat="server" DataSourceID="ASLB" Height="181px" Width="341px" AllowPaging="True">
            <EditItemTemplate>
                service_id:
                <asp:TextBox ID="service_idTextBox" runat="server" Text='<%# Bind("service_id") %>' />
                <br />
                service_name:
                <asp:TextBox ID="service_nameTextBox" runat="server" Text='<%# Bind("service_name") %>' />
                <br />
                server_id:
                <asp:TextBox ID="server_idTextBox" runat="server" Text='<%# Bind("server_id") %>' />
                <br />
                server_name_fqdn:
                <asp:TextBox ID="server_name_fqdnTextBox" runat="server" Text='<%# Bind("server_name_fqdn") %>' />
                <br />
                datebase_id:
                <asp:TextBox ID="datebase_idTextBox" runat="server" Text='<%# Bind("datebase_id") %>' />
                <br />
                database_name:
                <asp:TextBox ID="database_nameTextBox" runat="server" Text='<%# Bind("database_name") %>' />
                <br />
                url:
                <asp:TextBox ID="urlTextBox" runat="server" Text='<%# Bind("url") %>' />
                <br />
                loadbalance_id:
                <asp:TextBox ID="loadbalance_idTextBox" runat="server" Text='<%# Bind("loadbalance_id") %>' />
                <br />
                <asp:LinkButton ID="UpdateButton" runat="server" CausesValidation="True" CommandName="Update" Text="Update" />
                &nbsp;<asp:LinkButton ID="UpdateCancelButton" runat="server" CausesValidation="False" CommandName="Cancel" Text="Cancel" />
            </EditItemTemplate>
            <InsertItemTemplate>
                service_id:
                <asp:TextBox ID="service_idTextBox" runat="server" Text='<%# Bind("service_id") %>' />
                <br />
                service_name:
                <asp:TextBox ID="service_nameTextBox" runat="server" Text='<%# Bind("service_name") %>' />
                <br />
                server_id:
                <asp:TextBox ID="server_idTextBox" runat="server" Text='<%# Bind("server_id") %>' />
                <br />
                server_name_fqdn:
                <asp:TextBox ID="server_name_fqdnTextBox" runat="server" Text='<%# Bind("server_name_fqdn") %>' />
                <br />
                datebase_id:
                <asp:TextBox ID="datebase_idTextBox" runat="server" Text='<%# Bind("datebase_id") %>' />
                <br />
                database_name:
                <asp:TextBox ID="database_nameTextBox" runat="server" Text='<%# Bind("database_name") %>' />
                <br />
                url:
                <asp:TextBox ID="urlTextBox" runat="server" Text='<%# Bind("url") %>' />
                <br />
                loadbalance_id:
                <asp:TextBox ID="loadbalance_idTextBox" runat="server" Text='<%# Bind("loadbalance_id") %>' />
                <br />
                <asp:LinkButton ID="InsertButton" runat="server" CausesValidation="True" CommandName="Insert" Text="Insert" />
                &nbsp;<asp:LinkButton ID="InsertCancelButton" runat="server" CausesValidation="False" CommandName="Cancel" Text="Cancel" />
            </InsertItemTemplate>
            <ItemTemplate>
                service_id:
                <asp:Label ID="service_idLabel" runat="server" Text='<%# Bind("service_id") %>' />
                <br />
                service_name:
                <asp:Label ID="service_nameLabel" runat="server" Text='<%# Bind("service_name") %>' />
                <br />
                server_id:
                <asp:Label ID="server_idLabel" runat="server" Text='<%# Bind("server_id") %>' />
                <br />
                server_name_fqdn:
                <asp:Label ID="server_name_fqdnLabel" runat="server" Text='<%# Bind("server_name_fqdn") %>' />
                <br />
                datebase_id:
                <asp:Label ID="datebase_idLabel" runat="server" Text='<%# Bind("datebase_id") %>' />
                <br />
                database_name:
                <asp:Label ID="database_nameLabel" runat="server" Text='<%# Bind("database_name") %>' />
                <br />
                url:
                <asp:Label ID="urlLabel" runat="server" Text='<%# Bind("url") %>' />
                <br />
                loadbalance_id:
                <asp:Label ID="loadbalance_idLabel" runat="server" Text='<%# Bind("loadbalance_id") %>' />
                <br />

            </ItemTemplate>
        </asp:FormView>
    
    </div>
    </form>
</body>
</html>
