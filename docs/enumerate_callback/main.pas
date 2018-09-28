unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TMainForm = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation
{$R *.dfm}

function EnumWindowsFunc(Handle: THandle; List: TStringList) : boolean ; stdcall;
var
  caption: array[0..256] of Char;
begin
 if GetWindowText (Handle, Caption, SizeOf(Caption)-1) <> 0 then
 begin
  List.Add(Caption) ;
  SetWindowText(Handle, PChar('About - ' + Caption)) ;
 end;

 result :=True;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
  Memo1.Clear;
  EnumWindows(@EnumWindowsFunc, LParam(Memo1.Lines)) ;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  ProxyHndList:=TList.Create;

end;

end.
