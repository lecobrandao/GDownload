unit uThreadDownload;

interface

uses
  System.Classes, System.SysUtils, IdHTTP, IdSSLOpenSSL, IdComponent, Data.FMTBcd, Data.DB,
  Data.SqlExpr, Data.DbxSqlite;

type
  ThreadDownload = class(TThread)
  SQLConnection1: TSQLConnection;
  SQLQuery1: TSQLQuery;
  private
    { Private declarations }
  protected
    procedure Execute; override;
    procedure IdHTTPWorkBegin(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64);
    procedure IdHTTPWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
    procedure IdHTTPWorkEnd(ASender: TObject; AWorkMode: TWorkMode);
  public
    gURL, gPathApp: String;
    gProgressDownloadPosition, gProgressDownloadMax: Integer;
    gStop: Boolean;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ ThreadDownload }

constructor ThreadDownload.Create;
begin
  inherited Create(True);
  FreeOnTerminate := True;
  gStop := False;
  SQLConnection1 := TSQLConnection.Create(nil);
  SQLConnection1.DriverName := 'Sqlite';
  SQLQuery1 := TSQLQuery.Create(nil);
  SQLQuery1.SQLConnection := SQLConnection1;
  SQLConnection1.Params.Add('Database='+ gPathApp + 'dados\dados');
  SQLConnection1.Connected := True;
end;

destructor ThreadDownload.Destroy;
begin
  inherited;
  SQLQuery1.Free;
  SQLConnection1.Free;
end;

procedure ThreadDownload.Execute;
var iCodigo: Integer;
    i: Integer;
    FileName: String;
    SSLHandler: TIdSSLIOHandlerSocketOpenSSL;
    IdHTTP1: TIdHTTP;
    Stream: TMemoryStream;
begin
  try
    SQLQuery1.Close;
    SQLQuery1.SQL.Text := ' select coalesce(max(codigo),0) as cod from logdownload ';
    SQLQuery1.Open;
    iCodigo := SQLQuery1.Fields[0].AsInteger;

    SQLQuery1.Close;
    SQLQuery1.SQL.Text := ' insert into logdownload (codigo, url, datainicio) ' +
                          ' values (' + IntToStr(iCodigo+1) +
                                  ',' + QuotedStr(gURL) +
                                  ', current_timestamp) ';
    SQLQuery1.ExecSQL;
  except
    on E:Exception do
      raise exception.Create(E.Message);
  end;

  SSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  with SSLHandler do
  begin
    SSLOptions.Method := sslvSSLv23;
    SSLOptions.SSLVersions := [sslvTLSv1, sslvTLSv1_1, sslvTLSv1_2];
  end;

  IdHTTP1 := TIdHTTP.Create(nil);
  with IdHTTP1 do
  begin
    OnWorkBegin := IdHTTPWorkBegin;
    OnWork := IdHTTPWork;
    OnWorkEnd := IdHTTPWorkEnd;
    IOHandler := SSLHandler;
  end;

  i := LastDelimiter('/', gURL);
  FileName := Copy(gURL, i + 1, Length(gURL) - i);
  Stream := TMemoryStream.Create;
  try
    try
      IdHTTP1.Get(gURL, Stream);
      Stream.SaveToFile(gPathApp + 'downloads\' + FileName);
    except
      on E:Exception do
        raise exception.Create(E.Message);
    end;
  finally
    Stream.Free;
    SSLHandler.Free;
    IdHTTP1.Free;
  end;
end;

procedure ThreadDownload.IdHTTPWork(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCount: Int64);
begin
  gProgressDownloadPosition := AWorkCount;
  if gStop then
    Abort;
end;

procedure ThreadDownload.IdHTTPWorkBegin(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCountMax: Int64);
begin
  gProgressDownloadPosition := 0;
  gProgressDownloadMax := AWorkCountMax;
end;

procedure ThreadDownload.IdHTTPWorkEnd(ASender: TObject; AWorkMode: TWorkMode);
begin
  gProgressDownloadPosition := gProgressDownloadMax;

  try
    SQLQuery1.Close;
    SQLQuery1.SQL.Text := ' update logdownload set datafim = current_timestamp ' +
                          ' where url = ' + QuotedStr(gURL);
    SQLQuery1.ExecSQL;
    gStop := True;
    Terminate;
  except
    on E:Exception do
      raise exception.Create(E.Message);
  end;
end;

end.
