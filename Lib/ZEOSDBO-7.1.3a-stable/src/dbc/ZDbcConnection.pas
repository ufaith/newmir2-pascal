{*********************************************************}
{                                                         }
{                 Zeos Database Objects                   }
{         Abstract Database Connectivity Classes          }
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

unit ZDbcConnection;

interface

{$I ZDbc.inc}

uses
{$IFDEF FPC}
  {$IFDEF WIN32}
    Comobj,
  {$ENDIF}
{$ENDIF}
{$IFDEF WITH_LCONVENCODING}
  LConvEncoding,
{$ENDIF}
  Types, Classes, {$IFDEF MSEgui}mclasses,{$ENDIF} SysUtils,
  ZClasses, ZDbcIntfs, ZTokenizer, ZCompatibility, ZGenericSqlToken,
  ZGenericSqlAnalyser, ZPlainDriver, ZURL, ZCollections, ZVariant;

type

  {** Implements Abstract Database Driver. }
  {$WARNINGS OFF} //to supress the deprecated Warning of connect
  TZAbstractDriver = class(TInterfacedObject, IZDriver)
  private
    FTokenizer: IZTokenizer;
    FAnalyser: IZStatementAnalyser;
  protected
    FCachedPlainDrivers: IZHashMap;
    FSupportedProtocols: TStringDynArray;
    procedure AddSupportedProtocol(AProtocol: String);
    function AddPlainDriverToCache(PlainDriver: IZPlainDriver; const Protocol: string = ''; LibLocation: string = ''): String;
    function GetPlainDriverFromCache(const Protocol, LibLocation: string): IZPlainDriver;
    function GetPlainDriver(const Url: TZURL; const InitDriver: Boolean = True): IZPlainDriver; virtual;
    property Tokenizer: IZTokenizer read FTokenizer write FTokenizer;
    property Analyser: IZStatementAnalyser read FAnalyser write FAnalyser;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    function GetSupportedProtocols: TStringDynArray;
    function GetSupportedClientCodePages(const Url: TZURL;
      Const {$IFNDEF UNICODE}AutoEncode, {$ENDIF} SupportedsOnly: Boolean;
      CtrlsCPType: TZControlsCodePage = cCP_UTF16): TStringDynArray;
    function Connect(const Url: string; Info: TStrings = nil): IZConnection; overload; deprecated;
    function Connect(const Url: TZURL): IZConnection; overload; virtual;
    function AcceptsURL(const Url: string): Boolean; virtual;

    function GetPropertyInfo(const Url: string; Info: TStrings): TStrings; virtual;
    function GetMajorVersion: Integer; virtual;
    function GetMinorVersion: Integer; virtual;
    function GetSubVersion: Integer; virtual;
    function GetTokenizer: IZTokenizer; virtual;
    function GetStatementAnalyser: IZStatementAnalyser; virtual;
    function GetClientVersion(const Url: string): Integer; virtual;
  end;
  {$WARNINGS OFF}

  {** Implements Abstract Database Connection. }

  { TZAbstractConnection }

  TZAbstractConnection = class(TZCodePagedObject, IZConnection)
  private
    FDriver: IZDriver;
    FIZPlainDriver: IZPlainDriver;
    FAutoCommit: Boolean;
    FReadOnly: Boolean;
    FTransactIsolationLevel: TZTransactIsolationLevel;
    FClosed: Boolean;
    FURL: TZURL;
    FUseMetadata: Boolean;
    function GetHostName: string;
    procedure SetHostName(const Value: String);
    function GetPort: Integer;
    procedure SetConnPort(const Value: Integer);
    function GetDatabase: string;
    procedure SetDatabase(const Value: String);
    function GetUser: string;
    procedure SetUser(const Value: String);
    function GetPassword: string;
    procedure SetPassword(const Value: String);
    function GetInfo: TStrings;
  protected
    FUndefinedVarcharAsStringLength: Integer; //used for PostgreSQL and SQLite
    FClientCodePage: String;
    FMetadata: TContainedObject;
    {$IFDEF ZEOS_TEST_ONLY}
    FTestMode: Byte;
    {$ENDIF}
    procedure InternalCreate; virtual; abstract;
    function GetEncoding: TZCharEncoding;
    function GetConSettings: PZConSettings;
    procedure CheckCharEncoding(const CharSet: String; const DoArrange: Boolean = False);
    function GetClientCodePageInformations: PZCodePage; //EgonHugeist
    function GetAutoEncodeStrings: Boolean; //EgonHugeist
    procedure SetAutoEncodeStrings(const Value: Boolean);
    procedure OnPropertiesChange(Sender: TObject); virtual;
    procedure RaiseUnsupportedException;

    function CreateRegularStatement(Info: TStrings): IZStatement;
      virtual;
    function CreatePreparedStatement(const SQL: string; Info: TStrings):
      IZPreparedStatement; virtual;
    function CreateCallableStatement(const SQL: string; Info: TStrings):
      IZCallableStatement; virtual;

    property Driver: IZDriver read FDriver write FDriver;
    property PlainDriver: IZPlainDriver read FIZPlainDriver write FIZPlainDriver;
    property HostName: string read GetHostName write SetHostName;
    property Port: Integer read GetPort write SetConnPort;
    property Database: string read GetDatabase write SetDatabase;
    property User: string read GetUser write SetUser;
    property Password: string read GetPassword write SetPassword;
    property Info: TStrings read GetInfo;
    property AutoCommit: Boolean read FAutoCommit write FAutoCommit;
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
    property URL: TZURL read FURL;
    property TransactIsolationLevel: TZTransactIsolationLevel
      read FTransactIsolationLevel write FTransactIsolationLevel;
    property Closed: Boolean read FClosed write FClosed;
  public
    constructor Create(Driver: IZDriver; const Url: string;
      PlainDriver: IZPlainDriver; const HostName: string; Port: Integer;
      const Database: string; const User: string; const Password: string;
      Info: TStrings); overload; deprecated;
    constructor Create(const ZUrl: TZURL); overload;
    destructor Destroy; override;

    function CreateStatement: IZStatement;
    function PrepareStatement(const SQL: string): IZPreparedStatement;
    function PrepareCall(const SQL: string): IZCallableStatement;

    function CreateStatementWithParams(Info: TStrings): IZStatement;
    function PrepareStatementWithParams(const SQL: string; Info: TStrings):
      IZPreparedStatement;
    function PrepareCallWithParams(const SQL: string; Info: TStrings):
      IZCallableStatement;

    function CreateNotification(const Event: string): IZNotification; virtual;
    function CreateSequence(const Sequence: string; BlockSize: Integer):
      IZSequence; virtual;

    function NativeSQL(const SQL: string): string; virtual;

    procedure SetAutoCommit(AutoCommit: Boolean); virtual;
    function GetAutoCommit: Boolean; virtual;

    procedure Commit; virtual;
    procedure Rollback; virtual;

    //2Phase Commit Support initially for PostgresSQL (firmos) 21022006
    procedure PrepareTransaction(const transactionid: string);virtual;
    procedure CommitPrepared(const transactionid: string);virtual;
    procedure RollbackPrepared(const transactionid: string);virtual;

    //Ping Support initially for MySQL 27032006 (firmos)
    function PingServer: Integer; virtual;
    function EscapeString(Value: RawByteString): RawByteString; virtual;

    procedure Open; virtual;
    procedure Close; virtual;
    function IsClosed: Boolean; virtual;

    function GetDriver: IZDriver;
    function GetIZPlainDriver: IZPlainDriver;
    function GetMetadata: IZDatabaseMetadata;
    function GetParameters: TStrings;
    {ADDED by fduenas 15-06-2006}
    function GetClientVersion: Integer; virtual;
    function GetHostVersion: Integer; virtual;
    {END ADDED by fduenas 15-06-2006}
    function GetDescription: AnsiString;
    procedure SetReadOnly(ReadOnly: Boolean); virtual;
    function IsReadOnly: Boolean; virtual;

    procedure SetCatalog(const Catalog: string); virtual;
    function GetCatalog: string; virtual;

    procedure SetTransactionIsolation(Level: TZTransactIsolationLevel); virtual;
    function GetTransactionIsolation: TZTransactIsolationLevel; virtual;

    function GetWarnings: EZSQLWarning; virtual;
    procedure ClearWarnings; virtual;
    function GetBinaryEscapeString(const Value: RawByteString): String; overload; virtual;
    function GetBinaryEscapeString(const Value: TByteDynArray): String; overload; virtual;
    function GetEscapeString(const Value: ZWideString): ZWideString; overload; virtual;
    function GetEscapeString(const Value: RawByteString): RawByteString; overload; virtual;
    function UseMetadata: boolean;
    procedure SetUseMetadata(Value: Boolean);
    {$IFDEF ZEOS_TEST_ONLY}
    function GetTestMode : Byte;
    procedure SetTestMode(Mode: Byte);
    {$ENDIF}
