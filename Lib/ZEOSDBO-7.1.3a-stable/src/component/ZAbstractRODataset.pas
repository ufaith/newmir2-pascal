{*********************************************************}
{                                                         }
{                 Zeos Database Objects                   }
{          Abstract Read/Only Dataset component           }
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

unit ZAbstractRODataset;

interface

{$I ZComponent.inc}

uses
{$IFNDEF UNIX}
  Windows,
{$ENDIF}
  Variants,
  Types, SysUtils, Classes, {$IFDEF MSEgui}mclasses, mdb{$ELSE}DB{$ENDIF},
  ZSysUtils, ZAbstractConnection, ZDbcIntfs, ZSqlStrings,
  Contnrs, ZDbcCache, ZDbcCachedResultSet, ZCompatibility, ZExpression
  {$IFDEF WITH_GENERIC_TLISTTFIELD}, Generics.Collections{$ENDIF};

type
  {$IFDEF xFPC} // fixed in r3943 or earlier 2006-06-25
  TUpdateStatusSet = set of TUpdateStatus;

  EUpdateError = class(EDatabaseError)
  end;
  {$ENDIF}

  TSortType = (stAscending, stDescending, stIgnored);   {bangfauzan addition}

  {** Options for dataset. }
  TZDatasetOption = (doOemTranslate, doCalcDefaults, doAlwaysDetailResync,
    doSmartOpen, doPreferPrepared, doDontSortOnPost, doUpdateMasterFirst);

  {** Set of dataset options. }
  TZDatasetOptions = set of TZDatasetOption;

  // Forward declarations.
  TZAbstractRODataset = class;

  {** Implements a Zeos specific database exception with SQL error code. }
  EZDatabaseError = class(EDatabaseError)
  private
    FErrorCode: Integer;
    FStatusCode: String;
    procedure SetStatusCode(const Value: String);
   public
    constructor Create(const Msg: string);
    constructor CreateFromException(E: EZSQLThrowable);

    property ErrorCode: Integer read FErrorCode write FErrorCode;
    property StatusCode: String read FStatusCode write SetStatusCode;
  end;

  {** Dataset Linker class. }
  TZDataLink = class(TMasterDataLink)
  private
    FDataset: TZAbstractRODataset;
  protected
    procedure ActiveChanged; override;
    procedure RecordChanged(Field: TField); override;
  public
    constructor Create(ADataset: TZAbstractRODataset); {$IFDEF FPC}reintroduce;{$ENDIF}
  end;

  {** Abstract dataset component optimized for read/only access. }
  {$IFDEF WITH_WIDEDATASET}
  TZAbstractRODataset = class(TWideDataSet)
  {$ELSE}
  TZAbstractRODataset = class(TDataSet)
  {$ENDIF}
  private
{$IFDEF WITH_FUNIDIRECTIONAL}
    FUniDirectional: Boolean;
{$ENDIF}
    FCurrentRow: Integer;
    FRowAccessor: TZRowAccessor;
    FOldRowBuffer: PZRowBuffer;
    FNewRowBuffer: PZRowBuffer;
    FCurrentRows: TZSortedList;
    FFetchCount: Integer;
    FFieldsLookupTable: TIntegerDynArray;
    FRowsAffected: Integer;

    FFilterEnabled: Boolean;
    FFilterExpression: IZExpression;
    FFilterStack: TZExecutionStack;
    FFilterFieldRefs: TObjectDynArray;
    FInitFilterFields: Boolean;

    FRequestLive: Boolean;
    FFetchRow: integer;    // added by Patyi

    FSQL: TZSQLStrings;
    FParams: TParams;
    FShowRecordTypes: TUpdateStatusSet;
    FOptions: TZDatasetOptions;

    FProperties: TStrings;
    FConnection: TZAbstractConnection;
    FStatement: IZPreparedStatement;
    FResultSet: IZResultSet;

    FRefreshInProgress: Boolean;

    FDataLink: TDataLink;
    FMasterLink: TMasterDataLink;
    FLinkedFields: string; {renamed by bangfauzan}
    FIndexFieldNames : String; {bangfauzan addition}

    FIndexFields: {$IFDEF WITH_GENERIC_TLISTTFIELD}TList<TField>{$ELSE}TList{$ENDIF};

    FSortType : TSortType; {bangfauzan addition}

    FSortedFields: string;
    FSortedFieldRefs: TObjectDynArray;
    FSortedFieldIndices: TIntegerDynArray;
    FSortedFieldDirs: TBooleanDynArray;
    FSortedOnlyDataFields: Boolean;
    FSortRowBuffer1: PZRowBuffer;
    FSortRowBuffer2: PZRowBuffer;
    FPrepared: Boolean;
    FDoNotCloseResultset: Boolean;
    FUseCurrentStatment: Boolean;
  private
    function GetReadOnly: Boolean;
    procedure SetReadOnly(Value: Boolean);
    function GetSQL: TStrings;
    procedure SetSQL(Value: TStrings);
    function GetParamCheck: Boolean;
    procedure SetParamCheck(Value: Boolean);
    function GetParamChar: Char;
    procedure SetParamChar(Value: Char);
    procedure SetParams(Value: TParams);
    function GetShowRecordTypes: TUpdateStatusSet;
    procedure SetShowRecordTypes(Value: TUpdateStatusSet);
    procedure SetConnection(Value: TZAbstractConnection);
    procedure SetDataSource(Value: TDataSource);
    function GetMasterFields: string;
    procedure SetMasterFields(const Value: string);
    function GetMasterDataSource: TDataSource;
    procedure SetMasterDataSource(Value: TDataSource);
    function GetLinkedFields: string; {renamed by bangfauzan}
    procedure SetLinkedFields(const Value: string);  {renamed by bangfauzan}
    function GetIndexFieldNames : String; {bangfauzan addition}
    procedure SetIndexFieldNames(Value : String); {bangfauzan addition}
    procedure SetOptions(Value: TZDatasetOptions);
    procedure SetSortedFields({const} Value: string); {bangfauzan modification}
    procedure SetProperties(const Value: TStrings);

    function GetSortType : TSortType; {bangfauzan addition}
    Procedure SetSortType(Value : TSortType); {bangfauzan addition}

    procedure UpdateSQLStrings(Sender: TObject);
    procedure ReadParamData(Reader: TReader);
    procedure WriteParamData(Writer: TWriter);

    procedure SetPrepared(Value : Boolean);
    function  GetUniDirectional: boolean;

  protected
    procedure CheckOpened;
    procedure CheckConnected;
    procedure CheckBiDirectional;
    procedure CheckSQLQuery; virtual;
    procedure RaiseReadOnlyError;

    function FetchOneRow: Boolean;
    function FetchRows(RowCount: Integer): Boolean;
    function FilterRow(RowNo: Integer): Boolean;
    function GotoRow(RowNo: Integer): Boolean; // added by tohenk
    procedure RereadRows;
    procedure SetStatementParams(Statement: IZPreparedStatement;
      ParamNames: TStringDynArray; Params: TParams;
      DataLink: TDataLink); virtual;
    procedure MasterChanged(Sender: TObject);
    procedure MasterDisabled(Sender: TObject);
    procedure DoOnNewRecord; override;

    function GetDataSource: TDataSource; override;

  protected
    { Internal protected properties. }
    property RowAccessor: TZRowAccessor read FRowAccessor write FRowAccessor;
    property CurrentRow: Integer read FCurrentRow write FCurrentRow;
    property OldRowBuffer: PZRowBuffer read FOldRowBuffer write FOldRowBuffer;
    property NewRowBuffer: PZRowBuffer read FNewRowBuffer write FNewRowBuffer;
    property CurrentRows: TZSortedList read FCurrentRows write FCurrentRows;
    property FetchCount: Integer read FFetchCount write FFetchCount;
    property FieldsLookupTable: TIntegerDynArray read FFieldsLookupTable
      write FFieldsLookupTable;

    property FilterEnabled: Boolean read FFilterEnabled write FFilterEnabled;
    property FilterExpression: IZExpression read FFilterExpression
      write FFilterExpression;
    property FilterStack: TZExecutionStack read FFilterStack write FFilterStack;
    property FilterFieldRefs: TObjectDynArray read FFilterFieldRefs
      write FFilterFieldRefs;
    property InitFilterFields: Boolean read FInitFilterFields
      write FInitFilterFields;

    property Statement: IZPreparedStatement read FStatement write FStatement;
    property ResultSet: IZResultSet read FResultSet write FResultSet;

    property DataLink: TDataLink read FDataLink;
    property MasterLink: TMasterDataLink read FMasterLink;
    property IndexFields: {$IFDEF WITH_GENERIC_TLISTTFIELD}TList<TField>{$ELSE}TList{$ENDIF} read FIndexFields;

    { External protected properties. }
    property RequestLive: Boolean read FRequestLive write FRequestLive
      default False;
    property FetchRow: integer read FFetchRow write FFetchRow default 0;  // added by Patyi
    property SQL: TStrings read GetSQL write SetSQL;
    property ParamCheck: Boolean read GetParamCheck write SetParamCheck
      default True;
    property ParamChar: Char read GetParamChar write SetParamChar
      default ':';
    property Params: TParams read FParams write SetParams;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default True;
    property ShowRecordTypes: TUpdateStatusSet read GetShowRecordTypes
      write SetShowRecordTypes default [usUnmodified, usModified, usInserted];
{$IFDEF WITH_FUNIDIRECTIONAL}
    property IsUniDirectional: Boolean read FUniDirectional
      write FUnidirectional default False;
{$ELSE}
    property IsUniDirectional: Boolean read GetUniDirectional
      write SetUniDirectional default False;
{$ENDIF}
    property Properties: TStrings read FProperties write SetProperties;
    property Options: TZDatasetOptions read FOptions write SetOptions
      default [doCalcDefaults];
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property MasterFields: string read GetMasterFields
      write SetMasterFields;
    property MasterSource: TDataSource read GetMasterDataSource
      write SetMasterDataSource;
    property LinkedFields: string read GetLinkedFields
      write SetLinkedFields; {renamed by bangfauzan}
    property IndexFieldNames:String read GetIndexFieldNames
      write SetIndexFieldNames; {bangfauzan addition}
    property DoNotCloseResultset: Boolean read FDoNotCloseResultset;
  protected
    { Abstracts methods }
    procedure InternalAddRecord(Buffer: Pointer; Append: Boolean); override;
    procedure InternalDelete; override;
    procedure InternalPost; override;

    procedure SetFieldData(Field: TField; Buffer: {$IFDEF WITH_TVALUEBUFFER}TValueBuffer{$ELSE}Pointer{$ENDIF};
      NativeFormat: Boolean); override;
    procedure SetFieldData(Field: TField; Buffer: {$IFDEF WITH_TVALUEBUFFER}TValueBuffer{$ELSE}Pointer{$ENDIF}); override;
    procedure DefineProperties(Filer: TFiler); override;

{$IFDEF WITH_TRECORDBUFFER}
    function GetRecord(Buffer: TRecordBuffer; GetMode: TGetMode; DoCheck: Boolean):
      TGetResult; override;
{$ELSE}
    function GetRecord(Buffer: PChar; GetMode: TGetMode; DoCheck: Boolean):
      TGetResult; override;
{$ENDIF}
    function GetRecordSize: Word; override;
    function GetActiveBuffer(var RowBuffer: PZRowBuffer): Boolean;
{$IFDEF WITH_TRECORDBUFFER}
    function AllocRecordBuffer: TRecordBuffer; override;
    procedure FreeRecordBuffer(var Buffer: TRecordBuffer); override;
{$ELSE}
    function AllocRecordBuffer: PChar; override;
    procedure FreeRecordBuffer(var Buffer: PChar); override;
{$ENDIF}
{$IFDEF WITH_FTDATASETSUPPORT}
    function CreateNestedDataSet(DataSetField: TDataSetField): TDataSet; override;
{$ENDIF}
    procedure CloseBlob(Field: TField); override;
    function CreateStatement(const SQL: string; Properties: TStrings):
      IZPreparedStatement; virtual;
    function CreateResultSet(const SQL: string; MaxRows: Integer):
      IZResultSet; virtual;

    procedure CheckFieldCompatibility(Field: TField; FieldDef: TFieldDef); {$IFDEF WITH_CHECKFIELDCOMPATIBILITY} override;{$ENDIF}
{$IFDEF WITH_TRECORDBUFFER}
    procedure ClearCalcFields(Buffer: TRecordBuffer); override;
{$ELSE}
    procedure ClearCalcFields(Buffer: PChar); override;
{$ENDIF}

    procedure InternalInitFieldDefs; override;
    procedure InternalOpen; override;
    procedure InternalClose; override;
    procedure InternalFirst; override;
    procedure InternalLast; override;
{$IFDEF WITH_TRECORDBUFFER}
    procedure InternalInitRecord(Buffer: TRecordBuffer); override;
{$ELSE}
    procedure InternalInitRecord(Buffer: PChar); override;
{$ENDIF}
    procedure InternalGotoBookmark(Bookmark: Pointer); override;
    procedure InternalRefresh; override;
    procedure InternalHandleException; override;
{$IFDEF WITH_TRECORDBUFFER}
    procedure InternalSetToRecord(Buffer: TRecordBuffer); override;

    procedure GetBookmarkData(Buffer: TRecordBuffer;
      Data:{$IFDEF WITH_BOOKMARKDATA_TBOOKMARK}TBookMark{$ELSE}Pointer{$ENDIF}); override;
    function GetBookmarkFlag(Buffer: TRecordBuffer): TBookmarkFlag; override;
    procedure SetBookmarkFlag(Buffer: TRecordBuffer; Value: TBookmarkFlag); override;
    procedure SetBookmarkData(Buffer: TRecordBuffer;
      Data: {$IFDEF WITH_BOOKMARKDATA_TBOOKMARK}TBookMark{$ELSE}Pointer{$ENDIF}); override;
{$ELSE}
    procedure InternalSetToRecord(Buffer: PChar); override;

    procedure GetBookmarkData(Buffer: PChar; Data: Pointer); override;
    function GetBookmarkFlag(Buffer: PChar): TBookmarkFlag; override;
    procedure SetBookmarkFlag(Buffer: PChar; Value: TBookmarkFlag); override;
    procedure SetBookmarkData(Buffer: PChar; Data: Pointer); override;
{$ENDIF}
    function InternalLocate(const KeyFields: string; const KeyValues: Variant;
      Options: TLocateOptions): LongInt;
    function FindRecord(Restart, GoForward: Boolean): Boolean; override;
    procedure SetFiltered(Value: Boolean); override;
    procedure SetFilterText(const Value: string); override;

    procedure SetAnotherResultset(const Value: IZResultSet);
    procedure InternalSort;
    function ClearSort(Item1, Item2: Pointer): Integer;
    function HighLevelSort(Item1, Item2: Pointer): Integer;
    function LowLevelSort(Item1, Item2: Pointer): Integer;

    function GetCanModify: Boolean; override;
    function GetRecNo: Integer; override;
    function GetRecordCount: Integer; override;
    procedure MoveRecNo(Value: Integer);
    procedure SetRecNo(Value: Integer); override;
    function IsCursorOpen: Boolean; override;

    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;

    procedure RefreshParams; virtual;

    procedure InternalPrepare; virtual;
    procedure InternalUnPrepare; virtual;
  protected
  {$IFDEF WITH_IPROVIDER}
    procedure PSStartTransaction; override;
    procedure PSEndTransaction(Commit: Boolean); override;
    // Silvio Clecio
    {$IFDEF WITH_IPROVIDERWIDE}
    function PSGetTableNameW: WideString; override;
    function PSGetQuoteCharW: WideString; override;
    function PSGetKeyFieldsW: WideString; override;
    procedure PSSetCommandText(const CommandText: WideString); overload; override;
    procedure PSSetCommandText(const CommandText: string); overload; override;
    //??     function PSGetCommandTextW: WideString; override;
    function PSExecuteStatement(const ASQL: WideString; AParams: TParams;
      ResultSet: Pointer = nil): Integer; override;
    {$ELSE}
    function PSGetTableName: string; override;
    function PSGetQuoteChar: string; override;
    function PSGetKeyFields: string; override;
    function PSExecuteStatement(const ASQL: string; AParams: TParams;
      ResultSet: Pointer = nil): Integer; override;
    procedure PSSetCommandText(const CommandText: string); override;
    {$ENDIF}
    function PSGetUpdateException(E: Exception;
      Prev: EUpdateError): EUpdateError; override;
    function PSIsSQLBased: Boolean; override;
    function PSIsSQLSupported: Boolean; override;
    procedure PSReset; override;
    function PSUpdateRecord(UpdateKind: TUpdateKind;
      Delta: TDataSet): Boolean; override;
    procedure PSExecute; override;
    function PSGetParams: TParams; override;
    procedure PSSetParams(AParams: TParams); override;
    function PSInTransaction: Boolean; override;
  {$ENDIF}

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure FetchAll; virtual;  // added by Patyi
    procedure ExecSQL; virtual;
    function RowsAffected: LongInt;
    function ParamByName(const Value: string): TParam;

    function Locate(const KeyFields: string; const KeyValues: Variant;
      Options: TLocateOptions): Boolean; override;
    function Lookup(const KeyFields: string; const KeyValues: Variant;
      const ResultFields: string): Variant; override;
    function IsSequenced: Boolean; override;

    function CompareBookmarks(Bookmark1, Bookmark2: TBookmark): Integer;
      override;
    function BookmarkValid(Bookmark: TBookmark): Boolean; override;

    function GetFieldData(Field: TField; {$IFDEF WITH_VAR_TVALUEBUFFER}var{$ENDIF}Buffer: {$IFDEF WITH_TVALUEBUFFER}TValueBuffer{$ELSE}Pointer{$ENDIF}): Boolean; override;
    function GetFieldData(Field: TField; {$IFDEF WITH_VAR_TVALUEBUFFER}var{$ENDIF}Buffer: {$IFDEF WITH_TVALUEBUFFER}TValueBuffer{$ELSE}Pointer{$ENDIF};
      NativeFormat: Boolean): Boolean; override;
    function CreateBlobStream(Field: TField; Mode: TBlobStreamMode): TStream;
      override;
    function UpdateStatus: TUpdateStatus; override;
    function Translate(Src, Dest: PAnsiChar; ToOem: Boolean): Integer; override;
    procedure Prepare;
    procedure Unprepare;

  public
    property Active;
    property Prepared: Boolean read FPrepared write SetPrepared;
    property FieldDefs stored False;
    property DbcStatement: IZPreparedStatement read FStatement;
    property DbcResultSet: IZResultSet read FResultSet;

  published
    property Connection: TZAbstractConnection read FConnection write SetConnection;
    property SortedFields: string read FSortedFields write SetSortedFields;
    property SortType : TSortType read FSortType write SetSortType
      default stAscending; {bangfauzan addition}

    property AutoCalcFields;
    property BeforeOpen;
    property AfterOpen;
    property BeforeClose;
    property AfterClose;
    property BeforeRefresh;
    property AfterRefresh;
    property BeforeScroll;
    property AfterScroll;
    property OnCalcFields;
    property OnFilterRecord;
    property Filter;
    property Filtered;
  end;

