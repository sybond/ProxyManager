unit UMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, Menus, ExtCtrls, ImgList;

type
  PHwndRec=^THwndRec;
  TWndType=(wtProxy,wtFaker,wtUnknown);
  THwndRec= record
    WindowHandler: THandle;
    WndType: TWndType;
    hLclIP,hRmtIP,hLclPort,hRmtPort,hStartBtn,hStopBtn: THandle;
    Idx: Integer;
  end;

  TFrmProxyManager = class(TForm)
    btnRefresh: TButton;
    lvProxyList: TListView;
    pmTask: TPopupMenu;
    pmtStart: TMenuItem;
    pmtStop: TMenuItem;
    pmtRefresh: TMenuItem;
    N1: TMenuItem;
    RefreshTimer: TTimer;
    pmtInfo: TMenuItem;
    cbAutoRefStatus: TCheckBox;
    pmtAbout: TMenuItem;
    ilMain: TImageList;
    procedure FormCreate(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lvProxyListDblClick(Sender: TObject);
    procedure pmTaskPopup(Sender: TObject);
    procedure pmtStartClick(Sender: TObject);
    procedure pmtStopClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure pmtRefreshClick(Sender: TObject);
    procedure RefreshTimerTimer(Sender: TObject);
    procedure pmtInfoClick(Sender: TObject);
    procedure cbAutoRefStatusClick(Sender: TObject);
    procedure pmtAboutClick(Sender: TObject);
  private

  public
    procedure AddProxy(aName,aRemoteIP,aRPort, aLPort, aCurStatus, aHndID: String);
    procedure Log(aTxt: String);
    procedure RefreshStatus;
    procedure RefreshAll;
  end;
  function EnumWindowsFunc(Handle: THandle; List: TList) : boolean ; stdcall;
  function CEnumWindowsFunc(Handle: THandle;  List: TStringList) : boolean ; stdcall;
  function GetHndClassName(aHandle: THandle): String;

var
  FrmProxyManager: TFrmProxyManager;
  ProxyHndList: TList;

implementation

uses UFrmAbout,PsAPI,TlHelp32;

{$R *.dfm}

procedure TFrmProxyManager.AddProxy(aName, aRemoteIP, aRPort, aLPort, aCurStatus, aHndID: String);
var a: TListItem;
begin
  a:=lvProxyList.Items.Add;
  a.Caption:=aName;
  a.SubItems.Add(aRemoteIP);
  a.SubItems.Add(aRPort);
  a.SubItems.Add(aLPort);
  a.SubItems.Add(aCurStatus);
  a.SubItems.Add(aHndID);
end;

function IsWinXP: Boolean;
begin
  Result := (Win32Platform = VER_PLATFORM_WIN32_NT) and
    (Win32MajorVersion = 5) and (Win32MinorVersion = 1);
end;

function IsWin2k: Boolean;
begin
  Result := (Win32MajorVersion >= 5) and
    (Win32Platform = VER_PLATFORM_WIN32_NT);
end;

function IsWinNT4: Boolean;
begin
  Result := Win32Platform = VER_PLATFORM_WIN32_NT;
  Result := Result and (Win32MajorVersion = 4);
end;

function IsWin3X: Boolean;
begin
  Result := Win32Platform = VER_PLATFORM_WIN32_NT;
  Result := Result and (Win32MajorVersion = 3) and
    ((Win32MinorVersion = 1) or (Win32MinorVersion = 5) or
    (Win32MinorVersion = 51));
end;


function ProcessFileName(PID: DWORD): string;
  var
    Handle: THandle;
begin
    Result := '';
    Handle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, PID);
    if Handle <> 0 then
      try
        SetLength(Result, MAX_PATH);
        if True then
        begin
          if GetModuleFileNameEx(Handle, 0, PChar(Result), MAX_PATH) > 0 then
            SetLength(Result, StrLen(PChar(Result)))
          else
            Result := '';
        end
        else
        begin
          if GetModuleBaseNameA(Handle, 0, PChar(Result), MAX_PATH) > 0 then
            SetLength(Result, StrLen(PChar(Result)))
          else
            Result := '';
        end;
      finally
        CloseHandle(Handle);
      end;
end;


function GetHndExeFilename(aHandle: THandle): String;
var FN: array[0..255] of char;
    ProcInfo: TProcessEntry32;
