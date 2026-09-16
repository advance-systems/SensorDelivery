unit uFrameSituacaoLoja;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, System.JSON;

type
  TfraSituacaoLoja = class(TFrame)
    rctFundo: TRectangle;
    rctConteudo: TRectangle;
    cirStatus: TCircle;
    lblFiguraStatus: TLabel;
    lblStatus: TLabel;
    lblMensagem: TLabel;
    rctHorario: TRectangle;
    lblHorarioTitulo: TLabel;
    lblHorarios: TLabel;
    rctTentarNovamente: TRectangle;
    lblTentarNovamente: TLabel;
    lblConfigurarConexao: TLabel;
    procedure rctTentarNovamenteClick(Sender: TObject);
    procedure lblConfigurarConexaoClick(Sender: TObject);
  private
    FOnTentarNovamente: TNotifyEvent;
    FAreaDiagnostico: TRectangle;
    FDiagnostico: TLabel;

    procedure MontarHorarios(AHorarios: TJSONArray);
  public
    constructor Create(AOwner: TComponent); override;
    procedure MostrarVerificando;
    procedure MostrarFechada(const AMensagem: string; AHorarios: TJSONArray);
    procedure MostrarIndisponivel(const ADetalhe: string = '');

    property OnTentarNovamente: TNotifyEvent
      read FOnTentarNovamente
      write FOnTentarNovamente;
  end;

implementation

{$R *.fmx}

uses
  System.StrUtils, FMX.DialogService.Async, uApiConfig;

function CompletarEnderecoServidor(const AValor: string): string;
var
  LInicioAutoridade: Integer;
  LFimAutoridade: Integer;
  LAutoridade: string;
begin
  Result := Trim(AValor);
  if Result.IsEmpty then
    Exit;

  if not Result.Contains('://') then
    Result := 'http://' + Result;

  LInicioAutoridade := Pos('://', Result) + 3;
  LFimAutoridade := PosEx('/', Result, LInicioAutoridade);
  if LFimAutoridade = 0 then
    LFimAutoridade := Length(Result) + 1;

  LAutoridade := Copy(
    Result,
    LInicioAutoridade,
    LFimAutoridade - LInicioAutoridade
  );
  if not LAutoridade.Contains(':') then
    Insert(':3001', Result, LFimAutoridade);
end;

constructor TfraSituacaoLoja.Create(AOwner: TComponent);
var
  LMostrador, LCentro: TCircle;
  LPonteiroHora, LPonteiroMinuto: TRectangle;
begin
  inherited;

  { O emoji de relógio é recortado por algumas fontes do Android. }
  lblFiguraStatus.Visible := False;

  LMostrador := TCircle.Create(Self);
  LMostrador.Parent := cirStatus;
  LMostrador.Position.Point := PointF(23, 22);
  LMostrador.Width := 34;
  LMostrador.Height := 34;
  LMostrador.Fill.Kind := TBrushKind.None;
  LMostrador.Stroke.Color := $FF676C78;
  LMostrador.Stroke.Thickness := 2;
  LMostrador.HitTest := False;

  LPonteiroHora := TRectangle.Create(Self);
  LPonteiroHora.Parent := cirStatus;
  LPonteiroHora.Position.Point := PointF(39, 29);
  LPonteiroHora.Width := 2;
  LPonteiroHora.Height := 13;
  LPonteiroHora.Fill.Color := $FF676C78;
  LPonteiroHora.Stroke.Kind := TBrushKind.None;
  LPonteiroHora.XRadius := 1;
  LPonteiroHora.YRadius := 1;
  LPonteiroHora.HitTest := False;

  LPonteiroMinuto := TRectangle.Create(Self);
  LPonteiroMinuto.Parent := cirStatus;
  LPonteiroMinuto.Position.Point := PointF(39, 40);
  LPonteiroMinuto.Width := 11;
  LPonteiroMinuto.Height := 2;
  LPonteiroMinuto.Fill.Color := $FF676C78;
  LPonteiroMinuto.Stroke.Kind := TBrushKind.None;
  LPonteiroMinuto.XRadius := 1;
  LPonteiroMinuto.YRadius := 1;
  LPonteiroMinuto.HitTest := False;

  LCentro := TCircle.Create(Self);
  LCentro.Parent := cirStatus;
  LCentro.Position.Point := PointF(37.5, 38.5);
  LCentro.Width := 5;
  LCentro.Height := 5;
  LCentro.Fill.Color := $FF676C78;
  LCentro.Stroke.Kind := TBrushKind.None;
  LCentro.HitTest := False;

  FAreaDiagnostico := TRectangle.Create(Self);
  FAreaDiagnostico.Parent := rctConteudo;
  FAreaDiagnostico.Position.Point := PointF(22, 292);
  FAreaDiagnostico.Width := 314;
  FAreaDiagnostico.Height := 142;
  FAreaDiagnostico.Fill.Color := $FFF5F6F8;
  FAreaDiagnostico.Stroke.Color := $FFE1E4E8;
  FAreaDiagnostico.XRadius := 10;
  FAreaDiagnostico.YRadius := 10;
  FAreaDiagnostico.Visible := False;

  FDiagnostico := TLabel.Create(Self);
  FDiagnostico.Parent := FAreaDiagnostico;
  FDiagnostico.Align := TAlignLayout.Client;
  FDiagnostico.Margins.Rect := RectF(12, 9, 12, 9);
  FDiagnostico.StyledSettings := [];
  FDiagnostico.TextSettings.Font.Family := 'Manrope';
  FDiagnostico.TextSettings.Font.Size := 9;
  FDiagnostico.TextSettings.FontColor := $FF4F5663;
  FDiagnostico.TextSettings.HorzAlign := TTextAlign.Leading;
  FDiagnostico.TextSettings.VertAlign := TTextAlign.Leading;
  FDiagnostico.TextSettings.WordWrap := True;
  FDiagnostico.HitTest := False;