implementation

uses Math, ZVariant, ZMessages, ZDatasetUtils, ZStreamBlob, ZSelectSchema,
  ZGenericSqlToken, ZTokenizer, ZGenericSqlAnalyser, ZAbstractDataset
  {$IFDEF WITH_DBCONSTS}, DBConsts {$ELSE}, DBConst{$ENDIF}
  {$IFDEF WITH_WIDESTRUTILS}, WideStrUtils{$ENDIF}
  {$IFDEF WITH_UNITANSISTRINGS}, AnsiStrings{$ENDIF};

{ EZDatabaseError }

{**
  Constructs a database exception with a string message.
  @param Msg a string message which describes the error.
}
constructor EZDatabaseError.Create(const Msg: string);
begin
  inherited Create(Msg);
end;

{**
  Constructs a database exception from TZSQLThrowable instance.
  @param E an original TZSQLThrowable instance.
}
constructor EZDatabaseError.CreateFromException(E: EZSQLThrowable);
begin
  inherited Create(E.Message);
  ErrorCode := E.ErrorCode;
  Statuscode:= E.StatusCode;
end;

procedure EZDatabaseError.SetStatusCode(const Value: String);
begin
  FStatusCode := value;
end;

{ TZDataLink }

{**
  Creates this dataset link object.
  @param ADataset an owner linked dataset component.
}
constructor TZDataLink.Create(ADataset: TZAbstractRODataset);
begin
  inherited Create(ADataset);
  FDataset := ADataset;
end;

{**
  Processes changes in state of linked dataset.
}
procedure TZDataLink.ActiveChanged;
begin
  if FDataset.Active then
    FDataset.RefreshParams;
end;

{**
  Processes changes in fields of the linked dataset.
  @param Field a field which was changed.
}
procedure TZDataLink.RecordChanged(Field: TField);
begin
  if (Field = nil) and FDataset.Active then
    FDataset.RefreshParams;
end;

{ TZAbstractRODataset }

{**
  Constructs this object and assignes the mail properties.
  @param AOwner a component owner.
}
constructor TZAbstractRODataset.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FSQL := TZSQLStrings.Create;
  TZSQLStrings(FSQL).Dataset := Self;
  TZSQLStrings(FSQL).MultiStatements := False;
  FSQL.OnChange := UpdateSQLStrings;
  FParams := TParams.Create(Self);
  FCurrentRows := TZSortedList.Create;
  BookmarkSize := SizeOf(Integer);
  FShowRecordTypes := [usModified, usInserted, usUnmodified];
  FRequestLive := False;
  FFetchRow := 0;                // added by Patyi
  FOptions := [doCalcDefaults];

  FFilterEnabled := False;
  FProperties := TStringList.Create;
  FFilterExpression := TZExpression.Create;
  FFilterExpression.Tokenizer := CommonTokenizer;
  FFilterStack := TZExecutionStack.Create;

  FDataLink := TZDataLink.Create(Self);
  FMasterLink := TMasterDataLink.Create(Self);
  FMasterLink.OnMasterChange := MasterChanged;
  FMasterLink.OnMasterDisable := MasterDisabled;
  {$IFDEF WITH_GENERIC_TLISTTFIELD}
  FIndexFields := TList<TField>.Create;
  {$ELSE}
  FIndexFields := TList.Create;
  {$ENDIF}
end;

{**
  Destroys this object and cleanups the memory.
}
destructor TZAbstractRODataset.Destroy;
begin
  Unprepare;
  if Assigned(Connection) then
  begin
    try
      SetConnection(nil);
    except
    end;
  end;

  FreeAndNil(FSQL);
  FreeAndNil(FParams);
  FreeAndNil(FCurrentRows);
  FreeAndNil(FProperties);
  FreeAndNil(FFilterStack);

  FreeAndNil(FDataLink);
  FreeAndNil(FMasterLink);
  FreeAndNil(FIndexFields);

  inherited Destroy;
end;

{**
  Sets database connection object.
  @param Value a database connection object.
}
procedure TZAbstractRODataset.SetConnection(Value: TZAbstractConnection);
begin
  if FConnection <> Value then
  begin
    if Active then
       Close;
    if Assigned(Statement) then
      Statement.Close;
    Statement := nil;
    if FConnection <> nil then
      FConnection.UnregisterDataSet(Self);
    FConnection := Value;
    if FConnection <> nil then
      FConnection.RegisterDataSet(Self);
  end;
end;

{**
  Gets the SQL query.
  @return the SQL query strings.
}

function TZAbstractRODataset.GetSQL: TStrings;
begin
  Result := FSQL;
end;

{**
  Gets unidirectional state of dataset.
  @return the unidirectional flag (delphi).
}

function TZAbstractRODataset.GetUniDirectional: boolean;
begin
  Result := inherited IsUniDirectional;
end;

{**
  Sets a new SQL query.
  @param Value a new SQL query.
}
procedure TZAbstractRODataset.SetSQL(Value: TStrings);
begin
  FSQL.Assign(Value);
end;

{**
  Gets a parameters check value.
  @return a parameters check value.
}
function TZAbstractRODataset.GetParamCheck: Boolean;
begin
  Result := FSQL.ParamCheck;
end;

{**
  Sets a new parameters check value.
  @param Value a parameters check value.
}
procedure TZAbstractRODataset.SetParamCheck(Value: Boolean);
begin
  FSQL.ParamCheck := Value;
  UpdateSQLStrings(Self);
end;

{**
  Gets a parameters marker.
  @return a parameter marker.
}
function TZAbstractRODataset.GetParamChar: Char;
begin
  Result := FSQL.ParamChar;
end;

{**
  Sets a new parameter marker.
  @param Value a parameter marker.
}
procedure TZAbstractRODataset.SetParamChar(Value: Char);
begin
  FSQL.ParamChar := Value;
  UpdateSQLStrings(Self);
end;

{**
  Sets a new set of parameters.
  @param Value a set of parameters.
}
procedure TZAbstractRODataset.SetParams(Value: TParams);
begin
  FParams.AssignValues(Value);
end;

{**
  Defines a persistent dataset properties.
  @param Filer a persistent manager object.
}
procedure TZAbstractRODataset.DefineProperties(Filer: TFiler);

  function WriteData: Boolean;
  begin
    if Filer.Ancestor <> nil then
      Result := not FParams.IsEqual(TZAbstractRODataset(Filer.Ancestor).FParams)
    else
      Result := FParams.Count > 0;
  end;

begin
  inherited DefineProperties(Filer);
  Filer.DefineProperty('ParamData', ReadParamData, WriteParamData, WriteData);
end;

{**
  Reads parameter data from persistent storage.
  @param Reader an input data stream.
}
procedure TZAbstractRODataset.ReadParamData(Reader: TReader);
begin
  Reader.ReadValue;
  Reader.ReadCollection(FParams);
end;

{**
  Writes parameter data from persistent storage.
  @param Writer an output data stream.
}
procedure TZAbstractRODataset.WriteParamData(Writer: TWriter);
begin
  Writer.WriteCollection(Params);
end;

{**
  Gets a SQL parameter by its name.
  @param Value a parameter name.
  @return a found parameter object.
}
function TZAbstractRODataset.ParamByName(const Value: string): TParam;
begin
  Result := FParams.ParamByName(Value);
end;

{**
  Updates parameters from SQL statement.
  @param Sender an event sender object.
}
procedure TZAbstractRODataset.UpdateSQLStrings(Sender: TObject);
var
  I: Integer;
  OldParams: TParams;
begin
  FieldDefs.Clear;
  if Active then
    Close
  else
    begin
    if assigned(Statement) then
      Statement.Close;
    Statement := nil;
    end;

  UnPrepare;

  OldParams := TParams.Create;
  OldParams.Assign(FParams);
  FParams.Clear;

  try
    for I := 0 to FSQL.ParamCount - 1 do
      FParams.CreateParam(ftUnknown, FSQL.ParamNames[I], ptUnknown);
    FParams.AssignValues(OldParams);
  finally
    OldParams.Free;
  end;
end;

{**
  Gets the ReadOnly property.
  @return <code>True</code> if the opened result set read only.
}
function TZAbstractRODataset.GetReadOnly: Boolean;
begin
  Result := not RequestLive;
end;

{**
  Sets a new ReadOnly property.
  @param Value <code>True</code> to set result set read-only.
}
procedure TZAbstractRODataset.SetReadOnly(Value: Boolean);
begin
  RequestLive := not Value;
end;

{**
  Gets a visible updated records types.
  @param return visible UpdateRecordTypes value.
}
function TZAbstractRODataset.GetShowRecordTypes: TUpdateStatusSet;
begin
  Result := FShowRecordTypes;
end;

{**
  Sets a new visible updated records types.
  @param Value a new visible UpdateRecordTypes value.
}
procedure TZAbstractRODataset.SetShowRecordTypes(Value: TUpdateStatusSet);
begin
  if Value <> FShowRecordTypes then
  begin
    FShowRecordTypes := Value;
    RereadRows;
  end;
end;

{**
  Checks if this dataset is opened.
}
procedure TZAbstractRODataset.CheckOpened;
begin
  if not Active then
    DatabaseError(SOperationIsNotAllowed4);
end;

{**
  Checks if the database connection is assigned
  and tries to connect.
}
procedure TZAbstractRODataset.CheckConnected;
begin
  if Connection = nil then
    raise EZDatabaseError.Create(SConnectionIsNotAssigned);
  Connection.Connect;
end;

{**
  Checks is the database has bidirectional access.
}
procedure TZAbstractRODataset.CheckBiDirectional;
begin
  if IsUniDirectional then
    raise EZDatabaseError.Create(SOperationIsNotAllowed1);
end;

{**
  Checks the correct SQL query.
}
procedure TZAbstractRODataset.CheckSQLQuery;
begin
  if FSQL.StatementCount < 1 then
    raise EZDatabaseError.Create(SQueryIsEmpty);
  if FSQL.StatementCount > 1 then
    raise EZDatabaseError.Create(SCanNotExecuteMoreQueries);
end;

{**
  Raises an error 'Operation is not allowed in read-only dataset.
}
procedure TZAbstractRODataset.RaiseReadOnlyError;
begin
  raise EZDatabaseError.Create(SOperationIsNotAllowed2);
end;

{**
  Fetches specified number of records.
  @param RowCount a specified number of rows to be fetched.
  @return <code>True</code> if all required rows were fetched.
}
function TZAbstractRODataset.FetchRows(RowCount: Integer): Boolean;
begin
  Connection.ShowSQLHourGlass;
  try
    if RowCount = 0 then
    begin
      while FetchOneRow do;
      Result := True;
    end
    else
    begin
      while (CurrentRows.Count < RowCount) do
      begin
        if not FetchOneRow then
          Break;
      end;
      Result := CurrentRows.Count >= RowCount;
    end;
  finally
    Connection.HideSQLHourGlass;
  end;
end;

{**
  Fetches one row from the result set.
  @return <code>True</code> if record was successfully fetched.
}
function TZAbstractRODataset.FetchOneRow: Boolean;
begin
  repeat
    if (FetchCount = 0) or (ResultSet.GetRow = FetchCount)
      or ResultSet.MoveAbsolute(FetchCount) then
      Result := ResultSet.Next
    else
      Result := False;
    if Result then
    begin
      Inc(FFetchCount);
      if FilterRow(ResultSet.GetRow) then
        CurrentRows.Add(Pointer(ResultSet.GetRow))
      else
        Continue;
    end;
  until True;
end;

{**
  Checks the specified row with the all filters.
  @param RowNo a number of the row.
  @return <code>True</code> if the row sutisfy to all filters.
}
function TZAbstractRODataset.FilterRow(RowNo: Integer): Boolean;
var
  I: Integer;
  SavedRow: Integer;
  SavedRows: TZSortedList;
  SavedState: TDatasetState;
