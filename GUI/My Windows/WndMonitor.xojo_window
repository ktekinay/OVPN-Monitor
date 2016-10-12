#tag Window
Begin Window WndMonitor
   BackColor       =   &cFFFFFF00
   Backdrop        =   0
   CloseButton     =   True
   Compatibility   =   ""
   Composite       =   False
   Frame           =   0
   FullScreen      =   False
   FullScreenButton=   False
   HasBackColor    =   False
   Height          =   400
   ImplicitInstance=   True
   LiveResize      =   True
   MacProcID       =   0
   MaxHeight       =   32000
   MaximizeButton  =   True
   MaxWidth        =   32000
   MenuBar         =   520355839
   MenuBarVisible  =   True
   MinHeight       =   64
   MinimizeButton  =   True
   MinWidth        =   64
   Placement       =   0
   Resizeable      =   True
   Title           =   "OpenVPN Server Monitor"
   Visible         =   True
   Width           =   600
   Begin MonitorToolbar TB
      Enabled         =   True
      Index           =   -2147483648
      InitialParent   =   ""
      LockedInPosition=   False
      Scope           =   2
      TabPanelIndex   =   0
      Visible         =   True
   End
   Begin Timer TmrMonitor
      Index           =   -2147483648
      LockedInPosition=   False
      Mode            =   2
      Period          =   1000
      Scope           =   2
      TabPanelIndex   =   0
   End
   Begin Shell ShMonitor
      Arguments       =   ""
      Backend         =   ""
      Canonical       =   False
      Index           =   -2147483648
      LockedInPosition=   False
      Mode            =   2
      Scope           =   2
      TabPanelIndex   =   0
      TimeOut         =   0
   End
   Begin CustomListbox LbStatus
      AutoDeactivate  =   True
      AutoHideScrollbars=   True
      Bold            =   False
      Border          =   True
      ColumnCount     =   1
      ColumnsResizable=   False
      ColumnWidths    =   ""
      DataField       =   ""
      DataSource      =   ""
      DefaultRowHeight=   -1
      Enabled         =   True
      EnableDrag      =   False
      EnableDragReorder=   False
      GridLinesHorizontal=   0
      GridLinesVertical=   0
      HasHeading      =   False
      HeadingIndex    =   -1
      Height          =   360
      HelpTag         =   ""
      Hierarchical    =   False
      Index           =   -2147483648
      InitialParent   =   ""
      InitialValue    =   ""
      Italic          =   False
      Left            =   9
      LockBottom      =   True
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      RequiresSelection=   False
      Scope           =   0
      ScrollbarHorizontal=   False
      ScrollBarVertical=   True
      SelectionType   =   0
      TabIndex        =   0
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0.0
      TextUnit        =   0
      Top             =   20
      Underline       =   False
      UseAlternateRowColor=   False
      UseFocusRing    =   True
      Visible         =   True
      Width           =   583
      _ScrollOffset   =   0
      _ScrollWidth    =   -1
   End
End
#tag EndWindow

