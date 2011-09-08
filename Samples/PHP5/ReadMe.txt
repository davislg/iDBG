
 sample on how to use this COM library from a PHP script.

 I would recommend running the latest php 5.x
 Get the zip file package with php.exe and not just
 the cgi binary so you can run it on the command line.

 then you can run it from a command window like



 c:\php\php.exe -f c:\iDefense\IDbg\Samples\PHP5\IDbg.php





 Debugger Interface Reference:
 --------------------------------------------


CDebugger has had some new methods added since this was first created, 
see src or type lib viewer for details

Class CDebugger

	Enum ExceptionFlags
	    EXCEPTION_CONTINUABLE = 0
	    EXCEPTION_NONCONTINUABLE = 1   '\\ Noncontinuable exception
	End Enum
	
	Enum Registers
	    edi
	    Esi
	    Ebx
	    Edx
	    Ecx
	    Eax
	    ebp
	    eip
	    esp
	End Enum
	
	Enum DebugDecisions
	    DBG_CONTINUE = &H10002
	    DBG_TERMINATE_THREAD = &H40010003
	    DBG_TERMINATE_PROCESS = &H40010004
	    DBG_CONTROL_C = &H40010005
	    DBG_CONTROL_BREAK = &H40010008
	    DBG_EXCEPTION_NOT_HANDLED = &H80010001
	End Enum

	Event ReadyToRun()
	Event Exception(except As CException)
	Event SingleStep(except As CException)
	Event UserBreakpoint(except As CException)
	Event Terminate()
	Event DllLoad(path As String, base As Long, size As Long)
	Event ThreadCreate(threadID As Long, startAddress As Long)
	Event ThreadDestroy(threadID As Long, exitCode As Long)
	Event DevMessage(func As String, msg As String)
	
	Public LastEventAddress As Long
	Public LastEventCode As Long
	Public LoadedFile As String
	Public ActiveThreadID As Long
	Public Threads As New Collection  //thread handles
	Public Modules As Collection      //of CModule Classes (base , path, size)
	Public BreakPoints As Collection  //of CBreakPoint classes
	
	Sub About()
	Function InjectDLL(ByVal dllPath As String) As Boolean
	Sub StepInto()
	Sub StepOver()
	Sub DbgDontHandle()
	Sub DbgContinue()
	Sub Continue(Optional ByVal mode As DebugDecisions = DBG_CONTINUE)
	Property Get isDebugging() As Boolean
	Function isUserBpx(ByVal va As Long, Optional cb As CBreakPoint) As Boolean
	Function SetBreakPoint(ByVal va As Long, Optional ByVal oneShot As Boolean = False) As Boolean
	Function RemoveBreakpoint(ByVal va As Long) As Boolean
	Function LaunchProcess(ByVal path As String) As Boolean
	Sub StopDbg()
	Function GetErr() As String
	Function NameForDebugEvent(ByVal id As DbgEvents) As String
	Function WriteByte(ByVal va As Long, ByVal b As Byte) As Long
	Function ReadByte2(ByVal va As Long, b As Byte) As Boolean
	Function ReadLng(ByVal va As Long, retLng As Long) As Boolean
	Property Get CurrentInstruction(Optional instLen As Long) As String
	Function ReadBuf(ByVal va As Long, ByVal leng As Long, buf() As Byte) As Boolean
	Function DisasmVA(ByVal va As Long, Optional leng As Long) As String
	Function DisasmBlock(ByVal va As Long) As String
	Function DisasmBack(ByVal va As Long, Optional nBack As Integer = 5) As Integer
	Function GetMemory(ByVal va As Long, Optional ByVal asciiDump As Boolean = False) As String
	Function hexdump(ByVal base As Long, it() As Byte)
	Function GetSehChain(Optional ByVal threadID As Long = 0, Optional ByVal verbose As Boolean = True) As String
	Function ReadRegister(ByVal reg As Registers) As Long
	Sub ModifyRegister(ByVal reg As Registers, ByVal valu As Long)


Class Exception
	Public ExceptionCode As DbgEvents
	Public ExceptionFlags As Long
	Public pExceptionRecord As Long
	Public ExceptionAddress As Long
	Public NumberParameters As Long
	Public dwFirstChance As Long
	Public Disasm As String
	Public Enviroment As String
	Public CrashInModule As String
 
