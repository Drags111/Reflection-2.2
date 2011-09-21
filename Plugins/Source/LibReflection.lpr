library LibReflection;

{$mode objfpc}{$H+}

uses
  {$IFDEF LINUX}cmem, {$ENDIF}Classes, Sysutils, math,
  dynlibs;

type
  TIntegerArray = {%H-}array of Integer;
  //T2DIntegerArray = array of array of Integer;
  EObjectException = Class(Exception);

var
   SmartLib: TLibHandle;
   UseMemManagement: Boolean = True;
   OpenObjects: TIntegerArray;
   libs_GetFunctionCount: function(): Longint; stdcall;
   libs_GetFunctionInfo: function(X: Integer; var ProcAddr: Pointer; var ProcDef: PChar): Integer; stdcall;

   std_setup: procedure(root, params: String; width, height: Integer; initseq: String); stdcall;
   std_stringFromBytes: function(Bytes: Integer; Str: String): Integer; stdcall;
   std_stringFromChars: function(Chars: Integer; Str: String): Integer; stdcall;
   std_stringFromString: function(JStr: Integer; Str: String): Integer; stdcall;
   std_getFieldObject: function(Parent: Integer; Path: String): Integer; stdcall;
   std_isPathValid: function(Parent: Integer; path: String): Boolean; stdcall;
   std_getFieldInt: function(Parent: Integer; path: String): Integer; stdcall;
   std_getFieldShort: function(Parent: Integer; path: String): Integer; stdcall;
   std_getFieldByte: function(Parent: Integer; path: String): Integer; stdcall;
   std_getFieldFloat: function(Parent: Integer; path: String): Extended; stdcall;
   std_getFieldDouble: function(Parent: Integer; path: String): Extended; stdcall;
   std_getFieldBool: function(Parent: Integer; path: String): Boolean; stdcall;
   std_getFieldLongH: function(Parent: Integer; path: String): Integer; stdcall;
   std_getFieldLongL: function(Parent: Integer; path: String): Integer; stdcall;
   std_getFieldArrayObject: function(Parent: Integer; path: String; indeX: Integer): Integer; stdcall;
   std_getFieldArrayInt: function(Parent: Integer; path: String; indeX: Integer): Integer; stdcall;
   std_getFieldArrayFloat: function(Parent: Integer; path: String; indeX: Integer): Extended; stdcall;
   std_getFieldArrayDouble: function(Parent: Integer; path: String; indeX: Integer): Extended; stdcall;
   std_getFieldArrayLongH: function(Parent: Integer; path: String; indeX: Integer): Integer; stdcall;
   std_getFieldArrayLongL: function(Parent: Integer; path: String; indeX: Integer): Integer; stdcall;
   std_getFieldArrayBool: function(Parent: Integer; path: String; indeX: Integer): Boolean; stdcall;
   std_getFieldArrayByte: function(Parent: Integer; path: String; indeX: Integer): Integer; stdcall;
   std_getFieldArrayShort: function(Parent: Integer; path: String; indeX: Integer): Integer; stdcall;
   std_getFieldArrayChar: function(Parent: Integer; path: String; indeX: Integer): Integer; stdcall;
   std_getFieldArray2DObject: function(Parent: Integer; path: String; X, Y: Integer): Integer; stdcall;
   std_getFieldArray2DInt: function(Parent: Integer; path: String; X, Y: Integer): Integer; stdcall;
   std_getFieldArray2DFloat: function(Parent: Integer; path: String; X, Y: Integer): Extended; stdcall;
   std_getFieldArray2DDouble: function(Parent: Integer; path: String; X, Y: Integer): Extended; stdcall;
   std_getFieldArray2DBool: function(Parent: Integer; path: String; X, Y: Integer): Boolean; stdcall;
   std_getFieldArray2DLongH: function(Parent: Integer; path: String; X, Y: Integer): Integer; stdcall;
   std_getFieldArray2DLongL: function(Parent: Integer; path: String; X, Y: Integer): Integer; stdcall;
   std_getFieldArray2DByte: function(Parent: Integer; path: String; X, Y: Integer): Integer; stdcall;
   std_getFieldArray2DShort: function(Parent: Integer; path: String; X, Y: Integer): Integer; stdcall;
   std_getFieldArray2DChar: function(Parent: Integer; path: String; X, Y: Integer): Integer; stdcall;
   std_getFieldArray3DObject: function(Parent: Integer; path: String; X, Y, z: Integer): Integer; stdcall;
   std_getFieldArray3DInt: function(Parent: Integer; path: String; X, Y, z: Integer): Integer; stdcall;
   std_getFieldArray3DFloat: function(Parent: Integer; path: String; X, Y, z: Integer): Extended; stdcall;
   std_getFieldArray3DDouble: function(Parent: Integer; path: String; X, Y, z: Integer): Extended; stdcall;
   std_getFieldArray3DBool: function(Parent: Integer; path: String; X, Y, z: Integer): Boolean; stdcall;
   std_getFieldArray3DLongH: function(Parent: Integer; path: String; X, Y, z: Integer): Integer; stdcall;
   std_getFieldArray3DLongL: function(Parent: Integer; path: String; X, Y, z: Integer): Integer; stdcall;
   std_getFieldArray3DByte: function(Parent: Integer; path: String; X, Y, z: Integer): Integer; stdcall;
   std_getFieldArray3DShort: function(Parent: Integer; path: String; X, Y, z: Integer): Integer; stdcall;
   std_getFieldArray3DChar: function(Parent: Integer; path: String; X, Y, z: Integer): Integer; stdcall;
   std_getFieldArraySize: function(Parent: Integer; path: String; dim: Integer): Integer; stdcall;
   std_isEqual: function(Obja, ObjB: Integer): Boolean; stdcall;
   std_isNull: function(Obj: Integer): Boolean; stdcall;
   std_setDebug: procedure(Debug: Boolean); stdcall;
   std_freeObject: procedure(Obj: Integer); stdcall;

