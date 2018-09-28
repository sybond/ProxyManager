unit UFrmAbout;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, GIFImage;

type
  TdlgAbout = class(TForm)
    iAbout: TImage;
    pnlAbout: TPanel;
    mmAbout: TMemo;
    btnDismiss: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  dlgAbout: TdlgAbout;

implementation

{$R *.dfm}

end.
