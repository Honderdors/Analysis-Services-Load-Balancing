using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Configuration.Install;
using System.Linq;
using System.Threading.Tasks;

namespace ASLB_Monitor_Service
{
    [RunInstaller(true)]
    public partial class ASLB_Monitor_Installer : System.Configuration.Install.Installer
    {
        public ASLB_Monitor_Installer()
        {
            InitializeComponent();
        }
        private void ASLB_Monitor_Installer_AfterInstall(object sender, InstallEventArgs e)
        {

        }

    }
}
