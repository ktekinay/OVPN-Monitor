#tag Class
Protected Class App
Inherits Application
	#tag Event
		Sub Close()
		  if SingleLaunchMutex isa object then
		    SingleLaunchMutex.Leave
		    SingleLaunchMutex = nil
		  end if
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub NewDocument()
		  dim w as new WndMonitor
		  w.Show
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub Open()
		  SingleLaunchMutex = new Mutex( Crypto.MD5( App.ExecutableFile.NativePath ) )
		  if not SingleLaunchMutex.TryEnter then
		    
		    MsgBox "Another instance is already running."
		    SingleLaunchMutex = nil
		    quit
		    
		  else
		    
		    dim args() as string = CommandLineArgs
		    args.Remove 0
		    if args.Ubound <> -1 then
		      'MsgBox join( args, EndOfLine )
		      for each arg as string in args
		        dim f as new FolderItem( arg, FolderItem.PathTypeNative )
		        OpenDocument f
		      next
		    end if
		    
		  end if
		End Sub
	#tag EndEvent

	#tag Event
		Sub OpenDocument(item As FolderItem)
		  //
		  // Find an existing new Monitor window
		  //
		  dim useWnd as WndMonitor
		  dim newWnd as WndMonitor
		  
		  dim lastIndex as integer = WindowCount - 1
		  for i as integer = lastIndex downto 0
		    dim w as Window = Window( i )
		    if w isa WndMonitor then
		      dim monitor as WndMonitor = WndMonitor( w )
		      if monitor.IsNew and newWnd is nil then
		        newWnd = monitor
		      elseif monitor.File isa object and monitor.File.Path.Compare( item.NativePath.ToText, Text.CompareCaseSensitive ) = 0 then
		        useWnd = monitor
		        exit for i
		      end if
		    end if
		  next
		  
		  if useWnd is nil then
		    useWnd = newWnd
		  end if
		  
		  if useWnd is nil then
		    useWnd = new WndMonitor
		  end if
		  
		  useWnd.Show
		  
		  dim newItem as new Xojo.IO.FolderItem( item.NativePath.ToText )
		  useWnd.LoadDocument newItem
		  
		End Sub
	#tag EndEvent

	#tag Event
		Function UnhandledException(error As RuntimeException) As Boolean
		  dim ti as Xojo.Introspection.TypeInfo = Xojo.Introspection.GetType( error )
		  MsgBox join( error.Stack, EndOfLine ).Left( 512 )
		  quit
		  return true
		  
		End Function
	#tag EndEvent


	#tag MenuHandler
		Function FileNew() As Boolean Handles FileNew.Action
			NewDocument
			Return True
			
		End Function
	#tag EndMenuHandler

	#tag MenuHandler
		Function FileOpen() As Boolean Handles FileOpen.Action
			dim dlg as new OpenDialog
			dlg.PromptText = "Select a monitor document:"
			dlg.Filter = DocumentFileTypes.Monitor
			
			dim f as FolderItem = dlg.ShowModal
			if f isa object then
			dim lastIndex as integer = dlg.Count - 1
			for i as integer = 0 to lastIndex
			OpenDocument dlg.Item( i )
			next
			end if
			
			Return True
			
		End Function
	#tag EndMenuHandler

	#tag MenuHandler
		Function HelpAbout() As Boolean Handles HelpAbout.Action
			WndAbout.Show
			return true
		End Function
	#tag EndMenuHandler


	#tag Method, Flags = &h0, CompatibilityFlags = (TargetHasGUI)
		Function CommandLineArgs() As String()
		  // Return an array of command-line arguments
		  
		  const kDebugDeclares = false
		  
		  dim args() as string
		  
		  #if DebugBuild and not kDebugDeclares then 
		    //
		    // Not perfect, but will emulate what you'll get in the built app
		    //
		    
		    args = ParseStringValue(System.CommandLine)
		    
		  #elseif TargetMacOS then
		    const kCocoaLib = "Cocoa.framework"
		    
		    declare function NSClassFromString lib kCocoaLib (aClassName as CFStringRef) as Ptr
		    declare function defaultCenter lib kCocoaLib selector "processInfo" (class_id as Ptr) as Ptr
		    declare function arguments lib kCocoaLib selector "arguments" (obj_id as Ptr) as Ptr
		    declare function m_count lib kCocoaLib selector "count" (obj as Ptr) as UInteger
		    declare function objectAtIndex lib kCocoaLib selector "objectAtIndex:" (theArray as Ptr, idx as Integer) as CFStringRef
		    
		    static c as Ptr = defaultCenter(NSClassFromString("NSProcessInfo"))
		    dim nsArrayRef as Ptr = arguments(c)
		    dim ub as integer = m_count(nsArrayRef) - 1
		    for i as integer = 0 to ub
		      dim s as string = objectAtIndex(nsArrayRef, i)
		      args.Append s
		    next
		    
		  #elseif TargetWin32 then
		    //
		    // Windows and Linux code from Thomas Tempelmann
		    //
		    
		    declare function GetCommandLineW lib "kernel32.dll" () as Ptr
		    declare function CommandLineToArgvW lib "shell32.dll" (lpCmdLine As Ptr, ByRef pNumArgs As Integer) As Ptr
		    declare sub LocalFree Lib "kernel32.dll" (p as Ptr)
		    
		    dim cl as Ptr = GetCommandLineW()
		    dim n as Integer
		    dim argList as Ptr = CommandLineToArgvW (cl, n)
		    for idx as Integer = 0 to n-1
		      dim mb as MemoryBlock = argList.Ptr(idx*4)
		      // mb points to a UTF16 0-terminated string. It seems we have to scan its length ourselves now.
		      dim len as Integer
		      while mb.UInt16Value(len) <> 0
		        len = len + 2
		      wend
		      dim s as String = mb.StringValue(0,len).DefineEncoding(Encodings.UTF16)
		      s = s.ConvertEncoding(Encodings.UTF8)
		      args.Append s
		    next
		    LocalFree(argList)
		    
		  #elseif TargetLinux then
		    // read from "/proc/self/cmdline", each item is 0-terminated
		    
		    const SystemLib = "libc.so"
		    declare function open lib SystemLib (path as CString, flags as Integer) As Integer
		    declare function read lib SystemLib (fd as Integer, data as Ptr, n as Integer) as Integer
		    
		    // first, read the entire cmdline into a string
		    dim fd as Integer = open ("/proc/self/cmdline", 0)
		    dim s as String
		    do
		      dim mb as new MemoryBlock(1000)
		      dim n as Integer = read (fd, mb, mb.Size)
		      s = s + mb.StringValue (0, n)
		      if n < mb.Size then exit
		    loop
		    args = s.Split(Chr(0))
		    call args.Pop // remove last array item because of extra 00 byte at end of string
		    
		    for i as integer = 0 to args.Ubound
		      dim thisArg as string = args(i)
		      if Encodings.UTF8.IsValidData(thisArg) then
		        args(i) = thisArg.DefineEncoding(Encodings.UTF8)
		      else
		        args(i) = thisArg.DefineEncoding(Encodings.ISOLatin1)
		      end if
		    next
		    
		  #endif
		  
		  return args
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, CompatibilityFlags = (TargetConsole and (Target32Bit or Target64Bit)) or  (TargetWeb and (Target32Bit or Target64Bit)) or  (TargetDesktop and (Target32Bit or Target64Bit))
		Private Function IsQuoteCharacter(char As String) As Boolean
		  #if TargetWin32 then
		    return (char = """")
		  #else
		    return (char = """" or char = "'")
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, CompatibilityFlags = (TargetConsole and (Target32Bit or Target64Bit)) or  (TargetWeb and (Target32Bit or Target64Bit)) or  (TargetDesktop and (Target32Bit or Target64Bit))
		Private Sub ParseRestOfString(value As String, appendTo() As String)
		  value = value.Trim
		  if value = "" then
		    return
		  end if
		  
		  if value.Encoding = nil then
		    #if TargetMacOS then
		      value = value.DefineEncoding(Encodings.MacRoman)
		    #else
		      value = value.DefineEncoding(Encodings.ISOLatin1)
		    #endif
		  end if
		  
		  value = value.ConvertEncoding( Encodings.UTF8 )
		  
		  dim allChars() as string = value.Split("")
		  dim thisChunk() as string
		  dim inQuote as boolean
		  dim quoteChar as string
		  
		  dim charIndex as integer
		  while charIndex <= allChars.Ubound
		    dim thisChar as string = allChars(charIndex)
		    
		    if thisChar = "\" and charIndex < allChars.Ubound then
		      thisChunk.Append allChars(charIndex + 1)
		      charIndex = charIndex + 1
		      
		    elseif inQuote and thisChar = quoteChar then
		      inQuote = false
		      
		    elseif inQuote then
		      thisChunk.Append thisChar
		      
		    elseif IsQuoteCharacter(thisChar) then
		      inQuote = true
		      quoteChar = thisChar
		      
		    elseif thisChar = " " then
		      if thisChunk.Ubound <> -1 then
		        appendTo.Append join(thisChunk, "")
		        redim thisChunk(-1)
		      end if
		      
		    else // Just a character
		      
		      thisChunk.Append thisChar
		      
		    end if
		    
		    charIndex = charIndex + 1
		  wend
		  
		  if thisChunk.Ubound <> -1 then
		    appendTo.Append join(thisChunk, "")
		  end if
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, CompatibilityFlags = (TargetConsole and (Target32Bit or Target64Bit)) or  (TargetWeb and (Target32Bit or Target64Bit)) or  (TargetDesktop and (Target32Bit or Target64Bit))
		Private Function ParseStringValue(value As String) As String()
		  //
		  // Parse the arguments into a `String` array of parameters, then pass the contents of that
		  // array to the 'real' `Parse(args() As String)` method.
		  //
		  // ### Parameters
		  //
		  // * `value` - Command line arguments contained in a single line string. This is 
		  //   used in a Desktop via a call to `System.CommandLine` as a Desktop
		  //   has no direct access to the `args()` parameter that a `ConsoleApplication`
		  //   does.
		  //
		  // ### Notes
		  //
		  // See `Parse(args() As String)` for more detailed information
		  //
		  
		  Dim matches() As String
		  
		  Dim rx As New RegEx
		  
		  '#if TargetWin32 then
		  '
		  '// Code from Michel Bujardet (https://forum.xojo.com/14420-system-commandline)
		  '
		  'rx.SearchPattern = "(""[^""]+""|[^\s""]+)"
		  '
		  'Dim match As RegExMatch = rx.Search(value)
		  '
		  'While match <> Nil
		  'matches.Append ReplaceAll(match.SubExpressionString(1), chr(34), "")
		  'match = rx.Search()
		  'Wend
		  '
		  '#else // TargetDesktop
		  
		  //
		  // We have to peel off of the executable first
		  //
		  
		  dim rest as string
		  
		  dim myPath as string = App.ExecutableFile.NativePath
		  dim pattern as string = """?(\Q" + myPath.ReplaceAllB( "\E", "\\EE\Q" ) + "\E)""? (.*)"
		  
		  rx.SearchPattern = pattern
		  dim match as RegExMatch = rx.Search(value)
		  
		  if match IsA RegExMatch then
		    matches.Append match.SubExpressionString(1)
		    rest = match.SubExpressionString(2)
		    ParseRestOfString(rest, matches)
		  else
		    matches.Append value
		  end if
		  
		  '#endif
		  
		  return(matches)
		  
		  
		End Function
	#tag EndMethod


	#tag Property, Flags = &h21
		Private SingleLaunchMutex As Mutex
	#tag EndProperty


	#tag Constant, Name = kEditClear, Type = String, Dynamic = False, Default = \"&Delete", Scope = Public
		#Tag Instance, Platform = Windows, Language = Default, Definition  = \"&Delete"
		#Tag Instance, Platform = Linux, Language = Default, Definition  = \"&Delete"
	#tag EndConstant

	#tag Constant, Name = kFileCloseShortcut, Type = String, Dynamic = False, Default = \"Alt+F4", Scope = Public
		#Tag Instance, Platform = Mac OS, Language = Default, Definition  = \"Cmd+W"
	#tag EndConstant

	#tag Constant, Name = kFileQuit, Type = String, Dynamic = False, Default = \"&Quit", Scope = Public
		#Tag Instance, Platform = Windows, Language = Default, Definition  = \"E&xit"
	#tag EndConstant

	#tag Constant, Name = kFileQuitShortcut, Type = String, Dynamic = False, Default = \"", Scope = Public
		#Tag Instance, Platform = Mac OS, Language = Default, Definition  = \"Cmd+Q"
		#Tag Instance, Platform = Linux, Language = Default, Definition  = \"Ctrl+Q"
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="SingleLaunchMutex"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
