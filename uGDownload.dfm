object frmGDownload: TfrmGDownload
  Left = 0
  Top = 0
  BorderStyle = bsSingle
  Caption = 'GDownload'
  ClientHeight = 124
  ClientWidth = 609
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lblLink: TLabel
    Left = 24
    Top = 21
    Width = 65
    Height = 13
    Caption = 'Informe o link'
  end
  object bttDownload: TButton
    Left = 24
    Top = 80
    Width = 107
    Height = 25
    Caption = '&Iniciar Download'
    TabOrder = 1
    OnClick = bttDownloadClick
  end
  object bttMensagem: TButton
    Left = 156
    Top = 80
    Width = 107
    Height = 25
    Caption = '&Exibir mensagem'
    TabOrder = 2
    OnClick = bttMensagemClick
  end
  object bttParar: TButton
    Left = 288
    Top = 80
    Width = 107
    Height = 25
    Caption = '&Parar download'
    TabOrder = 3
    OnClick = bttPararClick
  end
  object bttHistorico: TButton
    Left = 424
    Top = 80
    Width = 161
    Height = 25
    Caption = '&Exibir hist'#243'rico de downloads'
    TabOrder = 4
    OnClick = bttHistoricoClick
  end
  object cbbLink: TComboBox
    Left = 24
    Top = 40
    Width = 561
    Height = 21
    TabOrder = 0
  end
  object SQLConnection1: TSQLConnection
    DriverName = 'Sqlite'
    LoginPrompt = False
    Params.Strings = (
      'DriverUnit=Data.DbxSqlite'
      
        'DriverPackageLoader=TDBXSqliteDriverLoader,DBXSqliteDriver240.bp' +
        'l'
      
        'MetaDataPackageLoader=TDBXSqliteMetaDataCommandFactory,DbxSqlite' +
        'Driver240.bpl'
      'FailIfMissing=True'
      'Database=.\dados\dados')
    Left = 472
    Top = 8
  end
  object SQLQuery1: TSQLQuery
    MaxBlobSize = -1
    Params = <>
    SQL.Strings = (
      'select * from logdownload')
    SQLConnection = SQLConnection1
    Left = 400
    Top = 8
  end
end
