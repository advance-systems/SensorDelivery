unit uFrameFinanceiro;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation;

type
  TfraFinanceiro = class(TFrame)
    rctFundo: TRectangle;
    lytPrincipal: TLayout;
    lytCabecalho: TLayout;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    lytConteudo: TLayout;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

end.
