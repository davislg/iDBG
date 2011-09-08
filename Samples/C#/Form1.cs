using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using System.Windows.Forms;
using System.Data;
using System.IO;

namespace WindowsApplication1
{
	/// <summary>
	/// Summary description for Form1.
	/// </summary>
	public class Form1 : System.Windows.Forms.Form
	{		
		private System.Windows.Forms.ListBox listBox1;
		private iDbg.CDebuggerClass dbg = new iDbg.CDebuggerClass(); 
		private System.Windows.Forms.Button button1;
		private System.Windows.Forms.TextBox textBox1;
		private System.Windows.Forms.TextBox textBox2;
		private System.Windows.Forms.Label label1;
		private System.Windows.Forms.Label label2;
		private System.Windows.Forms.Label label3;

		private iDbg.DebugDecisions DBG_CONTINUE =  iDbg.DebugDecisions.DBG_CONTINUE;
		private iDbg.DebugDecisions DBG_DONT_HANDLE =  iDbg.DebugDecisions.DBG_EXCEPTION_NOT_HANDLED; 
		private System.Windows.Forms.Label label4;
		private System.Windows.Forms.ListBox listBox2;
		private System.Windows.Forms.Label label5;
		 
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.Container components = null;

		public Form1()
		{
			//
			// Required for Windows Form Designer support
			//
			InitializeComponent();

			//
			// TODO: Add any constructor code after InitializeComponent call
			//
		}

		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		protected override void Dispose( bool disposing )
		{
			if( disposing )
			{
				if (components != null) 
				{
					components.Dispose();
				}
			}
			base.Dispose( disposing );
		}

		#region Windows Form Designer generated code
		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{
			this.listBox1 = new System.Windows.Forms.ListBox();
			this.button1 = new System.Windows.Forms.Button();
			this.textBox1 = new System.Windows.Forms.TextBox();
			this.textBox2 = new System.Windows.Forms.TextBox();
			this.label1 = new System.Windows.Forms.Label();
			this.label2 = new System.Windows.Forms.Label();
			this.label3 = new System.Windows.Forms.Label();
			this.label4 = new System.Windows.Forms.Label();
			this.listBox2 = new System.Windows.Forms.ListBox();
			this.label5 = new System.Windows.Forms.Label();
			this.SuspendLayout();
			// 
			// listBox1
			// 
			this.listBox1.Location = new System.Drawing.Point(8, 56);
			this.listBox1.Name = "listBox1";
			this.listBox1.Size = new System.Drawing.Size(552, 108);
			this.listBox1.TabIndex = 0;
			// 
			// button1
			// 
			this.button1.Location = new System.Drawing.Point(440, 8);
			this.button1.Name = "button1";
			this.button1.Size = new System.Drawing.Size(120, 24);
			this.button1.TabIndex = 1;
			this.button1.Text = "Launch Process";
			this.button1.Click += new System.EventHandler(this.button1_Click);
			// 
			// textBox1
			// 
			this.textBox1.Location = new System.Drawing.Point(80, 8);
			this.textBox1.Name = "textBox1";
			this.textBox1.Size = new System.Drawing.Size(352, 20);
			this.textBox1.TabIndex = 2;
			this.textBox1.Text = "c:\\iDefense\\iDbg\\test2.exe aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" +
				"aa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
			// 
			// textBox2
			// 
			this.textBox2.Location = new System.Drawing.Point(8, 184);
			this.textBox2.Multiline = true;
			this.textBox2.Name = "textBox2";
			this.textBox2.ScrollBars = System.Windows.Forms.ScrollBars.Both;
			this.textBox2.Size = new System.Drawing.Size(552, 176);
			this.textBox2.TabIndex = 3;
			this.textBox2.Text = "";
			this.textBox2.WordWrap = false;
			// 
			// label1
			// 
			this.label1.Location = new System.Drawing.Point(8, 8);
			this.label1.Name = "label1";
			this.label1.Size = new System.Drawing.Size(56, 16);
			this.label1.TabIndex = 4;
			this.label1.Text = "Exe/Args";
			// 
			// label2
			// 
			this.label2.Location = new System.Drawing.Point(8, 40);
			this.label2.Name = "label2";
			this.label2.Size = new System.Drawing.Size(88, 16);
			this.label2.TabIndex = 5;
			this.label2.Text = "Event Messages";
			// 
			// label3
			// 
			this.label3.Location = new System.Drawing.Point(8, 168);
			this.label3.Name = "label3";
			this.label3.Size = new System.Drawing.Size(128, 16);
			this.label3.TabIndex = 6;
			this.label3.Text = "Exception Enviroment";
			// 
			// label4
			// 
			this.label4.Location = new System.Drawing.Point(8, 368);
			this.label4.Name = "label4";
			this.label4.Size = new System.Drawing.Size(128, 16);
			this.label4.TabIndex = 7;
			this.label4.Text = "DevMsgs";
			// 
			// listBox2
			// 
			this.listBox2.Location = new System.Drawing.Point(8, 384);
			this.listBox2.Name = "listBox2";
			this.listBox2.Size = new System.Drawing.Size(552, 69);
			this.listBox2.TabIndex = 8;
			// 
			// label5
			// 
			this.label5.Location = new System.Drawing.Point(152, 32);
			this.label5.Name = "label5";
			this.label5.Size = new System.Drawing.Size(448, 16);
			this.label5.TabIndex = 9;
			this.label5.Text = "Note: press space at end of demo app for it to reach its crash on ret to see exp " +
				"env";
			// 
			// Form1
			// 
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.ClientSize = new System.Drawing.Size(568, 469);
			this.Controls.Add(this.label5);
			this.Controls.Add(this.listBox2);
			this.Controls.Add(this.label4);
			this.Controls.Add(this.label3);
			this.Controls.Add(this.label2);
			this.Controls.Add(this.label1);
			this.Controls.Add(this.textBox2);
			this.Controls.Add(this.textBox1);
			this.Controls.Add(this.button1);
			this.Controls.Add(this.listBox1);
			this.Name = "Form1";
			this.Text = "Form1";
			this.Load += new System.EventHandler(this.Form1_Load);
			this.ResumeLayout(false);

		}
		#endregion

