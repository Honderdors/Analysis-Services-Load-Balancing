namespace ASLB_Monitor_Service
{
    partial class ASLB_Monitor_Installer
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary> 
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Component Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.ASLB_Installer = new System.ServiceProcess.ServiceInstaller();
            this.ASLB_Process_Installer = new System.ServiceProcess.ServiceProcessInstaller();
            // 
            // ASLB_Installer
            // 
            this.ASLB_Installer.DelayedAutoStart = true;
            this.ASLB_Installer.Description = "ASLB Monitor";
            this.ASLB_Installer.DisplayName = "ASLB Monitor";
            this.ASLB_Installer.ServiceName = "ASLB Monitor";
            this.ASLB_Installer.StartType = System.ServiceProcess.ServiceStartMode.Automatic;
            // 
            // ASLB_Process_Installer
            // 
            this.ASLB_Process_Installer.Password = null;
            this.ASLB_Process_Installer.Username = null;
            // 
            // ASLB_Monitor_Installer
            // 
            this.Installers.AddRange(new System.Configuration.Install.Installer[] {
            this.ASLB_Installer,
            this.ASLB_Process_Installer});

        }

        #endregion

        public System.ServiceProcess.ServiceInstaller ASLB_Installer;
        public System.ServiceProcess.ServiceProcessInstaller ASLB_Process_Installer;
    }
}