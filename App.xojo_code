#tag Class
Protected Class App
Inherits Application
	#tag Event
		Sub NewDocument()
		  dim w as new WndMonitor
		  w.Show
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub OpenDocument(item As FolderItem)
		  //
		  // Find an existing new Monitor window
		  //
		  dim useWnd as WndMonitor
		  
		  dim lastIndex as integer = WindowCount - 1
		  for i as integer = lastIndex downto 0
		    dim w as Window = Window( i )
		    if w isa WndMonitor then
		      dim monitor as WndMonitor = WndMonitor( w )
		      if monitor.IsNew then
		        useWnd = monitor
		        exit for i
		      end if
		    end if
		  next
		  
		  if useWnd is nil then
		    useWnd = new WndMonitor
		  end if
		  
		  useWnd.Show
		  
		  dim newItem as new Xojo.IO.FolderItem( item.NativePath.ToText )
		  useWnd.LoadDocument newItem
		  
		End Sub
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
			dim lastIndex as integer = dlg.Count
			for i as integer = 0 to lastIndex
			OpenDocument dlg.Item( i )
			next
			end if
			
			Return True
			
		End Function
	#tag EndMenuHandler


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


End Class
#tag EndClass