procedure SetMemoryManagement(Use: Boolean);
begin
  UseMemManagement := Use;
end;

procedure AddOpenObject(Obj: Integer);
var
  L: Integer;
begin
  L := Length(OpenObjects);
  SetLength(OpenObjects, L+1);
  OpenObjects[L] := Obj;
end;

function RemoveOpenObject(Obj: Integer): Boolean;
var
  L, I, Index: Integer;
begin
  Result := False;
  L := Length(OpenObjects);
  Index := -1;
  for I := 0 to L-1 do
  begin
    if(OpenObjects[I] = Obj)then
    begin
      Index := I;
      Break;
    end;
  end;
  if(Index = -1)then
    Exit;
  if(L > 1)then
  begin
    for I := Index to L-2 do
      OpenObjects[I] := OpenObjects[I+1];
    SetLength(OpenObjects, L-1);
  end else
    SetLength(OpenObjects, 0);
  Result := True;
end;

procedure PrintOpenObjects(); stdcall;
var
  I: Integer;
begin
  Writeln('There are '+IntToStr(Length(OpenObjects))+' unfreed objects in SMART.');
  for I := 0 to High(OpenObjects)do
    Writeln(OpenObjects[I]);
end;

procedure SmartSetup(Root, Params: String; Width, Height: Integer; InitSeq: String);
begin
  std_setup(Root, Params, Width, Height, InitSeq);
end;

function IsPathValid(Parent: Integer; Path: String): Boolean; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to IsPathValid.');
  Result := std_isPathValid(Parent, Path);
end;

procedure FreeObject(Obj: Integer); stdcall;
begin
  if(Obj < 0)then
    Raise EObjectException.Create('An invalid object has been passed to FreeObject.');
  if(UseMemManagement)then
    if not RemoveOpenObject(Obj)then
      Exit;
  std_freeObject(Obj);
end;

function StringFromBytes(Bytes: Integer; Str: String): Integer; stdcall;
begin
  if(Bytes < 0)then
    Raise EObjectException.Create('An invalid object has been passed to StringFromBytes.');
  Result := std_stringFromBytes(Bytes, Str);
end;

function StringFromChars(Chars: Integer; Str: String): Integer; stdcall;
begin
  if(Chars < 0)then
    Raise EObjectException.Create('An invalid object has been passed to StringFromChars.');
  Result := std_stringFromChars(Chars, Str);
end;

function StringFromString(JStr: Integer; Str: String): Integer; stdcall;
begin
  if(JStr < 0)then
    Raise EObjectException.Create('An invalid object has been passed to StringFromString.');
  Result := std_stringFromString(JStr, Str);
end;

function GetFieldObject(Parent: Integer; Path: String): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldObject.');
  Result := std_getFieldObject(Parent, Path);
  if(UseMemManagement)then
    if(Result > 0)then
      AddOpenObject(Result);
end;

