{*********************************************************}
{                                                         }
{                 Zeos Database Objects                   }
{                Generic Cached Resolver                  }
{                                                         }
{        Originally written by Sergey Seroukhov           }
{                                                         }
{*********************************************************}

{@********************************************************}
{    Copyright (c) 1999-2012 Zeos Development Group       }
{                                                         }
{ License Agreement:                                      }
{                                                         }
{ This library is distributed in the hope that it will be }
{ useful, but WITHOUT ANY WARRANTY; without even the      }
{ implied warranty of MERCHANTABILITY or FITNESS FOR      }
{ A PARTICULAR PURPOSE.  See the GNU Lesser General       }
{ Public License for more details.                        }
{                                                         }
{ The source code of the ZEOS Libraries and packages are  }
{ distributed under the Library GNU General Public        }
{ License (see the file COPYING / COPYING.ZEOS)           }
{ with the following  modification:                       }
{ As a special exception, the copyright holders of this   }
{ library give you permission to link this library with   }
{ independent modules to produce an executable,           }
{ regardless of the license terms of these independent    }
{ modules, and to copy and distribute the resulting       }
{ executable under terms of your choice, provided that    }
{ you also meet, for each linked independent module,      }
{ the terms and conditions of the license of that module. }
{ An independent module is a module which is not derived  }
{ from or based on this library. If you modify this       }
{ library, you may extend this exception to your version  }
{ of the library, but you are not obligated to do so.     }
{ If you do not wish to do so, delete this exception      }
{ statement from your version.                            }
{                                                         }
{                                                         }
{ The project web site is located on:                     }
{   http://zeos.firmos.at  (FORUM)                        }
{   http://sourceforge.net/p/zeoslib/tickets/ (BUGTRACKER)}
{   svn://svn.code.sf.net/p/zeoslib/code-0/trunk (SVN)    }
{                                                         }
{   http://www.sourceforge.net/projects/zeoslib.          }
{                                                         }
{                                                         }
{                                 Zeos Development Group. }
{********************************************************@}

unit ZDbcGenericResolver;

interface

{$I ZDbc.inc}

uses
  Types, Classes, {$IFDEF MSEgui}mclasses,{$ENDIF} SysUtils, Contnrs,
  ZVariant, ZDbcIntfs, ZDbcCache, ZDbcCachedResultSet, ZCompatibility,
  ZSelectSchema;

type

  {** Implements a resolver parameter object. }
  TZResolverParameter = class (TObject)
  private
    FColumnIndex: Integer;
    FColumnName: string;
    FColumnType: TZSQLType;
    FNewValue: Boolean;
    FDefaultValue: string;
  public
    constructor Create(ColumnIndex: Integer; ColumnName: string;
      ColumnType: TZSQLType; NewValue: Boolean; DefaultValue: string);

    property ColumnIndex: Integer read FColumnIndex write FColumnIndex;
    property ColumnName: string read FColumnName write FColumnName;
    property ColumnType: TZSQLType read FColumnType write FColumnType;
    property NewValue: Boolean read FNewValue write FNewValue;
    property DefaultValue: string read FDefaultValue write FDefaultValue;
  end;

  {**
    Implements a generic cached resolver object which generates
    DML SQL statements and posts resultset updates to database.
  }

  { TZGenericCachedResolver }

  TZGenericCachedResolver = class (TInterfacedObject, IZCachedResolver)
  private
    FConnection: IZConnection;
    FStatement : IZStatement;
    FMetadata: IZResultSetMetadata;
    FDatabaseMetadata: IZDatabaseMetadata;
    FIdentifierConvertor: IZIdentifierConvertor;

    FInsertColumns: TObjectList;
    FUpdateColumns: TObjectList;
    FWhereColumns: TObjectList;

    FCalcDefaults: Boolean;
    FWhereAll: Boolean;
    FUpdateAll: Boolean;

    InsertStatement            : IZPreparedStatement;
    UpdateStatement            : IZPreparedStatement;
    DeleteStatement            : IZPreparedStatement;

  protected
    procedure CopyResolveParameters(FromList, ToList: TObjectList);
    function ComposeFullTableName(Catalog, Schema, Table: string): string;
    function DefineTableName: string;

    function CreateResolverStatement(SQL : String):IZPreparedStatement;

    procedure DefineCalcColumns(Columns: TObjectList;
      RowAccessor: TZRowAccessor);
    procedure DefineInsertColumns(Columns: TObjectList);
    procedure DefineUpdateColumns(Columns: TObjectList;
      OldRowAccessor, NewRowAccessor: TZRowAccessor);
    procedure DefineWhereKeyColumns(Columns: TObjectList);
    procedure DefineWhereAllColumns(Columns: TObjectList; IgnoreKeyColumn: Boolean = False);
    function CheckKeyColumn(ColumnIndex: Integer): Boolean; virtual;

    procedure FillStatement(Statement: IZPreparedStatement;
      Params: TObjectList; OldRowAccessor, NewRowAccessor: TZRowAccessor);

    property Connection: IZConnection read FConnection write FConnection;
    property Metadata: IZResultSetMetadata read FMetadata write FMetadata;
    property DatabaseMetadata: IZDatabaseMetadata read FDatabaseMetadata
      write FDatabaseMetadata;
    property IdentifierConvertor: IZIdentifierConvertor
      read FIdentifierConvertor write FIdentifierConvertor;

    property InsertColumns: TObjectList read FInsertColumns;
    property UpdateColumns: TObjectList read FUpdateColumns;
    property WhereColumns: TObjectList read FWhereColumns;

    property CalcDefaults: Boolean read FCalcDefaults write FCalcDefaults;
    property WhereAll: Boolean read FWhereAll write FWhereAll;
    property UpdateAll: Boolean read FUpdateAll write FUpdateAll;

  public
    constructor Create(Statement: IZStatement; Metadata: IZResultSetMetadata);
    destructor Destroy; override;

    function FormWhereClause(Columns: TObjectList;
      OldRowAccessor: TZRowAccessor): string; virtual;
    function FormInsertStatement(Columns: TObjectList;
      NewRowAccessor: TZRowAccessor): string;
    function FormUpdateStatement(Columns: TObjectList;
      OldRowAccessor, NewRowAccessor: TZRowAccessor): string;
    function FormDeleteStatement(Columns: TObjectList;
      OldRowAccessor: TZRowAccessor): string;
    function FormCalculateStatement(Columns: TObjectList): string; virtual;

    procedure CalculateDefaults(Sender: IZCachedResultSet;
      RowAccessor: TZRowAccessor);
    procedure PostUpdates(Sender: IZCachedResultSet;
      UpdateType: TZRowUpdateType;
      OldRowAccessor, NewRowAccessor: TZRowAccessor); virtual;
    {BEGIN of PATCH [1185969]: Do tasks after posting updates. ie: Updating AutoInc fields in MySQL }
    procedure UpdateAutoIncrementFields(Sender: IZCachedResultSet;
      UpdateType: TZRowUpdateType;
      OldRowAccessor, NewRowAccessor: TZRowAccessor; Resolver: IZCachedResolver); virtual;
    {END of PATCH [1185969]: Do tasks after posting updates. ie: Updating AutoInc fields in MySQL }
    procedure RefreshCurrentRow(Sender: IZCachedResultSet;RowAccessor: TZRowAccessor); //FOS+ 07112006

  end;

implementation

uses ZMessages, ZSysUtils, ZDbcMetadata, ZDbcUtils;

{ TZResolverParameter }

{**
  Constructs this resolver parameter and assignes the main properties.
  @param ColumnIndex a result set column index.
  @param ColumnName a result set column name.
  @param NewValue <code>True</code> for new value and <code>False</code>
    for an old one.
  @param DefaultValue a default column value to evalute on server.
}
constructor TZResolverParameter.Create(ColumnIndex: Integer;
  ColumnName: string; ColumnType: TZSQLType; NewValue: Boolean; DefaultValue: string);
begin
  FColumnType := ColumnType;
  FColumnIndex := ColumnIndex;
  FColumnName := ColumnName;
  FNewValue := NewValue;
  FDefaultValue := DefaultValue;
end;

{ TZGenericCachedResolver }

{**
  Creates a cached resolver and assignes the main properties.
  @param ResultSet a related ResultSet object.
}
constructor TZGenericCachedResolver.Create(Statement: IZStatement;
  Metadata: IZResultSetMetadata);
begin
  FStatement := Statement;
  FConnection := Statement.GetConnection;
  FMetadata := Metadata;
  FDatabaseMetadata := Statement.GetConnection.GetMetadata;
  FIdentifierConvertor := FDatabaseMetadata.GetIdentifierConvertor;

  FInsertColumns := TObjectList.Create(True);
  FWhereColumns := TObjectList.Create(True);
  FUpdateColumns := TObjectList.Create(True);

  FCalcDefaults := StrToBoolEx(DefineStatementParameter(Statement,
    'defaults', 'true'));
  FUpdateAll := UpperCase(DefineStatementParameter(Statement,
    'update', 'changed')) = 'ALL';
  FWhereAll := UpperCase(DefineStatementParameter(Statement,
    'where', 'keyonly')) = 'ALL';

  InsertStatement := nil;
  UpdateStatement := nil;
  DeleteStatement := nil;

end;

{**
  Destroys this object and cleanups the memory.
}
destructor TZGenericCachedResolver.Destroy;
begin
  FMetadata := nil;
  FDatabaseMetadata := nil;

  FreeAndNil(FInsertColumns);
  FreeAndNil(FUpdateColumns);
  FreeAndNil(FWhereColumns);

  inherited Destroy;
end;

{**
  Copies resolver parameters from source list to destination list.
  @param FromList the source object list.
  @param ToList the destination object list.
}
procedure TZGenericCachedResolver.CopyResolveParameters(
  FromList: TObjectList; ToList: TObjectList);
var
  I: Integer;
  Current: TZResolverParameter;
begin
  for I := 0 to FromList.Count - 1 do
  begin
    Current := TZResolverParameter(FromList[I]);
    if Current.ColumnName <> '' then
      ToList.Add(TZResolverParameter.Create(Current.ColumnIndex,
        Current.ColumnName, Current.ColumnType, Current.NewValue, ''));
  end;
end;

{**
  Composes a fully quilified table name.
  @param Catalog a table catalog name.
  @param Schema a table schema name.
  @param Table a table name.
  @return a fully qualified table name.
}
function TZGenericCachedResolver.ComposeFullTableName(Catalog, Schema,
  Table: string): string;
begin
  if Table <> '' then
  begin
    Result := IdentifierConvertor.Quote(Table);
    if Schema <> '' then
      Result := IdentifierConvertor.Quote(Schema) + '.' + Result;
    if Catalog <> '' then
      Result := IdentifierConvertor.Quote(Catalog) + '.' + Result;
  end
  else
    Result := '';
end;

{**
  Defines a table name from the select statement.
}
function TZGenericCachedResolver.DefineTableName: string;
var
  I: Integer;
  Temp: string;
begin
  Result := '';
  for I := 1 to Metadata.GetColumnCount do
  begin
    Temp := ComposeFullTableName(Metadata.GetCatalogName(I),
      Metadata.GetSchemaName(I), Metadata.GetTableName(I));
    if (Result = '') and (Temp <> '') then
      Result := Temp
    else if (Result <> '') and (Temp <> '') and (Temp <> Result) then
      raise EZSQLException.Create(SCanNotUpdateComplexQuery);
  end;
  if Result = '' then
    raise EZSQLException.Create(SCanNotUpdateThisQueryType);
end;

function TZGenericCachedResolver.CreateResolverStatement(SQL: String): IZPreparedStatement;
var
  Temp : TStrings;
begin
  if StrToBoolEx(FStatement.GetParameters.Values['preferprepared']) then
    begin
      Temp := TStringList.Create;
      Temp.Values['preferprepared'] := 'true';
      if not ( Connection.GetParameters.Values['chunk_size'] = '' ) then //ordered by precedence
        Temp.Values['chunk_size'] := Connection.GetParameters.Values['chunk_size']
      else
        Temp.Values['chunk_size'] := FStatement.GetParameters.Values['chunk_size'];
      Result := Connection.PrepareStatementWithParams(SQL, Temp);
      Temp.Free;
    end
  else
    Result := Connection.PrepareStatement(SQL);

end;

{**
  Gets a collection of data columns for INSERT statements.
  @param Columns a collection of columns.
}
procedure TZGenericCachedResolver.DefineInsertColumns(Columns: TObjectList);
var
  I: Integer;
begin
  { Precache insert parameters. }
  if InsertColumns.Count = 0 then
  begin
    for I := 1 to Metadata.GetColumnCount do
    begin
      if (Metadata.GetTableName(I) <> '') and (Metadata.GetColumnName(I) <> '')
        and Metadata.IsWritable(I) then
      begin
        InsertColumns.Add(TZResolverParameter.Create(I,
          Metadata.GetColumnName(I), Metadata.GetColumnType(I), True, ''));
      end;
    end;
  end;
  { Use cached insert parameters }
  CopyResolveParameters(InsertColumns, Columns);
end;

{**
  Gets a collection of data columns for UPDATE statements.
  @param Columns a collection of columns.
  @param OldRowAccessor an accessor object to old column values.
  @param NewRowAccessor an accessor object to new column values.
}
procedure TZGenericCachedResolver.DefineUpdateColumns(
  Columns: TObjectList; OldRowAccessor, NewRowAccessor: TZRowAccessor);
var
  I: Integer;
  ColumnIndices: TIntegerDynArray;
  ColumnDirs: TBooleanDynArray;
begin
  { Use precached parameters. }
  if UpdateAll and (UpdateColumns.Count > 0) then
  begin
    CopyResolveParameters(UpdateColumns, Columns);
    Exit;
  end;

  { Defines parameters for UpdateAll mode. }
  if UpdateAll then
  begin
    for I := 1 to Metadata.GetColumnCount do
    begin
      if (Metadata.GetTableName(I) <> '') and (Metadata.GetColumnName(I) <> '')
        and Metadata.IsWritable(I) then
      begin
        UpdateColumns.Add(TZResolverParameter.Create(I,
          Metadata.GetColumnName(I), Metadata.GetColumnType(I), True, ''));
      end;
    end;
    CopyResolveParameters(UpdateColumns, Columns);
  end
  { Defines parameters for UpdateChanged mode. }
  else
  begin
    SetLength(ColumnIndices, 1);
    SetLength(ColumnDirs, 1);
    ColumnDirs[0] := True;
    for I := 1 to Metadata.GetColumnCount do
    begin
      ColumnIndices[0] := I;
      if (Metadata.GetTableName(I) <> '') and (Metadata.GetColumnName(I) <> '')
        and Metadata.IsWritable(I) and (OldRowAccessor.CompareBuffers(
        OldRowAccessor.RowBuffer, NewRowAccessor.RowBuffer, ColumnIndices,
        ColumnDirs) <> 0)then
      begin
        Columns.Add(TZResolverParameter.Create(I,
          Metadata.GetColumnName(I), Metadata.GetColumnType(I), True, ''));
      end;
    end;
  end;
end;

{**
  Gets a collection of where key columns for DELETE or UPDATE DML statements.
  @param Columns a collection of key columns.
}
procedure TZGenericCachedResolver.DefineWhereKeyColumns(Columns: TObjectList);
var
  I: Integer;
  Found: Boolean;
  ColumnName: string;
  Catalog, Schema, Table: string;
  PrimaryKeys: IZResultSet;
begin
  { Use precached values. }
  if WhereColumns.Count > 0 then
  begin
    CopyResolveParameters(WhereColumns, Columns);
    Exit;
  end;

  { Defines catalog, schema and a table. }
  Table := DefineTableName;
  for I := 1 to Metadata.GetColumnCount do
  begin
    Table := Metadata.GetTableName(I);
    if Table <> '' then
    begin
      Schema := Metadata.GetSchemaName(I);
      Catalog := Metadata.GetCatalogName(I);
      Break;
    end;
  end;

  { Tryes to define primary keys. }
  if not WhereAll then
  begin
    PrimaryKeys := DatabaseMetadata.GetPrimaryKeys(Catalog, Schema, Table);
    while PrimaryKeys.Next do
    begin
      ColumnName := PrimaryKeys.GetString(4);
      Found := False;
      for I := 1 to Metadata.GetColumnCount do
      begin
        if (ColumnName = Metadata.GetColumnName(I))
          and (Table = Metadata.GetTableName(I)) then
        begin
          Found := True;
          Break;
        end;
      end;
      if not Found then
      begin
        WhereColumns.Clear;
        Break;
      end;
      WhereColumns.Add(TZResolverParameter.Create(I, ColumnName,
        stUnknown, False, ''));
    end;
  end;

  if WhereColumns.Count > 0 then
    CopyResolveParameters(WhereColumns, Columns)
  else
    DefineWhereAllColumns(Columns);
end;

{**
  Gets a collection of where all columns for DELETE or UPDATE DML statements.
  @param Columns a collection of key columns.
}
procedure TZGenericCachedResolver.DefineWhereAllColumns(Columns: TObjectList;
  IgnoreKeyColumn: Boolean = False);
var
  I: Integer;
begin
  { Use precached values. }
  if WhereColumns.Count > 0 then
  begin
    CopyResolveParameters(WhereColumns, Columns);
    Exit;
  end;

  { Takes a a key all non-blob fields. }
  for I := 1 to Metadata.GetColumnCount do
  begin
    if CheckKeyColumn(I) then
      WhereColumns.Add(TZResolverParameter.Create(I,
        Metadata.GetColumnName(I), Metadata.GetColumnType(I), False, ''))
    else
      if IgnoreKeyColumn then
        WhereColumns.Add(TZResolverParameter.Create(I,
          Metadata.GetColumnName(I), Metadata.GetColumnType(I), False, ''));
  end;
  if ( WhereColumns.Count = 0 ) and ( not IgnoreKeyColumn ) then
    DefineWhereAllColumns(Columns, True)
  else
    { Copy defined parameters to target columns }
    CopyResolveParameters(WhereColumns, Columns);
end;

{**
  Checks is the specified column can be used in where clause.
  @param ColumnIndex an index of the column.
  @returns <code>true</code> if column can be included into where clause.
}
function TZGenericCachedResolver.CheckKeyColumn(ColumnIndex: Integer): Boolean;
begin
  Result := (Metadata.GetTableName(ColumnIndex) <> '')
    and (Metadata.GetColumnName(ColumnIndex) <> '')
    and Metadata.IsSearchable(ColumnIndex)
    and not (Metadata.GetColumnType(ColumnIndex)
    in [stUnknown, stAsciiStream, stBinaryStream, stUnicodeStream]);
end;

{**
  Gets a collection of data columns to initialize before INSERT statements.
  @param Columns a collection of columns.
  @param RowAccessor an accessor object to column values.
}
procedure TZGenericCachedResolver.DefineCalcColumns(Columns: TObjectList;
  RowAccessor: TZRowAccessor);
var
  I: Integer;
begin
  for I := 1 to Metadata.GetColumnCount do
  begin
    if RowAccessor.IsNull(I) and (Metadata.GetTableName(I) <> '')
      and ((Metadata.GetDefaultValue(I) <> '') or (RowAccessor.GetColumnDefaultExpression(I) <> '')) then
    begin
      // DefaultExpression takes takes precedence on database default value
      if RowAccessor.GetColumnDefaultExpression(I) <> '' then
        Columns.Add(TZResolverParameter.Create(I,
          Metadata.GetColumnName(I), Metadata.GetColumnType(I),
          True, RowAccessor.GetColumnDefaultExpression(I)))
      else
        Columns.Add(TZResolverParameter.Create(I,
          Metadata.GetColumnName(I), Metadata.GetColumnType(I),
          True, Metadata.GetDefaultValue(I)));
    end;
  end;
end;

{**
  Fills the specified statement with stored or given parameters.
  @param ResultSet a source result set object.
  @param Statement a DBC statement object.
  @param Config an UpdateStatement configuration.
  @param OldRowAccessor an accessor object to old column values.
  @param NewRowAccessor an accessor object to new column values.
}
procedure TZGenericCachedResolver.FillStatement(Statement: IZPreparedStatement;
  Params: TObjectList; OldRowAccessor, NewRowAccessor: TZRowAccessor);
var
  I: Integer;
  ColumnIndex: Integer;
  Current: TZResolverParameter;
  RowAccessor: TZRowAccessor;
  WasNull: Boolean;
begin
  WasNull := False;
  for I := 0 to Params.Count - 1 do
  begin
    Current := TZResolverParameter(Params[I]);
    if Current.NewValue then
      RowAccessor := NewRowAccessor
    else
      RowAccessor := OldRowAccessor;
    ColumnIndex := Current.ColumnIndex;

    if FCalcDefaults then
      Statement.SetDefaultValue(I + 1, Metadata.GetDefaultValue(ColumnIndex));

    case Metadata.GetColumnType(ColumnIndex) of
      stBoolean:
        Statement.SetBoolean(I + 1,
          RowAccessor.GetBoolean(ColumnIndex, WasNull));
      stByte:
        Statement.SetByte(I + 1, RowAccessor.GetByte(ColumnIndex, WasNull));
      stShort:
        Statement.SetShort(I + 1, RowAccessor.GetShort(ColumnIndex, WasNull));
      stInteger:
        Statement.SetInt(I + 1, RowAccessor.GetInt(ColumnIndex, WasNull));
      stLong:
        Statement.SetLong(I + 1, RowAccessor.GetLong(ColumnIndex, WasNull));
      stFloat:
        Statement.SetFloat(I + 1, RowAccessor.GetFloat(ColumnIndex, WasNull));
      stDouble:
        Statement.SetDouble(I + 1, RowAccessor.GetDouble(ColumnIndex, WasNull));
      stBigDecimal:
        Statement.SetBigDecimal(I + 1,
          RowAccessor.GetBigDecimal(ColumnIndex, WasNull));
      stString:
        Statement.SetString(I + 1, RowAccessor.GetString(ColumnIndex, WasNull));
      stUnicodeString:
        Statement.SetUnicodeString(I + 1,
          RowAccessor.GetUnicodeString(ColumnIndex, WasNull));
      stBytes, stGUID:
        Statement.SetBytes(I + 1, RowAccessor.GetBytes(ColumnIndex, WasNull));
      stDate:
        Statement.SetDate(I + 1, RowAccessor.GetDate(ColumnIndex, WasNull));
      stTime:
        Statement.SetTime(I + 1, RowAccessor.GetTime(ColumnIndex, WasNull));
      stTimestamp:
        Statement.SetTimestamp(I + 1,
          RowAccessor.GetTimestamp(ColumnIndex, WasNull));
      stAsciiStream:
         Statement.SetBlob(I + 1, stAsciiStream,
           RowAccessor.GetBlob(ColumnIndex, WasNull));
      stUnicodeStream:
         Statement.SetBlob(I + 1, stUnicodeStream,
           RowAccessor.GetBlob(ColumnIndex, WasNull));
      stBinaryStream:
         Statement.SetBlob(I + 1, stBinaryStream,
           RowAccessor.GetBlob(ColumnIndex, WasNull));
    end;
    if WasNull then
      Statement.SetNull(I + 1, Metadata.GetColumnType(ColumnIndex))
  end;
end;

{**
  Forms a where clause for UPDATE or DELETE DML statements.
  @param Columns a collection of key columns.
  @param OldRowAccessor an accessor object to old column values.
}
function TZGenericCachedResolver.FormWhereClause(Columns: TObjectList;
  OldRowAccessor: TZRowAccessor): string;
var
  I, N: Integer;
  Current: TZResolverParameter;
begin
  Result := '';
  N := Columns.Count - WhereColumns.Count;

  for I := 0 to WhereColumns.Count - 1 do
  begin
    Current := TZResolverParameter(WhereColumns[I]);
    if Result <> '' then
      Result := Result + ' AND ';

    Result := Result + IdentifierConvertor.Quote(Current.ColumnName);
    if OldRowAccessor.IsNull(Current.ColumnIndex) then
    begin
      Result := Result + ' IS NULL ';
      Columns.Delete(N);
    end
    else
    begin
      Result := Result + '=?';
      Inc(N);
    end;
  end;

  if Result <> '' then
    Result := ' WHERE ' + Result;
end;

{**
  Forms a where clause for INSERT statements.
  @param Columns a collection of key columns.
  @param NewRowAccessor an accessor object to new column values.
}
function TZGenericCachedResolver.FormInsertStatement(Columns: TObjectList;
  NewRowAccessor: TZRowAccessor): string;
var
  I: Integer;
  Current: TZResolverParameter;
  TableName: string;
  Temp1, Temp2: string;
  l1: Integer; 

  procedure Append(const app: String); 
  begin 
    if Length(Temp1) < l1 + length(app) then 
      SetLength(Temp1, 2 * (length(app) + l1)); 
    Move(app[1], Temp1[l1+1], length(app)*SizeOf(Char)); 
    Inc(l1, length(app)); 
  end; 

begin
  TableName := DefineTableName;
  DefineInsertColumns(Columns);
  if Columns.Count = 0 then
  begin
    Result := '';
    Exit;
  end;

  Temp1 := '';    l1 := 0; 
  SetLength(Temp2, 2 * Columns.Count - 1); 
  for I := 0 to Columns.Count - 1 do 
  begin 
    Current := TZResolverParameter(Columns[I]); 
    if Temp1 <> '' then 
      Append(','); 
    Append(IdentifierConvertor.Quote(Current.ColumnName)); 
    if I > 0 then 
      Temp2[I*2] := ','; 
    Temp2[I*2+1] := '?'; 
  end; 
  SetLength(Temp1, l1); 
  Result := Format('INSERT INTO %s (%s) VALUES (%s)', [TableName, Temp1, Temp2]);
end;

{**
  Forms a where clause for UPDATE statements.
  @param Columns a collection of key columns.
  @param OldRowAccessor an accessor object to old column values.
  @param NewRowAccessor an accessor object to new column values.
}
function TZGenericCachedResolver.FormUpdateStatement(Columns: TObjectList;
  OldRowAccessor, NewRowAccessor: TZRowAccessor): string;
var
  I: Integer;
  Current: TZResolverParameter;
  TableName: string;
  Temp: string;
begin
  TableName := DefineTableName;
  DefineUpdateColumns(Columns, OldRowAccessor, NewRowAccessor);
  if Columns.Count = 0 then
  begin
    Result := '';
    Exit;
  end;

  Temp := '';
  for I := 0 to Columns.Count - 1 do
  begin
    Current := TZResolverParameter(Columns[I]);
    if Temp <> '' then
      Temp := Temp + ',';
    Temp := Temp + IdentifierConvertor.Quote(Current.ColumnName) + '=?';
  end;

  Result := Format('UPDATE %s SET %s', [TableName, Temp]);
  DefineWhereKeyColumns(Columns);
  Result := Result + FormWhereClause(Columns, OldRowAccessor);
end;

{**
  Forms a where clause for DELETE statements.
  @param Columns a collection of key columns.
  @param OldRowAccessor an accessor object to old column values.
}
function TZGenericCachedResolver.FormDeleteStatement(Columns: TObjectList;
  OldRowAccessor: TZRowAccessor): string;
var
  TableName: string;
begin
  TableName := DefineTableName;
  Result := Format('DELETE FROM %s', [TableName]);
  DefineWhereKeyColumns(Columns);
  Result := Result + FormWhereClause(Columns, OldRowAccessor);
end;

{**
  Forms a where clause for SELECT statements to calculate default values.
  @param Columns a collection of key columns.
  @param OldRowAccessor an accessor object to old column values.
}
function TZGenericCachedResolver.FormCalculateStatement(
  Columns: TObjectList): string;
var
  I: Integer;
  Current: TZResolverParameter;
begin
  Result := '';
  if Columns.Count = 0 then
     Exit;

  for I := 0 to Columns.Count - 1 do
  begin
    Current := TZResolverParameter(Columns[I]);
    if Result <> '' then
      Result := Result + ',';
    if Current.DefaultValue <> '' then
      Result := Result + Current.DefaultValue
    else
      Result := Result + 'NULL';
  end;
  Result := 'SELECT ' + Result;
end;

{**
  Posts updates to database.
  @param Sender a cached result set object.
  @param UpdateType a type of updates.
  @param OldRowAccessor an accessor object to old column values.
  @param NewRowAccessor an accessor object to new column values.
}
procedure TZGenericCachedResolver.PostUpdates(Sender: IZCachedResultSet;
  UpdateType: TZRowUpdateType; OldRowAccessor, NewRowAccessor: TZRowAccessor);
var
  Statement            : IZPreparedStatement;
  SQL                  : string;
  SQLParams            : TObjectList;
  lUpdateCount         : Integer;
  lValidateUpdateCount : Boolean;

begin
  if (UpdateType = utDeleted)
    and (OldRowAccessor.RowBuffer.UpdateType = utInserted) then
    Exit;

  SQLParams := TObjectList.Create(True);
  try
    case UpdateType of
      utInserted:
          begin
        SQL := FormInsertStatement(SQLParams, NewRowAccessor);
            If Assigned(InsertStatement) and (SQL <> InsertStatement.GetSQL) then
              InsertStatement := nil;
            If not Assigned(InsertStatement) then
              InsertStatement := CreateResolverStatement(SQL);
            Statement := InsertStatement;
          end;
      utDeleted:
          begin
        SQL := FormDeleteStatement(SQLParams, OldRowAccessor);
            If Assigned(DeleteStatement) and (SQL <> DeleteStatement.GetSQL) then
              DeleteStatement := nil;
            If not Assigned(DeleteStatement) then
              DeleteStatement := CreateResolverStatement(SQL);
            Statement := DeleteStatement;
          end;
      utModified:
          begin
        SQL := FormUpdateStatement(SQLParams, OldRowAccessor, NewRowAccessor);
            If SQL =''then // no fields have been changed
               exit;
            If Assigned(UpdateStatement) and (SQL <> UpdateStatement.GetSQL) then
              UpdateStatement := nil;
            If not Assigned(UpdateStatement) then
              UpdateStatement := CreateResolverStatement(SQL);
            Statement := UpdateStatement;
          end;
      else
        Exit;
    end;

    if SQL <> '' then
    begin

      FillStatement(Statement, SQLParams, OldRowAccessor, NewRowAccessor);
      // if Property ValidateUpdateCount isn't set : assume it's true
      lValidateUpdateCount := (Sender.GetStatement.GetParameters.IndexOfName('ValidateUpdateCount') = -1)
                            or StrToBoolEx(Sender.GetStatement.GetParameters.Values['ValidateUpdateCount']);

      lUpdateCount := Statement.ExecuteUpdatePrepared;
      {$IFDEF WITH_VALIDATE_UPDATE_COUNT}
      if  (lValidateUpdateCount) and (lUpdateCount <> 1   ) then
        raise EZSQLException.Create(Format(SInvalidUpdateCount, [lUpdateCount]));
      {$ENDIF}
    end;
  finally
    FreeAndNil(SQLParams);
  end;
end;

procedure TZGenericCachedResolver.RefreshCurrentRow(Sender: IZCachedResultSet;  RowAccessor: TZRowAccessor);
begin
 raise EZSQLException.Create(SRefreshRowOnlySupportedWithUpdateObject);
end;

{**
  Calculate default values for the fields.
  @param Sender a cached result set object.
  @param RowAccessor an accessor object to column values.
}
procedure TZGenericCachedResolver.CalculateDefaults(
  Sender: IZCachedResultSet; RowAccessor: TZRowAccessor);
var
  I: Integer;
  SQL: string;
  SQLParams: TObjectList;
  Statement: IZStatement;
  ResultSet: IZResultSet;
  Metadata: IZResultSetMetadata;
  Current: TZResolverParameter;
begin
  if not FCalcDefaults then
     Exit;

  SQLParams := TObjectList.Create(True);
  try
    DefineCalcColumns(SQLParams, RowAccessor);
    SQL := FormCalculateStatement(SQLParams);
    if SQL = '' then
       Exit;

    { Executes statement and fills default fields. }
    Statement := Connection.CreateStatement;
    try
      ResultSet := Statement.ExecuteQuery(SQL);
      if ResultSet.Next then
      begin
        Metadata := ResultSet.GetMetadata;
        for I := 1 to Metadata.GetColumnCount do
        begin
          Current := TZResolverParameter(SQLParams[I - 1]);
          try
            case Current.ColumnType of
              stBoolean:
                RowAccessor.SetBoolean(Current.ColumnIndex,
                  ResultSet.GetBoolean(I));
              stByte:
                RowAccessor.SetByte(Current.ColumnIndex, ResultSet.GetByte(I));
              stShort:
                RowAccessor.SetShort(Current.ColumnIndex, ResultSet.GetShort(I));
              stInteger:
                RowAccessor.SetInt(Current.ColumnIndex, ResultSet.GetInt(I));
              stLong:
                RowAccessor.SetLong(Current.ColumnIndex, ResultSet.GetLong(I));
              stFloat:
                RowAccessor.SetFloat(Current.ColumnIndex, ResultSet.GetFloat(I));
              stDouble:
                RowAccessor.SetDouble(Current.ColumnIndex, ResultSet.GetDouble(I));
              stBigDecimal:
                RowAccessor.SetBigDecimal(Current.ColumnIndex, ResultSet.GetBigDecimal(I));
              stString, stAsciiStream:
                RowAccessor.SetString(Current.ColumnIndex, ResultSet.GetString(I));
              stUnicodeString, stUnicodeStream:
                RowAccessor.SetUnicodeString(Current.ColumnIndex, ResultSet.GetUnicodeString(I));
              stBytes, stGUID:
                RowAccessor.SetBytes(Current.ColumnIndex, ResultSet.GetBytes(I));
              stDate:
                RowAccessor.SetDate(Current.ColumnIndex, ResultSet.GetDate(I));
              stTime:
                RowAccessor.SetTime(Current.ColumnIndex, ResultSet.GetTime(I));
              stTimestamp:
                RowAccessor.SetTimestamp(Current.ColumnIndex,
                  ResultSet.GetTimestamp(I));
            end;

            if ResultSet.WasNull then
              RowAccessor.SetNull(Current.ColumnIndex);
          except
            { Supress any errors in default fields. }
          end;
        end;
      end;
      ResultSet.Close;
    finally
      Statement.Close;
    end;
  finally
    FreeAndNil(SQLParams);
  end;
end;

{BEGIN of PATCH [1185969]: Do tasks after posting updates. ie: Updating AutoInc fields in MySQL }
procedure TZGenericCachedResolver.UpdateAutoIncrementFields(
  Sender: IZCachedResultSet; UpdateType: TZRowUpdateType; OldRowAccessor,
  NewRowAccessor: TZRowAccessor; Resolver: IZCachedResolver);
begin
 //Should be implemented at Specific database Level Cached resolver
end;
{END of PATCH [1185969]: Do tasks after posting updates. ie: Updating AutoInc fields in MySQL }

end.