begin
  Result := True;

  { Locates the result set to the specified row. }
  if ResultSet.GetRow <> RowNo then
  begin
    if not ResultSet.MoveAbsolute(RowNo) then
      Result := False;
  end;
  if not Result then
     Exit;

  { Checks record by ShowRecordType }
  if ResultSet.RowUpdated then
    Result := usModified in ShowRecordTypes
  else if ResultSet.RowInserted then
    Result := usInserted in ShowRecordTypes
  else if ResultSet.RowDeleted then
    Result := usDeleted in ShowRecordTypes
  else
    Result := usUnmodified in ShowRecordTypes;
  if not Result then
     Exit;

  { Check master-detail links }
  if MasterLink.Active then
  begin
    for I := 0 to MasterLink.Fields.Count - 1 do
    begin
      if I < IndexFields.Count then
        Result := CompareKeyFields(TField(IndexFields[I]), ResultSet,
          TField(MasterLink.Fields[I]));

      if not Result then
        Break;
    end;
  end;
  if not Result then
     Exit;

  { Checks record by OnFilterRecord event }
  if FilterEnabled and Assigned(OnFilterRecord) then
  begin
    SavedRow := CurrentRow;
    SavedRows := CurrentRows;
    CurrentRows := TZSortedList.Create;

    SavedState := SetTempState(dsNewValue);
    CurrentRows.Add(Pointer(RowNo));
    CurrentRow := 1;

    try
      OnFilterRecord(Self, Result);
    except
      if Assigned(ApplicationHandleException)
      then ApplicationHandleException(Self);
    end;

    CurrentRow := SavedRow;
    CurrentRows.Free;
    CurrentRows := SavedRows;
    RestoreState(SavedState);

  end;
  if not Result then
     Exit;

  { Check the record by filter expression. }
  if FilterEnabled and (FilterExpression.Expression <> '') then
  begin
    if not InitFilterFields then
    begin
      FilterFieldRefs := DefineFilterFields(Self, FilterExpression);
      InitFilterFields := True;
    end;
    CopyDataFieldsToVars(FilterFieldRefs, ResultSet,
      FilterExpression.DefaultVariables);
    Result := FilterExpression.VariantManager.GetAsBoolean(
      FilterExpression.Evaluate4(FilterExpression.DefaultVariables,
      FilterExpression.DefaultFunctions, FilterStack));
  end;
  if not Result then
     Exit;
end;

{**
  Go to specified row.
  @param RowNo a number of the row.
  @return <code>True</code> if the row successfully located.
}
function TZAbstractRODataset.GotoRow(RowNo: Integer): Boolean;
var
  Index: Integer;
begin
  Result := False;
  Index := CurrentRows.IndexOf(Pointer(RowNo));
  if Index >= 0 then
  begin
    if Index < CurrentRow then
      CheckBiDirectional;
    CurrentRow := Index + 1;
    Result := True;
  end;
end;

{**
  Rereads all rows and applies a filter.
}
procedure TZAbstractRODataset.RereadRows;
var
  I, RowNo: Integer;
begin
  if not (State in [dsInactive]) and not IsUniDirectional then
  begin
    if (CurrentRow > 0) and (CurrentRow <= CurrentRows.Count) and
      (CurrentRows.Count > 0) then
      RowNo := Integer(CurrentRows[CurrentRow - 1])
    else
      RowNo := -1;
    CurrentRows.Clear;

    for I := 1 to FetchCount do
    begin
      if FilterRow(I) then
        CurrentRows.Add(Pointer(I));
    end;

    CurrentRow := CurrentRows.IndexOf(Pointer(RowNo)) + 1;
    CurrentRow := Min(Max(1, CurrentRow), CurrentRows.Count);

    if FSortedFields <> '' then
      InternalSort
    else
      Resync([]);
  end;
end;

{**
  Fill prepared statement with parameters.
  @param Statement a prepared SQL statement.
  @param ParamNames an array of parameter names.
  @param Params a collection of SQL parameters.
  @param DataLink a datalink to get parameters.
}
procedure TZAbstractRODataset.SetStatementParams(Statement: IZPreparedStatement;
  ParamNames: TStringDynArray; Params: TParams; DataLink: TDataLink);
var
  I: Integer;
  TempParam, Param: TParam;
  Dataset: TDataset;
  Field: TField;
begin
  if DataLink.Active then
    Dataset := DataLink.DataSet
  else
    Dataset := nil;

  TempParam := TParam.Create(nil);

  try
    for I := Low(ParamNames) to High(ParamNames) do
    begin
      if Assigned(Dataset) then
        Field := Dataset.FindField(ParamNames[I])
      else
        Field := nil;

      if Assigned(Field) then
      begin
        TempParam.AssignField(Field);
        Param := TempParam;
      end
      else
      begin
        Param := Params.FindParam(ParamNames[I]);
        if not Assigned(Param) or (Param.ParamType in [ptOutput, ptResult]) then
          Continue;
      end;

      SetStatementParam(I+ 1, Statement, Param);
    end;
  finally
    TempParam.Free;
  end;
end;

{**
  Locates a specified record in dataset.
  @param Buffer a record buffer to put the contents of the row.
  @param GetMode a location mode.
  @param DoCheck flag to perform checking.
  @return a location result.
}

{$IFDEF WITH_TRECORDBUFFER}
function TZAbstractRODataset.GetRecord(Buffer: TRecordBuffer; GetMode: TGetMode;
  DoCheck: Boolean): TGetResult;
{$ELSE}

function TZAbstractRODataset.GetRecord(Buffer: PChar; GetMode: TGetMode;
  DoCheck: Boolean): TGetResult;
{$ENDIF}
var
  RowNo: Integer;
begin
  // mad stub for unidirectional (problem in TDataSet.MoveBuffer) - dont know about FPC
  // we always use same TDataSet-level buffer, because we can see only one row
  {$IFNDEF WITH_FUNIDIRECTIONAL}
  if IsUniDirectional then
    Buffer := {$IFDEF WITH_BUFFERS_IS_TRECBUF}Pointer{$ENDIF}(Buffers[0]);
  {$ENDIF}

  Result := grOK;
  case GetMode of
    gmNext:
      begin
        if FetchRows(CurrentRow + 1) then
          CurrentRow := CurrentRow + 1
        else
          Result := grEOF;
      end;
    gmPrior:
      begin
        CheckBiDirectional;
        if (CurrentRow > 1) and (CurrentRows.Count > 0) then
          CurrentRow := CurrentRow - 1
        else
          Result := grBOF;
      end;
    gmCurrent:
      begin
        if CurrentRow < CurrentRows.Count then
          CheckBiDirectional;

        if CurrentRow = 0 then
        begin
          if CurrentRows.Count = 0 then
            FetchRows(1);
          CurrentRow := Min(CurrentRows.Count, 1);
        end
        else if not FetchRows(CurrentRow) then
          CurrentRow := Max(1, Min(CurrentRows.Count, CurrentRow));

        if CurrentRows.Count = 0 then
          Result := grError;
      end;
  end;

  if Result = grOK then
  begin
    RowNo := Integer(CurrentRows[CurrentRow - 1]);
    if ResultSet.GetRow <> RowNo then
      ResultSet.MoveAbsolute(RowNo);
    RowAccessor.RowBuffer := PZRowBuffer(Buffer);
    RowAccessor.RowBuffer^.Index := RowNo;
    FetchFromResultSet(ResultSet, FieldsLookupTable, Fields, RowAccessor);
    FRowAccessor.RowBuffer^.BookmarkFlag := Ord(bfCurrent);
    GetCalcFields({$IFDEF WITH_GETCALCFIELDS_TRECBUF}NativeInt{$ENDIF}(Buffer));
  end;

  if (Result = grError) and DoCheck then
    raise EZDatabaseError.Create(SNoMoreRecords);
end;

{**
  Gets the current record buffer depended on the current dataset state.
  @param RowBuffer a reference to the result row buffer.
  @return <code>True</code> if the buffer was defined.
}
function TZAbstractRODataset.GetActiveBuffer(var RowBuffer: PZRowBuffer):
  Boolean;
var
  RowNo: Integer;
  CachedResultSet: IZCachedResultSet;
begin
  RowBuffer := nil;
  case State of
    dsBrowse,dsblockread:
      if not IsEmpty then
        RowBuffer := PZRowBuffer(ActiveBuffer);
    dsEdit, dsInsert:
      RowBuffer := PZRowBuffer(ActiveBuffer);
    dsCalcFields:
      RowBuffer := PZRowBuffer(CalcBuffer);
    dsOldValue, dsNewValue, dsCurValue:
      begin
        RowNo := Integer(CurrentRows[CurrentRow - 1]);
        if RowNo <> ResultSet.GetRow then
          CheckBiDirectional;

        if State = dsOldValue then
          RowBuffer := OldRowBuffer
        else
          RowBuffer := NewRowBuffer;

        if RowBuffer.Index <> RowNo then
        begin
          RowAccessor.RowBuffer := RowBuffer;
          RowAccessor.Clear;
          if (ResultSet.GetRow = RowNo) or ResultSet.MoveAbsolute(RowNo) then
          begin
            if (State = dsOldValue) and (ResultSet.
              QueryInterface(IZCachedResultSet, CachedResultSet) = 0) then
              CachedResultSet.MoveToInitialRow;
            FetchFromResultSet(ResultSet, FieldsLookupTable, Fields, RowAccessor);
            RowBuffer.Index := RowNo;
            ResultSet.MoveToCurrentRow;
          end
          else
            RowBuffer := nil;
        end;
      end;
  end;
  Result := RowBuffer <> nil;
end;

function TZAbstractRODataset.GetFieldData(Field: TField;
  {$IFDEF WITH_VAR_TVALUEBUFFER}var{$ENDIF}Buffer:
  {$IFDEF WITH_TVALUEBUFFER}TValueBuffer{$ELSE}Pointer{$ENDIF};
  NativeFormat: Boolean): Boolean;
begin
  if Field.DataType in [ftWideString] then
    NativeFormat := True;
  Result := inherited GetFieldData(Field, Buffer, NativeFormat);
end;

{**
  Retrieves the column value and stores it into the field buffer.
  @param Field an field object to be retrieved.
  @param Buffer a field value buffer.
  @return <code>True</code> if non-null value was retrieved.
}
function TZAbstractRODataset.GetFieldData(Field: TField;
  {$IFDEF WITH_VAR_TVALUEBUFFER}var{$ENDIF}Buffer:
    {$IFDEF WITH_TVALUEBUFFER}TValueBuffer{$ELSE}Pointer{$ENDIF}): Boolean;
var
  ColumnIndex: Integer;
  RowBuffer: PZRowBuffer;
  ACurrency: Double;
  Bts: TByteDynArray;
  {$IFNDEF WITH_WIDESTRUTILS}
  WS: WideString;
  {$ENDIF}
begin
  if GetActiveBuffer(RowBuffer) then
  begin
    ColumnIndex := DefineFieldIndex(FieldsLookupTable, Field);
    RowAccessor.RowBuffer := RowBuffer;
    if Buffer <> nil then
    begin
      case Field.DataType of
        { Processes DateTime fields. }
        ftDate, ftTime, ftDateTime:
          begin
            if Field.DataType <> ftTime then
              DateTimeToNative(Field.DataType,
                RowAccessor.GetTimestamp(ColumnIndex, Result), Buffer)
            else
              DateTimeToNative(Field.DataType,
                RowAccessor.GetTime(ColumnIndex, Result), Buffer);
            Result := not Result;
          end;
        { Processes binary array fields. }
        ftBytes:
          begin
            Bts := RowAccessor.GetBytes(ColumnIndex, Result);
            System.Move(PAnsiChar(Bts)^,
              PAnsiChar(Buffer)^, Min(Length(Bts), RowAccessor.GetColumnDataSize(ColumnIndex)));
            Result := not Result;
          end;
        { Processes blob fields. }
        ftBlob, ftMemo, ftGraphic, ftFmtMemo {$IFDEF WITH_WIDEMEMO},ftWideMemo{$ENDIF} :
          Result := not RowAccessor.GetBlob(ColumnIndex, Result).IsEmpty;
        ftWideString:
          begin
            {$IFDEF WITH_WIDESTRUTILS}
            WStrCopy(PWideChar(Buffer), PWideChar(RowAccessor.GetUnicodeString(ColumnIndex, Result)));
            {$ELSE}
            //FPC: WideStrings are COM managed fields
            WS:=RowAccessor.GetUnicodeString(ColumnIndex, Result);
            //include null terminator in copy
            System.Move(PWideChar(WS)^,buffer^,(length(WS)+1)*sizeof(WideChar));
            {$ENDIF}
            Result := not Result;
          end;
        ftString{$IFDEF WITH_FTGUID}, ftGUID{$ENDIF}:
          begin
            {$IFDEF WITH_STRCOPY_DEPRECATED}AnsiStrings.{$ENDIF}StrCopy(PAnsiChar(Buffer), PAnsiChar({$IFDEF UNICODE}AnsiString{$ENDIF}(RowAccessor.GetString(ColumnIndex, Result))));
            Result := not Result;
          end;
        {$IFDEF WITH_FTDATASETSUPPORT}
        ftDataSet:
          Result := not RowAccessor.GetDataSet(ColumnIndex, Result).IsEmpty;
        {$ENDIF}
        { Processes all other fields. }
        ftCurrency:
          begin
            {SizeOf(double) = 8Byte but SizeOf(Extented) = 10 Byte, so i need to convert the value}
            ACurrency := RowAccessor.GetDouble(ColumnIndex, Result);
            System.Move(Pointer(@ACurrency)^, Pointer(Buffer)^, SizeOf(Double));
            Result := not Result;
          end;
        else
          begin
            System.Move(RowAccessor.GetColumnData(ColumnIndex, Result)^,
              Pointer(Buffer)^, RowAccessor.GetColumnDataSize(ColumnIndex));
            Result := not Result;
          end;
      end;
    end
    else
    begin
      if Field.DataType in [ftBlob, ftMemo, ftGraphic, ftFmtMemo {$IFDEF WITH_WIDEMEMO},ftWideMemo{$ENDIF}] then
        Result := not RowAccessor.GetBlob(ColumnIndex, Result).IsEmpty
      else
        Result := not RowAccessor.IsNull(ColumnIndex);
    end;
  end
  else
    Result := False;
end;

{**
  Support for widestring field
}
procedure TZAbstractRODataset.SetFieldData(Field: TField; Buffer: {$IFDEF WITH_TVALUEBUFFER}TValueBuffer{$ELSE}Pointer{$ENDIF};
  NativeFormat: Boolean);
begin
  if Field.DataType in [ftWideString{$IFDEF WITH_WIDEMEMO}, ftWideMemo{$ENDIF}] then
    NativeFormat := True;

  {$IFNDEF VIRTUALSETFIELDDATA}
  inherited;
  {$ELSE}
  SetFieldData(Field, Buffer);
  {$ENDIF}
end;

{**
  Stores the column value from the field buffer.
  @param Field an field object to be stored.
  @param Buffer a field value buffer.
}
procedure TZAbstractRODataset.SetFieldData(Field: TField; Buffer: {$IFDEF WITH_TVALUEBUFFER}TValueBuffer{$ELSE}Pointer{$ENDIF});
var
  ColumnIndex: Integer;
  RowBuffer: PZRowBuffer;
  WasNull: Boolean;
  {$IFNDEF UNICODE}
  L: Cardinal;
  Temp: String;
  {$ENDIF}
