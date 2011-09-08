

Note !

This C# project was developed and tested with an earlier
version of iDbg and has not been updated in a while.

Right now i dont have a machine with VS.NET on it
so you will have to tweak this source back into shape
to get it to run. 

The interface has not changed that much but at a minimum
you will have to:

- re-add the reference to the iDbg COM object
- add a call to dbg.DbgContinue at end of the ReadToRun event

I do not think any existing events prototypes have changed
although they may have. You would get a compile error if they did.

This project will be updated as soon as I have time/disk space
to reinstall VS.NET :-\