#tag WindowCode
	#tag Event
		Sub Close()
		  TmrMonitor.Mode = Timer.ModeOff
		  CloseShell
		End Sub
	#tag EndEvent

	#tag Event
		Sub Open()
		  static counter as integer
		  
		  counter = counter + 1
		  WindowIndex = counter
		  
		  SetTitle
		End Sub
	#tag EndEvent


	#tag MenuHandler
		Function FileClose() As Boolean Handles FileClose.Action
			self.Close
			Return True
			
		End Function
	#tag EndMenuHandler

	#tag MenuHandler
		Function FileSave() As Boolean Handles FileSave.Action
			SaveDocument
			return true
		End Function
	#tag EndMenuHandler

	#tag MenuHandler
		Function FileSaveAs() As Boolean Handles FileSaveAs.Action
			DoSaveAs
			return true
			
		End Function
	#tag EndMenuHandler


	#tag Method, Flags = &h21
		Private Function AbbreviateBytes(bytes As Integer) As String
		  dim suffix as string
		  dim stringValue as string
		  
		  select case bytes
		  case is > 1024 * 1024 * 1000
		    suffix = " GB"
		    stringValue = format( bytes / ( 1024 ^ 3 ), "#,0.00" )
		    
		  case is > 1024 * 1000
		    suffix = " MB"
		    stringValue = format( bytes / ( 1024 ^ 2 ), "#,0.00" )
		    
		  case is > 1000
		    suffix = " KB"
		    stringValue = format( bytes / 1024, "#,0.00" )
		    
		  case else
		    suffix = " b"
		    stringValue = format( bytes, "#,0" )
		    
		  end select
		  
		  return stringValue + suffix
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub CloseShell()
		  if ShMonitor.IsRunning then
		    ShMonitor.WriteLine "quit"
		    Mode = Modes.Closing
		  end if
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoSaveAs()
		  dim dlg as new SaveAsDialog
		  dlg.PromptText = "Save monitor document:"
		  dlg.Filter = DocumentFileTypes.Monitor
		  dlg.SuggestedFileName = "Untitled" + DocumentFileTypes.Monitor.Extensions
		  
		  dim f as FolderItem = dlg.ShowModalWithin( self )
		  if f is nil then
		    return
		  end if
		  
		  File = new Xojo.IO.FolderItem( f.NativePath.ToText )
		  SaveDocument
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub LoadDocument(f As Xojo.IO.FolderItem)
		  CloseShell
		  
		  dim tis as Xojo.IO.TextInputStream = Xojo.IO.TextInputStream.Open( f, Xojo.Core.TextEncoding.UTF8 )
		  dim contents as text = tis.ReadAll
		  tis.Close
		  
		  Settings.FromJSON contents
		  IsNew = false
		  ContentsChanged = false
		  File = f
		  
		  SetTitle
		  
		  Exception err as RuntimeException
		    if err isa EndException or err isa ThreadEndException then
		      raise err
		    end if
		    
		    MsgBox "Could not open this document." + EndOfLine + EndOfLine + err.Message
		    self.Close
		    
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ParseStatus(data As String)
		  const kTab as string = &u09
		  
		  static excludeHeaders() as string = _
		  array( "Connected Since (time_t)" )
		  dim excludeColumnIndexes() as integer
		  
		  dim touchedRows() as boolean
		  redim touchedRows( LbStatus.ListCount - 1 )
		  
		  data = ReplaceLineEndings( data, EndOfLine )
		  dim lines() as string = data.Split( EndOfLine )
		  
		  for lineIndex as integer = 0 to lines.Ubound
		    dim dataLine as string = lines( lineIndex )
		    if dataLine = "" then
		      continue for lineIndex
		    end if
		    
		    dim fields() as string = dataLine.Split( kTab )
		    dim fieldHeader as string = fields( 0 )
		    fields.Remove 0
		    
		    if fieldHeader = "HEADER" then
		      fieldHeader = fieldHeader + " " + fields( 0 )
		      fields.Remove 0
		    end if
		    
		    select case fieldHeader
		    case "END"
		      exit for lineIndex
		      
		    case "HEADER CLIENT_LIST"
		      for i as integer = fields.Ubound downto 0
		        if excludeHeaders.IndexOf( fields( i ) ) <> -1 then
		          fields.Remove i
		          excludeColumnIndexes.Append i
		        end if
		      next
		      excludeColumnIndexes.Sort
		      
		      LbStatus.HasHeading = true
		      LbStatus.ColumnCount = fields.Ubound + 1
		      for headerIndex as integer = 0 to fields.Ubound
		        LbStatus.Heading( headerIndex ) = fields( headerIndex )
		      next headerIndex
		      
		      LbStatus.ColumnWidths = "10%,20%,20%,10%,10%,20%,10%"
		      
		    case "CLIENT_LIST"
		      for i as integer = excludeColumnIndexes.Ubound downto 0
		        fields.Remove excludeColumnIndexes( i )
		      next
		      
		      fields( integer( Columns.BytesReceived ) ) = AbbreviateBytes( fields( integer( Columns.BytesReceived ) ).Val )
		      fields( integer( Columns.BytesSent ) ) = AbbreviateBytes( fields( integer( Columns.BytesSent ) ).Val )
		      
		      dim hash as string = fields( integer( Columns.Username ) ) + fields( integer( Columns.RealAddress ) ) + _
		      fields( integer( Columns.ConnectedSince ) )
		      hash = EncodeHex( Crypto.MD5( hash ) )
		      
		      dim row as integer = RowByHash( hash )
		      if row = -1 then
		        LbStatus.AddRow fields
		        LbStatus.RowTag( LbStatus.LastIndex ) = hash
		      else
		        for col as integer = 0 to fields.Ubound
		          LbStatus.Cell( row, col ) = fields( col )
		        next
		        touchedRows( row ) = true
		      end if
		      
		    end select
		    
		  next lineIndex
		  
		  //
		  // See which rows weren't touched
		  //
		  dim deleteDate as new Date
		  deleteDate.TotalSeconds = deleteDate.TotalSeconds + 30
		  dim now as new Date
		  
		  for row as integer = touchedRows.Ubound downto 0
		    if touchedRows( row ) = false then
		      //
		      // See if already needs to be deleted
		      //
		      dim tag as variant = LbStatus.RowTag( row )
		      if tag.Type = Variant.TypeDate and tag.DateValue.TotalSeconds < now.TotalSeconds then
		        LbStatus.RemoveRow row
		      elseif tag.Type <> Variant.TypeDate then
		        LbStatus.RowTag( row ) = deleteDate
		      end if
		      
		    end if
		  next
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function RowByHash(hash As String) As Integer
		  dim lastRow as integer = LbStatus.ListCount - 1
		  for row as integer = 0 to lastRow
		    dim tag as variant = LbStatus.RowTag( row )
		    if tag.StringValue = hash then
		      return row
		    end if
		  next
		  
		  return -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SaveDocument()
		  if File is nil then
		    DoSaveAs
		    return
		  end if
		  
		  dim contents as text = Settings.ToJSON
		  
		  dim temp as FolderItem = GetTemporaryFolderItem
		  dim tos as TextOutputStream = TextOutputStream.Append( temp )
		  tos.Write contents
		  tos.Close
		  
		  dim newTemp as new Xojo.IO.FolderItem( temp.NativePath.ToText )
		  dim dest as Xojo.IO.FolderItem = File.Parent.Child( newTemp.Name )
		  if dest.Exists then
		    dest.Delete
		  end if
		  newTemp.MoveTo dest
		  newTemp = dest
		  
		  if File.Exists then
		    File.Delete
		  end if
		  newTemp.Name = File.Name
		  
		  ContentsChanged = false
		  IsNew = false
		  
		  SetTitle
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SetTitle()
		  if IsNew then
		    Title = kDefaultTitle + str( WindowIndex )
		  elseif File isa object then
		    Title = File.Name
		  else
		    Title = Settings.ShellCommand
		  end if
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ShowSettings()
		  dim w as new WndSettings
		  dim newSettings as DocumentSettings = w.ShowModalWithin( self, Settings )
		  if newSettings isa object and newSettings <> Settings then
		    CloseShell
		    Settings = newSettings
		    IsNew = false
		    self.ContentsChanged = true
		  end if
		  
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private File As Xojo.IO.FolderItem
	#tag EndProperty

	#tag Property, Flags = &h0
		IsNew As Boolean = True
	#tag EndProperty

	#tag Property, Flags = &h21
		Private Mode As Modes
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( hidden ) Private mSettings As DocumentSettings
	#tag EndProperty

	#tag ComputedProperty, Flags = &h21
		#tag Getter
			Get
			  if mSettings is nil then
			    mSettings = new DocumentSettings
			  end if
			  
			  return mSettings
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  mSettings = value
			End Set
		#tag EndSetter
		Private Settings As DocumentSettings
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private WindowIndex As Integer
	#tag EndProperty


	#tag Constant, Name = kDefaultTitle, Type = String, Dynamic = False, Default = \"New OpenVPN Monitor ", Scope = Private
	#tag EndConstant


	#tag Enum, Name = Columns, Type = Integer, Flags = &h21
		CommonName
		  RealAddress
		  VirtualAddress
		  BytesReceived
		  BytesSent
		  ConnectedSince
		Username
	#tag EndEnum

	#tag Enum, Name = Modes, Type = Integer, Flags = &h21
		Standby
		  Connecting
		  GettingStatus
		Closing
	#tag EndEnum


