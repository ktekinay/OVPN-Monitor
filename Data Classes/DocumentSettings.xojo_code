#tag Class
Protected Class DocumentSettings
	#tag Method, Flags = &h0
		Sub Constructor()
		  if DefaultSettingsDict is nil then
		    DefaultSettingsDict = ToDictionary
		  end if
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub FromDictionary(dict As Xojo.Core.Dictionary)
		  dim defaults as Xojo.Core.Dictionary = DefaultSettingsDict
		  dim ti as Xojo.Introspection.TypeInfo = Xojo.Introspection.GetType( self )
		  
		  for each prop as Xojo.Introspection.PropertyInfo in ti.Properties
		    if not prop.IsShared and prop.IsPublic and prop.CanRead and prop.CanWrite then
		      dim key as text = prop.Name.Lowercase
		      if dict.HasKey( key ) then
		        prop.Value( self ) = dict.Value( key )
		      elseif defaults.HasKey( key ) then
		        prop.Value( self ) = defaults.Value( key )
		      end if
		    end if
		  next
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub FromJSON(json As Text)
		  dim dict as Xojo.Core.Dictionary = Xojo.Data.ParseJSON( json )
		  FromDictionary dict
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Attributes( hidden )  Function Operator_Compare(other As DocumentSettings) As Integer
		  dim result as integer = 0
		  
		  dim ti as Xojo.Introspection.TypeInfo = Xojo.Introspection.GetType( self )
		  
		  for each prop as Xojo.Introspection.PropertyInfo in ti.Properties
		    if not prop.IsShared and prop.IsPublic and prop.CanRead and prop.CanWrite then
		      select case prop.PropertyType.Name
		      case "String"
		        result = StrComp( prop.Value( self ), prop.Value( other ), 0 )
		        
		      case "Text"
		        dim t1 as text = prop.Value( self )
		        dim t2 as text = prop.Value( other )
		        result = t1.Compare( t2, Text.CompareCaseSensitive, Xojo.Core.Locale.Current )
		        
		      case else
		        //
		        // We don't know the type so raise an exception
		        //
		        raise new UnsupportedFormatException
		        
		      end select
		      
		      if result <> 0 then
		        exit for prop
		      end if
		    end if
		  next
		  
		  return result
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Reset()
		  FromDictionary DefaultSettingsDict
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ToDictionary() As Xojo.Core.Dictionary
		  dim dict as new Xojo.Core.Dictionary
		  
		  dim ti as Xojo.Introspection.TypeInfo = Xojo.Introspection.GetType( self )
		  
		  for each prop as Xojo.Introspection.PropertyInfo in ti.Properties
		    if not prop.IsShared and prop.IsPublic and prop.CanRead and prop.CanWrite then
		      dim key as text = prop.Name.Lowercase
		      dict.Value( key ) = prop.Value( self )
		    end if
		  next
		  
		  return dict
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ToJSON() As Text
		  dim dict as Xojo.Core.Dictionary = ToDictionary
		  return Xojo.Data.GenerateJSON( dict )
		  
		End Function
	#tag EndMethod


	#tag Property, Flags = &h21
		Private Shared DefaultSettingsDict As Xojo.Core.Dictionary
	#tag EndProperty

	#tag Property, Flags = &h0
		ShellCommand As String = "ssh pi@pi-vpn.local 'telnet 127.0.0.1 5555'"
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ShellCommand"
			Group="Behavior"
			InitialValue="telnet 127.0.0.1 5555"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
