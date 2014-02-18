require([[autorun\javaClassEditor]])

--parser for .class files and java bytecode
--http://docs.oracle.com/javase/specs/jvms/se7/html/jvms-4.html

--constant type values
java_CONSTANT_Class=7
java_CONSTANT_Fieldref=9
java_CONSTANT_Methodref=10
java_CONSTANT_InterfaceMethodref=11
java_CONSTANT_String=8
java_CONSTANT_Integer=3
java_CONSTANT_Float=4
java_CONSTANT_Long=5
java_CONSTANT_Double=6
java_CONSTANT_NameAndType=12
java_CONSTANT_Utf8=1
java_CONSTANT_MethodHandle=15
java_CONSTANT_MethodType=16
java_CONSTANT_InvokeDynamic=18


function java_read_u4(stream)
  local b={string.byte(stream.data, stream.index,stream.index+4-1)}
  stream.index=stream.index+4

  return byteTableToDword({b[4],b[3],b[2],b[1]})
end


function java_read_u2(stream)
  local b={string.byte(stream.data, stream.index,stream.index+2-1)}
  stream.index=stream.index+2

  return byteTableToWord({b[2],b[1]})
end

function java_read_u1(stream)
  local result=string.byte(stream.data, stream.index)
  stream.index=stream.index+1

  return result
end

function java_parseConstantPool_Class(stream)
  result={}
  result.tag=java_CONSTANT_Class
  result.name_index=java_read_u2(stream)
  return result
end

function java_parseConstantPool_Fieldref(stream)
  result={}
  result.tag=java_CONSTANT_Fieldref
  result.class_index=java_read_u2(stream)
  result.name_and_type_index=java_read_u2(stream)
  return result
end

function java_parseConstantPool_Methodref(stream)
  result={}
  result.tag=java_CONSTANT_Methodref
  result.class_index=java_read_u2(stream)
  result.name_and_type_index=java_read_u2(stream)
  return result
end

function java_parseConstantPool_InterfaceMethodref(stream)
  result={}
  result.tag=java_CONSTANT_InterfaceMethodref
  result.class_index=java_read_u2(stream)
  result.name_and_type_index=java_read_u2(stream)
  return result
end


function java_parseConstantPool_String(stream)
  result={}
  result.tag=java_CONSTANT_String
  result.string_index=java_read_u2(stream)

  return result
end


function java_parseConstantPool_Integer(stream)
  result={}
  result.tag=java_CONSTANT_Integer
  result.bytes=java_read_u4(stream)
  result.value=result.bytes
  return result
end

function java_parseConstantPool_Float(stream)
  result={}
  result.tag=java_CONSTANT_Float
  result.bytes=java_read_u4(stream)

  result.value=byteTableToFloat(dwordToByteTable(result.bytes))
  return result
end


function java_parseConstantPool_Long(stream)
  result={}
  result.tag=java_CONSTANT_Long
  result.high_bytes=java_read_u4(stream)
  result.low_bytes=java_read_u4(stream)

  local hb=dwordToByteTable(result.high_bytes)
  local lb=dwordToByteTable(result.low_bytes)

  local i
  for i=1, 4 do
    lb[i+4]=hb[i]
  end

  result.value=byteTableToQword(lb)
  return result
end

function java_parseConstantPool_Double(stream)
  result={}
  result.tag=java_CONSTANT_Double
  result.high_bytes=java_read_u4(stream)
  result.low_bytes=java_read_u4(stream)

  local hb=dwordToByteTable(result.high_bytes)
  local lb=dwordToByteTable(result.low_bytes)

  local i
  for i=1, 4 do
    lb[i+4]=hb[i]
  end

  result.value=byteTableToDouble(lb)

  return result
end

function java_parseConstantPool_NameAndType(stream)
  result={}
  result.tag=java_CONSTANT_NameAndType
  result.name_index=java_read_u2(stream)
  result.descriptor_index=java_read_u2(stream)
  return result