end;

  {** Implements Abstract Database notification. }
  TZAbstractNotification = class(TInterfacedObject, IZNotification)
  private
    FEventName: string;
    FConnection: IZConnection;
  protected
    property EventName: string read FEventName write FEventName;
    property Connection: IZConnection read FConnection write FConnection;
  public
    constructor Create(Connection: IZConnection; EventName: string);
    function GetEvent: string;
    procedure Listen; virtual;
    procedure Unlisten; virtual;
    procedure DoNotify; virtual;
    function CheckEvents: string; virtual;

    function GetConnection: IZConnection; virtual;
  end;

  {** Implements Abstract Sequence generator. }
  TZAbstractSequence = class(TInterfacedObject, IZSequence)
  private
    FName: string;
    FBlockSize: Integer;
    FConnection: IZConnection;
  protected
    function GetName: string; virtual;
    function GetBlockSize: Integer; virtual;
    procedure SetName(const Value: string); virtual;
    procedure SetBlockSize(const Value: Integer); virtual;
    property Connection: IZConnection read FConnection write FConnection;
  public
    constructor Create(Connection: IZConnection; Name: string;
      BlockSize: Integer);

    function GetCurrentValue: Int64; virtual;
    function GetNextValue: Int64; virtual;

    function GetCurrentValueSQL: string; virtual; abstract;
    function GetNextValueSQL: string; virtual; abstract;

    function GetConnection: IZConnection; virtual;

    property Name: string read GetName write SetName;
    property BlockSize: Integer read GetBlockSize write SetBlockSize;
  end;

implementation

uses ZMessages, ZSysUtils, ZDbcMetadata, ZDbcUtils, ZEncoding
  {$IFDEF WITH_UNITANSISTRINGS},AnsiStrings{$ENDIF};

{ TZAbstractDriver }

{**
  Constructs this object with default properties.
}
constructor TZAbstractDriver.Create;
begin
  FCachedPlainDrivers := TZHashMap.Create;
end;

{**
  Destroys this object and cleanups the memory.
}
destructor TZAbstractDriver.Destroy;
begin
  FTokenizer := nil;
  FAnalyser := nil;
  FCachedPlainDrivers.Clear;
  FCachedPlainDrivers := nil;
  inherited Destroy;
end;

function TZAbstractDriver.GetSupportedProtocols: TStringDynArray;
begin
  Result := FSupportedProtocols;
end;

{**
  EgonHugeist:
  Get names of the supported CharacterSets.
  For example: ASCII, UTF8...
}
function TZAbstractDriver.GetSupportedClientCodePages(const Url: TZURL;
  Const {$IFNDEF UNICODE}AutoEncode,{$ENDIF} SupportedsOnly: Boolean;
  CtrlsCPType: TZControlsCodePage = cCP_UTF16): TStringDynArray;
