unit uFrameFiltro;

interface

uses
  System.Classes,
  System.UITypes,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Objects,
  FMX.StdCtrls, FMX.Controls.Presentation, uSensorIcons;

type
  TfraFiltro = class(TFrame)
    rctFundo: TRectangle;
    lblTexto: TLabel;
    pthSeta: TPath;
    pthIcone: TPath;
    procedure rctFundoClick(Sender: TObject);
    procedure rctFundoMouseEnter(Sender: TObject);
    procedure rctFundoMouseLeave(Sender: TObject);
  private
    FOnFiltroClick: TNotifyEvent;
    FIcone: TSensorIconType;

    function GetTexto: string;
    procedure SetTexto(const Value: string);
    procedure SetIcone(const Value: TSensorIconType);
    procedure AjustarLayout;

  public
    constructor Create(AOwner: TComponent); override;
    property Texto: string read GetTexto write SetTexto;
    property Icone: TSensorIconType read FIcone write SetIcone;
    property OnFiltroClick: TNotifyEvent read FOnFiltroClick write FOnFiltroClick;
  end;

implementation

{$R *.fmx}

constructor TfraFiltro.Create(AOwner: TComponent);
begin
  inherited;

  Width := 160;
  Height := 42;

  FIcone := sitNenhum;

  pthSeta.Data.Data := 'M2,4 L6,8 L10,4 Z';

  AjustarLayout;
end;

function TfraFiltro.GetTexto: string;
begin
  Result := lblTexto.Text;
end;

procedure TfraFiltro.SetTexto(const Value: string);
begin
  lblTexto.Text := Value;
end;

procedure TfraFiltro.SetIcone(const Value: TSensorIconType);
begin
  FIcone := Value;

  TSensorIcon.Definir(pthIcone, FIcone, $FF8795A8);

  AjustarLayout;
end;

procedure TfraFiltro.AjustarLayout;
begin
  if FIcone = sitNenhum then
  begin
    pthIcone.Visible := False;

    lblTexto.Position.X := 14;
    lblTexto.Width :=
      Width - 14 - 30;
  end
  else
  begin
    pthIcone.Visible := True;

    pthIcone.Position.X := 14;
    pthIcone.Position.Y :=
      (Height - pthIcone.Height) / 2;

    lblTexto.Position.X := 40;
    lblTexto.Width :=
      Width - 40 - 30;
  end;

  pthSeta.Position.X :=
    Width - pthSeta.Width - 14;

  pthSeta.Position.Y :=
    (Height - pthSeta.Height) / 2;
end;

procedure TfraFiltro.rctFundoClick(Sender: TObject);
begin
  if Assigned(FOnFiltroClick) then
    FOnFiltroClick(Self);
end;

procedure TfraFiltro.rctFundoMouseEnter(Sender: TObject);
begin
  rctFundo.Fill.Color := $FF18283B;
  rctFundo.Stroke.Color := $FF3A506A;

  lblTexto.TextSettings.FontColor := $FFFFFFFF;
  pthSeta.Fill.Color := $FFB8C4D2;
end;

procedure TfraFiltro.rctFundoMouseLeave(Sender: TObject);
begin
  rctFundo.Fill.Color := $FF121F30;
  rctFundo.Stroke.Color := $FF26374C;

  lblTexto.TextSettings.FontColor := $FFD5DCE6;
  pthSeta.Fill.Color := $FF8795A8;
end;

end.