begin
  WasNull := False;
  if not Active then
    raise EZDatabaseError.Create(SOperationIsNotAllowed4);
  if not RequestLive and (Field.FieldKind = fkData) then
    RaiseReadOnlyError;
  // Check for readonly updates
  // Lookup values are requeried automatically on edit of all fields.
  // Didn't find a way to avoid this...
  if Field.ReadOnly and (Field.FieldKind <> fkLookup)
                    and not (State in [dsSetKey, dsCalcFields, dsFilter, dsBlockRead, dsInternalCalc, dsOpening]) then
    DatabaseErrorFmt(SFieldReadOnly, [Field.DisplayName]);
  if not (State in dsWriteModes) then
    DatabaseError(SNotEditing, Self);

  if GetActiveBuffer(RowBuffer) then
  begin
    ColumnIndex := DefineFieldIndex(FieldsLookupTable, Field);
    RowAccessor.RowBuffer := RowBuffer;

    if State in [dsEdit, dsInsert] then
      Field.Validate(Buffer);

    if Assigned(Buffer) then
    begin
      case Field.DataType of
        ftDate, ftDateTime: { Processes Date/DateTime fields. }
          RowAccessor.SetTimestamp(ColumnIndex, NativeToDateTime(Field.DataType, Buffer));
        ftTime: { Processes Time fields. }
          RowAccessor.SetTime(ColumnIndex, NativeToDateTime(Field.DataType, Buffer));
        ftBytes: { Processes binary array fields. }
          RowAccessor.SetBytes(ColumnIndex, BufferToBytes(Pointer(Buffer), Field.Size));
        ftWideString: { Processes widestring fields. }
          {$IFDEF WITH_PWIDECHAR_TOWIDESTRING}
          RowAccessor.SetUnicodeString(ColumnIndex, PWideChar(Buffer));
          {$ELSE}
          RowAccessor.SetUnicodeString(ColumnIndex, PWideString(Buffer)^);
          {$ENDIF}
        ftString{$IFDEF WITH_FTGUID}, ftGUID{$ENDIF}: { Processes string fields. }
          {$IFDEF UNICODE}
          RowAccessor.SetString(ColumnIndex, String(PAnsichar(Buffer)));
          {$ELSE}
          begin
            L := {$IFDEF WITH_STRLEN_DEPRECATED}AnsiStrings.{$ENDIF}StrLen(PAnsiChar(Buffer));
            SetLength(Temp, L);
            Move(PAnsiChar(Buffer)^, PAnsiChar(Temp)^, L);
            RowAccessor.SetString(ColumnIndex, Temp);
          end;
          {$ENDIF}
        ftCurrency:
            {SizeOf(curreny) = 8Byte but SizeOf(Extented) = 10 Byte, so i need to convert the value}
            RowAccessor.SetDouble(ColumnIndex, PDouble(Buffer)^); //cast Currrency to Extented
        else  { Processes all other fields. }
          begin
            System.Move(Pointer(Buffer)^, RowAccessor.GetColumnData(ColumnIndex, WasNull)^,
            RowAccessor.GetColumnDataSize(ColumnIndex));
            RowAccessor.SetNotNull(ColumnIndex);
          end;
      end;
    end
    else
      RowAccessor.SetNull(ColumnIndex);

    if not (State in [dsCalcFields, dsFilter, dsNewValue]) then
      DataEvent(deFieldChange, ULong(Field));
  end
  else
    raise EZDatabaseError.Create(SRowDataIsNotAvailable);

  if Field.FieldKind = fkData then
  begin
    OldRowBuffer.Index := -1;
    NewRowBuffer.Index := -1;
  end;
end;

{**
  Checks is the cursor opened.
  @return <code>True</code> if the cursor is opened.
}
function TZAbstractRODataset.IsCursorOpen: Boolean;
begin
  Result := ResultSet <> nil;
end;

{**
  Gets an affected rows by the last executed statement.
  @return a number of last updated rows.
}
function TZAbstractRODataset.RowsAffected: LongInt;
begin
  Result := FRowsAffected;
end;

{**
  Gets the size of the record buffer.
  @return the size of the record buffer.
}
function TZAbstractRODataset.GetRecordSize: Word;
begin
  Result := RowAccessor.RowSize;
end;

{**
  Allocates a buffer for new record.
  @return an allocated record buffer.
}

{$IFDEF WITH_TRECORDBUFFER}

function TZAbstractRODataset.AllocRecordBuffer: TRecordBuffer;
begin
   Result := TRecordBuffer(RowAccessor.Alloc);
end;
{$ELSE}

function TZAbstractRODataset.AllocRecordBuffer: PChar;
begin
  Result := PChar(RowAccessor.Alloc);
end;
{$ENDIF}

{**
  Frees a previously allocated record buffer.
  @param Buffer a previously allocated buffer.
}

{$IFDEF WITH_TRECORDBUFFER}

procedure TZAbstractRODataset.FreeRecordBuffer(var Buffer: TRecordBuffer);
{$ELSE}

procedure TZAbstractRODataset.FreeRecordBuffer(var Buffer: PChar);
{$ENDIF}
begin
  RowAccessor.DisposeBuffer(PZRowBuffer(Buffer));
end;

{**
  Fetch all records. Added by Patyi
}
procedure TZAbstractRODataset.FetchAll;
begin
  Connection.ShowSQLHourGlass;
  FetchRows(0);
  if Active then
    UpdateCursorPos;
  Connection.HideSQLHourGlass;
end;

{**
  Executes a DML SQL statement.
}
procedure TZAbstractRODataset.ExecSQL;
begin
  if Active then
    begin
      Connection.ShowSQLHourGlass;
      try
        Close;
      finally
        Connection.HideSQLHourGlass;
      end;
    end;

  Prepare;

  Connection.ShowSQLHourGlass;
  try
    SetStatementParams(Statement, FSQL.Statements[0].ParamNamesArray,
      FParams, FDataLink);

    FRowsAffected := Statement.ExecuteUpdatePrepared;
  finally
    Connection.HideSQLHourGlass;
  end;
end;

{**
  Performs an internal initialization of field defiitions.
}
procedure TZAbstractRODataset.InternalInitFieldDefs;
var
  I, J, Size: Integer;
  AutoInit: Boolean;
  FieldType: TFieldType;
  ResultSet: IZResultSet;
  FieldName: string;
  FName: string;
begin
  FieldDefs.Clear;
  ResultSet := Self.ResultSet;
  AutoInit := ResultSet = nil;

  try
    { Opens an internal result set if query is closed. }
    if AutoInit then
    begin
      CheckSQLQuery;
      CheckConnected;
      Prepare;
      ResultSet := CreateResultSet(FSQL.Statements[0].SQL, 0);
    end;
    if not Assigned(ResultSet) then
      raise Exception.Create(SCanNotOpenResultSet);

    { Reads metadata from resultset. }

    with ResultSet.GetMetadata do
    begin
    if GetColumnCount > 0 then
      for I := 1 to GetColumnCount do
      begin
        FieldType := ConvertDbcToDatasetType(GetColumnType(I));
        //if IsCurrency(I) then
          //FieldType := ftCurrency;
        if FieldType in [ftBytes, ftString, ftWidestring] then
          Size := GetPrecision(I)
        else
          {$IFDEF WITH_FTGUID}
          if FieldType = ftGUID then
            Size := 38
          else
          {$ENDIF}
            Size := 0;

        J := 0;
        FieldName := GetColumnLabel(I);
        FName := FieldName;
        while FieldDefs.IndexOf(FName) >= 0 do
        begin
          Inc(J);
          FName := Format('%s_%d', [FieldName, J]);
        end;

        with TFieldDef.Create(FieldDefs, FName, FieldType,
          Size, False, I) do
        begin
          {$IFNDEF OLDFPC}
          Required := IsWritable(I) and (IsNullable(I) = ntNoNulls);
          {$ENDIF}
          if IsReadOnly(I) then Attributes := Attributes + [faReadonly];
          Precision := GetPrecision(I);
          DisplayName := FName;
        end;
      end;
    end;

  finally
    { Closes localy opened resultset. }
    if AutoInit then
    begin
      if ResultSet <> nil then
      begin
        ResultSet.Close;
        ResultSet := nil;
      end;
      UnPrepare;
    end;
  end;
end;

{**
  Creates a DBC statement for the query.
  @param SQL an SQL query.
  @param Properties a statement specific properties.
  @returns a created DBC statement.
}
function TZAbstractRODataset.CreateStatement(const SQL: string; Properties: TStrings):
  IZPreparedStatement;
var
  Temp: TStrings;
begin
  Temp := TStringList.Create;
  try
    if Assigned(Properties) then
      Temp.AddStrings(Properties);
    { Define TDataset specific parameters. }
    if doCalcDefaults in FOptions then
      Temp.Values['defaults'] := 'true'
    else
      Temp.Values['defaults'] := 'false';
    if doPreferPrepared in FOptions then
      Temp.Values['preferprepared'] := 'true'
    else
      Temp.Values['preferprepared'] := 'false';

    Result := FConnection.DbcConnection.PrepareStatementWithParams(SQL, Temp);
  finally
    Temp.Free;
  end;
end;

{**
  Creates a DBC resultset for the query.
  @param SQL an SQL query.
  @param MaxRows a maximum rows number (-1 for all).
  @returns a created DBC resultset.
}
function TZAbstractRODataset.CreateResultSet(const SQL: string;
  MaxRows: Integer): IZResultSet;
begin
  Connection.ShowSQLHourGlass;
  try
    SetStatementParams(Statement, FSQL.Statements[0].ParamNamesArray,
      FParams, FDataLink);
    if RequestLive then
      Statement.SetResultSetConcurrency(rcUpdatable)
    else
      Statement.SetResultSetConcurrency(rcReadOnly);
    Statement.SetFetchDirection(fdForward);
    if IsUniDirectional then
      Statement.SetResultSetType(rtForwardOnly)
    else
      Statement.SetResultSetType(rtScrollInsensitive);
    if MaxRows > 0 then
      Statement.SetMaxRows(MaxRows);

    if doSmartOpen in FOptions then
    begin
      if Statement.ExecutePrepared then
        Result := Statement.GetResultSet
      else
        Result := nil;
    end
    else
      Result := Statement.ExecuteQueryPrepared;
  finally
    Connection.HideSQLHourGlass;
  end;
end;

{**
  Performs internal query opening.
}
procedure TZAbstractRODataset.InternalOpen;
var
  ColumnList: TObjectList;
  I: Integer;
begin
  {$IFNDEF FPC}
  If (csDestroying in Componentstate) then
    raise Exception.Create(SCanNotOpenDataSetWhenDestroying);
  {$ENDIF}
  if not FUseCurrentStatment then Prepare;

  CurrentRow := 0;
  FetchCount := 0;
  CurrentRows.Clear;

  Connection.ShowSQLHourGlass;
  try
    { Creates an SQL statement and resultsets }
    if not FUseCurrentStatment then
      if FSQL.StatementCount> 0 then
        ResultSet := CreateResultSet(FSQL.Statements[0].SQL, -1)
      else
        ResultSet := CreateResultSet('', -1);
      if not Assigned(ResultSet) then
      begin
        if not (doSmartOpen in FOptions) then
          raise Exception.Create(SCanNotOpenResultSet)
        else
          Exit;
      end;

    { Initializes field and index defs. }
    if not FRefreshInProgress then
      InternalInitFieldDefs;

    if DefaultFields and not FRefreshInProgress then
    begin
      CreateFields;
      for i := 0 to Fields.Count -1 do
        if Fields[i].DataType in [ftString, ftWideString{$IFDEF WITH_FTGUID}, ftGUID{$ENDIF}] then
          {$IFDEF WITH_FTGUID}
          if Fields[i].DataType = ftGUID then
            Fields[i].DisplayWidth := 40 //to get a full view of the GUID values
          else
          {$ENDIF}
            if not (ResultSet.GetMetadata.GetColumnDisplaySize(I+1) = 0) then
            begin
              {$IFNDEF FPC}Fields[i].Size := ResultSet.GetMetadata.GetColumnDisplaySize(I+1);{$ENDIF}
              Fields[i].DisplayWidth := ResultSet.GetMetadata.GetColumnDisplaySize(I+1);
            end;
    end;
    BindFields(True);

    { Initializes accessors and buffers. }
    ColumnList := ConvertFieldsToColumnInfo(Fields);
    try
      RowAccessor := TZRowAccessor.Create(ColumnList, Connection.DbcConnection.GetConSettings);
    finally
      ColumnList.Free;
    end;
    FOldRowBuffer := PZRowBuffer(AllocRecordBuffer);
    FNewRowBuffer := PZRowBuffer(AllocRecordBuffer);

    FieldsLookupTable := CreateFieldsLookupTable(Fields);
    InitFilterFields := False;

    IndexFields.Clear;
    GetFieldList(IndexFields, FLinkedFields); {renamed by bangfauzan}

    { Performs sorting. }
    if FSortedFields <> '' then
      InternalSort;
  finally
    Connection.HideSQLHourGlass;
  end;
end;

{**
  Performs internal query closing.
}
procedure TZAbstractRODataset.InternalClose;
begin
  if ResultSet <> nil then
    if not FDoNotCloseResultSet then ResultSet.Close;
  ResultSet := nil;

  if FOldRowBuffer <> nil then
{$IFDEF WITH_TRECORDBUFFER}
    FreeRecordBuffer(TRecordBuffer(FOldRowBuffer));   // TRecordBuffer can be both pbyte and pchar in FPC. Don't assume.
{$ELSE}
    FreeRecordBuffer(PChar(FOldRowBuffer));
{$ENDIF}
  FOldRowBuffer := nil;
  if FNewRowBuffer <> nil then
{$IFDEF WITH_TRECORDBUFFER}
    FreeRecordBuffer(TRecordBuffer(FNewRowBuffer));
{$ELSE}
    FreeRecordBuffer(PChar(FNewRowBuffer));
{$ENDIF}
  FNewRowBuffer := nil;

  if RowAccessor <> nil then
    RowAccessor.Free;
  RowAccessor := nil;

  { Destroy default fields }
  if DefaultFields and not FRefreshInProgress then
    DestroyFields;

  CurrentRows.Clear;
  FieldsLookupTable := nil;
end;

{**
  Performs internal go to first record.
}
procedure TZAbstractRODataset.InternalFirst;
begin
  if CurrentRow > 0 then
    CheckBiDirectional;
  CurrentRow := 0;
end;

{**
  Performs internal go to last record.
}
procedure TZAbstractRODataset.InternalLast;
begin
  FetchRows(0);
  if CurrentRows.Count > 0 then
    CurrentRow := CurrentRows.Count + 1
  else
    CurrentRow := 0;
end;

{**
  Processes internal exception handling.
}
procedure TZAbstractRODataset.InternalHandleException;
begin
//  Application.HandleException(Self);
end;

{**
  Gets the maximum records count.
  @return the maximum records count.
}
function TZAbstractRODataset.GetRecordCount: LongInt;
begin
  CheckActive;
  if not IsUniDirectional then
    FetchRows(FFetchRow);     // the orginal code was FetchRows(0); modifyed by Patyi
  Result := CurrentRows.Count;
end;

{**
  Gets the current record number.
  @return the current record number.
}
function TZAbstractRODataset.GetRecNo: Longint;
begin
  if Active then
    UpdateCursorPos;
  Result := CurrentRow;
end;