var
  Plain: IZPlainDriver;
begin
  Plain := GetPlainDriverFromCache(Url.Protocol, '');
  if Assigned(Plain) then
  Result := Plain.GetSupportedClientCodePages({$IFNDEF UNICODE}AutoEncode,{$ENDIF}
    not SupportedsOnly, CtrlsCPType);
end;

{**
  Attempts to make a database connection to the given URL.
  The driver should return "null" if it realizes it is the wrong kind
  of driver to connect to the given URL.  This will be common, as when
  the JDBC driver manager is asked to connect to a given URL it passes
  the URL to each loaded driver in turn.

  <P>The driver should raise a SQLException if it is the right
  driver to connect to the given URL, but has trouble connecting to
  the database.

  <P>The java.util.Properties argument can be used to passed arbitrary
  string tag/value pairs as connection arguments.
  Normally at least "user" and "password" properties should be
  included in the Properties.

  @param url the URL of the database to which to connect
  @param info a list of arbitrary string tag/value pairs as
    connection arguments. Normally at least a "user" and
    "password" property should be included.
  @return a <code>Connection</code> object that represents a
    connection to the URL
}
{$WARNINGS OFF}
function TZAbstractDriver.Connect(const Url: string; Info: TStrings): IZConnection;
var
  TempURL:  TZURL;
begin
  TempURL := TZURL.Create(Url, Info);
  try
    Result := Connect(TempURL);
  finally
    TempUrl.Free;
  end;
end;

function TZAbstractDriver.Connect(const Url: TZURL): IZConnection;
begin
  Result := nil;
end;
{$WARNINGS ON}

{**
  Returns true if the driver thinks that it can open a connection
  to the given URL.  Typically drivers will return true if they
  understand the subprotocol specified in the URL and false if
  they don't.
  @param url the URL of the database
  @return true if this driver can connect to the given URL
}
function TZAbstractDriver.AcceptsURL(const Url: string): Boolean;
var
  I: Integer;
  Protocols: TStringDynArray;
begin
  Result := False;
  Protocols := GetSupportedProtocols;
  for I := Low(Protocols) to High(Protocols) do
  begin
    Result := StartsWith(LowerCase(Url), Format('zdbc:%s:', [LowerCase(Protocols[I])]));
    if Result then
      Break;
  end;
end;

procedure TZAbstractDriver.AddSupportedProtocol(AProtocol: String);
begin
  SetLength(FSupportedProtocols, Length(FSupportedProtocols)+1);
  FSupportedProtocols[High(FSupportedProtocols)] := AProtocol;
end;

function TZAbstractDriver.AddPlainDriverToCache(PlainDriver: IZPlainDriver;
  const Protocol: string = ''; LibLocation: string = ''): String;
var
  TempKey: IZAnyValue;
begin
  if Protocol = '' then
  begin
    Result := PlainDriver.GetProtocol;
    TempKey := TZAnyValue.CreateWithString(PlainDriver.GetProtocol)
  end
  else
  begin
    Result := Protocol;
    TempKey := TZAnyValue.CreateWithString(Protocol+LibLocation);
  end;
  FCachedPlainDrivers.Put(TempKey, PlainDriver);
end;

function TZAbstractDriver.GetPlainDriverFromCache(const Protocol, LibLocation: string): IZPlainDriver;
var
  TempKey: IZAnyValue;
  TempPlain: IZPlainDriver;
begin
  TempKey := TZAnyValue.CreateWithString(Protocol+LibLocation);
  Result := FCachedPlainDrivers.Get(TempKey) as IZPlainDriver;
  if Result = nil then
  begin
    TempKey := nil;
    TempKey := TZAnyValue.CreateWithString(Protocol);
    TempPlain := FCachedPlainDrivers.Get(TempKey) as IZPlainDriver;
    if Assigned(TempPlain) then
      Result := TempPlain.Clone;
  end;
end;

{**
  Gets plain driver for selected protocol.
  @param Url a database connection URL.
  @return a selected plaindriver.
}
function TZAbstractDriver.GetPlainDriver(const Url: TZURL;
  const InitDriver: Boolean): IZPlainDriver;
begin
  Result := GetPlainDriverFromCache(Url.Protocol, Url.LibLocation);
  if Assigned(Result) and InitDriver then
    Result.Initialize(Url.LibLocation);
end;

{**
  Gets information about the possible properties for this driver.
  <p>The getPropertyInfo method is intended to allow a generic GUI tool to
  discover what properties it should prompt a human for in order to get
  enough information to connect to a database.  Note that depending on
  the values the human has supplied so far, additional values may become
  necessary, so it may be necessary to iterate though several calls
  to getPropertyInfo.

  @param url the URL of the database to which to connect
  @param info a proposed list of tag/value pairs that will be sent on
    connect open
  @return an array of DriverPropertyInfo objects describing possible
    properties.  This array may be an empty array if no properties
    are required.
}
function TZAbstractDriver.GetPropertyInfo(const Url: string; Info: TStrings): TStrings;
begin
  Result := nil;
end;

{**
  Gets the driver's major version number. Initially this should be 1.
  @return this driver's major version number
}
function TZAbstractDriver.GetMajorVersion: Integer;
begin
  Result := 1;
end;

{**
  Gets the driver's minor version number. Initially this should be 0.
  @return this driver's minor version number
}
function TZAbstractDriver.GetMinorVersion: Integer;
begin
  Result := 0;
end;

{**
  Gets the driver's sub version (revision) number. Initially this should be 0.
  @return this driver's sub version number
}
function TZAbstractDriver.GetSubVersion: Integer;
begin
 Result := 0;
end;
{**
  Creates a generic statement analyser object.
  @returns a generic statement analyser object.
}
function TZAbstractDriver.GetStatementAnalyser: IZStatementAnalyser;
begin
  if Analyser = nil then
    Analyser := TZGenericStatementAnalyser.Create;
  Result := Analyser;