		/// <summary>
		/// The main entry point for the application.
		/// </summary>
		[STAThread]
		static void Main() 
		{
			Application.Run(new Form1());
		}

		private void Form1_Load(object sender, System.EventArgs e)
		{
			//hook our handlers into the debugger events
			dbg.DllLoad += new iDbg.__CDebugger_DllLoadEventHandler(dbg_DllLoad); 
			dbg.Exception += new iDbg.__CDebugger_ExceptionEventHandler(dbg_Exception);
			dbg.ReadyToRun +=new iDbg.__CDebugger_ReadyToRunEventHandler(dbg_ReadyToRun);
			dbg.Terminate +=new iDbg.__CDebugger_TerminateEventHandler(dbg_Terminate);
			dbg.ThreadCreate += new iDbg.__CDebugger_ThreadCreateEventHandler(dbg_ThreadCreate);
			dbg.ThreadDestroy += new iDbg.__CDebugger_ThreadDestroyEventHandler(dbg_ThreadDestroy);
			dbg.UserBreakpoint += new iDbg.__CDebugger_UserBreakpointEventHandler(dbg_UserBreakpoint);
			dbg.SingleStep += new iDbg.__CDebugger_SingleStepEventHandler(dbg_SingleStep);	
			dbg.DevMessage +=new iDbg.__CDebugger_DevMessageEventHandler(dbg_DevMessage);
			
			String p = Application.ExecutablePath ;
			int a = p.IndexOf("Samples");
			if(a>0){
				p = p.Substring(0,a) + "test2.exe";
				if( File.Exists(p) ) textBox1.Text = p + " AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
			}
			
			dbg.SymbolPath = "f:\\symbols";
			dbg.UseSymbols = true;
			
			 
		}