{**
  Moves current record to the specified record.
  @param Value a new current record number.
}
procedure TZAbstractRODataset.MoveRecNo(Value: Integer);
var
  PreviousCurrentRow: Integer;
begin
  Value := Max(1, Value);
  if Value < CurrentRow then
    CheckBiDirectional;

  if FetchRows(Value) then
    CurrentRow := Value
  else
    CurrentRow := CurrentRows.Count;

  PreviousCurrentRow := CurrentRow;//Resync moves the current row away
  try
    if not (State in [dsInactive]) then
       Resync([]);
  finally
    CurrentRow := PreviousCurrentRow;
  end;
  UpdateCursorPos;
end;

{**
  Sets a new currenct record number.
  @param Value a new current record number.
}
procedure TZAbstractRODataset.SetRecNo(Value: Integer);
begin
  CheckOpened;
  Value := Max(1, Value);
  if Value < CurrentRow then
    CheckBiDirectional;

  DoBeforeScroll;
  MoveRecNo(Value);
  DoAfterScroll;
end;

{**
  Defines is the query editable?
  @return <code>True</code> if the query is editable.
}
function TZAbstractRODataset.GetCanModify: Boolean;
begin
  Result := RequestLive;
end;

{**
  Gets a linked datasource.
  @returns a linked datasource.
}
function TZAbstractRODataset.GetDataSource: TDataSource;
begin
  Result := DataLink.DataSource;
end;

{**
  Sets the value of the Prepared property.
  Setting to <code>True</code> prepares the query. Setting to <code>False</code> unprepares.
  @param Value a new value for the Prepared property.
}
procedure TZAbstractRODataset.SetPrepared(Value: Boolean);
begin
  FUseCurrentStatment := False;
  FDoNotCloseResultSet := False;
  If Value <> FPrepared then
    begin
      If Value then
        InternalPrepare
      else
        InternalUnprepare;
      FPrepared := Value;
    end;
end;

{**
  Sets a new linked datasource.
  @param Value a new linked datasource.
}
procedure TZAbstractRODataset.SetDataSource(Value: TDataSource);
begin
  {$IFNDEF FPC}
  if IsLinkedTo(Value) then
  {$ELSE}
  if Value.IsLinkedTo(Self) then
  {$ENDIF}
    raise EZDatabaseError.Create(SCircularLink);
  DataLink.DataSource := Value;
end;

{**
  Gets a master datasource.
  @returns a master datasource.
}
function TZAbstractRODataset.GetMasterDataSource: TDataSource;
begin
  Result := MasterLink.DataSource;
end;

{**
  Sets a new master datasource.
  @param Value a new master datasource.
}
procedure TZAbstractRODataset.SetMasterDataSource(Value: TDataSource);
begin
  {$IFNDEF FPC}
  if IsLinkedTo(Value) then
  {$ELSE}
  if Value.IsLinkedTo(Self) then
  {$ENDIF}
    raise EZDatabaseError.Create(SCircularLink);
  MasterLink.DataSource := Value;
  RereadRows;
end;

{**
  Gets master link fields.
  @returns a list with master fields.
}
function TZAbstractRODataset.GetMasterFields: string;
begin
  Result := FMasterLink.FieldNames;
end;

{**
  Sets master link fields.
  @param Value a new master link fields.
}
procedure TZAbstractRODataset.SetMasterFields(const Value: string);
begin
  if FMasterLink.FieldNames <> Value then
  begin
    FMasterLink.FieldNames := Value;
    RereadRows;
  end;
end;

{**
  Processes change events from the master dataset.
  @param Sender an event sender object.
}
procedure TZAbstractRODataset.MasterChanged(Sender: TObject);
begin
  CheckBrowseMode;
  if (doAlwaysDetailResync in FOptions) or (FMasterLink.DataSet = nil)
    or not (FMasterLink.DataSet.State in [dsEdit, dsInsert]) then
    RereadRows;
end;

{**
  Processes disable events from the master dataset.
  @param Sender an event sender object.
}
procedure TZAbstractRODataset.MasterDisabled(Sender: TObject);
begin
  RereadRows;
end;

{**
  Initializes new record with master fields.
}
{$WARNINGS OFF}
procedure TZAbstractRODataset.DoOnNewRecord;
var
  I: Integer;
  MasterField, DetailField: TField;
  Temp: Int64;
  P1, P2 : Integer;
begin
  if MasterLink.Active and (MasterLink.Fields.Count > 0) then
  begin
    for I := 0 to MasterLink.Fields.Count - 1 do
    begin
      if I < IndexFields.Count then
      begin
        MasterField := TField(MasterLink.Fields[I]);
        DetailField := TField(IndexFields[I]);
        // Processes LargeInt fields.
        if (MasterField is TLargeIntField)
          or (DetailField is TLargeIntField) then
        begin
          if MasterField is TLargeIntField then
            Temp := TLargeIntField(
              MasterField).{$IFDEF WITH_ASLARGEINT}AsLargeInt{$ELSE}Value{$ENDIF}
          else
            Temp := MasterField.AsInteger;
          if DetailField is TLargeIntField then
            TLargeIntField(DetailField).{$IFDEF WITH_ASLARGEINT}AsLargeInt{$ELSE}Value{$ENDIF} := Temp
          else
            DetailField.AsString := IntToStr(Temp);
        end
        // Processes all other fields.
        else
          DetailField.Value := MasterField.Value;
      end;
    end;
  end
  else
  begin
    if DataLink.Active and (DataLink.dataset.Fields.Count > 0) then
    begin
      p1 := 1; p2 := 1;
      while (P1 <= Length(LinkedFields)) and (p2 <= Length(MasterFields)) do
      begin
        DetailField := FieldByName(ExtractFieldName(LinkedFields, P1));
        MasterField := DataLink.DataSet.FieldByName (ExtractFieldName(MasterFields, P2));
        DetailField.Assign(MasterField);
      end;
    end;
  end;
  inherited DoOnNewRecord;
end;
{$WARNINGS ON}

{**
  Gets a list of index field names.
  @returns a list of index field names.
}
function TZAbstractRODataset.GetLinkedFields: string; {renamed by bangfauzan}
begin
  Result := FLinkedFields; {renamed by bangfauzan}
end;

{**
  Sets a new list of index field names.
  @param Value a new list of index field names.
}
procedure TZAbstractRODataset.SetLinkedFields(const Value: string); {renamed by bangfauzan}
begin
  if FLinkedFields <> Value then {renamed by bangfauzan}
  begin
    FLinkedFields := Value; {renamed by bangfauzan}
    IndexFields.Clear;
    if State <> dsInactive then
    begin
      GetFieldList(IndexFields, FLinkedFields); {renamed by bangfauzan}
      RereadRows;
    end;
  end;
end;

{**
  Sets a new set of dataset options.
  @param Value a new set of dataset options.
}
procedure TZAbstractRODataset.SetOptions(Value: TZDatasetOptions);
begin
  if FOptions <> Value then
    FOptions := Value;
end;

{**
  Sets a new sorted fields.
  @param Value a new sorted fields.
}
procedure TZAbstractRODataset.SetSortedFields({const} Value: string); {bangfauzan modification}
begin
  Value:=Trim(Value); {bangfauzan addition}
  if (FSortedFields <> Value) or (FIndexFieldNames <> Value)then {bangfauzan modification}
  begin
    FIndexFieldNames:=Value;
    FSortType := GetSortType; {bangfauzan addition}
    {removing ASC or DESC behind space}
    if (FSortType <> stIgnored) then
    begin {pawelsel modification}
       Value:=StringReplace(Value,' Desc','',[rfReplaceAll,rfIgnoreCase]);
       Value:=StringReplace(Value,' Asc','',[rfReplaceAll,rfIgnoreCase]);
    end;
    FSortedFields := Value;
    if Active then
      {InternalSort;}
      {bangfauzan modification}
      if (FSortedFields = '') then
        Self.InternalRefresh
      else
        InternalSort;
      {end of bangfauzan modification}
  end;
end;

{**
  Refreshes parameters and reopens the dataset.
}
procedure TZAbstractRODataset.RefreshParams;
var
  DataSet: TDataSet;
begin
  DisableControls;
  try
    if FDataLink.DataSource <> nil then
    begin
      DataSet := FDataLink.DataSource.DataSet;
      if DataSet <> nil then
        if DataSet.Active and not (DataSet.State in [dsSetKey, dsEdit]) then
        begin
          Refresh;
        end;
    end;
  finally
    EnableControls;
  end;
end;

{**
  Performs the internal preparation of the query.
}
procedure TZAbstractRODataset.InternalPrepare;
begin
  CheckSQLQuery;
  CheckInactive;  //AVZ - Need to check this
  CheckConnected;

  Connection.ShowSQLHourGlass;
  try
    if (FSQL.StatementCount > 0) and((Statement = nil) or (Statement.GetConnection.IsClosed)) then
      Statement := CreateStatement(FSQL.Statements[0].SQL, Properties)
    else
      if (Assigned(Statement)) then
         Statement.ClearParameters;
  finally
    Connection.HideSQLHourGlass;
  end;
end;

{**
  Rolls back the internal preparation of the query.
}
procedure TZAbstractRODataset.InternalUnPrepare;
begin
  if Statement <> nil then
    begin
      Statement.Close;
      Statement := nil;
    end;
end;

{**
  Performs internal switch to the specified bookmark.
  @param Bookmark a specified bookmark.
}
procedure TZAbstractRODataset.InternalGotoBookmark(Bookmark: Pointer);
begin
  if not GotoRow(PInteger(Bookmark)^) then
    raise EZDatabaseError.Create(SBookmarkWasNotFound);
end;

{**
  Performs an internal switch to the specified record.
  @param Buffer the specified row buffer.
}

{$IFDEF WITH_TRECORDBUFFER}
procedure TZAbstractRODataset.InternalSetToRecord(Buffer: TRecordBuffer);
{$ELSE}
procedure TZAbstractRODataset.InternalSetToRecord(Buffer: PChar);
{$ENDIF}
begin
  GotoRow(PZRowBuffer(Buffer)^.Index);
end;

{**
  Performs an internal adding a new record.
  @param Buffer a buffer of the new adding record.
  @param Append <code>True</code> if record should be added to the end
    of the result set.
}
procedure TZAbstractRODataset.InternalAddRecord(Buffer: Pointer;
  Append: Boolean);
begin
  RaiseReadOnlyError;
end;

{**
  Performs an internal record removing.
}
procedure TZAbstractRODataset.InternalDelete;
begin
  RaiseReadOnlyError;
end;

{**
  Performs an internal post updates.
}
procedure TZAbstractRODataset.InternalPost;
  procedure Checkrequired;
  var
    I: longint;
    columnindex : integer;
  begin
    For I:=0 to Fields.Count-1 do
      With Fields[i] do
        Case State of
         dsEdit:
          if Required and not ReadOnly and (FieldKind=fkData) and IsNull then
            raise EZDatabaseError.Create(Format(SNeedField,[DisplayName]));
         dsInsert:
          if Required and not ReadOnly and (FieldKind=fkData) and IsNull then
            begin
           // allow autoincrement and defaulted fields to be null;
              columnindex := Resultset.FindColumn(Fields[i].FieldName);
              if (Columnindex = 0) or
                 (not Resultset.GetMetadata.HasDefaultValue(columnIndex) and
                  not Resultset.GetMetadata.IsAutoIncrement(columnIndex)) then
                raise EZDatabaseError.Create(Format(SNeedField,[DisplayName]));
            end;
        End;
  end;

begin
  if not (Self is TZAbstractDataset) then
    RaiseReadOnlyError;

  Checkrequired;
end;

{**
  Gets a bookmark flag from the specified record.
  @param Buffer a pointer to the record buffer.
  @return a bookmark flag from the specified record.
}

{$IFDEF WITH_TRECORDBUFFER}

function TZAbstractRODataset.GetBookmarkFlag(Buffer: TRecordBuffer): TBookmarkFlag;
{$ELSE}

function TZAbstractRODataset.GetBookmarkFlag(Buffer: PChar): TBookmarkFlag;
{$ENDIF}
begin
  Result := TBookmarkFlag(PZRowBuffer(Buffer)^.BookmarkFlag);
end;

{**
  Sets a new bookmark flag to the specified record.
  @param Buffer a pointer to the record buffer.
  @param Value a new bookmark flag to the specified record.
}

{$IFDEF WITH_TRECORDBUFFER}
procedure TZAbstractRODataset.SetBookmarkFlag(Buffer: TRecordBuffer;
  Value: TBookmarkFlag);
{$ELSE}
procedure TZAbstractRODataset.SetBookmarkFlag(Buffer: PChar;
  Value: TBookmarkFlag);
{$ENDIF}
begin
  PZRowBuffer(Buffer)^.BookmarkFlag := Ord(Value);
end;

{**
  Gets bookmark value from the specified record.
  @param Buffer a pointer to the record buffer.
  @param Data a pointer to the bookmark value.
}

procedure TZAbstractRODataset.GetBookmarkData(
  Buffer: {$IFDEF WITH_TRECORDBUFFER}TRecordBuffer{$ELSE}PChar{$ENDIF};
  Data: {$IFDEF WITH_BOOKMARKDATA_TBOOKMARK}TBookMark{$ELSE}Pointer{$ENDIF});
begin
  PInteger(Data)^ := PZRowBuffer(Buffer)^.Index;
end;

{**
  Sets a new bookmark value from the specified record.
  @param Buffer a pointer to the record buffer.
  @param Data a pointer to the bookmark value.
}


procedure TZAbstractRODataset.SetBookmarkData(
  Buffer: {$IFDEF WITH_TRECORDBUFFER}TRecordBuffer{$ELSE}PChar{$ENDIF};
  Data: {$IFDEF WITH_BOOKMARKDATA_TBOOKMARK}TBookMark{$ELSE}Pointer{$ENDIF});
begin
  PZRowBuffer(Buffer)^.Index := PInteger(Data)^;
end;

{**
  Compare two specified bookmarks.
  @param Bookmark1 the first bookmark object.
  @param Bookmark2 the second bookmark object.
  @return 0 if bookmarks are equal, -1 if the first bookmark is less,
    1 if the first bookmark is greatter.
}
function TZAbstractRODataset.CompareBookmarks(Bookmark1,
  Bookmark2: TBookmark): Integer;
var
  Index1, Index2: Integer;
begin
  Result := 0;
  if not Assigned(Bookmark1) or not Assigned(Bookmark2) then
    Exit;

  Index1 := CurrentRows.IndexOf(Pointer(PInteger(Bookmark1)^));
  Index2 := CurrentRows.IndexOf(Pointer(PInteger(Bookmark2)^));

  if Index1 < Index2 then Result := -1
  else if Index1 > Index2 then Result := 1;
end;

{**
  Checks is the specified bookmark valid.
  @param Bookmark a bookmark object.
  @return <code>True</code> if the bookmark is valid.
}
function TZAbstractRODataset.BookmarkValid(Bookmark: TBookmark): Boolean;
begin
  Result := False;
  if Active and Assigned(Bookmark) and (FResultSet <> nil) then
    try
      Result := CurrentRows.IndexOf(Pointer(PInteger(Bookmark)^)) >= 0;
    except
      Result := False;
    end;
end;

{**
  Performs an internal initialization of record buffer.
  @param Buffer a record buffer for initialization.
}

{$IFDEF WITH_TRECORDBUFFER}
procedure TZAbstractRODataset.InternalInitRecord(Buffer: TRecordBuffer);
{$ELSE}
procedure TZAbstractRODataset.InternalInitRecord(Buffer: PChar);
{$ENDIF}
begin
  RowAccessor.ClearBuffer(PZRowBuffer(Buffer));