begin

  Result:=  ProcessFileName(aHandle);
end;

function EnumWindowsFunc(Handle: THandle;
  List: TList): boolean; stdcall;
var
  Caption: array[0..255] of Char;
  item: PHwndRec;
  Ht: THandle;
begin
 if GetClassName(Handle, Caption, SizeOf(Caption)-1) <> 0 then
 begin
  Ht:=GetWindow(Handle,GW_CHILD);
  Ht:=GetWindow(Ht,GW_CHILD);

  if (Caption='TFrmProxyLog') and (GetHndClassName(Ht)='TCheckBox') then
  begin
    new(item);
    item^.WndType:=wtProxy;
    item^.WindowHandler:=Handle;

    Ht:=GetWindow(Handle,GW_CHILD);
    Ht:=GetWindow(Ht,GW_CHILD);
    item^.hLclIP:=GetWindow(Ht,GW_HWNDNEXT); //LocalIP
    Ht:=GetWindow(item^.hLclIP,GW_HWNDNEXT);
    Ht:=GetWindow(Ht,GW_HWNDNEXT);
    item^.hStopBtn:=GetWindow(Ht,GW_HWNDNEXT); //Stop Button
    item^.hStartBtn:=GetWindow(item^.hStopBtn,GW_HWNDNEXT); //Start Button
    item^.hRmtPort:=GetWindow(item^.hStartBtn,GW_HWNDNEXT); //RPort
    item^.hRmtIP:=GetWindow(item^.hRmtPort,GW_HWNDNEXT); //RemoteIP
    item^.hLclPort:=GetWindow(item^.hRmtIP,GW_HWNDNEXT); //LPort
    List.Add(item);
  end;
{  if Caption='TForm1' then
  begin
    new(item);
    item^.WndType:=wtFaker;
    item^.WindowHandler:=Handle;
    List.Add(item);
  end;}
 end;
 result :=True;
end;

function CEnumWindowsFunc(Handle: THandle;   List: TStringList): boolean; stdcall;
var
  caption: array[0..256] of Char;
begin
 if GetWindowText(Handle, Caption, SizeOf(Caption)-1) <> 0 then
 begin
    list.Add(Caption);
 end;
 result :=True;
end;

function GetTextNow(aHandle: THandle): String;
var TheText: array[0..255] of char;
    TextLen : LongInt;
begin
    TextLen := SendMessage (aHandle, WM_GETTEXTLENGTH, 0, 0);
    SendMessage (aHandle, WM_GETTEXT, TextLen + 1, LongInt (@TheText[0]));
    Result:=TheText;
end;

function GetHndClassName(aHandle: THandle): String;
var
TmpCN: array[0..256] of Char;
begin
 if GetClassName(aHandle, TmpCN, SizeOf(TmpCN)-1) <> 0 then
  Result:=TmpCN else Result:='';
end;

function GetHndStatus(aHandle: THandle): String;
var i: Integer;
begin
  i:=GetWindowLong(aHandle,GWL_STYLE);
  if (i and WS_DISABLED)=WS_DISABLED then
    Result:='Started' else  Result:='Stopped';
end;

procedure TFrmProxyManager.FormCreate(Sender: TObject);
begin
  ProxyHndList:=TList.Create;
  EnumWindows(@EnumWindowsFunc, LParam(ProxyHndList));
end;

procedure TFrmProxyManager.btnRefreshClick(Sender: TObject);
begin
  RefreshAll;
  RefreshStatus;
end;

procedure TFrmProxyManager.FormDestroy(Sender: TObject);
var i: Word;
    itm: PHwndRec;
begin
  if ProxyHndList.Count<>0 then
  for i:=0 to ProxyHndList.Count-1 do begin
    itm:=ProxyHndList[i];
    Dispose(itm);
  end;
  ProxyHndList.Free;
end;

procedure TFrmProxyManager.lvProxyListDblClick(Sender: TObject);
begin
  if lvProxyList.Selected<>nil then begin
  end;
end;

procedure TFrmProxyManager.pmTaskPopup(Sender: TObject);
begin
  if lvProxyList.Selected<>nil then begin
    pmtStart.Enabled:=true;
    pmtStop.Enabled:=true;
//    pmtInfo.Enabled:=true;
  end else begin
    pmtStart.Enabled:=false;
    pmtStop.Enabled:=false;