end;

{**
  Creates a generic tokenizer object.
  @returns a created generic tokenizer object.
}
function TZAbstractDriver.GetTokenizer: IZTokenizer;
begin
  if Tokenizer = nil then
    Tokenizer := TZGenericSQLTokenizer.Create;
  Result := Tokenizer;
end;

{**
  Returns the version of the plain driver library that will be used to open a connection
  to the given URL.
  @param url the URL of the database
  @return the version number of the plain driver library for the give URL
}
function TZAbstractDriver.GetClientVersion(const Url: string): Integer;
begin
  Result := 0;
end;

{ TZAbstractConnection }

function TZAbstractConnection.GetHostName: string;
begin
  Result := FURL.HostName;
end;

procedure TZAbstractConnection.SetHostName(const Value: String);
begin
  FURL.HostName := Value;
end;

function TZAbstractConnection.GetPort: Integer;
begin
  Result := FURL.Port;
end;

procedure TZAbstractConnection.SetConnPort(const Value: Integer);
begin
  FURL.Port := Value;
end;

function TZAbstractConnection.GetDatabase: string;
begin
  Result := FURL.Database;
end;

procedure TZAbstractConnection.SetDatabase(const Value: String);
begin
  FURL.Database := Value;
end;

function TZAbstractConnection.GetUser: string;
begin
  Result := FURL.UserName;
end;

procedure TZAbstractConnection.SetUser(const Value: String);
begin
  FURL.UserName := Value;
end;

function TZAbstractConnection.GetPassword: string;
begin
  Result := FURL.Password;
end;

procedure TZAbstractConnection.SetPassword(const Value: String);
begin
  FURL.Password := Value;
end;

function TZAbstractConnection.GetInfo: TStrings;
begin
  Result := FURL.Properties;
end;

function TZAbstractConnection.GetEncoding: TZCharEncoding;
begin
  Result := ConSettings.ClientCodePage^.Encoding;
end;

function TZAbstractConnection.GetConSettings: PZConSettings;
begin
  Result := ConSettings;
end;

{**
  EgonHugeist: Check if the given Charset for Compiler/Database-Support!!
    Not supported means if there is a pissible String-DataLoss.
    So it raises an Exception if case of settings. This handling
    is an improofment to inform Zeos-Users about the troubles the given
    CharacterSet may have.
  @param CharSet the CharacterSet which has to be proofed
  @param DoArrange represents a switch to check and set a aternative ZAlias as
    default. This means it ignores the choosen Client-CharacterSet and sets a
    "more" Zeos-Compatible Client-CharacterSet if known.
}
procedure TZAbstractConnection.CheckCharEncoding(const CharSet: String;
  const DoArrange: Boolean = False);
begin
  ConSettings.ClientCodePage := GetIZPlainDriver.ValidateCharEncoding(CharSet, DoArrange);
  FClientCodePage := ConSettings.ClientCodePage^.Name; //resets the developer choosen ClientCodePage
  {$IFDEF WITH_LCONVENCODING}
  SetConvertFunctions(ConSettings.CTRL_CP, ConSettings.ClientCodePage.CP,
    ConSettings.PlainConvertFunc, ConSettings.DbcConvertFunc);
  {$ENDIF}
  ZEncoding.SetConvertFunctions(ConSettings);
end;


{**
  EgonHugeist: this is a compatibility-Option for exiting Applictions.
    Zeos is now able to preprepare direct insered SQL-Statements.
    Means do the UTF8-preparation if the CharacterSet was choosen.
    So we do not need to do the SQLString + UTF8Encode(Edit1.Test) for example.
  @result True if coPreprepareSQL was choosen in the TZAbstractConnection
}
function TZAbstractConnection.GetAutoEncodeStrings: Boolean;
begin
  {$IFDEF UNICODE}
  Result := True;
  {$ELSE}
  Result := ConSettings.AutoEncode;
  {$ENDIF}
end;

procedure TZAbstractConnection.SetAutoEncodeStrings(const Value: Boolean);
begin
  {$IFNDEF UNICODE}
  ConSettings.AutoEncode := Value;
  {$ENDIF}
end;

{**
  EgonHugeist and MDeams: The old deprecadet constructor which was used
  from the descendant classes. We left him here for compatibility reasons to
  exesting projects which using the DbcConnections directly

  Constructs this object and assignes the main properties.
  @param Driver the parent ZDBC driver.
  @param Url a connection URL.
  @param PlainDriver a versioned ZPlainDriver object interface.
  @param HostName a name of the host.
  @param Port a port number (0 for default port).
  @param Database a name pof the database.
  @param User a user name.
  @param Password a user password.
  @param Info a string list with extra connection parameters.
}
{$WARNINGS OFF} //suppress the deprecatad warning of calling create from internal
constructor TZAbstractConnection.Create(Driver: IZDriver; const Url: string;
  PlainDriver: IZPlainDriver;
  const HostName: string; Port: Integer; const Database: string;
  const User: string; const Password: string; Info: TStrings);
var
  TempURL: TZURL;
begin
  TempURL := TZURL.Create(Url, HostName, Port, Database, User, Password, Info);
  Create(TempURL);
  TempURL.Free;
end;
{$WARNINGS OFF}

{**
  Constructs this object and assignes the main properties.
  @param Url a connection ZURL-class which exports all connection parameters.
}
constructor TZAbstractConnection.Create(const ZUrl: TZURL);
begin
  FClosed := True;
  if not assigned(ZUrl) then
    raise Exception.Create('ZUrl is not assigned!')
  else
    FURL := TZURL.Create();
  FDriver := DriverManager.GetDriver(ZURL.URL);
  FIZPlainDriver := FDriver.GetPlainDriver(ZUrl);

  FURL.OnPropertiesChange := OnPropertiesChange;
  FURL.URL := ZUrl.URL;

  FClientCodePage := Info.Values['codepage'];
  {CheckCharEncoding}
  ConSettings := New(PZConSettings);

  SetConSettingsFromInfo(Info);
  CheckCharEncoding(FClientCodePage, True);

  FAutoCommit := True;
  FReadOnly := True;
  FTransactIsolationLevel := tiNone;
  FUseMetadata := True;
  InternalCreate;
  {$IFDEF ZEOS_TEST_ONLY}
  FTestMode := 0;
  {$ENDIF}