end

function java_parseConstantPool_Utf8(stream)
  result={}
  result.tag=java_CONSTANT_Utf8
  result.length=java_read_u2(stream)
  result.bytes={string.byte(stream.data, stream.index, stream.index+result.length-1)}
  result.utf8=string.sub(stream.data, stream.index, stream.index+result.length-1)

  stream.index=stream.index+result.length

  return result
end

function java_parseConstantPool_MethodHandle(stream)
  result={}
  result.tag=java_CONSTANT_MethodHandle
  result.reference_kind=java_read_u1(stream)
  result.reference_index=java_read_u2(stream)
  return result
end

function java_parseConstantPool_MethodType(stream)
  result={}
  result.tag=java_CONSTANT_MethodType
  result.descriptor_index=java_read_u2(stream)
  return result

end

function java_parseConstantPool_InvokeDynamic(stream)
  result={}
  result.tag=java_CONSTANT_InvokeDynamic
  result.bootstrap_method_attr_index=java_read_u2(stream)
  result.name_and_type_index=java_read_u2(stream)
  return result
end






java_parseConstantPoolTag={}
java_parseConstantPoolTag[java_CONSTANT_Class]=java_parseConstantPool_Class
java_parseConstantPoolTag[java_CONSTANT_Fieldref]=java_parseConstantPool_Fieldref
java_parseConstantPoolTag[java_CONSTANT_Methodref]=java_parseConstantPool_Methodref
java_parseConstantPoolTag[java_CONSTANT_InterfaceMethodref]=java_parseConstantPool_InterfaceMethodref
java_parseConstantPoolTag[java_CONSTANT_String]=java_parseConstantPool_String
java_parseConstantPoolTag[java_CONSTANT_Integer]=java_parseConstantPool_Integer
java_parseConstantPoolTag[java_CONSTANT_Float]=java_parseConstantPool_Float
java_parseConstantPoolTag[java_CONSTANT_Long]=java_parseConstantPool_Long
java_parseConstantPoolTag[java_CONSTANT_Double]=java_parseConstantPool_Double
java_parseConstantPoolTag[java_CONSTANT_NameAndType]=java_parseConstantPool_NameAndType
java_parseConstantPoolTag[java_CONSTANT_Utf8]=java_parseConstantPool_Utf8
java_parseConstantPoolTag[java_CONSTANT_MethodHandle]=java_parseConstantPool_MethodHandle
java_parseConstantPoolTag[java_CONSTANT_MethodType]=java_parseConstantPool_MethodType
java_parseConstantPoolTag[java_CONSTANT_InvokeDynamic]=java_parseConstantPool_InvokeDynamic


function java_parseConstantPool(s, count)
  local i
  local result={}


  for i=1,count-1 do
    local tag=java_read_u1(s)

	--print(tag.." "..string.format("%x",s.index))

	if java_parseConstantPoolTag[tag]~=nil then
	  result[i]=java_parseConstantPoolTag[tag](s)
	else
	  error("Invalid constant pool tag encountered: "..s.index.." (tag="..tag..") (i="..i..")")
	end

  end

  return result
end

function java_parseAttribute_ConstantValue(cp, a)
  --create a local stream for parsing the info bytes of the attribute
  local s={}
  s.data=a.info
  s.index=1

  a.constantvalue_index=java_read_u2(s);
  if cp[a.constantvalue_index].tag==java_CONSTANT_String then
    a.value=cp[cp[a.constantvalue_index].string_index].utf8
  else
    a.value=cp[a.constantvalue_index].value
  end
end

function java_parseBytecode(cp, s, code_length)
  local result={}
  result.bytes={string.byte(s.data, s.index, s.index+code_length-1)}

  --parse the bytes into an array of programcounter and interpreted bytecode command
  result.interpreted=bytecodeDisassembler(result.bytes)


  s.index=s.index+code_length
  return result
end