function GetFieldString(Parent: Integer; Path: String): String; stdcall;
var
  JStr: Integer;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldString.');
  JStr := std_getFieldObject(Parent, Path);
  SetLength(Result, 512);
  SetLength(Result, StringFromString(JStr, Result));
  Result := StringReplace(Result, 'Â', '', [rfReplaceAll]);
  Result := StringReplace(Result, #160, #32, [rfReplaceAll]);
  std_freeObject(JStr);
end;

function GetFieldInt(Parent: Integer; Path: String): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldInt.');
  Result := std_getFieldInt(Parent, Path);
end;

function GetFieldShort(Parent: Integer; Path: String): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldShort');
  Result := std_getFieldShort(Parent, Path);
end;

function GetFieldByte(Parent: Integer; Path: String): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldByte');
  Result := std_getFieldByte(Parent, Path);
end;

function GetFieldFloat(Parent: Integer; Path: String): Extended; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldFloat');
  Result := std_getFieldFloat(Parent, Path);
end;

function GetFieldDouble(Parent: Integer; Path: String): Extended; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldDouble');
  Result := std_getFieldDouble(Parent, Path);
end;

function GetFieldBoolean(Parent: Integer; Path: String): Boolean; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldBoolean');
  Result := std_getFieldBool(Parent, Path);
end;

function GetFieldLongH(Parent: Integer; Path: String): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldLongH');
  Result := std_getFieldLongH(Parent, Path);
end;

function GetFieldLongL(Parent: Integer; Path: String): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldLongL');
  Result := std_getFieldLongL(Parent, Path);
end;

function GetFieldArrayObject(Parent: Integer; Path: String; Index: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArrayObject.');
  Result := std_getFieldArrayObject(Parent, Path, Index);
  if(UseMemManagement)then
    if(Result > 0)then
      AddOpenObject(Result);
end;

function GetFieldArrayString(Parent: Integer; Path: String; Index: Integer): String; stdcall;
var
  JStr: Integer;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArrayString.');
  JStr := std_getFieldArrayObject(Parent, Path, Index);
  SetLength(Result, 512);
  SetLength(Result, StringFromString(JStr, Result));
  Result := StringReplace(Result, 'Â', '', [rfReplaceAll]);
  Result := StringReplace(Result, #160, #32, [rfReplaceAll]);
  std_freeObject(JStr);
end;

function GetFieldArrayInt(Parent: Integer; Path: String; Index: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArrayInt.');
  Result := std_getFieldArrayInt(Parent, Path, Index);
end;

function GetFieldArrayFloat(Parent: Integer; Path: String; Index: Integer): Extended; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArrayFloat.');
  Result := std_getFieldArrayFloat(Parent, Path, Index);
end;

function GetFieldArrayDouble(Parent: Integer; Path: String; Index: Integer): Extended; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArrayDouble.');
  Result := std_getFieldArrayDouble(Parent, Path, Index);
end;

function GetFieldArrayLongH(Parent: Integer; Path: String; Index: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArrayLongH.');
  Result := std_getFieldArrayLongH(Parent, Path, Index);
end;

function GetFieldArrayLongL(Parent: Integer; Path: String; Index: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArrayLongL.');
  Result := std_getFieldArrayLongL(Parent, Path, Index);
end;

function GetFieldArrayBoolean(Parent: Integer; Path: String; Index: Integer): Boolean; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArrayBoolean.');
  Result := std_getFieldArrayBool(Parent, Path, Index);
end;

function GetFieldArrayByte(Parent: Integer; Path: String; Index: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArrayByte.');
  Result := std_getFieldArrayByte(Parent, Path, Index);
end;

function GetFieldArrayShort(Parent: Integer; Path: String; Index: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArrayShort.');
  Result := std_getFieldArrayShort(Parent, Path, Index);
end;

function GetFieldArrayChar(Parent: Integer; Path: String; Index: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArrayChar.');
  Result := std_getFieldArrayChar(Parent, Path, Index);
  if(UseMemManagement)then
    if(Result > 0)then
      AddOpenObject(Result);
end;

function GetFieldArray2DObject(Parent: Integer; Path: String; X, Y: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray2DObject.');
  Result := std_getFieldArray2DObject(Parent, Path, X, Y);
  if(UseMemManagement)then
    if(Result > 0)then
      AddOpenObject(Result);
end;

function GetFieldArray2DString(Parent: Integer; Path: String; X, Y: Integer): String; stdcall;
var
  JStr: Integer;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray2DString.');
  JStr := std_getFieldArray2DObject(Parent, Path, X, Y);
  SetLength(Result, 512);
  SetLength(Result, StringFromString(JStr, Result));
  Result := StringReplace(Result, 'Â', '', [rfReplaceAll]);
  Result := StringReplace(Result, #160, #32, [rfReplaceAll]);
  std_freeObject(JStr);
end;

function GetFieldArray2DInt(Parent: Integer; Path: String; X, Y: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray2DInt.');
  Result := std_getFieldArray2DInt(Parent, Path, X, Y);
end;

function GetFieldArray2DFloat(Parent: Integer; Path: String; X, Y: Integer): Extended; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray2DFloat.');
  Result := std_getFieldArray2DFloat(Parent, Path, X, Y);
end;

function GetFieldArray2DDouble(Parent: Integer; Path: String; X, Y: Integer): Extended; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray2DDouble.');
  Result := std_getFieldArray2DDouble(Parent, Path, X, Y);
end;

function GetFieldArray2DBoolean(Parent: Integer; Path: String; X, Y: Integer): Boolean; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray2DBoolean.');
  Result := std_getFieldArray2DBool(Parent, Path, X, Y);
end;

function GetFieldArray2DLongH(Parent: Integer; Path: String; X, Y: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray2DLongH.');
  Result := std_getFieldArray2DLongH(Parent, Path, X, Y);
end;

function GetFieldArray2DLongL(Parent: Integer; Path: String; X, Y: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray2DLongL.');
  Result := std_getFieldArray2DLongL(Parent, Path, X, Y);
end;

function GetFieldArray2DByte(Parent: Integer; Path: String; X, Y: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray2DByte.');
  Result := std_getFieldArray2DByte(Parent, Path, X, Y);
end;

function GetFieldArray2DShort(Parent: Integer; Path: String; X, Y: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray2DShort.');
  Result := std_getFieldArray2DShort(Parent, Path, X, Y);
end;

function GetFieldArray2DChar(Parent: Integer; Path: String; X, Y: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray2DChar.');
  Result := std_getFieldArray2DChar(Parent, Path, X, Y);
  if(UseMemManagement)then
    if(Result > 0)then
      AddOpenObject(Result);
end;

function GetFieldArray3DObject(Parent: Integer; Path: String; X, Y, Z: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray3DObject.');
  Result := std_getFieldArray3DObject(Parent, Path, X, Y, Z);
  if(UseMemManagement)then
    if(Result > 0)then
      AddOpenObject(Result);
end;

function GetFieldArray3DString(Parent: Integer; Path: String; X, Y, Z: Integer): String; stdcall;
var
  JStr: Integer;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray3DString.');
  JStr := std_getFieldArray3DObject(Parent, Path, X, Y, Z);
  SetLength(Result, 512);
  SetLength(Result, StringFromString(JStr, Result));
  Result := StringReplace(Result, 'Â', '', [rfReplaceAll]);
  Result := StringReplace(Result, #160, #32, [rfReplaceAll]);
  std_freeObject(JStr);
end;

function GetFieldArray3DInt(Parent: Integer; Path: String; X, Y, Z: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray3DInt.');
  Result := std_getFieldArray3DInt(Parent, Path, X, Y, Z);
end;

function GetFieldArray3DFloat(Parent: Integer; Path: String; X, Y, Z: Integer): Extended; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray3DFloat.');
  Result := std_getFieldArray3DFloat(Parent, Path, X, Y, Z);
end;

function GetFieldArray3DDouble(Parent: Integer; Path: String; X, Y, Z: Integer): Extended; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray3DDouble.');
  Result := std_getFieldArray3DDouble(Parent, Path, X, Y, Z);
end;

function GetFieldArray3DBoolean(Parent: Integer; Path: String; X, Y, Z: Integer): Boolean; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray3DBoolean.');
  Result := std_getFieldArray3DBool(Parent, Path, X, Y, Z);
end;

function GetFieldArray3DLongH(Parent: Integer; Path: String; X, Y, Z: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray3DLongH.');
  Result := std_getFieldArray3DLongH(Parent, Path, X, Y, Z);
end;

function GetFieldArray3DLongL(Parent: Integer; Path: String; X, Y, Z: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray3DLongL.');
  Result := std_getFieldArray3DLongL(Parent, Path, X, Y, Z);
end;

function GetFieldArray3DByte(Parent: Integer; Path: String; X, Y, Z: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray3DByte.');
  Result := std_getFieldArray3DByte(Parent, Path, X, Y, Z);
end;

function GetFieldArray3DShort(Parent: Integer; Path: String; X, Y, Z: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray3DShort.');
  Result := std_getFieldArray3DShort(Parent, Path, X, Y, Z);
end;

function GetFieldArray3DChar(Parent: Integer; Path: String; X, Y, Z: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArray3DChar.');
  Result := std_getFieldArray3DChar(Parent, Path, X, Y, Z);
  if(UseMemManagement)then
    if(Result > 0)then
      AddOpenObject(Result);
end;

function GetFieldArraySize(Parent: Integer; Path: String; Dim: Integer): Integer; stdcall;
begin
  if(Parent < 0)then
    Raise EObjectException.Create('An invalid parent has been passed to GetFieldArraySize.');
  Result := std_getFieldArraySize(Parent, Path, Dim);
end;

function IsEqual(ObjA, ObjB: Integer): Boolean; stdcall;
begin
  if(ObjA < 0)or(ObjB < 0)then
    Raise EObjectException.Create('An invalid object has been passed to IsEqual.');
  Result := std_isEqual(ObjA, ObjB);
end;

function IsNull(Obj: Integer): Boolean; stdcall;
begin
  if(Obj < 0)then
    Raise EObjectException.Create('An invalid object has been passed to IsNull.');
  Result := std_isNull(Obj);
end;

procedure SetDebug(Debug: Boolean);
begin
  std_setDebug(Debug);
end;

procedure CleanSmartObjects(); stdcall;
var
  I: Integer;
begin
  Writeln('Cleaning '+IntToStr(Length(OpenObjects))+' objects from SMART.');
  for I := 0 to High(OpenObjects)do
  begin
    std_freeObject(OpenObjects[I]);
  end;
  SetLength(OpenObjects, 0);
end;

function GetFunctionCount(): Integer; stdcall; export;
begin
  Result := 85;
end;

function GetFunctionCallingConv(X : Integer) : Integer; stdcall; export;
begin
  Result := 0;
  case X of
    0 : Result := 1;
  end;
end;

function GetFunctionInfo(X: Integer; var ProcAddr: Pointer; var ProcDef: PChar): Integer; stdcall; export;
begin
  case X of
    0:
      begin
        ProcAddr := @SmartSetup;
        StrPCopy(ProcDef, 'procedure SmartSetup(Root, Params: String; Width, Height: Integer; InitSeq: String);');
      end;
    1..28: libs_GetFunctionInfo(X, ProcAddr, ProcDef);
    29: libs_GetFunctionInfo(32, ProcAddr, ProcDef);
    37:
      begin
        ProcAddr := @SetMemoryManagement;
        StrPCopy(ProcDef, 'procedure SetMemoryManagement(Use: Boolean);');
      end;
    30:
      begin
        ProcAddr := @PrintOpenObjects;
        StrPCopy(ProcDef, 'procedure PrintOpenObjects;');
      end;
    39:
      begin
        ProcAddr := @IsPathValid;
        StrPCopy(ProcDef, 'function SmartIsPathValid(Parent: Integer; Path: String): Boolean;');
      end;
    35:
      begin
        ProcAddr := @FreeObject;
        StrPCopy(ProcDef, 'procedure SmartFreeObject(Obj: Integer);');
      end;
    31:
      begin
        ProcAddr := @StringFromBytes;
        StrPCopy(ProcDef, 'function SmartStringFromBytes(Bytes: Integer; Str: String): Integer;');
      end;
    32:
      begin
        ProcAddr := @StringFromChars;
        StrPCopy(ProcDef, 'function SmartStringFromChars(Chars: Integer; Str: String): Integer;');
      end;
    33:
      begin
        ProcAddr := @StringFromString;
        StrPCopy(ProcDef, 'function SmartStringFromString(JStr: Integer; Str: String): Integer;');
      end;
    34:
      begin
        ProcAddr := @GetFieldObject;
        StrPCopy(ProcDef, 'function SmartGetFieldObject(Parent: Integer; Path: String): Integer;');
      end;
    38:
      begin
        ProcAddr := @GetFieldString;
        StrPCopy(ProcDef, 'function SmartGetFieldString(Parent: Integer; Path: String): String;');
      end;
    40:
      begin
        ProcAddr := @GetFieldInt;
        StrPCopy(ProcDef, 'function SmartGetFieldInt(Parent: Integer; Path: String): Integer;');
      end;
    41:
      begin
        ProcAddr := @GetFieldShort;
        StrPCopy(ProcDef, 'function SmartGetFieldShort(Parent: Integer; Path: String): Integer;');
      end;
    42:
      begin
        ProcAddr := @GetFieldByte;
        StrPCopy(ProcDef, 'function SmartGetFieldByte(Parent: Integer; Path: String): Integer;');
      end;
    43:
      begin
        ProcAddr := @GetFieldFloat;
        StrPCopy(ProcDef, 'function SmartGetFieldFloat(Parent: Integer; Path: String): Extended;');
      end;
    44:
      begin
        ProcAddr := @GetFieldDouble;
        StrPCopy(ProcDef, 'function SmartGetFieldDouble(Parent: Integer; Path: String): Extended;');
      end;
    45:
      begin
        ProcAddr := @GetFieldBoolean;
        StrPCopy(ProcDef, 'function SmartGetFieldBoolean(Parent: Integer; Path: String): Boolean;');
      end;
    46:
      begin
        ProcAddr := @GetFieldLongH;
        StrPCopy(ProcDef, 'function SmartGetFieldLongH(Parent: Integer; Path: String): Integer;');
      end;
    47:
      begin
        ProcAddr := @GetFieldLongL;
        StrPCopy(ProcDef, 'function SmartGetFieldLongL(Parent: Integer; Path: String): Integer;');
      end;
    48:
      begin
        ProcAddr := @GetFieldArrayObject;
        StrPCopy(ProcDef, 'function SmartGetFieldArrayObject(Parent: Integer; Path: String; Index: Integer): Integer;');
      end;
    49:
      begin
        ProcAddr := @GetFieldArrayString;
        StrPCopy(ProcDef, 'function SmartGetFieldArrayString(Parent: Integer; Path: String; Index: Integer): String;');
      end;
    50:
      begin
        ProcAddr := @GetFieldArrayInt;
        StrPCopy(ProcDef, 'function SmartGetFieldArrayInt(Parent: Integer; Path: String; Index: Integer): Integer;');
      end;
    51:
      begin
        ProcAddr := @GetFieldArrayFloat;
        StrPCopy(ProcDef, 'function SmartGetFieldArrayFloat(Parent: Integer; Path: String; Index: Integer): Extended;');
      end;
    52:
      begin
        ProcAddr := @GetFieldArrayDouble;
        StrPCopy(ProcDef, 'function SmartGetFieldArrayDouble(Parent: Integer; Path: String; Index: Integer): Extended;');
      end;
    53:
      begin
        ProcAddr := @GetFieldArrayLongH;
        StrPCopy(ProcDef, 'function SmartGetFieldArrayLongH(Parent: Integer; Path: String; Index: Integer): Integer;');
      end;
    54:
      begin
        ProcAddr := @GetFieldArrayLongL;
        StrPCopy(ProcDef, 'function SmartGetFieldArrayLongL(Parent: Integer; Path: String; Index: Integer): Integer;');
      end;
    55:
      begin
        ProcAddr := @GetFieldArrayBoolean;
        StrPCopy(ProcDef, 'function SmartGetFieldArrayBoolean(Parent: Integer; Path: String; Index: Integer): Boolean;');
      end;
    56:
      begin
        ProcAddr := @GetFieldArrayByte;
        StrPCopy(ProcDef, 'function SmartGetFieldArrayByte(Parent: Integer; Path: String; Index: Integer): Integer;');
      end;
    57:
      begin
        ProcAddr := @GetFieldArrayShort;
        StrPCopy(ProcDef, 'function SmartGetFieldArrayShort(Parent: Integer; Path: String; Index: Integer): Integer;');
      end;
    58:
      begin
        ProcAddr := @GetFieldArrayChar;
        StrPCopy(ProcDef, 'function SmartGetFieldArrayChar(Parent: Integer; Path: String; Index: Integer): Integer;');
      end;
    59:
      begin
        ProcAddr := @GetFieldArray2DObject;
        StrPCopy(ProcDef, 'function SmartGetFieldArray2DObject(Parent: Integer; Path: String; X, Y: Integer): Integer;');
      end;
    60:
      begin
        ProcAddr := @GetFieldArray2DString;
        StrPCopy(ProcDef, 'function SmartGetFieldArray2DString(Parent: Integer; Path: String; X, Y: Integer): String;');
      end;
    61:
      begin
        ProcAddr := @GetFieldArray2DInt;
        StrPCopy(ProcDef, 'function SmartGetFieldArray2DInt(Parent: Integer; Path: String; X, Y: Integer): Integer;');
      end;
    62:
      begin
        ProcAddr := @GetFieldArray2DFloat;
        StrPCopy(ProcDef, 'function SmartGetFieldArray2DFloat(Parent: Integer; Path: String; X, Y: Integer): Extended;');
      end;
    63:
      begin
        ProcAddr := @GetFieldArray2DDouble;
        StrPCopy(ProcDef, 'function SmartGetFieldArray2DDouble(Parent: Integer; Path: String; X, Y: Integer): Extended;');
      end;
    64:
      begin
        ProcAddr := @GetFieldArray2DBoolean;
        StrPCopy(ProcDef, 'function SmartGetFieldArray2DBoolean(Parent: Integer; Path: String; X, Y: Integer): Boolean;');
      end;
    65:
      begin
        ProcAddr := @GetFieldArray2DLongH;
        StrPCopy(ProcDef, 'function SmartGetFieldArray2DLongH(Parent: Integer; Path: String; X, Y: Integer): Integer;');
      end;
    66:
      begin
        ProcAddr := @GetFieldArray2DLongL;
        StrPCopy(ProcDef, 'function SmartGetFieldArray2DLongL(Parent: Integer; Path: String; X, Y: Integer): Integer;');
      end;
    67:
      begin
        ProcAddr := @GetFieldArray2DByte;
        StrPCopy(ProcDef, 'function SmartGetFieldArray2DByte(Parent: Integer; Path: String; X, Y: Integer): Integer;');
      end;
    68:
      begin
        ProcAddr := @GetFieldArray2DShort;
        StrPCopy(ProcDef, 'function SmartGetFieldArray2DShort(Parent: Integer; Path: String; X, Y: Integer): Integer;');
      end;
    69:
      begin
        ProcAddr := @GetFieldArray2DChar;
        StrPCopy(ProcDef, 'function SmartGetFieldArray2DChar(Parent: Integer; Path: String; X, Y: Integer): Integer;');
      end;
    70:
      begin
        ProcAddr := @GetFieldArray3DObject;
        StrPCopy(ProcDef, 'function SmartGetFieldArray3DObject(Parent: Integer; Path: String; X, Y, Z: Integer): Integer;');
      end;
    71:
      begin
        ProcAddr := @GetFieldArray3DString;
        StrPCopy(ProcDef, 'function SmartGetFieldArray3DString(Parent: Integer; Path: String; X, Y, Z: Integer): String;');
      end;
    72:
      begin
        ProcAddr := @GetFieldArray3DInt;
        StrPCopy(ProcDef, 'function SmartGetFieldArray3DInt(Parent: Integer; Path: String; X, Y, Z: Integer): Integer;');
      end;
    73:
      begin
        ProcAddr := @GetFieldArray3DFloat;
        StrPCopy(ProcDef, 'function SmartGetFieldArray3DFloat(Parent: Integer; Path: String; X, Y, Z: Integer): Extended;');
      end;
    74:
      begin
        ProcAddr := @GetFieldArray3DDouble;
        StrPCopy(ProcDef, 'function SmartGetFieldArray3DDouble(Parent: Integer; Path: String; X, Y, Z: Integer): Extended;');
      end;
    75:
      begin
        ProcAddr := @GetFieldArray3DBoolean;
        StrPCopy(ProcDef, 'function SmartGetFieldArray23DBoolean(Parent: Integer; Path: String; X, Y, Z: Integer): Boolean;');
      end;
    76:
      begin
        ProcAddr := @GetFieldArray3DLongH;
        StrPCopy(ProcDef, 'function SmartGetFieldArray3DLongH(Parent: Integer; Path: String; X, Y, Z: Integer): Integer;');
      end;
    77:
      begin
        ProcAddr := @GetFieldArray3DLongL;
        StrPCopy(ProcDef, 'function SmartGetFieldArray3DLongL(Parent: Integer; Path: String; X, Y, Z: Integer): Integer;');
      end;
    78:
      begin
        ProcAddr := @GetFieldArray3DByte;
        StrPCopy(ProcDef, 'function SmartGetFieldArray3DByte(Parent: Integer; Path: String; X, Y, Z: Integer): Integer;');
      end;
    79:
      begin
        ProcAddr := @GetFieldArray3DShort;
        StrPCopy(ProcDef, 'function SmartGetFieldArray3DShort(Parent: Integer; Path: String; X, Y, Z: Integer): Integer;');
      end;
    80:
      begin
        ProcAddr := @GetFieldArray3DChar;
        StrPCopy(ProcDef, 'function SmartGetFieldArray3DChar(Parent: Integer; Path: String; X, Y, Z: Integer): Integer;');
      end;
    81:
      begin
        ProcAddr := @GetFieldArraySize;
        StrPCopy(ProcDef, 'function SmartGetFieldArraySize(Parent: Integer; Path: String; Dim: Integer): Integer;');
      end;
    82:
      begin
        ProcAddr := @IsEqual;
        StrPCopy(ProcDef, 'function SmartIsEqual(ObjA, ObjB: Integer): Boolean;');
      end;
    83:
      begin
        ProcAddr := @IsNull;
        StrPCopy(ProcDef, 'function SmartIsNull(Obj: Integer): Boolean;');
      end;
    84:
      begin
        ProcAddr := @SetDebug;
        StrPCopy(ProcDef, 'procedure SmartSetDebug(Debug: Boolean);');
      end;
    36:
      begin
        ProcAddr := @CleanSmartObjects;
        StrPCopy(ProcDef, 'procedure CleanSmartObjects;');
      end;
    else
      X := -1;
  end;
  Result := X;
end;

exports GetFunctionCount;
exports GetFunctionInfo;
exports GetFunctionCallingConv;
exports PrintOpenObjects;
exports SmartSetup;
exports StringFromBytes;
exports StringFromChars;
exports StringFromString;
exports GetFieldObject;
exports FreeObject;
exports CleanSmartObjects;
exports SetMemoryManagement;
exports GetFieldString;
exports IsPathValid;
exports GetFieldInt;
exports GetFieldShort;
exports GetFieldByte;
exports GetFieldFloat;
exports GetFieldDouble;
exports GetFieldBoolean;
exports GetFieldLongH;
exports GetFieldLongL;
exports GetFieldArrayObject;
exports GetFieldArrayString;
exports GetFieldArrayInt;
exports GetFieldArrayFloat;
exports GetFieldArrayDouble;
exports GetFieldArrayLongH;
exports GetFieldArrayLongL;
exports GetFieldArrayBoolean;
exports GetFieldArrayByte;
exports GetFieldArrayShort;
exports GetFieldArrayChar;
exports GetFieldArray2DObject;
exports GetFieldArray2DString;
exports GetFieldArray2DInt;
exports GetFieldArray2DFloat;
exports GetFieldArray2DDouble;
exports GetFieldArray2DBoolean;
exports GetFieldArray2DLongH;
exports GetFieldArray2DLongL;
exports GetFieldArray2DByte;
exports GetFieldArray2DShort;
exports GetFieldArray2DChar;
exports GetFieldArray3DObject;
exports GetFieldArray3DString;
exports GetFieldArray3DInt;
exports GetFieldArray3DFloat;
exports GetFieldArray3DDouble;
exports GetFieldArray3DBoolean;
exports GetFieldArray3DLongH;
exports GetFieldArray3DLongL;
exports GetFieldArray3DByte;
exports GetFieldArray3DShort;
exports GetFieldArray3DChar;
exports GetFieldArraySize;
exports IsEqual;
exports IsNull;
exports SetDebug;

initialization

SmartLib := LoadLibrary('libsmart.' + SharedSuffiX);
if(SmartLib = 0)then
begin
  SmartLib := LoadLibrary('Plugins/libsmart.' + SharedSuffiX);
  if(SmartLib = 0)then
  begin
     Writeln('****error loading libsmart into libreflection!****');
     EXit;
  end;
end;

Writeln('LibSmart loaded in LibReflection!');
Pointer(libs_GetFunctionCount) := GetProcedureAddress(SmartLib, PChar('GetFunctionCount'));
Writeln('Loaded ' + IntToStr(libs_GetFunctionCount()) + ' functions from SMART.');
Pointer(libs_GetFunctionInfo) := GetProcedureAddress(SmartLib, PChar('GetFunctionInfo'));

Pointer(std_setup) := GetProcedureAddress(SmartLib, PChar('std_setup'));
Pointer(std_stringFromBytes) := GetProcedureAddress(SmartLib, PChar('std_stringFromBytes'));
Pointer(std_stringFromChars) := GetProcedureAddress(SmartLib, PChar('std_stringFromChars'));
Pointer(std_stringFromString) := GetProcedureAddress(SmartLib, PChar('std_stringFromString'));
Pointer(std_getFieldObject) := GetProcedureAddress(SmartLib, PChar('std_getFieldObject'));
Pointer(std_isPathValid) := GetProcedureAddress(SmartLib, PChar('std_isPathValid'));
Pointer(std_getFieldInt) := GetProcedureAddress(SmartLib, PChar('std_getFieldInt'));
Pointer(std_getFieldShort) := GetProcedureAddress(SmartLib, PChar('std_getFieldShort'));
Pointer(std_getFieldByte) := GetProcedureAddress(SmartLib, PChar('std_getFieldByte'));
Pointer(std_getFieldFloat) := GetProcedureAddress(SmartLib, PChar('std_getFieldFloat'));
Pointer(std_getFieldDouble) := GetProcedureAddress(SmartLib, PChar('std_getFieldDouble'));
Pointer(std_getFieldBool) := GetProcedureAddress(SmartLib, PChar('std_getFieldBool'));
Pointer(std_getFieldLongH) := GetProcedureAddress(SmartLib, PChar('std_getFieldLongH'));
Pointer(std_getFieldLongL) := GetProcedureAddress(SmartLib, PChar('std_getFieldLongL'));
Pointer(std_getFieldArrayInt) := GetProcedureAddress(SmartLib, PChar('std_getFieldArrayInt'));
Pointer(std_getFieldArrayFloat) := GetProcedureAddress(SmartLib, PChar('std_getFieldArrayFloat'));
Pointer(std_getFieldArrayDouble) := GetProcedureAddress(SmartLib, PChar('std_getFieldArrayDouble'));
Pointer(std_getFieldArrayLongH) := GetProcedureAddress(SmartLib, PChar('std_getFieldArrayLongH'));
Pointer(std_getFieldArrayLongL) := GetProcedureAddress(SmartLib, PChar('std_getFieldArrayLongL'));
Pointer(std_getFieldArrayBool) := GetProcedureAddress(SmartLib, PChar('std_getFieldArrayBool'));
Pointer(std_getFieldArrayByte) := GetProcedureAddress(SmartLib, PChar('std_getFieldArrayByte'));
Pointer(std_getFieldArrayShort) := GetProcedureAddress(SmartLib, PChar('std_getFieldArrayShort'));
Pointer(std_getFieldArrayChar) := GetProcedureAddress(SmartLib, PChar('std_getFieldArrayChar'));
Pointer(std_getFieldArray3DInt) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray3DInt'));
Pointer(std_getFieldArray3DFloat) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray3DFloat'));
Pointer(std_getFieldArray3DDouble) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray3DDouble'));
Pointer(std_getFieldArray3DBool) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray3DBool'));
Pointer(std_getFieldArray3DLongH) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray3DLongH'));
Pointer(std_getFieldArray3DLongL) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray3DLongL'));
Pointer(std_getFieldArray3DByte) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray3DByte'));
Pointer(std_getFieldArray3DShort) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray3DShort'));
Pointer(std_getFieldArray3DChar) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray3DChar'));
Pointer(std_getFieldArray3DObject) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray3DObject'));
Pointer(std_getFieldArray2DInt) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray2DInt'));
Pointer(std_getFieldArray2DFloat) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray2DFloat'));
Pointer(std_getFieldArray2DDouble) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray2DDouble'));
Pointer(std_getFieldArray2DBool) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray2DBool'));
Pointer(std_getFieldArray2DLongH) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray2DLongH'));
Pointer(std_getFieldArray2DLongL) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray2DLongL'));
Pointer(std_getFieldArray2DByte) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray2DByte'));
Pointer(std_getFieldArray2DShort) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray2DShort'));
Pointer(std_getFieldArray2DChar) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray2DChar'));
Pointer(std_getFieldArray2DObject) := GetProcedureAddress(SmartLib, PChar('std_getFieldArray2DObject'));
Pointer(std_getFieldArrayObject) := GetProcedureAddress(SmartLib, PChar('std_getFieldArrayObject'));
Pointer(std_getFieldArraySize) := GetProcedureAddress(SmartLib, PChar('std_getFieldArraySize'));
Pointer(std_isEqual) := GetProcedureAddress(SmartLib, PChar('std_isEqual'));
Pointer(std_isNull) := GetProcedureAddress(SmartLib, PChar('std_isNull'));
Pointer(std_freeObject) := GetProcedureAddress(SmartLib, PChar('std_freeObject'));
Pointer(std_setDebug) := GetProcedureAddress(SmartLib, PChar('std_setDebug'));
//Pointer() := GetProcedureAddress(SmartLib, PChar('')); <- Template.

finalization

if(SmartLib <> 0)then
  UnloadLibrary(SmartLib);

end.