end;

procedure TfraSituacaoLoja.MostrarVerificando;
begin
  lblStatus.Text := 'Conectando...';
  lblMensagem.Text :=
    'Estamos verificando a disponibilidade da loja.';

  lblMensagem.WordWrap := True;
  lblMensagem.Height := 90;

  cirStatus.Fill.Color := $FFF1EDFF;
  rctHorario.Visible := False;
  FAreaDiagnostico.Visible := False;
  lblConfigurarConexao.Visible := False;
  rctTentarNovamente.Visible := False;
end;

procedure TfraSituacaoLoja.MontarHorarios(
  AHorarios: TJSONArray);
const
  DIAS: array[0..6] of string = (
    'Domingo',
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado'
  );
var
  I: Integer;
  LItem: TJSONObject;
  LDia: Integer;
  LAbertura: string;
  LFechamento: string;
  LFechado: Boolean;
  LTexto: string;
begin
  LTexto := '';

  if not Assigned(AHorarios) then
  begin
    lblHorarios.Text := '';
    Exit;
  end;

  for I := 0 to AHorarios.Count - 1 do
  begin
    LItem :=
      AHorarios.Items[I] as TJSONObject;

    LDia :=
      LItem.GetValue<Integer>(
        'dia_semana',
        -1
      );

    LAbertura :=
      LItem.GetValue<string>(
        'horario_abertura',
        ''
      );

    LFechamento :=
      LItem.GetValue<string>(
        'horario_fechamento',
        ''
      );

    LFechado :=
      LItem.GetValue<Boolean>(
        'fechado',
        False
      );

    if (LDia < 0) or (LDia > 6) then
      Continue;

    if LFechado then
      LTexto :=
        LTexto +
        Format(
          '%-10s  Fechado',
          [DIAS[LDia]]
        )
    else
      LTexto :=
        LTexto +
        Format(
          '%-10s  %s às %s',
          [
            DIAS[LDia],
            Copy(LAbertura, 1, 5),
            Copy(LFechamento, 1, 5)
          ]
        );

    if I < AHorarios.Count - 1 then
      LTexto := LTexto + sLineBreak;
  end;

  lblHorarios.Text := LTexto;
end;

procedure TfraSituacaoLoja.MostrarFechada(
  const AMensagem: string;
  AHorarios: TJSONArray);
begin
  lblStatus.Text := 'Pizzaria Fechada';
  lblMensagem.Text := AMensagem;

  cirStatus.Fill.Color := $FFFFF2F2;

  rctHorario.Visible := True;
  FAreaDiagnostico.Visible := False;
  lblConfigurarConexao.Visible := False;

  MontarHorarios(AHorarios);

  rctTentarNovamente.Visible := True;
end;

procedure TfraSituacaoLoja.MostrarIndisponivel(const ADetalhe: string);
begin
  lblStatus.Text :=
    'Serviço indisponível';

  lblMensagem.Text :=
    'Não foi possível conectar à pizzaria neste momento.' +
    sLineBreak +
    'Tente novamente em alguns instantes.';

  lblMensagem.WordWrap := True;
  lblMensagem.Height := 90;

  cirStatus.Fill.Color := $FFFFF7E8;

  rctHorario.Visible := False;

  FAreaDiagnostico.Visible := not ADetalhe.Trim.IsEmpty;
  if FAreaDiagnostico.Visible then
    FDiagnostico.Text := 'Diagnóstico' + sLineBreak + ADetalhe
  else
    FDiagnostico.Text := '';

  lblConfigurarConexao.Visible := True;
  rctTentarNovamente.Visible := True;
end;

procedure TfraSituacaoLoja.lblConfigurarConexaoClick(Sender: TObject);
begin
  TDialogServiceAsync.InputQuery(
    'Configurar conexão',
    ['IP ou endereço do servidor:'],
    [TApiConfig.BaseUrl],
    procedure(const AResult: TModalResult; const AValues: array of string)
    var
      LEndereco: string;
    begin
      if (AResult <> mrOk) or (Length(AValues) = 0) then
        Exit;

      LEndereco := CompletarEnderecoServidor(AValues[0]);
      try
        TApiConfig.DefinirBaseUrl(LEndereco);
      except
        on E: Exception do
        begin
          TDialogServiceAsync.ShowMessage(E.Message);
          Exit;
        end;
      end;

      if Assigned(FOnTentarNovamente) then
        FOnTentarNovamente(Self);
    end
  );
end;

procedure TfraSituacaoLoja.rctTentarNovamenteClick(Sender: TObject);
begin
  if Assigned(FOnTentarNovamente) then
    FOnTentarNovamente(Self);
end;

end.