function java_parseAttribute_Code(cp, a)
  local i;
  local s={}
  s.data=a.info
  s.index=1

  a.max_stack=java_read_u2(s)
  a.max_locals=java_read_u2(s)
  a.code_length=java_read_u4(s)
  a.code=java_parseBytecode(cp, s, a.code_length)

  a.exception_table_length=java_read_u2(s)
  a.exception_table={}
  for i=1, a.exception_table_length do
    a.exception_table[i]={}
	a.exception_table[i].start_pc=java_read_u2(s)
    a.exception_table[i].end_pc=java_read_u2(s)
	a.exception_table[i].handler_pc=java_read_u2(s)
	a.exception_table[i].catch_type=java_read_u2(s)
  end

  a.attributes_count=java_read_u2(s)
  a.attributes=java_parseAttributes(cp, s, a.attributes_count)

end



java_parseAttribute={}
java_parseAttribute["ConstantValue"]=java_parseAttribute_ConstantValue
java_parseAttribute["Code"]=java_parseAttribute_Code

--add more yourself...

function java_parseAttributes(cp, s, count)
  local i
  local result={}
  for i=1,count do
    result[i]={}
    result[i].attribute_name_index=java_read_u2(s)
	result[i].attribute_length=java_read_u4(s)
	result[i].info=string.sub(s.data, s.index, s.index+result[i].attribute_length-1)
	s.index=s.index+result[i].attribute_length

	--fill in some extra data (not required for rebuilding)
	result[i].attribute_name=cp[result[i].attribute_name_index].utf8



	if java_parseAttribute[result[i].attribute_name]~=nil then --extra data for this attribute is available
	  java_parseAttribute[result[i].attribute_name](cp, result[i])
	end


  end
  return result
end

function java_parseFields(cp, s, count)
  local i
  local result={}


  for i=1,count do
    result[i]={}
    result[i].access_flags=java_read_u2(s)
	result[i].name_index=java_read_u2(s)
	result[i].descriptor_index=java_read_u2(s)
	result[i].attributes_count=java_read_u2(s)
	result[i].attributes=java_parseAttributes(cp, s, result[i].attributes_count)
  end

  return result
end



function java_parseMethods(cp, s, count)
  local i
  local result={}


  for i=1,count do
    result[i]={}
    result[i].access_flags=java_read_u2(s)
	result[i].name_index=java_read_u2(s)
	result[i].descriptor_index=java_read_u2(s)
	result[i].attributes_count=java_read_u2(s)
	result[i].attributes=java_parseAttributes(cp, s, result[i].attributes_count)
  end


  return result
end





function java_parseClass(data)
  local result={}
  local s={}
  local i,j
  s.data=data
  s.index=1
  result.magic=java_read_u4(s)

  if (result.magic~=0xcafebabe) then
    error("Not a valid classfile")
  end

  result.minor_version=java_read_u2(s)
  result.major_version=java_read_u2(s)
  result.constant_pool_count=java_read_u2(s)
  result.constant_pool_start=s.index
  result.constant_pool=java_parseConstantPool(s, result.constant_pool_count)
  result.constant_pool_stop=s.index

  result.access_flags=java_read_u2(s)
  result.this_class=java_read_u2(s)
  result.super_class=java_read_u2(s)

  result.interfaces_count=java_read_u2(s)
  result.interfaces={}
  for i=1,result.interfaces_count do
    result.interfaces[i]=java_read_u2(s)
  end

  result.fields_count=java_read_u2(s)
  result.fields=java_parseFields(result.constant_pool, s, result.fields_count)

  result.methods_count=java_read_u2(s)
  result.methods=java_parseMethods(result.constant_pool, s, result.methods_count)


  result.attributes_count=java_read_u2(s)
  result.attributes=java_parseAttributes(result.constant_pool, s, result.attributes_count)


  return result
end


--teststuff
f=io.open([[c:\Users\DB\workspace\guitest\bin\Test.class]],"rb")
data=f:read("*all")

x=java_parseClass(data)