end;

{**
  Performs an internal refreshing.
}
procedure TZAbstractRODataset.InternalRefresh;
var
  RowNo: Integer;
  Found: Boolean;
  KeyFields: string;
  Temp: TZVariantDynArray;
  KeyValues: Variant;
  FieldRefs: TObjectDynArray;
  OnlyDataFields: Boolean;
begin
  OnlyDataFields := False;
  FieldRefs := nil;
  if Active then
  begin
    if CurrentRow > 0 then
    begin
      RowNo := Integer(CurrentRows[CurrentRow - 1]);
      if ResultSet.GetRow <> RowNo then
        ResultSet.MoveAbsolute(RowNo);

      if Properties.Values['KeyFields'] <> '' then
        KeyFields := Properties.Values['KeyFields']
      else
        KeyFields := DefineKeyFields(Fields);
      FieldRefs := DefineFields(Self, KeyFields, OnlyDataFields);
      SetLength(Temp, Length(FieldRefs));
      RetrieveDataFieldsFromResultSet(FieldRefs, ResultSet, Temp);
      if Length(FieldRefs) = 1 then
        KeyValues := EncodeVariant(Temp[0])
      else
        KeyValues := EncodeVariantArray(Temp);
    end
    else
    begin
      KeyFields := '';
      KeyValues := Unassigned;
    end;

    DisableControls;
    try
      try
        FRefreshInProgress := True;
        InternalClose;
        InternalOpen;
      finally
        FRefreshInProgress := False;
      end;

      DoBeforeScroll;
      if KeyFields <> '' then
        Found := Locate(KeyFields, KeyValues, [])
      else
        Found := False;
    finally
      EnableControls;
    end;

    if not Found then
    begin
      DoBeforeScroll;
      DoAfterScroll;
    end;
  end;
end;

{**
  Finds the next record in a filtered query.
  @param Restart a <code>True</code> to find from the start of the query.
  @param GoForward <code>True</code> to navigate in the forward direction.
  @return <code>True</code> if a sutisfied row was found.
}
function TZAbstractRODataset.FindRecord(Restart, GoForward: Boolean): Boolean;
var
  Index: Integer;
  SavedFilterEnabled: Boolean;
begin
  { Checks the current state. }
  CheckBrowseMode;
  DoBeforeScroll;
  Result := False;

  { Defines an initial position position. }
  if Restart then
  begin
    if GoForward then
      Index := 1
    else
    begin
      FetchRows(0);
      Index := CurrentRows.Count;
    end
  end
  else
  begin
    Index := CurrentRow;
    if GoForward then
    begin
      Inc(Index);
      if Index > CurrentRows.Count then
        FetchOneRow;
    end
    else
      Dec(Index);
  end;

  { Finds a record. }
  SavedFilterEnabled := FilterEnabled;
  try
    FilterEnabled := True;
    while (Index >= 1) and (Index <= CurrentRows.Count) do
    begin
      if FilterRow(Index) then
      begin
        Result := True;
        Break;
      end;
      if GoForward then
      begin
        Inc(Index);
        if Index > CurrentRows.Count then
          FetchOneRow;
      end
      else
        Dec(Index)
    end
  finally
    FilterEnabled := SavedFilterEnabled;
  end;

  { Sets a new found position. }
  SetFound(Result);
  if Result then
  begin
    MoveRecNo(Index);
    DoAfterScroll;
  end;
end;

{**
  Sets a filtering control flag.
  @param Value <code>True</code> to turn filtering On.
}
procedure TZAbstractRODataset.SetFiltered(Value: Boolean);
begin
  if Value <> FilterEnabled then
  begin
    FilterEnabled := Value;
    inherited SetFiltered(Value);
    RereadRows;
  end;
end;

{**
  Sets a new filter expression string.
  @param Value a new filter expression.
}
procedure TZAbstractRODataset.SetFilterText(const Value: string);
begin
  inherited SetFilterText(Value);
  FilterExpression.DefaultVariables.Clear;
  FilterExpression.Expression := Value;
  InitFilterFields := False;
  if FilterEnabled then
    RereadRows;
end;

{**
  Checks is the opened resultset sequensed?
  @return <code>True</code> if the opened resultset is sequenced.
}
function TZAbstractRODataset.IsSequenced: Boolean;
begin
  Result := (not FilterEnabled);
end;

{**
  Processes component notifications.
  @param AComponent a changed component object.
  @param Operation a component operation code.
}
procedure TZAbstractRODataset.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);

  if (Operation = opRemove) and (AComponent = FConnection) then
  begin
    Close;
    FConnection := nil;
  end;

  if (Operation = opRemove) and Assigned(FDataLink)
    and (AComponent = FDataLink.Datasource) then
    FDataLink.DataSource := nil;

  if (Operation = opRemove) and Assigned(FMasterLink)
    and (AComponent = FMasterLink.Datasource) then
  begin
    FMasterLink.DataSource := nil;
    RereadRows;
  end;
end;

{**
  Performs an internal record search.
  @param KeyFields a list of field names.
  @param KeyValues a list of field values.
  @param Options a search options.
  @return an index of found row or -1 if nothing was found.
}
function TZAbstractRODataset.InternalLocate(const KeyFields: string;
  const KeyValues: Variant; Options: TLocateOptions): LongInt;
var
  I, RowNo, RowCount: Integer;
  FieldRefs: TObjectDynArray;
  FieldIndices: TIntegerDynArray;
  OnlyDataFields: Boolean;
  SearchRowBuffer: PZRowBuffer;
  DecodedKeyValues: TZVariantDynArray;
  RowValues: TZVariantDynArray;
  PartialKey: Boolean;
  CaseInsensitive: Boolean;
begin
  OnlyDataFields := False;
  CheckBrowseMode;
  Result := -1;
  DecodedKeyValues := nil;

  PartialKey := loPartialKey in Options;
  CaseInsensitive := loCaseInsensitive in Options;

  FieldRefs := DefineFields(Self, KeyFields, OnlyDataFields);
  FieldIndices := nil;
  if FieldRefs = nil then
     Exit;
  DecodedKeyValues := DecodeVariantArray(KeyValues);

  { Checks for equal field and values number }
  if Length(FieldRefs) <> Length(DecodedKeyValues) then
    raise EZDatabaseError.Create(SIncorrectSearchFieldsNumber);
  SetLength(RowValues, Length(DecodedKeyValues));

  if not OnlyDataFields then
  begin
    { Processes fields if come calculated or lookup fields are involved. }
    SearchRowBuffer := PZRowBuffer(AllocRecordBuffer);
    try
      I := 0;
      FieldIndices := DefineFieldIndices(FieldsLookupTable, FieldRefs);
      RowCount := CurrentRows.Count;
      while True do
      begin
        while (I >= RowCount) and FetchOneRow do
          RowCount := CurrentRows.Count;
        if I >= RowCount then
          Break;

        RowNo := Integer(CurrentRows[I]);
        ResultSet.MoveAbsolute(RowNo);

        RowAccessor.RowBuffer := SearchRowBuffer;
        RowAccessor.RowBuffer^.Index := RowNo;
        FetchFromResultSet(ResultSet, FieldsLookupTable, Fields, RowAccessor);
{$IFDEF WITH_TRECORDBUFFER}
        GetCalcFields({$IFDEF WITH_GETCALCFIELDS_TRECBUF}NativeInt{$ELSE}TRecordBuffer{$ENDIF}(SearchRowBuffer));
{$ELSE}
        GetCalcFields(PChar(SearchRowBuffer));
{$ENDIF}
        RetrieveDataFieldsFromRowAccessor(
          FieldRefs, FieldIndices, RowAccessor, RowValues);

        if CompareDataFields(DecodedKeyValues, RowValues,
          PartialKey, CaseInsensitive) then
        begin
          Result := I + 1;
          Break;
        end;

        Inc(I);
      end;
    finally
      if SearchRowBuffer <> nil then
{$IFDEF WITH_TRECORDBUFFER}
        FreeRecordBuffer(TRecordBuffer(SearchRowBuffer));
{$ELSE}
        FreeRecordBuffer(PChar(SearchRowBuffer));
{$ENDIF}
    end;
  end
  else
  begin
    PrepareValuesForComparison(FieldRefs, DecodedKeyValues,
      ResultSet, PartialKey, CaseInsensitive);

    { Processes only data fields. }
    I := 0;
    RowCount := CurrentRows.Count;
    while True do
    begin
      while (I >= RowCount) and FetchOneRow do
        RowCount := CurrentRows.Count;
      if I >= RowCount then
        Break;

      RowNo := Integer(CurrentRows[I]);
      ResultSet.MoveAbsolute(RowNo);

      if CompareFieldsFromResultSet(FieldRefs, DecodedKeyValues,
        ResultSet, PartialKey, CaseInsensitive) then
      begin
        Result := I + 1;
        Break;
      end;

      Inc(I);
    end;
  end;
end;

{**
  Locates an interested record by specified search criteria.
  @param KeyFields a list of field names.
  @param KeyValues a list of field values.
  @param Options a search options.
  @return <code>True</code> if record was found or <code>False</code> otherwise.
}
function TZAbstractRODataset.Locate(const KeyFields: string;
  const KeyValues: Variant; Options: TLocateOptions): Boolean;
var
  Index: Integer;
begin
  DoBeforeScroll;
  if (Active) then //AVZ Check if the dataset is active before performing locate - return false otherwise
  begin
    Index := InternalLocate(KeyFields, KeyValues, Options);
    if Index > 0 then
    begin
      MoveRecNo(Index);
      DoAfterScroll;
      Result := True;
    end
    else
      Result := False;
    SetFound(Result);

  end
    else
  begin
    Result := False;
  end;
end;

{**
  Lookups specified fields from the searched record.
  @param KeyValues a list of field names to search record.
  @param KeyValues an array of field values to search record.
  @param ResultFields a list of field names to return as a result.
  @return an array of requested field values.
}
function TZAbstractRODataset.Lookup(const KeyFields: string;
  const KeyValues: Variant; const ResultFields: string): Variant;
var
  RowNo: Integer;
  FieldRefs: TObjectDynArray;
  FieldIndices: TIntegerDynArray;
  OnlyDataFields: Boolean;
  SearchRowBuffer: PZRowBuffer;
  ResultValues: TZVariantDynArray;
begin
  OnlyDataFields := False;
  Result := Null;
  RowNo := InternalLocate(KeyFields, KeyValues, []);
  FieldRefs := nil;
  FieldIndices := nil;
  if RowNo < 0 then
     Exit;

  { Fill result array }
  FieldRefs := DefineFields(Self, ResultFields, OnlyDataFields);
  FieldIndices := DefineFieldIndices(FieldsLookupTable, FieldRefs);
  SetLength(ResultValues, Length(FieldRefs));
  SearchRowBuffer := PZRowBuffer(AllocRecordBuffer);
  try
    RowNo := Integer(CurrentRows[RowNo - 1]);
    if ResultSet.GetRow <> RowNo then
      ResultSet.MoveAbsolute(RowNo);

    RowAccessor.RowBuffer := SearchRowBuffer;
    RowAccessor.RowBuffer^.Index := RowNo;
    FetchFromResultSet(ResultSet, FieldsLookupTable, Fields, RowAccessor);
{$IFDEF WITH_TRECORDBUFFER}
    GetCalcFields({$IFDEF WITH_GETCALCFIELDS_TRECBUF}NativeInt{$ELSE}TRecordBuffer{$ENDIF}(SearchRowBuffer));
{$ELSE}
    GetCalcFields(PChar(SearchRowBuffer));
{$ENDIF}
    RetrieveDataFieldsFromRowAccessor(
      FieldRefs, FieldIndices, RowAccessor, ResultValues);
  finally
{$IFDEF WITH_TRECORDBUFFER}
    FreeRecordBuffer(TRecordBuffer(SearchRowBuffer));
{$ELSE}
    FreeRecordBuffer(PChar(SearchRowBuffer));
{$ENDIF}
  end;

  if Length(FieldIndices) = 1 then
    Result := EncodeVariant(ResultValues[0])
  else
    Result := EncodeVariantArray(ResultValues);
end;

{**
  Gets the updated status for the current row.
  @return the UpdateStatus value for the current row.
}
function TZAbstractRODataset.UpdateStatus: TUpdateStatus;
var
  RowNo: Integer;
begin
  Result := usUnmodified;
  if (ResultSet <> nil) and (CurrentRows.Count > 0) then
  begin
    RowNo := Integer(CurrentRows[CurrentRow - 1]);
    if ResultSet.GetRow <> RowNo then
      ResultSet.MoveAbsolute(RowNo);

    if ResultSet.RowInserted then
      Result := usInserted
    else if ResultSet.RowUpdated then
      Result := usModified
    else if ResultSet.RowDeleted then
      Result := usDeleted;
  end;
end;

{**
  Translates strings between ansi and oem character sets.
}
function TZAbstractRODataset.Translate(Src, Dest: PAnsiChar; ToOem: Boolean):
   Integer;
begin
  if (Src <> nil) then
  begin
    Result := {$IFDEF WITH_STRLEN_DEPRECATED}AnsiStrings.{$ENDIF}StrLen(Src);
  {$IFNDEF UNIX}
    if doOemTranslate in FOptions then
    begin
      if ToOem then
        CharToOemA(Src, Dest)
      else
        OemToCharA(Src, Dest);
      Dest[Result] := #0;
    end
    else
  {$ENDIF}
    begin
      if (Src <> Dest) then
      {$IFDEF WITH_STRCOPY_DEPRECATED}AnsiStrings.{$ENDIF}StrCopy(Dest, Src);
    end;
  end
  else
    Result := 0;
end;

{**
  Prepares the query.
  If this actually does happen at the database connection level depends on the
  specific implementation.
}
procedure TZAbstractRODataset.Prepare;
begin
  Prepared := True;
end;

{**
  Unprepares the query.
  Before the query gets executed it must be prepared again.
}
procedure TZAbstractRODataset.Unprepare;
begin
  Prepared := False;
end;

{**
  Creates a stream object for specified blob field.
  @param Field an interested field object.
  @param Mode a blob open mode.
  @return a created stream object.
}
function TZAbstractRODataset.CreateBlobStream(Field: TField;
  Mode: TBlobStreamMode): TStream;
var
  ColumnIndex: Integer;
  RowBuffer: PZRowBuffer;
  Blob: IZBlob;
  WasNull: Boolean;
begin
  WasNull := False;
  CheckActive;

  Result := nil;
  if (Field.DataType in [ftBlob, ftMemo, ftGraphic, ftFmtMemo {$IFDEF WITH_WIDEMEMO},ftWideMemo{$ENDIF}])
    and GetActiveBuffer(RowBuffer) then
  begin
    ColumnIndex := DefineFieldIndex(FieldsLookupTable, Field);
    RowAccessor.RowBuffer := RowBuffer;

    if Mode = bmRead then
    begin
      case Field.DataType of
      ftMemo, ftFmtMemo:
        Result := RowAccessor.GetAsciiStream(ColumnIndex, WasNull);
      {$IFDEF WITH_WIDEMEMO}
      ftWideMemo:
        Result := RowAccessor.GetUnicodeStream(ColumnIndex, WasNull)
      {$ENDIF}
      else
        Result := RowAccessor.GetBinaryStream(ColumnIndex, WasNull);
      end;
    end
    else
    begin
      Blob := RowAccessor.GetBlob(ColumnIndex, WasNull);
      if Blob <> nil then
        Blob := Blob.Clone;
      RowAccessor.SetBlob(ColumnIndex, Blob);
      Result := TZBlobStream.Create(Field as TBlobField, Blob, Mode,
        FConnection.DbcConnection.GetConSettings);
    end;
  end;
  if Result = nil then
    Result := TMemoryStream.Create;