end;

{**
  Destroys this object and cleanups the memory.
}
destructor TZAbstractConnection.Destroy;
begin
  if not FClosed then
    Close;
  FreeAndNil(FMetadata);
  FURL.Free;
  FIZPlainDriver := nil;
  FDriver := nil;
  if Assigned(ConSettings) then
    Dispose(ConSettings);
  inherited Destroy;
end;

{**
  Opens a connection to database server with specified parameters.
}
procedure TZAbstractConnection.Open;
begin
  FClosed := False;
end;

{**
  Raises unsupported operation exception.
}
procedure TZAbstractConnection.RaiseUnsupportedException;
begin
  raise EZSQLException.Create(SUnsupportedOperation);
end;

{**
  Creates a <code>Statement</code> object for sending
  SQL statements to the database.
  SQL statements without parameters are normally
  executed using Statement objects. If the same SQL statement
  is executed many times, it is more efficient to use a
  <code>PreparedStatement</code> object.
  <P>
  Result sets created using the returned <code>Statement</code>
  object will by default have forward-only type and read-only concurrency.

  @return a new Statement object
}
function TZAbstractConnection.CreateStatement: IZStatement;
var
  Info: TStrings;
begin
  If StrToBoolEx(GetInfo.Values['preferprepared']) then
    begin
     Info := TSTringList.Create;
     Info.Append('preferprepared=TRUE');
    end
  Else
    Info := nil;

  Result := CreateRegularStatement(Info);

  If Info <> nil then
    Info.Free;
end;

{**
  Creates a <code>Statement</code> object for sending
  SQL statements to the database.
  SQL statements without parameters are normally
  executed using Statement objects. If the same SQL statement
  is executed many times, it is more efficient to use a
  <code>PreparedStatement</code> object.
  <P>
  Result sets created using the returned <code>Statement</code>
  object will by default have forward-only type and read-only concurrency.

  @param Info a statement parameters.
  @return a new Statement object
}
function TZAbstractConnection.CreateStatementWithParams(Info: TStrings):
  IZStatement;
begin
  If StrToBoolEx(GetInfo.Values['preferprepared']) then
    Info.Append('preferprepared=TRUE');
  Result := CreateRegularStatement(Info);
end;

{**
  Creates a regular statement object.
  @param SQL a SQL query string.
  @param Info a statement parameters.
  @returns a created statement.
}
function TZAbstractConnection.CreateRegularStatement(
  Info: TStrings): IZStatement;
begin
  Result := nil;
  RaiseUnsupportedException;
end;

{**
  Creates a <code>PreparedStatement</code> object for sending
  parameterized SQL statements to the database.

  A SQL statement with or without IN parameters can be
  pre-compiled and stored in a PreparedStatement object. This
  object can then be used to efficiently execute this statement
  multiple times.

  <P><B>Note:</B> This method is optimized for handling
  parametric SQL statements that benefit from precompilation. If
  the driver supports precompilation,
  the method <code>prepareStatement</code> will send
  the statement to the database for precompilation. Some drivers
  may not support precompilation. In this case, the statement may
  not be sent to the database until the <code>PreparedStatement</code> is
  executed.  This has no direct effect on users; however, it does
  affect which method throws certain SQLExceptions.

  Result sets created using the returned PreparedStatement will have
  forward-only type and read-only concurrency, by default.

  @param sql a SQL statement that may contain one or more '?' IN
    parameter placeholders
  @return a new PreparedStatement object containing the
    pre-compiled statement
}
function TZAbstractConnection.PrepareStatement(const SQL: string): IZPreparedStatement;
var
  Info: TStrings;
begin
  If StrToBoolEx(GetInfo.Values['preferprepared']) then
    begin
     Info := TSTringList.Create;
     Info.Append('preferprepared=TRUE');
    end
  Else
    Info := nil;

  Result := CreatePreparedStatement(SQL, Info);

  If Info <> nil then
    Info.Free;
end;

{**
  Creates a <code>PreparedStatement</code> object for sending
  parameterized SQL statements to the database.

  @param SQL a SQL statement that may contain one or more '?' IN
    parameter placeholders
  @param Info a statement parameters.
  @return a new PreparedStatement object containing the
    pre-compiled statement
}
function TZAbstractConnection.PrepareStatementWithParams(const SQL: string;
  Info: TStrings): IZPreparedStatement;
begin
  If StrToBoolEx(GetInfo.Values['preferprepared']) then
    Info.Append('preferprepared=TRUE');

  Result := CreatePreparedStatement(SQL, Info);
end;

procedure TZAbstractConnection.PrepareTransaction(const transactionid: string);
begin
  RaiseUnsupportedException;
end;

{**
  Creates a prepared statement object.
  @param SQL a SQL query string.
  @param Info a statement parameters.
  @returns a created statement.
}
function TZAbstractConnection.CreatePreparedStatement(const SQL: string;
  Info: TStrings): IZPreparedStatement;
begin
  Result := nil;
  RaiseUnsupportedException;
end;

{**
  Creates a <code>CallableStatement</code> object for calling
  database stored procedures.
  The <code>CallableStatement</code> object provides
  methods for setting up its IN and OUT parameters, and
  methods for executing the call to a stored procedure.

  <P><B>Note:</B> This method is optimized for handling stored
  procedure call statements. Some drivers may send the call
  statement to the database when the method <code>prepareCall</code>
  is done; others
  may wait until the <code>CallableStatement</code> object
  is executed. This has no
  direct effect on users; however, it does affect which method
  throws certain SQLExceptions.

  Result sets created using the returned CallableStatement will have
  forward-only type and read-only concurrency, by default.

  @param sql a SQL statement that may contain one or more '?'
    parameter placeholders. Typically this  statement is a JDBC
    function call escape string.
  @return a new CallableStatement object containing the
    pre-compiled SQL statement
}

