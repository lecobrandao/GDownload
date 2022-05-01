unit uGDownload;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IdHTTP, IdBaseComponent,
  IdComponent, IdTCPConnection, IdTCPClient, IdServerIOHandler, IdSSL,
  IdSSLOpenSSL, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, System.Generics.Collections,
  uThreadDownload, Data.FMTBcd, Data.DB, Data.SqlExpr, Data.DbxSqlite;

type
  TfrmGDownload = class(TForm)
    lblLink: TLabel;
    bttDownload: TButton;
    bttMensagem: TButton;
    bttParar: TButton;
    bttHistorico: TButton;
    cbbLink: TComboBox;
    SQLConnection1: TSQLConnection;
    SQLQuery1: TSQLQuery;
    procedure FormCreate(Sender: TObject);
    procedure bttDownloadClick(Sender: TObject);
    procedure bttMensagemClick(Sender: TObject);
    procedure bttPararClick(Sender: TObject);
    procedure bttHistoricoClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
    ListaThreads: TObjectList<ThreadDownload>;
  public
    { Public declarations }
  end;

var
  frmGDownload: TfrmGDownload;

implementation

{$R *.dfm}

procedure TfrmGDownload.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var i: Integer;
begin
  if ListaThreads.Count > 0 then
  begin
    for i := 0 to ListaThreads.Count - 1 do
    begin
      if not(ThreadDownload(ListaThreads.Items[i]).gStop) then
      begin
        if MessageDlg('Existe um download em andamento, deseja interrompê-lo?', mtInformation, mbYesNo, 0) = mrYes then
        begin
          ThreadDownload(ListaThreads.Items[i]).gStop := True;
          ThreadDownload(ListaThreads.Items[i]).Terminate;
          CanClose := True;
        end
        else
          CanClose := False;
        Break;
      end;
    end;
  end;
end;

procedure TfrmGDownload.FormCreate(Sender: TObject);
begin
  ListaThreads := TObjectList<ThreadDownload>.Create;
end;

procedure TfrmGDownload.bttDownloadClick(Sender: TObject);
var ThDownload: ThreadDownload;
begin
  if cbbLink.Text = '' then
  begin
    MessageDlg('Informe o link.', mtInformation, mbOKCancel, 0);
    Exit;
  end;

  if cbbLink.Items.IndexOf(cbbLink.Text) > -1 then
  begin
    MessageDlg('O download do link informado já foi iniciado.', mtInformation, mbOKCancel, 0);
    Exit;
  end;

  cbbLink.Items.Add(cbbLink.Text);
  try
    ThDownload := ThreadDownload.Create;
    ThDownload.gURL := cbbLink.Text;
    ThDownload.gPathApp := ExtractFilePath(Application.ExeName);
    ThDownload.Start;
    ListaThreads.Add(ThDownload);

    MessageDlg('Download iniciado.', mtInformation, mbOKCancel, 0);
  except
    on E:Exception do
    begin
      MessageDlg('Erro ao iniciar download: ' + #13#13 + E.Message, mtError, mbOKCancel, 0);
      cbbLink.Items.Delete(cbbLink.Items.IndexOf(cbbLink.Text));
    end;
  end;
end;

procedure TfrmGDownload.bttMensagemClick(Sender: TObject);
var pPosition, pMax: Integer;
begin
  if cbbLink.Text = '' then
  begin
    MessageDlg('Informe o link.', mtInformation, mbOKCancel, 0);
    Exit;
  end;

  if cbbLink.Items.IndexOf(cbbLink.Text) = -1 then
  begin
    MessageDlg('O download do link informado não foi iniciado.', mtInformation, mbOKCancel, 0);
    Exit;
  end;

  if ListaThreads.Items[cbbLink.Items.IndexOf(cbbLink.Text)] = nil then
    MessageDlg('O download desse arquivo já foi concluído.', mtInformation, mbOKCancel, 0)
  else
  begin
    pPosition := ThreadDownload(ListaThreads.Items[cbbLink.Items.IndexOf(cbbLink.Text)]).gProgressDownloadPosition;
    pMax := ThreadDownload(ListaThreads.Items[cbbLink.Items.IndexOf(cbbLink.Text)]).gProgressDownloadMax;
    if pMax = 0 then
      MessageDlg('O download ainda não foi iniciado.', mtInformation, mbOKCancel, 0)
    else
      MessageDlg('O download está em '+ IntToStr(Round(pPosition / pMax) * 100) +'%.', mtInformation, mbOKCancel, 0);
  end;
end;

procedure TfrmGDownload.bttPararClick(Sender: TObject);
begin
  if cbbLink.Text = '' then
  begin
    MessageDlg('Informe o link.', mtInformation, mbOKCancel, 0);
    Exit;
  end;

  if cbbLink.Items.IndexOf(cbbLink.Text) = -1 then
  begin
    MessageDlg('O download do link informado não foi iniciado.', mtInformation, mbOKCancel, 0);
    Exit;
  end;

  if ListaThreads.Items[cbbLink.Items.IndexOf(cbbLink.Text)] = nil then
    MessageDlg('O download desse arquivo já foi concluído.', mtInformation, mbOKCancel, 0)
  else
  begin
    ThreadDownload(ListaThreads.Items[cbbLink.Items.IndexOf(cbbLink.Text)]).gStop := True;
    ThreadDownload(ListaThreads.Items[cbbLink.Items.IndexOf(cbbLink.Text)]).Terminate;
    cbbLink.Items.Delete(cbbLink.Items.IndexOf(cbbLink.Text));
    MessageDlg('O download foi interrompido.', mtInformation, mbOKCancel, 0);
  end;
end;

procedure TfrmGDownload.bttHistoricoClick(Sender: TObject);
var sHistorico: String;
    Form: TForm;
    Label1: TLabel;
begin
  try
    SQLConnection1.Params.Add('Database='+ ExtractFilePath(Application.ExeName) + 'dados\dados');
    SQLConnection1.Connected := True;

    SQLQuery1.Close;
    SQLQuery1.SQL.Text := ' select * from logdownload ';
    SQLQuery1.Open;
    if SQLQuery1.IsEmpty then
      MessageDlg('Nenhum download foi encontrado.', mtInformation, mbOKCancel, 0)
    else
    begin
      sHistorico := '';
      SQLQuery1.First;
      while not(SQLQuery1.Eof) do
      begin
        sHistorico := sHistorico +
                      'Código: ' + SQLQuery1.Fields[0].AsString +
                      ' - URL: ' + SQLQuery1.Fields[1].AsString +
                      ' - DataInicial: ' + SQLQuery1.Fields[2].AsString +
                      ' - DataFinal: ' + SQLQuery1.Fields[3].AsString + #13#13;
        SQLQuery1.Next;
      end;

      Form := CreateMessageDialog(sHistorico, mtInformation, [mbOK]);
      try
        Label1 := TLabel(Form.FindComponent('Message'));
        Label1.Width := Label1.Width + 100;
        Form.ClientWidth := Form.ClientWidth + 100;
        Form.Position := poScreenCenter;
        Form.ShowModal;
      finally
        Form.Free;
      end;
    end;
  except
    on E:Exception do
      MessageDlg('Erro ao ler histórico de downloads: ' + #13#13 + E.Message, mtError, mbOKCancel, 0);
  end;
end;

end.
