#tag Class
Protected Class DocumentSettings
	#tag Method, Flags = &h0
		Sub FromJSON(json As Text)
		  dim dict as Xojo.Core.Dictionary = Xojo.Data.ParseJSON( json )
		  
		  dim ti as Xojo.Introspection.TypeInfo = Xojo.Introspection.GetType( self )
		  
		  for each prop as Xojo.Introspection.PropertyInfo in ti.Properties
		    dim key as text = prop.Name.Lowercase
		    if dict.HasKey( key ) then
		      prop.Value( self ) = dict.Value( key )
		    end if
		  next
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ToJSON() As Text
		  dim dict as new Xojo.Core.Dictionary
		  dim ti as Xojo.Introspection.TypeInfo = Xojo.Introspection.GetType( self )
		  
		  for each prop as Xojo.Introspection.PropertyInfo in ti.Properties
		    if not prop.IsShared and prop.IsPublic and prop.CanRead and prop.CanWrite then
		      dim key as text = prop.Name.Lowercase
		      dict.Value( key ) = prop.Value( self )
		    end if
		  next
		  
		  return Xojo.Data.GenerateJSON( dict )
		  
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		ShellCommand As String = "telnet 127.0.0.1 5555"
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
