unit uFrameItemBorda;

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Objects,
  FMX.StdCtrls, FMX.Controls.Presentation;

type
  TItemBordaSelecionadaEvent = procedure(
    Sender: TObject;
    const ABordaId: string
  ) of object;

  TfraItemBorda = class(TFrame)
    rctFundo: TRectangle;
    rctRadio: TRectangle;
    ellSelecionado: TEllipse;
    lblDescricao: TLabel;
    lblValor: TLabel;

    procedure rctFundoClick(Sender: TObject);
    procedure rctFundoMouseEnter(Sender: TObject);
    procedure rctFundoMouseLeave(Sender: TObject);
  private
    FBordaId: string;
    FDescricao: string;
    FValor: Currency;
    FSelecionado: Boolean;
    FOnSelecionado: TItemBordaSelecionadaEvent;

    procedure SetSelecionado(const Value: Boolean);
    procedure AtualizarVisual;
  public
    constructor Create(AOwner: TComponent); override;

    procedure Preencher(
      const ABordaId: string;
      const ADescricao: string;
      const AValor: Currency
    );

    property BordaId: string read FBordaId;
    property Descricao: string read FDescricao;
    property Valor: Currency read FValor;

    property Selecionado: Boolean
      read FSelecionado
      write SetSelecionado;

    property OnSelecionado: TItemBordaSelecionadaEvent
      read FOnSelecionado
      write FOnSelecionado;
  end;

implementation

{$R *.fmx}

constructor TfraItemBorda.Create(AOwner: TComponent);
begin
  inherited;

  FBordaId := '';
  FDescricao := '';
  FValor := 0;
  FSelecionado := False;

  AtualizarVisual;
end;

procedure TfraItemBorda.Preencher(
  const ABordaId: string;
  const ADescricao: string;
  const AValor: Currency);
begin
  FBordaId := ABordaId;
  FDescricao := ADescricao;
  FValor := AValor;

  lblDescricao.Text := FDescricao;

  if FValor > 0 then
  begin
    lblValor.Text :=
      FormatFloat('"+ R$ " #,##0.00', FValor);

    lblValor.Visible := True;
  end
  else
  begin
    lblValor.Text := '';
    lblValor.Visible := False;
  end;

  AtualizarVisual;
end;

procedure TfraItemBorda.SetSelecionado(
  const Value: Boolean);
begin
  if FSelecionado = Value then
    Exit;

  FSelecionado := Value;
  AtualizarVisual;
end;

procedure TfraItemBorda.AtualizarVisual;
begin
  if FSelecionado then
  begin
    rctFundo.Fill.Color := $221A2C42;

    rctRadio.Fill.Color := $FF152439;
    rctRadio.Stroke.Color := $FF8C63FF;
    rctRadio.Stroke.Thickness := 2;

    ellSelecionado.Visible := True;

    lblDescricao.TextSettings.FontColor := $FFF2F5F9;
  end
  else
  begin
    rctFundo.Fill.Color := $00FFFFFF;

    rctRadio.Fill.Color := $FF152439;
    rctRadio.Stroke.Color := $FF2A405B;
    rctRadio.Stroke.Thickness := 1;

    ellSelecionado.Visible := False;

    lblDescricao.TextSettings.FontColor := $FFD8E0EA;
  end;
end;

procedure TfraItemBorda.rctFundoClick(Sender: TObject);
begin
  if Assigned(FOnSelecionado) then
    FOnSelecionado(Self, FBordaId);
end;

procedure TfraItemBorda.rctFundoMouseEnter(Sender: TObject);
begin
  if not FSelecionado then
    rctFundo.Fill.Color := $FF18283B;
end;

procedure TfraItemBorda.rctFundoMouseLeave(Sender: TObject);
begin
  AtualizarVisual;
end;

end.
