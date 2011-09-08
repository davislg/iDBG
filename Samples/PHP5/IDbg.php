<?php

class DBG_EventSinker {
  var $terminated = false;
  
  function Terminate(){
	  e("Terminated");
	  $this->terminated = true;
  }

  function DevMessage($func, $msg){
	  //e("DevMsg -- Proc: " .  $func . " Msg: " . $msg);
  }
  
  function ReadyToRun(){
	  global $dbg;
	  
	  e("ReadyToRun! Setting Breakpoint") ;
	  
	  if( ! $dbg->SetBreakPoint(0x401036) ){
		   e("Failed to set bpx");
	   }
	    else{ e("bpx set ok"); }
	    
	  $dbg->DbgContinue;
	  
  }
  
  function DllLoad($path, $base, $size){
	  e("Dll loaded: " . $path . " base " . dechex($base));
  }
  
  function SingleStep($except){
	  global $dbg;
	  
	  e("Single step at " . dechex($except->ExceptionAddress) . "\n".
	     "  disasm " . $except->Disasm . "\n" .
	     "  eax = ". dechex($dbg->ReadRegister(5)) ."\n"
	    );
	     
	   if($except->ExceptionAddress <= 0x401024){
		    $dbg->StepInto();
   	   }	 
	    else{ $dbg->Continue(); }
			  
  }
  
  function UserBreakpoint($except){
	  global $dbg;
	  
	  $validPointer = false;
	  $pFormat=0;
	  $l = $dbg->ReadRegister(8);
	  
	  if( $dbg->ReadLng($l, $pFormat) ) $validPointer = true;
    
	  $msg = "UserBreakpoint @ " . dechex($except->ExceptionAddress) . "\n" .
			 "   Disasm = " . $except->Disasm . "\n" .
		     "   Esp = " . dechex($l) ;
        
	  if( $validPointer ) $msg = $msg . $dbg->GetMemory($pFormat, true);
		else $msg = $msg . $dbg->GetMemory($l, true);
    
	  e($msg . "\n");
	  e("Stepping over printf call...\n");
	  $dbg->StepOver();
  }
  
  function Exception($except){
	  global $dbg;
	  e("Exception @ ". dechex($except->ExceptionAddress));
	  			
	  if( $except->ExceptionAddress == $dbg->LastEventAddress){
		  e("Same Crash Killing...");
		  $dbg->StopDbg();
		  $this->terminated = true;
  	  }
	  else{
		   e("Passing exception to debugee for it to process firstchance? " . $except->dwFirstChance);
		   $dbg->DbgDontHandle();	   
  	  }  
  }
}

function e($msg){echo $msg . "\n";}

$dbg = new COM("iDbg.CDebugger");
// com_print_typeinfo($dbg); exit(0);

$sink =& new DBG_EventSinker();

if( !com_event_sink($dbg, $sink, "__CDebugger") ) exit("Event Sink Failed");

$pth = "c:\\iDefense\\iDbg\\test2.exe";

if(! file_exists($pth) ){
	e("Could not find test executable $pth");
	e("Trying root path...");
	$pth = "c:\\test2.exe";
}

if(! file_exists($pth) ) {
	e("Could not find test executable $pth\nAborting...");
}
else{
	$dbg->LaunchProcess($pth . " aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa") ;
	if ( ! $dbg->isDebugging ) exit("Failed to Launch Executable :( ");
	echo "Executable Launched ok Starting dbg Session\n";
	while( !$sink->terminated ) com_message_pump(100);
	e("Application terminated");
}

?> 