end;

{$IFDEF WITH_FTDATASETSUPPORT}
function TZAbstractRODataset.CreateNestedDataSet(DataSetField: TDataSetField): TDataSet;
begin
  Result := inherited CreateNestedDataSet(DataSetField);
end;
{$ENDIF}

{**
  Closes the specified BLOB field.
  @param a BLOB field object.
}
procedure TZAbstractRODataset.CloseBlob(Field: TField);
begin
end;

{**
  Closes the cursor-handles. Releases(not closing) the current resultset
  and opens the cursorhandles. The current statment is used further.
  @param the NewResultSet
}
procedure TZAbstractRODataset.SetAnotherResultset(const Value: IZResultSet);
begin
  {EgonHugeist: I was forced to go this stupid sequence
    first i wanted to exclude parts of InternalOpen/Close but this didn't solve
    the DataSet issues. You can't init the fields as long the Cursor is not
    closed.. Which is equal to cursor open}
  if Assigned(Value) and ( Value <> ResultSet ) then
  begin
    FDoNotCloseResultSet := True; //hint for InternalClose
    SetState(dsInactive);
    CloseCursor; //Calls InternalOpen in his sequence so InternalClose must be prepared
    FDoNotCloseResultSet := False; //reset hint for InternalClose
    ResultSet := Value; //Assign the new resultset
    if not ResultSet.IsBeforeFirst then
      ResultSet.BeforeFirst; //need this. All from dataset buffered resultsets are EOR
    FUseCurrentStatment := True; //hint for InternalOpen
    OpenCursor{$IFDEF FPC}(False){$ENDIF}; //Calls InternalOpen in his sequence so InternalOpen must be prepared
    OpenCursorComplete; //set DataSet to dsActive
    FUseCurrentStatment := False; //reset hint for InternalOpen
  end;
end;

{**
  Performs sorting of the internal rows.
}
procedure TZAbstractRODataset.InternalSort;
var
  I, RowNo: Integer;
  SavedRowBuffer: PZRowBuffer;
begin
  if FIndexFieldNames = '' then exit; {bangfauzan addition}
  if (ResultSet <> nil) and not IsUniDirectional then
  begin
    FIndexFieldNames := Trim(FIndexFieldNames); {bangfauzan modification}
    DefineSortedFields(Self, {FSortedFields} FIndexFieldNames {bangfauzan modification},
    FSortedFieldRefs, FSortedFieldDirs, FSortedOnlyDataFields);

    if (CurrentRow <= CurrentRows.Count) and (CurrentRows.Count > 0)
      and (CurrentRow > 0) then
      RowNo := Integer(CurrentRows[CurrentRow - 1])
    else
      RowNo := -1;

    { Restores the previous order. }
    if Length(FSortedFieldRefs) = 0 then
    begin
      CurrentRows.Sort(ClearSort);
    end
    else
    begin
      FetchRows(0);
      if FSortedOnlyDataFields then
      begin
        { Converts field objects into field indices. }
        SetLength(FSortedFieldIndices, Length(FSortedFieldRefs));
        for I := 0 to High(FSortedFieldRefs) do
          FSortedFieldIndices[I] := TField(FSortedFieldRefs[I]).FieldNo;
        { Performs a sorting. }
        CurrentRows.Sort(LowLevelSort);
      end
      else
      begin
        SavedRowBuffer := RowAccessor.RowBuffer;
        { Sorts using generic highlevel approach. }
        try
          { Allocates buffers for sorting. }
          RowAccessor.AllocBuffer(FSortRowBuffer1);
          RowAccessor.AllocBuffer(FSortRowBuffer2);
          { Converts field objects into field indices. }
          SetLength(FSortedFieldIndices, Length(FSortedFieldRefs));
          for I := 0 to High(FSortedFieldRefs) do
          begin
            FSortedFieldIndices[I] := DefineFieldIndex(FieldsLookupTable,
              TField(FSortedFieldRefs[I]));
          end;
          { Performs sorting. }
          CurrentRows.Sort(HighLevelSort);
        finally
          { Disposed buffers for sorting. }
          RowAccessor.DisposeBuffer(FSortRowBuffer1);
          RowAccessor.DisposeBuffer(FSortRowBuffer2);
          RowAccessor.RowBuffer := SavedRowBuffer;
        end;
      end;
    end;

    CurrentRow := CurrentRows.IndexOf(Pointer(RowNo)) + 1;
    CurrentRow := Min(Max(0, CurrentRow), CurrentRows.Count);
    if not (State in [dsInactive]) then
       Resync([]);
  end;
end;

{**
  Clears list sorting and restores the previous order.
  @param Item1 a reference to the first row.
  @param Item2 a reference to the second row.
  @returns &gt;0 if Item1 &gt; Item2, &lt;0 it Item1 &lt; Item2 and 0
    if Item1 and Item2 are equal.
}
function TZAbstractRODataset.ClearSort(Item1, Item2: Pointer): Integer;
begin
  Result := Integer(Item1) - Integer(Item2);
end;

{**
  Sorting list using generic approach which is slow but may be used
  with calculated fields.

  @param Item1 a reference to the first row.
  @param Item2 a reference to the second row.
  @returns &gt;0 if Item1 &gt; Item2, &lt;0 it Item1 &lt; Item2 and 0
    if Item1 and Item2 are equal.
}
function TZAbstractRODataset.HighLevelSort(Item1, Item2: Pointer): Integer;
var
  RowNo: Integer;
begin
  { Gets the first row. }
  RowNo := Integer(Item1);
  ResultSet.MoveAbsolute(RowNo);
  RowAccessor.RowBuffer := FSortRowBuffer1;
  RowAccessor.RowBuffer^.Index := RowNo;
  FetchFromResultSet(ResultSet, FieldsLookupTable, Fields, RowAccessor);
  FRowAccessor.RowBuffer^.BookmarkFlag := Ord(bfCurrent);
{$IFDEF WITH_TRECORDBUFFER}
  GetCalcFields({$IFDEF WITH_GETCALCFIELDS_TRECBUF}NativeInt{$ELSE}TRecordBuffer{$ENDIF}(FSortRowBuffer1));
{$ELSE}
  GetCalcFields(PChar(FSortRowBuffer1));
{$ENDIF}

  { Gets the second row. }
  RowNo := Integer(Item2);
  ResultSet.MoveAbsolute(RowNo);
  RowAccessor.RowBuffer := FSortRowBuffer2;
  RowAccessor.RowBuffer^.Index := RowNo;
  FetchFromResultSet(ResultSet, FieldsLookupTable, Fields, RowAccessor);
  FRowAccessor.RowBuffer^.BookmarkFlag := Ord(bfCurrent);
{$IFDEF WITH_TRECORDBUFFER}
  GetCalcFields({$IFDEF WITH_GETCALCFIELDS_TRECBUF}NativeInt{$ELSE}TRecordBuffer{$ENDIF}(FSortRowBuffer2));
{$ELSE}
  GetCalcFields(PChar(FSortRowBuffer2));
{$ENDIF}

  { Compare both records. }
  Result := RowAccessor.CompareBuffers(FSortRowBuffer1, FSortRowBuffer2,
    FSortedFieldIndices, FSortedFieldDirs);
end;

{**
  Sorting list using lowlevel approach which is fast but may not be used
  with calculated fields.

  @param Item1 a reference to the first row.
  @param Item2 a reference to the second row.
  @returns &gt;0 if Item1 &gt; Item2, &lt;0 it Item1 &lt; Item2 and 0
    if Item1 and Item2 are equal.
}
function TZAbstractRODataset.LowLevelSort(Item1, Item2: Pointer): Integer;
begin
  Result := ResultSet.CompareRows(Integer(Item1), Integer(Item2),
    FSortedFieldIndices, FSortedFieldDirs);
end;

{**
   Sets a new dataset properties.
   @param Value a dataset properties.
}
procedure TZAbstractRODataset.SetProperties(const Value: TStrings);
begin
  FProperties.Assign(Value);
end;

{$IFDEF WITH_IPROVIDER}

{**
  Starts a new transaction.
}
procedure TZAbstractRODataset.PSStartTransaction;
begin
  if Assigned(FConnection) and not FConnection.AutoCommit then
  begin
    if not FConnection.Connected then
      FConnection.Connect;
    FConnection.StartTransaction;
  end;
end;

{**
  Completes previously started transaction.
  @param Commit a commit transaction flag.
}
procedure TZAbstractRODataset.PSEndTransaction(Commit: Boolean);
begin
  if Assigned(FConnection) and FConnection.Connected
    and not FConnection.AutoCommit then
  begin
      if Commit then
         FConnection.Commit
      else
         FConnection.Rollback;
  end;
end;

{**
  Checks if this query is in transaction mode.
  @returns <code>True</code> if query in transaction.
}
function TZAbstractRODataset.PSInTransaction: Boolean;
begin
  Result := Assigned(FConnection) and FConnection.Connected
    and (FConnection.TransactIsolationLevel <> tiNone)
    and not FConnection.AutoCommit;
end;

{**
  Returns a string quote character.
  @retuns a quote character.
}
{$IFDEF WITH_IPROVIDERWIDE}
function TZAbstractRODataset.PSGetQuoteCharW: WideString;
{$ELSE}
function TZAbstractRODataset.PSGetQuoteChar: string;
{$ENDIF}
begin
  if Assigned(FConnection) then
  begin
    if not FConnection.Connected then
      FConnection.Connect;
    Result := FConnection.DbcConnection.GetMetadata.GetDatabaseInfo.GetIdentifierQuoteString;
    if Length(Result) > 1 then
      Result := Copy(Result, 1, 1);
  end
  else
    Result := '"';
end;

{**
  Checks if dataset can execute any commands?
  @returns <code>True</code> if the query can execute any commands.
}
function TZAbstractRODataset.PSIsSQLSupported: Boolean;
begin
  Result := True;
end;

{**
  Checks if dataset can execute SQL queries?
  @returns <code>True</code> if the query can execute SQL.
}
function TZAbstractRODataset.PSIsSQLBased: Boolean;
begin
  Result := True;
end;

{**
  Resets this dataset.
}
procedure TZAbstractRODataset.PSReset;
begin
  inherited PSReset;
  if Active then
  begin
    Refresh;
    First;
  end;
end;

{**
  Execute statement a SQL query.
}
procedure TZAbstractRODataset.PSExecute;
begin
  ExecSQL;
end;

{**
  Gets query parameters.
  @returns parameters of this query.
}
function TZAbstractRODataset.PSGetParams: TParams;
begin
  Result := Params;
end;

{**
  Set new query parameters
  @param AParams new parameters to set into this query.
}
procedure TZAbstractRODataset.PSSetParams(AParams: TParams);
begin
  if AParams.Count > 0 then
    Params.Assign(AParams);
end;

{**
  Sets a command text for this query to execute.
  @param CommandText a command text for this query.
}

{$IFDEF WITH_IPROVIDERWIDE}
procedure TZAbstractRODataset.PSSetCommandText(const CommandText: string);
begin
  SQL.Text := CommandText;
end;

procedure TZAbstractRODataset.PSSetCommandText(const CommandText: WideString);
{$ELSE}
procedure TZAbstractRODataset.PSSetCommandText(const CommandText: string);
{$ENDIF}
begin
  SQL.Text := CommandText;
end;

{**
  Updates a record in the specified dataset.
  @param UpdateKind a type of the update.
  @param Delta a dataset with updates.
}
function TZAbstractRODataset.PSUpdateRecord(UpdateKind: TUpdateKind;
  Delta: TDataSet): Boolean;
begin
  Result := False;
end;

{**
  Generates an EUpdateError object based on another exception object.
  @param E occured exception.
  @param Prev a previous update error.
  @returns a new created update error.
}
function TZAbstractRODataset.PSGetUpdateException(E: Exception;
  Prev: EUpdateError): EUpdateError;
var
  PrevErrorCode: Integer;
begin
  if E is EZSQLException then
  begin
    if Assigned(Prev) then
      PrevErrorCode := Prev.ErrorCode
    else
      PrevErrorCode := 0;

    Result := EUpdateError.Create(E.Message, '',
      EZSQLException(E).ErrorCode, PrevErrorCode, E);
  end
  else
    Result := EUpdateError.Create(E.Message, '', -1, -1, E);
end;

{**
  Gets a table name if table is only one in the SELECT SQL statement.
  @returns a table name or an empty string is SQL query is complex SELECT
    or not SELECT statement.
}
{$IFDEF WITH_IPROVIDERWIDE}
function TZAbstractRODataset.PSGetTableNameW: WideString;
{$ELSE}
function TZAbstractRODataset.PSGetTableName: string;
{$ENDIF}
var
  Driver: IZDriver;
  Tokenizer: IZTokenizer;
  StatementAnalyser: IZStatementAnalyser;
  SelectSchema: IZSelectSchema;
begin
  Result := '';
  if FConnection <> nil then
  begin
    Driver := FConnection.DbcDriver;
    Tokenizer := Driver.GetTokenizer;
    StatementAnalyser := Driver.GetStatementAnalyser;
    SelectSchema := StatementAnalyser.DefineSelectSchemaFromQuery(
      Tokenizer, SQL.Text);
    if Assigned(SelectSchema) and (SelectSchema.TableCount = 1) then
      Result := SelectSchema.Tables[0].FullName;
  end;
end;

{**
  Defines a list of query primary key fields.
  @returns a semicolon delimited list of query key fields.
}
// Silvio Clecio
{$IFDEF WITH_IPROVIDERWIDE}
{$WARNINGS OFF}
function TZAbstractRODataset.PSGetKeyFieldsW: WideString;
begin
  Result := inherited PSGetKeyFieldsW;
end;
{$WARNINGS ON}
{$ELSE}
function TZAbstractRODataset.PSGetKeyFields: string;
begin
  Result := inherited PSGetKeyFields;
end;
{$ENDIF}

{**
  Executes a SQL statement with parameters.
  @param ASQL a SQL statement with parameters defined with question marks.
  @param AParams a collection of statement parameters.
  @param ResultSet a supplied result set reference (just ignored).
  @returns a number of updated rows.
}

{$IFDEF WITH_IPROVIDERWIDE}
function TZAbstractRODataset.PSExecuteStatement(const ASQL: WideString; AParams: TParams;
  ResultSet: Pointer = nil): Integer;
{$ELSE}
function TZAbstractRODataset.PSExecuteStatement(const ASQL: string;
  AParams: TParams; ResultSet: Pointer): Integer;
{$ENDIF}
var
  I: Integer;
  Statement: IZPreparedStatement;
  ParamValue: TParam;
begin
  if Assigned(FConnection) then
  begin
    if not FConnection.Connected then
      FConnection.Connect;
    Statement := FConnection.DbcConnection.PrepareStatement(ASQL);
    if (AParams <> nil) and (AParams.Count > 0) then
      for I := 0 to AParams.Count - 1 do
      begin
        ParamValue := AParams[I];
        SetStatementParam(I+1, Statement, ParamValue);
      end;
    Result := Statement.ExecuteUpdatePrepared;
  end
  else
    Result := 0;
end;

{$ENDIF}