		private void button1_Click(object sender, System.EventArgs e)
		{
						
			String cmdline = textBox1.Text.ToString();
			dbg.LaunchProcess(cmdline.ToString());

			if( ! dbg.isDebugging )
			{
				listBox1.Items.Add("Failed to launch " + cmdline.ToString());
			}
			else
			{
				listBox1.Items.Add("Process Launched ok");
			}
		}

		private void dbg_ThreadCreate(ref int threadID, ref int startAddress)
		{
			listBox1.Items.Add("ThreadCreated ID " + threadID.ToString());
		}

		private void dbg_ThreadDestroy(ref int threadID, ref int exitCode)
		{
			listBox1.Items.Add("ThreadDestroyed ID " + threadID.ToString());
		}

		private void dbg_UserBreakpoint(ref iDbg.CException except)
		{
			bool validPointer = false;
			int pFormat=0;
			
			int l = dbg.ReadRegister(iDbg.Registers.esp);
			if( dbg.ReadLng(l, ref pFormat) ) validPointer = true;
    
			string msg = "UserBreakpoint @ " + except.ExceptionAddress.ToString("X") +
						  " Disasm = " + except.Disasm +
				          " Esp = " + l.ToString("X") + "  " ;
        
			if( validPointer ) msg +=  dbg.GetMemory(pFormat, true);
			 else msg += dbg.GetMemory(l, true);
    
			listBox1.Items.Add(msg);
			dbg.StepOver();
			
		}

		private void dbg_ReadyToRun()
		{
			listBox1.Items.Add("Ready to run! Setting Breakpoints");
			
			/* fixed bug: can now use stepinto right after bpx */
			if ( !dbg.SetBreakPoint (0x401020,false))
				System.Windows.Forms.MessageBox.Show("Failed to set new bpx");
				     
			
			
			if( !dbg.SetBreakPoint(0x401036, false) ){ //call printf hit 3 times
				listBox1.Items.Add("Failed to set breakpoint on call");
			}
			else{
				listBox1.Items.Add("Set breakpoint at 0x401036 call");
			}
		 
			dbg.Continue(DBG_CONTINUE);

		}

		private void dbg_Exception(ref iDbg.CException except)
		{
			listBox1.Items.Add("Caught Exception At address 0x"+ 
									except.ExceptionAddress.ToString("X") +
								    " Current Inst: " + except.Disasm.ToString() 
								);
			
			if( dbg.LastEventAddress == except.ExceptionAddress && 
				dbg.LastEventCode == (int)except.ExceptionCode)
			{
				dbg.StopDbg();
				listBox1.Items.Add("Crash in same place killing app");
			}
			else
			{
					dbg.Continue(DBG_DONT_HANDLE );
					listBox1.Items.Add("Passing err to seh handlers");
					textBox2.Text += except.Enviroment; 
			}

		}

		public void dbg_DllLoad(ref string s, ref int b, ref int sz)
		{
			String o;
			
			o = "Dll " + s + " loaded at base 0x" + 
					b.ToString("X") + 
					" size: 0x" + sz.ToString("X") ;

			listBox1.Items.Add(o.ToString());
		}

		private void dbg_Terminate()
		{
			listBox1.Items.Add("Debugee Terminated");
		}

		private void dbg_SingleStep(ref iDbg.CException except) {
			string msg = "Single step at addr " + except.ExceptionAddress.ToString("X") +
						 " disasm = " + except.Disasm + 
						 " return value = " + dbg.ReadRegister(iDbg.Registers.Eax).ToString("X");
						
			listBox1.Items.Add(msg);    
			
			if(except.ExceptionAddress <= 0x401024) dbg.StepInto();
			  else dbg.Continue(DBG_CONTINUE);

		}

		private void dbg_DevMessage(ref string func, ref string msg) {
			listBox2.Items.Add( func + " - " + msg);  
		}

	}
}
