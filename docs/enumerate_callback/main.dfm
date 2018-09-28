object MainForm: TMainForm
  Left = 0
  Top = 0
  Width = 200
  Height = 200
  Caption = 'Function Callbacks'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 8
    Top = 8
    Width = 173
    Height = 25
    Caption = 'Enumerate Windows'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Memo1: TMemo
    Left = 4
    Top = 36
    Width = 185
    Height = 133
    Lines.Strings = (
      'Memo1')
    ScrollBars = ssBoth
    TabOrder = 1
  end
end