function TZAbstractConnection.PrepareCall(
  const SQL: string): IZCallableStatement;
var
  Info: TStrings;
begin
  If StrToBoolEx(GetInfo.Values['preferprepared']) then
    begin
     Info := TSTringList.Create;
     Info.Append('preferprepared=TRUE');
    end
  Else
    Info := nil;

  Result := CreateCallableStatement(SQL, Info);

  If Info <> nil then
    Info.Free;
end;

{**
  Creates a <code>CallableStatement</code> object for calling
  database stored procedures.
  The <code>CallableStatement</code> object provides
  methods for setting up its IN and OUT parameters, and
  methods for executing the call to a stored procedure.

  @param SQL a SQL statement that may contain one or more '?'
    parameter placeholders. Typically this  statement is a JDBC
    function call escape string.
  @param Info a statement parameters.
  @return a new CallableStatement object containing the
    pre-compiled SQL statement
}
function TZAbstractConnection.PrepareCallWithParams(const SQL: string;
  Info: TStrings): IZCallableStatement;
begin
  If StrToBoolEx(GetInfo.Values['preferprepared']) then
    Info.Append('preferprepared=TRUE');
  Result := CreateCallableStatement(SQL, Info);
end;

{**
  Creates a callable statement object.
  @param SQL a SQL query string.
  @param Info a statement parameters.
  @returns a created statement.
}
function TZAbstractConnection.CreateCallableStatement(const SQL: string;
  Info: TStrings): IZCallableStatement;
begin
  Result := nil;
  RaiseUnsupportedException;
end;

{**
  Creates an object to send/recieve notifications from SQL server.
  @param Event an event name.
  @returns a created notification object.
}
function TZAbstractConnection.CreateNotification(const Event: string): IZNotification;
begin
  Result := nil;
  RaiseUnsupportedException;
end;

{**
  Creates a sequence generator object.
  @param Sequence a name of the sequence generator.
  @param BlockSize a number of unique keys requested in one trip to SQL server.
  @returns a created sequence object.
}
function TZAbstractConnection.CreateSequence(const Sequence: string;
  BlockSize: Integer): IZSequence;
begin
  Result := nil;
  RaiseUnsupportedException;
end;

{**
  Converts the given SQL statement into the system's native SQL grammar.
  A driver may convert the JDBC sql grammar into its system's
  native SQL grammar prior to sending it; this method returns the
  native form of the statement that the driver would have sent.

  @param sql a SQL statement that may contain one or more '?'
    parameter placeholders
  @return the native form of this statement
}
function TZAbstractConnection.NativeSQL(const SQL: string): string;
begin
  Result := SQL;
end;

{**
  Sets this connection's auto-commit mode.
  If a connection is in auto-commit mode, then all its SQL
  statements will be executed and committed as individual
  transactions.  Otherwise, its SQL statements are grouped into
  transactions that are terminated by a call to either
  the method <code>commit</code> or the method <code>rollback</code>.
  By default, new connections are in auto-commit mode.

  The commit occurs when the statement completes or the next
  execute occurs, whichever comes first. In the case of
  statements returning a ResultSet, the statement completes when
  the last row of the ResultSet has been retrieved or the
  ResultSet has been closed. In advanced cases, a single
  statement may return multiple results as well as output
  parameter values. In these cases the commit occurs when all results and
  output parameter values have been retrieved.

  @param autoCommit true enables auto-commit; false disables auto-commit.
}
procedure TZAbstractConnection.SetAutoCommit(AutoCommit: Boolean);
begin
  FAutoCommit := AutoCommit;
end;

{**
  Gets the current auto-commit state.
  @return the current state of auto-commit mode
  @see #setAutoCommit
}
function TZAbstractConnection.GetAutoCommit: Boolean;
begin
  Result := FAutoCommit;
end;

{**
  Makes all changes made since the previous
  commit/rollback permanent and releases any database locks
  currently held by the Connection. This method should be
  used only when auto-commit mode has been disabled.
  @see #setAutoCommit
}
procedure TZAbstractConnection.Commit;
begin
  RaiseUnsupportedException;
end;

procedure TZAbstractConnection.CommitPrepared(const transactionid: string);
begin
  RaiseUnsupportedException;
end;

{**
  Drops all changes made since the previous
  commit/rollback and releases any database locks currently held
  by this Connection. This method should be used only when auto-
  commit has been disabled.
  @see #setAutoCommit
}
procedure TZAbstractConnection.Rollback;
begin
  RaiseUnsupportedException;
end;

procedure TZAbstractConnection.RollbackPrepared(const transactionid: string);
begin
  RaiseUnsupportedException;
end;

{**
  Ping Current Connection's server, if client was disconnected,
  the connection is resumed.
  @return 0 if succesfull or error code if any error occurs
}
function TZAbstractConnection.PingServer: Integer;
begin
  Result := 1;
  RaiseUnsupportedException;
end;

{**
  Escape a string so it's acceptable for the Connection's server.
  @param value string that should be escaped
  @return Escaped string
}
function TZAbstractConnection.EscapeString(Value : RawByteString) : RawByteString;
begin
  Result := AnsiString(EncodeCString(String(Value)));
end;

{**
  Releases a Connection's database and JDBC resources
  immediately instead of waiting for
  them to be automatically released.

  <P><B>Note:</B> A Connection is automatically closed when it is
  garbage collected. Certain fatal errors also result in a closed
  Connection.
}

procedure TZAbstractConnection.Close;
begin
  FClosed := True;