#tag EndWindowCode

#tag Events TB
	#tag Event
		Sub Action(item As ToolItem)
		  select case item.Caption
		  case TB.Settings.Caption
		    ShowSettings
		    
		  end select
		  
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events TmrMonitor
	#tag Event
		Sub Action()
		  if Mode <> Modes.Standby then
		    return
		  end if
		  
		  if ShMonitor.IsRunning = false then
		    ShMonitor.Execute Settings.ShellCommand
		    
		  else
		    ShMonitor.WriteLine "status 3"
		    Mode = Modes.GettingStatus
		  end if
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events ShMonitor
	#tag Event
		Sub DataAvailable()
		  dim data as string = me.ReadAll
		  
		  select case Mode
		  case Modes.GettingStatus
		    ParseStatus data
		    
		  end select
		  
		  Mode = Modes.Standby
		  
		  
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events LbStatus
	#tag Event
		Function CellTextPaint(g As Graphics, row As Integer, column As Integer, x as Integer, y as Integer) As Boolean
		  #pragma unused column
		  #pragma unused x
		  #pragma unused y
		  
		  dim tag as variant = me.RowTag( row )
		  if tag.Type = Variant.TypeDate then
		    g.Italic = true
		  end if
		  
		End Function
	#tag EndEvent
#tag EndEvents
#tag ViewBehavior
	#tag ViewProperty
		Name="BackColor"
		Visible=true
		Group="Background"
		InitialValue="&hFFFFFF"
		Type="Color"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Backdrop"
		Visible=true
		Group="Background"
		Type="Picture"
		EditorType="Picture"
	#tag EndViewProperty
	#tag ViewProperty
		Name="CloseButton"
		Visible=true
		Group="Frame"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Composite"
		Group="OS X (Carbon)"
		InitialValue="False"
		Type="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Frame"
		Visible=true
		Group="Frame"
		InitialValue="0"
		Type="Integer"
		EditorType="Enum"
		#tag EnumValues
			"0 - Document"
			"1 - Movable Modal"
			"2 - Modal Dialog"
			"3 - Floating Window"
			"4 - Plain Box"
			"5 - Shadowed Box"
			"6 - Rounded Window"
			"7 - Global Floating Window"
			"8 - Sheet Window"
			"9 - Metal Window"
			"11 - Modeless Dialog"
		#tag EndEnumValues
	#tag EndViewProperty
	#tag ViewProperty
		Name="FullScreen"
		Group="Behavior"
		InitialValue="False"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="FullScreenButton"
		Visible=true
		Group="Frame"
		InitialValue="False"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="HasBackColor"
		Visible=true
		Group="Background"
		InitialValue="False"
		Type="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Height"
		Visible=true
		Group="Size"
		InitialValue="400"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="ImplicitInstance"
		Visible=true
		Group="Behavior"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Interfaces"
		Visible=true
		Group="ID"
		Type="String"
		EditorType="String"
	#tag EndViewProperty
	#tag ViewProperty
		Name="LiveResize"
		Visible=true
		Group="Behavior"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MacProcID"
		Group="OS X (Carbon)"
		InitialValue="0"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MaxHeight"
		Visible=true
		Group="Size"
		InitialValue="32000"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MaximizeButton"
		Visible=true
		Group="Frame"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MaxWidth"
		Visible=true
		Group="Size"
		InitialValue="32000"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MenuBar"
		Visible=true
		Group="Menus"
		Type="MenuBar"
		EditorType="MenuBar"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MenuBarVisible"
		Group="Behavior"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MinHeight"
		Visible=true
		Group="Size"
		InitialValue="64"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MinimizeButton"
		Visible=true
		Group="Frame"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MinWidth"
		Visible=true
		Group="Size"
		InitialValue="64"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Name"
		Visible=true
		Group="ID"
		Type="String"
		EditorType="String"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Placement"
		Visible=true
		Group="Behavior"
		InitialValue="0"
		Type="Integer"
		EditorType="Enum"
		#tag EnumValues
			"0 - Default"
			"1 - Parent Window"
			"2 - Main Screen"
			"3 - Parent Window Screen"
			"4 - Stagger"
		#tag EndEnumValues
	#tag EndViewProperty
	#tag ViewProperty
		Name="Resizeable"
		Visible=true
		Group="Frame"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Super"
		Visible=true
		Group="ID"
		Type="String"
		EditorType="String"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Title"
		Visible=true
		Group="Frame"
		InitialValue="Untitled"
		Type="String"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Visible"
		Visible=true
		Group="Behavior"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Width"
		Visible=true
		Group="Size"
		InitialValue="600"
		Type="Integer"
	#tag EndViewProperty
#tag EndViewBehavior