procedure TZAbstractRODataset.CheckFieldCompatibility(Field: TField;FieldDef: TFieldDef);

const
{$IFDEF FPC}
  BaseFieldTypes: array[TFieldType] of TFieldType = (
    ftUnknown, ftString, ftInteger, ftInteger, ftInteger, ftBoolean, ftFloat,
    ftCurrency, ftBCD, ftDateTime, ftDateTime, ftDateTime, ftBytes, ftVarBytes,
    ftInteger, ftBlob, ftBlob, ftBlob, ftBlob, ftBlob, ftBlob, ftBlob, ftUnknown,
    ftString, ftString, ftLargeInt, ftADT, ftArray, ftReference, ftDataSet,
    ftBlob, ftBlob, ftVariant, ftInterface, ftInterface, ftString, ftTimeStamp,
    ftFMTBcd , ftString, ftBlob);
{$ELSE}
{$IFDEF VER180} //D2006
BaseFieldTypes: array[TFieldType] of TFieldType = (
  ftUnknown, ftString, ftInteger, ftInteger, ftInteger, ftBoolean, ftFloat,
  ftCurrency, ftBCD, ftDateTime, ftDateTime, ftDateTime, ftBytes, ftVarBytes,
  ftInteger, ftBlob, ftBlob, ftBlob, ftBlob, ftBlob, ftBlob, ftBlob, ftUnknown,
  ftString, ftString, ftLargeInt, ftADT, ftArray, ftReference, ftDataSet,
  ftBlob, ftBlob, ftVariant, ftInterface, ftInterface, ftString, ftTimeStamp, ftFMTBcd,
  ftFixedWideChar,ftWideMemo,ftOraTimeStamp,ftOraInterval);
{$ELSE !VER180}
{$IFDEF VER185} //D2007
BaseFieldTypes: array[TFieldType] of TFieldType = (ftUnknown, ftString, ftSmallint, ftInteger, ftWord, // 0..4
  ftBoolean, ftFloat, ftCurrency, ftBCD, ftDate, ftTime, ftDateTime, // 5..11
  ftBytes, ftVarBytes, ftAutoInc, ftBlob, ftMemo, ftGraphic, ftFmtMemo, // 12..18
  ftParadoxOle, ftDBaseOle, ftTypedBinary, ftCursor, ftFixedChar, ftWideString, // 19..24
  ftLargeint, ftADT, ftArray, ftReference, ftDataSet, ftOraBlob, ftOraClob, // 25..31
  ftVariant, ftInterface, ftIDispatch, ftGuid, ftTimeStamp, ftFMTBcd, // 32..37
  ftFixedWideChar, ftWideMemo, ftOraTimeStamp, ftOraInterval); // 38..41
{$ELSE !VER185}
{$IFDEF VER200}
   BaseFieldTypes: array[TFieldType] of TFieldType = (
      ftUnknown, ftString, ftSmallint, ftInteger, ftWord,
      ftBoolean, ftFloat, ftCurrency, ftBCD, ftDate, ftTime, ftDateTime,
      ftBytes, ftVarBytes, ftAutoInc, ftBlob, ftMemo, ftGraphic, ftFmtMemo,
      ftParadoxOle, ftDBaseOle, ftTypedBinary, ftCursor, ftFixedChar, ftWideString,
      ftLargeint, ftADT, ftArray, ftReference, ftDataSet, ftOraBlob, ftOraClob,
      ftVariant, ftInterface, ftIDispatch, ftGuid, ftTimeStamp, ftFMTBcd,
      ftFixedWideChar, ftWideMemo, ftOraTimeStamp, ftOraInterval,
      ftLongWord, ftShortint, ftByte, ftExtended, ftConnection, ftParams, ftStream);
{$ELSE !VER200}
{$IFDEF VER210}
   BaseFieldTypes: array[TFieldType] of TFieldType = (
      ftUnknown, ftString, ftSmallint, ftInteger, ftWord,
      ftBoolean, ftFloat, ftCurrency, ftBCD, ftDate, ftTime, ftDateTime,
      ftBytes, ftVarBytes, ftAutoInc, ftBlob, ftMemo, ftGraphic, ftFmtMemo,
      ftParadoxOle, ftDBaseOle, ftTypedBinary, ftCursor, ftFixedChar, ftWideString,
      ftLargeint, ftADT, ftArray, ftReference, ftDataSet, ftOraBlob, ftOraClob,
      ftVariant, ftInterface, ftIDispatch, ftGuid, ftTimeStamp, ftFMTBcd,
      ftFixedWideChar, ftWideMemo, ftOraTimeStamp, ftOraInterval,
      ftLongWord, ftShortint, ftByte, ftExtended, ftConnection, ftParams, ftStream,
      ftTimeStampOffset, ftObject, ftSingle);
{$ELSE !VER210}
{$IFDEF VER220}
  BaseFieldTypes: array[TFieldType] of TFieldType = (
    ftUnknown, ftString, ftInteger, ftInteger, ftInteger, ftBoolean, ftFloat,  // 0..6
    ftFloat, ftBCD, ftDateTime, ftDateTime, ftDateTime, ftBytes, ftVarBytes, // 7..13
    ftInteger, ftBlob, ftBlob, ftBlob, ftBlob, ftBlob, ftBlob, ftBlob, ftUnknown, // 14..22
    ftString, ftWideString, ftLargeInt, ftADT, ftArray, ftReference, ftDataSet, // 23..29
    ftBlob, ftBlob, ftVariant, ftInterface, ftInterface, ftString, ftTimeStamp, ftFMTBcd, // 30..37
    ftWideString, ftBlob, ftOraTimeStamp, ftOraInterval, //38..41
    ftLongWord, ftInteger, ftInteger, ftExtended, ftConnection, ftParams, ftStream, //42..48
    ftTimeStampOffset, ftObject, ftSingle); // 49..51
{$ELSE !VER220}
{$IFDEF VER230}
  BaseFieldTypes: array[TFieldType] of TFieldType = (
    ftUnknown, ftString, ftSmallint, ftInteger, ftWord, ftBoolean, ftFloat,
    ftCurrency, ftBCD, ftDate, ftTime, ftDateTime, ftBytes, ftVarBytes, ftAutoInc,
    ftBlob, ftMemo, ftGraphic, ftFmtMemo, ftParadoxOle, ftDBaseOle, ftTypedBinary,
    ftCursor, ftFixedChar, ftWideString, ftLargeint, ftADT, ftArray, ftReference,
    ftDataSet, ftOraBlob, ftOraClob, ftVariant, ftInterface, ftIDispatch, ftGuid,
    ftTimeStamp, ftFMTBcd, ftFixedWideChar, ftWideMemo, ftOraTimeStamp, ftOraInterval,
    ftLongWord, ftShortint, ftByte, ftExtended, ftConnection, ftParams, ftStream,
    ftTimeStampOffset, ftObject, ftSingle );
{$ELSE !VER230}
{$IFDEF VER240}
  BaseFieldTypes: array[TFieldType] of TFieldType = (
    ftUnknown, ftString, ftSmallint, ftInteger, ftWord, ftBoolean, ftFloat,
    ftCurrency, ftBCD, ftDate, ftTime, ftDateTime, ftBytes, ftVarBytes, ftAutoInc,
    ftBlob, ftMemo, ftGraphic, ftFmtMemo, ftParadoxOle, ftDBaseOle, ftTypedBinary,
    ftCursor, ftFixedChar, ftWideString, ftLargeint, ftADT, ftArray, ftReference,
    ftDataSet, ftOraBlob, ftOraClob, ftVariant, ftInterface, ftIDispatch, ftGuid,
    ftTimeStamp, ftFMTBcd, ftFixedWideChar, ftWideMemo, ftOraTimeStamp, ftOraInterval,
    ftLongWord, ftShortint, ftByte, ftExtended, ftConnection, ftParams, ftStream,
    ftTimeStampOffset, ftObject, ftSingle );
{$ELSE !VER240}
{$IFDEF VER250}
  BaseFieldTypes: array[TFieldType] of TFieldType = (
    ftUnknown, ftString, ftSmallint, ftInteger, ftWord, ftBoolean, ftFloat,
    ftCurrency, ftBCD, ftDate, ftTime, ftDateTime, ftBytes, ftVarBytes, ftAutoInc,
    ftBlob, ftMemo, ftGraphic, ftFmtMemo, ftParadoxOle, ftDBaseOle, ftTypedBinary,
    ftCursor, ftFixedChar, ftWideString, ftLargeint, ftADT, ftArray, ftReference,
    ftDataSet, ftOraBlob, ftOraClob, ftVariant, ftInterface, ftIDispatch, ftGuid,
    ftTimeStamp, ftFMTBcd, ftFixedWideChar, ftWideMemo, ftOraTimeStamp, ftOraInterval,
    ftLongWord, ftShortint, ftByte, ftExtended, ftConnection, ftParams, ftStream,
    ftTimeStampOffset, ftObject, ftSingle );
{$ELSE !VER250}
{$IFDEF VER260}
  BaseFieldTypes: array[TFieldType] of TFieldType = (
    ftUnknown, ftString, ftSmallint, ftInteger, ftWord, ftBoolean, ftFloat,
    ftCurrency, ftBCD, ftDate, ftTime, ftDateTime, ftBytes, ftVarBytes, ftAutoInc,
    ftBlob, ftMemo, ftGraphic, ftFmtMemo, ftParadoxOle, ftDBaseOle, ftTypedBinary,
    ftCursor, ftFixedChar, ftWideString, ftLargeint, ftADT, ftArray, ftReference,
    ftDataSet, ftOraBlob, ftOraClob, ftVariant, ftInterface, ftIDispatch, ftGuid,
    ftTimeStamp, ftFMTBcd, ftFixedWideChar, ftWideMemo, ftOraTimeStamp, ftOraInterval,
    ftLongWord, ftShortint, ftByte, ftExtended, ftConnection, ftParams, ftStream,
    ftTimeStampOffset, ftObject, ftSingle );
{$ELSE !VER260} //>= D2005
  BaseFieldTypes: array[TFieldType] of TFieldType =
   (ftUnknown, ftString, ftSmallint, ftInteger, ftWord,
    ftBoolean, ftFloat, ftCurrency, ftBCD, ftDate, ftTime, ftDateTime,
    ftBytes, ftVarBytes, ftAutoInc, ftBlob, ftMemo, ftGraphic, ftFmtMemo,
    ftParadoxOle, ftDBaseOle, ftTypedBinary, ftCursor, ftFixedChar, ftWideString,
    ftLargeint, ftADT, ftArray, ftReference, ftDataSet, ftOraBlob, ftOraClob,
    ftVariant, ftInterface, ftIDispatch, ftGuid, ftTimeStamp, ftFMTBcd);
{$ENDIF VER260}
{$ENDIF VER250}
{$ENDIF VER240}
{$ENDIF VER230}
{$ENDIF VER220}
{$ENDIF VER210}
{$ENDIF VER200}
{$ENDIF VER185}
{$ENDIF VER180}
{$ENDIF FPC}


  CheckTypeSizes = [ftBytes, ftVarBytes, ftBCD, ftReference];

begin
  with Field do
  begin
    if (BaseFieldTypes[DataType] <> BaseFieldTypes[FieldDef.DataType]) then
      DatabaseErrorFmt(SFieldTypeMismatch, [DisplayName,
        FieldTypeNames[DataType], FieldTypeNames[FieldDef.DataType]], Self);
    if (DataType in CheckTypeSizes) and (Size <> FieldDef.Size) then
        DatabaseErrorFmt(SFieldSizeMismatch, [DisplayName, Size,
          FieldDef.Size], Self);
  end;
end;

{**
  Reset the calculated (includes fkLookup) fields
  @param Buffer
}

{$IFDEF WITH_TRECORDBUFFER}

procedure TZAbstractRODataset.ClearCalcFields(Buffer: TRecordBuffer);
{$ELSE}

procedure TZAbstractRODataset.ClearCalcFields(Buffer: PChar);
{$ENDIF}
var
  Index: Integer;
begin
  RowAccessor.RowBuffer := PZRowBuffer(Buffer);
  for Index := 1 to Fields.Count do
    if (Fields[Index-1].FieldKind in [fkCalculated, fkLookup]) then
      RowAccessor.SetNull(DefineFieldindex(FFieldsLookupTable,Fields[Index-1]));
end;

{=======================bangfauzan addition========================}
function TZAbstractRODataset.GetSortType: TSortType;
var
  AscCount, DescCount: Integer;
  s: String;
begin
  {pawelsel modification}
  AscCount:=0;
  DescCount:=0;
  s:=StringReplace(FIndexFieldNames,';',',',[rfReplaceAll]);
  while Pos(',',s)>0 do
  begin
    if Pos(' DESC',UpperCase(Copy(s,1,Pos(',',s))))>0 then
      Inc(DescCount)
    else
      Inc(AscCount);
    s:=Copy(s,Pos(',',s)+1,Length(s)-Pos(',',s));
  end;
  if Length(s)>0 then
    if Pos(' DESC',UpperCase(s))>0 then
      Inc(DescCount)
    else
      Inc(AscCount);
  if (DescCount > 0) and (AscCount > 0) then
     Result:=stIgnored
  else if (DescCount > 0) then
     Result:=stDescending
  else
     Result:=stAscending;
end;

procedure TZAbstractRODataset.SetSortType(Value: TSortType);
begin
  if FSortType <> Value then
  begin
    FSortType := Value;
    if (FSortType <> stIgnored) then
    begin {pawelsel modification}
       FSortedFields:=StringReplace(FSortedFields,' Desc','',[rfReplaceAll,rfIgnoreCase]);
       FSortedFields:=StringReplace(FSortedFields,' Asc','',[rfReplaceAll,rfIgnoreCase]);
    end;
    FIndexFieldNames:=GetIndexFieldNames;
    if Active then
       if (FSortedFields = '') then
          Self.InternalRefresh
      else
          InternalSort;
  end;
end;

function TZAbstractRODataset.GetIndexFieldNames : String;
begin
  Result:=FSortedFields;
  if Result <> '' then
  begin {pawelsel modification}
    if FSortType = stAscending then
    begin
       Result:=StringReplace(Result,';',' Asc;',[rfReplaceAll]);
       Result:=StringReplace(Result,',',' Asc,',[rfReplaceAll]);
       Result:=Result+' Asc';
    end;
    if FSortType = stDescending then
    begin
       Result:=StringReplace(Result,';',' Desc;',[rfReplaceAll]);
       Result:=StringReplace(Result,',',' Desc,',[rfReplaceAll]);
       Result:=Result+' Desc';
    end;
  end;
end;

procedure TZAbstractRODataset.SetIndexFieldNames(Value: String);
begin
  Value:=Trim(Value);
  {pawelsel modification}
  Value:=StringReplace(Value,'[','',[rfReplaceAll]);
  Value:=StringReplace(Value,']','',[rfReplaceAll]);

  if FIndexFieldNames <> Value then
  begin
     FIndexFieldNames := Value;
     FSortType:=GetSortType;
     if (FSortType <> stIgnored) then
     begin {pawelsel modification}
        Value:=StringReplace(Value,' Desc','',[rfReplaceAll,rfIgnoreCase]);
        Value:=StringReplace(Value,' Asc','',[rfReplaceAll,rfIgnoreCase]);
     end;
     FSortedFields:=Value;
  end;

  {Perform sorting}
  if Active then
     if (FSortedFields = '') then
        Self.InternalRefresh
     else
        InternalSort;
end;

{====================end of bangfauzan addition====================}

end.