end;

{**
  Tests to see if a Connection is closed.
  @return true if the connection is closed; false if it's still open
}
function TZAbstractConnection.IsClosed: Boolean;
begin
  Result := FClosed;
end;

{**
  Gets the parent ZDBC driver.
  @returns the parent ZDBC driver interface.
}
function TZAbstractConnection.GetDriver: IZDriver;
begin
  Result := FDriver;
end;

{**
  Gets the plain driver.
  @returns the plain driver interface.
}
function TZAbstractConnection.GetIZPlainDriver: IZPlainDriver;
begin
  result := FIZPlainDriver;
end;

{**
  Gets the metadata regarding this connection's database.
  A Connection's database is able to provide information
  describing its tables, its supported SQL grammar, its stored
  procedures, the capabilities of this connection, and so on. This
  information is made available through a DatabaseMetaData
  object.

  @return a DatabaseMetaData object for this Connection
}
function TZAbstractConnection.GetMetadata: IZDatabaseMetadata;
begin
  Result := FMetadata as IZDatabaseMetadata;
end;

{**
  Gets a connection parameters.
  @returns a list with connection parameters.
}
function TZAbstractConnection.GetParameters: TStrings;
begin
  Result := Info;
end;

{**
  Gets the client's full version number. Initially this should be 0.
  The format of the version resturned must be XYYYZZZ where
   X   = Major version
   YYY = Minor version
   ZZZ = Sub version
  @return this clients's full version number
}
function TZAbstractConnection.GetClientVersion: Integer;
begin
 Result := 0;
end;

{**
  Gets the host's full version number. Initially this should be 0.
  The format of the version returned must be XYYYZZZ where
   X   = Major version
   YYY = Minor version
   ZZZ = Sub version
  @return this server's full version number
}
function TZAbstractConnection.GetHostVersion: Integer;
begin
 Result := 0;
end;

function TZAbstractConnection.GetDescription: AnsiString;
begin
  PlainDriver.GetDescription;
end;

{END ADDED by fduenas 15-06-2006}

{**
  Puts this connection in read-only mode as a hint to enable
  database optimizations.

  <P><B>Note:</B> This method cannot be called while in the
  middle of a transaction.

  @param readOnly true enables read-only mode; false disables
    read-only mode.
}
procedure TZAbstractConnection.SetReadOnly(ReadOnly: Boolean);
begin
  FReadOnly := ReadOnly;
end;

{**
  Tests to see if the connection is in read-only mode.
  @return true if connection is read-only and false otherwise
}
function TZAbstractConnection.IsReadOnly: Boolean;
begin
  Result := FReadOnly;
end;

{**
  Sets a catalog name in order to select
  a subspace of this Connection's database in which to work.
  If the driver does not support catalogs, it will
  silently ignore this request.
}
procedure TZAbstractConnection.SetCatalog(const Catalog: string);
begin
end;

{**
  Returns the Connection's current catalog name.
  @return the current catalog name or null
}
function TZAbstractConnection.GetCatalog: string;
begin
  Result := '';
end;

{**
  Attempts to change the transaction isolation level to the one given.
  The constants defined in the interface <code>Connection</code>
  are the possible transaction isolation levels.

  <P><B>Note:</B> This method cannot be called while
  in the middle of a transaction.

  @param level one of the TRANSACTION_* isolation values with the
    exception of TRANSACTION_NONE; some databases may not support other values
  @see DatabaseMetaData#supportsTransactionIsolationLevel
}
procedure TZAbstractConnection.SetTransactionIsolation(
  Level: TZTransactIsolationLevel);
begin
  FTransactIsolationLevel := Level;
end;

{**
  Gets this Connection's current transaction isolation level.
  @return the current TRANSACTION_* mode value
}
function TZAbstractConnection.GetTransactionIsolation: TZTransactIsolationLevel;
begin
  Result := FTransactIsolationLevel;
end;

{**
  Returns the first warning reported by calls on this Connection.
  <P><B>Note:</B> Subsequent warnings will be chained to this
  SQLWarning.
  @return the first SQLWarning or null
}
function TZAbstractConnection.GetWarnings: EZSQLWarning;
begin
  Result := nil;
end;

{**
  Clears all warnings reported for this <code>Connection</code> object.
  After a call to this method, the method <code>getWarnings</code>
    returns null until a new warning is reported for this Connection.
}
procedure TZAbstractConnection.ClearWarnings;
begin
end;

function TZAbstractConnection.UseMetadata: boolean;
begin
  result := FUseMetadata;
end;

procedure TZAbstractConnection.SetUseMetadata(Value: Boolean);
begin
  FUseMetadata := Value;
end;

{$IFDEF ZEOS_TEST_ONLY}
function TZAbstractConnection.GetTestMode: Byte;
begin
  Result := FTestMode;
end;

procedure TZAbstractConnection.SetTestMode(Mode: Byte);
begin
  FTestMode := Mode;
end;
{$ENDIF}

{**
  EgonHugeist:
  Returns the BinaryString in a Tokenizer-detectable kind
  If the Tokenizer don't need to predetect it Result = BinaryString
  @param Value represents the Binary-String
  @param EscapeMarkSequence represents a Tokenizer detectable EscapeSequence (Len >= 3)
  @result the detectable Binary String
}
function TZAbstractConnection.GetBinaryEscapeString(const Value: RawByteString): String;
begin
  if GetAutoEncodeStrings then //Set detect-sequence only if Prepreparing should be done else it's not server-understandable.
    Result := Self.GetDriver.GetTokenizer.AnsiGetEscapeString(GetSQLHexString(PAnsiChar(Value), Length(Value)))
  else
    Result := GetSQLHexString(PAnsiChar(Value), Length(Value));
end;