//    pmtInfo.Enabled:=false;
  end;
end;

procedure TFrmProxyManager.pmtStartClick(Sender: TObject);
var i: Integer;
begin
//  ShowMessage(Format('Idx=%d',[ProxyHndList[lvProxyList.Selected.Index]]));
    i:= lvProxyList.Selected.Index;
    Log(Format('Sending START_CMD to %s at Idx=%d',[GetTextNow(PHWndrec(ProxyHndList[i])^.WindowHandler),i]));
    PostMessage(PHWndrec(ProxyHndList[i])^.hStartBtn,WM_LBUTTONDOWN,MK_LBUTTON,0);
    PostMessage(PHWndrec(ProxyHndList[i])^.hStartBtn, WM_LBUTTONUP,MK_LBUTTON,0);
    RefreshStatus;
//    btnRefreshClick(Sender);
//  PHwndRec(ProxyHndList[lvProxyList.Selected.Index])^.hStartBtn
end;

procedure TFrmProxyManager.pmtStopClick(Sender: TObject);
var i: Integer;
begin
//  ShowMessage(Format('Idx=%d',[ProxyHndList[lvProxyList.Selected.Index]]));
    i:=lvProxyList.Selected.Index;
    PostMessage(PHWndrec(ProxyHndList[i])^.hStopBtn,WM_LBUTTONDOWN,MK_LBUTTON,0);
    PostMessage(PHWndrec(ProxyHndList[i])^.hStopBtn, WM_LBUTTONUP,MK_LBUTTON,0);
    RefreshStatus;
//    btnRefreshClick(Sender);
//  PHwndRec(ProxyHndList[lvProxyList.Selected.Index])^.hStartBtn
end;

procedure TFrmProxyManager.FormShow(Sender: TObject);
begin
  btnRefreshClick(sender);
end;

procedure TFrmProxyManager.Log(aTxt: String);
begin
end;

procedure TFrmProxyManager.RefreshAll;
var  i: Integer;
      itm: PHwndRec;
begin
  if ProxyHndList.Count<>0 then
  for i:=0 to ProxyHndList.Count-1 do begin
    itm:=ProxyHndList[i];
    Dispose(itm);
  end;
  ProxyHndList.Clear;
  EnumWindows(@EnumWindowsFunc, LParam(ProxyHndList));
end;

procedure TFrmProxyManager.RefreshStatus;
 var  i,j: Integer;
      itm: PHwndRec;
begin
  j:=99999;
  if lvProxyList.Selected<>nil then j:=lvProxyList.Selected.Index;
  lvProxyList.Clear;
  for i:= 0 to ProxyHndList.Count-1 do
  if (PHwndRec(ProxyHndList[i])^.WndType=wtProxy) then
  begin
    itm:=ProxyHndList[i];
    AddProxy(GetTextNow(itm^.WindowHandler),
            // IntToStr(i),
             GetTextNow(itm^.hRmtIP),
             GetTextNow(itm^.hRmtPort),
             GetTextNow(itm^.hLclPort),
             GetHndStatus(itm^.hStartBtn),
             Format('%x',[itm^.WindowHandler])
             );
  end;
  if j<>99999 then lvProxyList.Items[j].Selected:=true;
end;

procedure TFrmProxyManager.pmtRefreshClick(Sender: TObject);
begin
  RefreshStatus;
end;

procedure TFrmProxyManager.RefreshTimerTimer(Sender: TObject);
begin
  RefreshStatus;
end;

procedure TFrmProxyManager.pmtInfoClick(Sender: TObject);
var i: Integer;
begin
    i:=lvProxyList.Selected.Index;
    ShowMessage(GetHndExeFilename(PHWndrec(ProxyHndList[i])^.WindowHandler));

    //PostMessage(PHWndrec(ProxyHndList[i])^.hStopBtn,WM_LBUTTONDOWN,MK_LBUTTON,0);
    //PostMessage(PHWndrec(ProxyHndList[i])^.hStopBtn, WM_LBUTTONUP,MK_LBUTTON,0);

end;

procedure TFrmProxyManager.cbAutoRefStatusClick(Sender: TObject);
begin
  RefreshTimer.Enabled:=TCheckBox(sender).Checked;
end;

procedure TFrmProxyManager.pmtAboutClick(Sender: TObject);
begin
  dlgAbout.ShowModal;
end;

end.
