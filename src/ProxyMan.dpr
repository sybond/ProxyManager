program ProxyMan;

uses
  Forms,
  UMainForm in 'UMainForm.pas' {FrmProxyManager},
  UFrmAbout in 'UFrmAbout.pas' {dlgAbout};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Proxy Task Manager';
  Application.CreateForm(TFrmProxyManager, FrmProxyManager);
  Application.CreateForm(TdlgAbout, dlgAbout);
  Application.Run;
end.