function TZAbstractConnection.GetBinaryEscapeString(const Value: TByteDynArray): String;
begin
  if GetAutoEncodeStrings then //Set detect-sequence only if Prepreparing should be done else it's not server-understandable.
    Result := Self.GetDriver.GetTokenizer.AnsiGetEscapeString(GetSQLHexString(PAnsiChar(Value), Length(Value)))
  else
    Result := GetSQLHexString(PAnsiChar(Value), Length(Value));
end;

function TZAbstractConnection.GetEscapeString(const Value: ZWideString): ZWideString;
begin
  if GetAutoEncodeStrings then
    if StartsWith(Value, '''') and EndsWith(Value, '''') then
      Result := GetDriver.GetTokenizer.GetEscapeString(Value)
    else
      {$IFDEF UNICODE}
      Result := AnsiQuotedStr(Value, #39)
      {$ELSE}
      Result := ZDbcUnicodeString(GetDriver.GetTokenizer.GetEscapeString(AnsiQuotedStr(ZPlainString(Value), #39)))
      {$ENDIF}
  else
    if StartsWith(Value, '''') and EndsWith(Value, '''') then
      Result := Value
    else
      {$IFDEF UNICODE}
      Result := AnsiQuotedStr(Value, #39);
      {$ELSE}
      Result := ZDbcUnicodeString(AnsiQuotedStr(ZPlainString(Value), #39));
      {$ENDIF}
end;

function TZAbstractConnection.GetEscapeString(const Value: RawByteString): RawByteString;
begin
  if GetAutoEncodeStrings then
    if StartsWith(Value, '''') and EndsWith(Value, '''') then
      Result := {$IFNDEF UNICODE}GetDriver.GetTokenizer.GetEscapeString{$ENDIF}(Value)
    else
      {$IFDEF WITH_UNITANSISTRINGS}
      AnsiStrings.AnsiQuotedStr(Value, #39)
      {$ELSE}
      Result := GetDriver.GetTokenizer.GetEscapeString(AnsiQuotedStr(ZDbcString(Value), #39))
      {$ENDIF}
  else
    if StartsWith(Value, '''') and EndsWith(Value, '''') then
      Result := Value
    else
      Result := {$IFDEF WITH_UNITANSISTRINGS}AnsiStrings.{$ENDIF}AnsiQuotedStr(Value, #39);
end;

{**
  Result 100% Compiler-Compatible
  And sets it Result to ClientCodePage by calling the
    PlainDriver.GetClientCodePageInformations function

  @param ClientCharacterSet the CharacterSet which has to be checked
  @result PZCodePage see ZCompatible.pas
}
function TZAbstractConnection.GetClientCodePageInformations: PZCodePage; //EgonHugeist
begin
  Result := ConSettings.ClientCodePage
end;

procedure TZAbstractConnection.OnPropertiesChange(Sender: TObject);
begin
  // do nothing in base class
end;

{ TZAbstractNotification }

{**
  Creates this object and assignes the main properties.
  @param Connection a database connection object.
  @param EventName a name of the SQL event.
}
constructor TZAbstractNotification.Create(Connection: IZConnection;
  EventName: string);
begin
  FConnection := Connection;
  FEventName := EventName;
end;

{**
  Gets an event name.
  @return an event name for this notification.
}
function TZAbstractNotification.GetEvent: string;
begin
  Result := FEventName;
end;

{**
  Sets a listener to the specified event.
}
procedure TZAbstractNotification.Listen;
begin
end;

{**
  Removes a listener to the specified event.
}
procedure TZAbstractNotification.Unlisten;
begin
end;

{**
  Checks for any pending events.
  @return a string with incoming events??
}
function TZAbstractNotification.CheckEvents: string;
begin
  Result := '';
end;

{**
  Sends a notification string.
}
procedure TZAbstractNotification.DoNotify;
begin
end;

{**
  Returns the <code>Connection</code> object
  that produced this <code>Statement</code> object.
  @return the connection that produced this statement
}
function TZAbstractNotification.GetConnection: IZConnection;
begin
  Result := FConnection;
end;

{ TZAbstractSequence }

{**
  Creates this sequence object.
  @param Connection an SQL connection interface.
  @param Name a name of the sequence generator.
  @param BlockSize a number of unique keys requested in one trip to server.
}
constructor TZAbstractSequence.Create(Connection: IZConnection;
  Name: string; BlockSize: Integer);
begin
  FConnection := Connection;
  FName := Name;
  FBlockSize := BlockSize;
end;

{**
  Returns the <code>Connection</code> object
  that produced this <code>Statement</code> object.
  @return the connection that produced this statement
}
function TZAbstractSequence.GetConnection: IZConnection;
begin
  Result := FConnection;
end;

{**
  Returns a name of the sequence generator.
  @return a name of this sequence generator.
}
function TZAbstractSequence.GetName: string;
begin
  Result := FName;
end;

{**
  Returns the assigned block size for this sequence.
  @return the assigned block size.
}
function TZAbstractSequence.GetBlockSize: Integer;
begin
  Result := FBlockSize;
end;

{**
  Gets the current unique key generated by this sequence.
  @param the last generated unique key.
}
function TZAbstractSequence.GetCurrentValue: Int64;
begin
  Result := 0;
end;

{
function TZAbstractSequence.GetCurrentValueSQL: String;
begin
 result:='IMPLEMENT';
end;
}

{**
  Gets the next unique key generated by this sequence.
  @param the next generated unique key.
}
function TZAbstractSequence.GetNextValue: Int64;
begin
  Result := 0;
end;

{
function TZAbstractSequence.GetNextValueSQL: String;
begin
 result:='IMPLEMENT';
end;
}

{**
  Sets the block size for this sequence.
  @param Value the block size.
}
procedure TZAbstractSequence.SetBlockSize(const Value: Integer);
begin
  FBlockSize := Value;
end;

{**
  Sets a name of the sequence generator.
  @param Value a name of this sequence generator.
}
procedure TZAbstractSequence.SetName(const Value: string);
begin
  FName := Value;
end;

end.
