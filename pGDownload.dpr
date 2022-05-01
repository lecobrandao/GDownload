program pGDownload;

uses
  Vcl.Forms,
  uGDownload in 'uGDownload.pas' {frmGDownload},
  uThreadDownload in 'uThreadDownload.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmGDownload, frmGDownload);
  Application.Run;
end.
