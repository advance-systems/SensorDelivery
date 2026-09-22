unit uLogin;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Objects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit;

type
  TfrmLogin = class(TForm)
    rctFundo: TRectangle;
    procedure FormCreate(Sender: TObject);
  private
    FEmail, FSenha: TEdit;
    FErro: TLabel;
    FBotao: TRectangle;
    FCampoCaret: TEdit;
    FCaretVisual: TRectangle;
    FTimerCaret: TTimer;
    procedure FormShow(Sender: TObject);
    procedure CampoApplyStyleLookup(Sender: TObject);
    procedure CampoEnter(Sender: TObject);
    procedure CampoExit(Sender: TObject);
    procedure AtualizarCaretVisual(Sender: TObject);
    procedure CampoChangeTracking(Sender: TObject);
    procedure CampoClick(Sender: TObject);
    procedure CampoKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure EntrarClick(Sender: TObject);
    procedure ToggleVerSenhaClick(Sender: TObject);
    procedure CampoKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    function CriarRotulo(const Parent: TFmxObject; const Texto: string;
      X, Y, W, H, Tamanho: Single; Cor: TAlphaColor): TLabel;
    function CriarCampo(const Parent: TFmxObject; const Titulo, Prompt: string;
      Y: Single; Senha: Boolean = False): TEdit;
  end;

implementation

{$R *.fmx}

uses uSessaoAdmin;

function TfrmLogin.CriarRotulo(const Parent: TFmxObject; const Texto: string;
  X, Y, W, H, Tamanho: Single; Cor: TAlphaColor): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := Parent;
  Result.Position.Point := PointF(X, Y);
  Result.Width := W;
  Result.Height := H;
  Result.Text := Texto;
  Result.StyledSettings := [];
  Result.TextSettings.Font.Family := 'Manrope';
  Result.TextSettings.Font.Size := Tamanho;
  Result.TextSettings.FontColor := Cor;
end;

function TfrmLogin.CriarCampo(const Parent: TFmxObject;
  const Titulo, Prompt: string; Y: Single; Senha: Boolean): TEdit;
var
  Fundo: TRectangle;
  BtnOlho: TLabel;
begin
  CriarRotulo(Parent, Titulo, 36, Y, 348, 18, 10, $FF9CAABC);
  Fundo := TRectangle.Create(Self);
  Fundo.Parent := Parent;
  Fundo.Position.Point := PointF(36, Y + 22);
  Fundo.Width := 348;
  Fundo.Height := 44;
  Fundo.Fill.Color := $FF152439;
  Fundo.Stroke.Color := $FF2A405B;
  Fundo.XRadius := 8;
  Fundo.YRadius := 8;
  Result := TEdit.Create(Self);
  Result.Parent := Fundo;
  Result.Align := TAlignLayout.Client;
  Result.Margins.Left := 12;
  Result.Margins.Right := 12;
  if Senha then
    Result.Margins.Right := 36;
  Result.StyleLookup := 'transparentedit';
  Result.StyledSettings := [];
  Result.TextSettings.FontColor := $FFF4F7FB;
  Result.TextPrompt := Prompt;
  Result.Hint := Prompt;
  Result.AutoSelect := False;
  Result.Password := Senha;
  Result.TagObject := Fundo;
  Result.OnApplyStyleLookup := CampoApplyStyleLookup;
  Result.OnEnter := CampoEnter;
  Result.OnExit := CampoExit;
  Result.OnChangeTracking := CampoChangeTracking;
  Result.OnClick := CampoClick;
  Result.OnKeyDown := CampoKeyDown;
  Result.OnKeyUp := CampoKeyUp;

  if Senha then
  begin
    BtnOlho := TLabel.Create(Self);
    BtnOlho.Parent := Fundo;
    BtnOlho.Align := TAlignLayout.Right;
    BtnOlho.Width := 34;
    BtnOlho.Margins.Right := 6;
    BtnOlho.Text := '👁';
    BtnOlho.StyledSettings := [];
    BtnOlho.TextSettings.Font.Family := 'Segoe UI Emoji';
    BtnOlho.TextSettings.Font.Size := 13;
    BtnOlho.TextSettings.FontColor := $FF9CAABC;
    BtnOlho.TextSettings.HorzAlign := TTextAlign.Center;
    BtnOlho.TextSettings.VertAlign := TTextAlign.Center;
    BtnOlho.Cursor := crHandPoint;
    BtnOlho.HitTest := True;
    BtnOlho.TagObject := Result;
    BtnOlho.OnClick := ToggleVerSenhaClick;
  end;
end;

procedure TfrmLogin.ToggleVerSenhaClick(Sender: TObject);
var
  EditCampo: TEdit;
  Btn: TLabel;
begin
  if (Sender is TLabel) and (TLabel(Sender).TagObject is TEdit) then
  begin
    Btn := TLabel(Sender);
    EditCampo := TEdit(Btn.TagObject);
    EditCampo.Password := not EditCampo.Password;
    if EditCampo.Password then
      Btn.TextSettings.FontColor := $FF9CAABC
    else
      Btn.TextSettings.FontColor := $FF8C63FF;
  end;
end;

procedure TfrmLogin.CampoApplyStyleLookup(Sender: TObject);
var
  Campo: TEdit;
begin
  if not (Sender is TEdit) then
    Exit;

  Campo := TEdit(Sender);
  Campo.Caret.BeginUpdate;
  try
    Campo.Caret.DefaultColor := $FFFFFFFF;
    Campo.Caret.Color := $FFFFFFFF;
    Campo.Caret.Width := 2;
    Campo.Caret.Interval := 500;
    Campo.Caret.Visible := True;
  finally
    Campo.Caret.EndUpdate;
  end;

  if Campo.IsFocused then
    Campo.Caret.Show;
end;

procedure TfrmLogin.CampoEnter(Sender: TObject);
var
  Fundo: TRectangle;
begin
  if not (Sender is TEdit) or
     not (TEdit(Sender).TagObject is TRectangle) then
    Exit;

  Fundo := TRectangle(TEdit(Sender).TagObject);
  Fundo.Fill.Color := $FF1C2E45;
  Fundo.Stroke.Color := $FF8C63FF;
  Fundo.Stroke.Thickness := 1.5;
  FCampoCaret := TEdit(Sender);
  TEdit(Sender).TextPrompt := '';
  CampoApplyStyleLookup(Sender);
  TEdit(Sender).Caret.Visible := True;
  TEdit(Sender).Caret.Show;
  AtualizarCaretVisual(nil);
end;

procedure TfrmLogin.CampoExit(Sender: TObject);
var
  Fundo: TRectangle;
begin
  if not (Sender is TEdit) or
     not (TEdit(Sender).TagObject is TRectangle) then
    Exit;

  Fundo := TRectangle(TEdit(Sender).TagObject);
  Fundo.Fill.Color := $FF152439;
  Fundo.Stroke.Color := $FF2A405B;
  Fundo.Stroke.Thickness := 1;
  if TEdit(Sender).Text.IsEmpty then
    TEdit(Sender).TextPrompt := TEdit(Sender).Hint;
  if FCampoCaret = Sender then
  begin
    FCampoCaret := nil;
    if Assigned(FCaretVisual) then
      FCaretVisual.Visible := False;
  end;
end;

procedure TfrmLogin.CampoChangeTracking(Sender: TObject);
begin
  if Sender is TEdit then
    FCampoCaret := TEdit(Sender);
  AtualizarCaretVisual(nil);
end;

procedure TfrmLogin.CampoClick(Sender: TObject);
begin
  if not (Sender is TEdit) then
    Exit;

  FCampoCaret := TEdit(Sender);
  { O clique primeiro reposiciona o cursor interno do TEdit. A fila sincroniza
    o cursor visual no mesmo ciclo da interface, sem aguardar o timer. }
  TThread.ForceQueue(nil,
    procedure
    begin
      if not (csDestroying in ComponentState) then
        AtualizarCaretVisual(nil);
    end);
end;

procedure TfrmLogin.CampoKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Sender is TEdit then
  begin
    FCampoCaret := TEdit(Sender);
    AtualizarCaretVisual(nil);
  end;
end;

procedure TfrmLogin.AtualizarCaretVisual(Sender: TObject);
var
  LAltura: Single;
begin
  if not Assigned(FCaretVisual) or not Assigned(FCampoCaret) or
     not FCampoCaret.IsFocused then
  begin
    if Assigned(FCaretVisual) then
      FCaretVisual.Visible := False;
    Exit;
  end;

  FCaretVisual.Parent := FCampoCaret;
  FCaretVisual.Position.X := FCampoCaret.Caret.Pos.X;
  FCaretVisual.Position.Y := FCampoCaret.Caret.Pos.Y;
  LAltura := FCampoCaret.Caret.Size.cy;
  if LAltura < 16 then
    LAltura := 20;
  FCaretVisual.Height := LAltura;
  FCaretVisual.Visible := True;
  FCaretVisual.BringToFront;

  if Sender = FTimerCaret then
  begin
    if FCaretVisual.Opacity > 0.5 then
      FCaretVisual.Opacity := 0
    else
      FCaretVisual.Opacity := 1;
  end
  else
    FCaretVisual.Opacity := 1;
end;

procedure TfrmLogin.FormShow(Sender: TObject);
begin
  { O foco precisa ser aplicado após a janela já estar visível; antes disso
    o Windows pode aceitar o foco sem criar/exibir o cursor do FireMonkey. }
  TThread.ForceQueue(nil,
    procedure
    begin
      if (csDestroying in ComponentState) or not Assigned(FEmail) then
        Exit;
      FEmail.SetFocus;
      FEmail.TextPrompt := '';
      FEmail.ApplyStyleLookup;
      CampoApplyStyleLookup(FEmail);
      FEmail.Caret.Visible := True;
      FEmail.Caret.Show;
      FCampoCaret := FEmail;
      AtualizarCaretVisual(nil);
    end
  );
end;

procedure TfrmLogin.FormCreate(Sender: TObject);
var
  Lado, Cartao: TRectangle;
  Titulo, Marca, Subtitulo, TextoBotao: TLabel;
begin
  OnShow := FormShow;
  Lado := TRectangle.Create(Self);
  Lado.Parent := rctFundo;
  Lado.Align := TAlignLayout.Left;
  Lado.Width := 500;
  Lado.Fill.Color := $FF080F1B;
  Lado.Stroke.Kind := TBrushKind.None;

  Marca := CriarRotulo(Lado, 'S', 62, 82, 74, 78, 54, $FF8C63FF);
  Marca.TextSettings.Font.Style := [TFontStyle.fsBold];
  CriarRotulo(Lado, 'Sensor Delivery', 140, 92, 300, 38, 28, $FFF4F7FB)
    .TextSettings.Font.Style := [TFontStyle.fsBold];
  CriarRotulo(Lado, 'Painel Administrativo', 142, 129, 260, 22, 12, $FF9CAABC);
  Titulo := CriarRotulo(Lado, 'Tudo sob controle, em um só lugar.',
    62, 260, 380, 88, 30, $FFF4F7FB);
  Titulo.WordWrap := True;
  CriarRotulo(Lado,
    'Gerencie pedidos, clientes, cardápio e sua equipe com segurança.',
    62, 365, 360, 62, 14, $FF8795A8).WordWrap := True;

  Cartao := TRectangle.Create(Self);
  Cartao.Parent := rctFundo;
  Cartao.Position.Point := PointF(605, 105);
  Cartao.Width := 420;
  Cartao.Height := 470;
  Cartao.Fill.Color := $FF111E2E;
  Cartao.Stroke.Color := $FF23364D;
  Cartao.XRadius := 14;
  Cartao.YRadius := 14;

  Titulo := CriarRotulo(Cartao, 'Entrar no sistema', 36, 34, 348, 34, 24, $FFF4F7FB);
  Titulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  Subtitulo := CriarRotulo(Cartao, 'Use seu e-mail e senha para continuar.',
    36, 70, 348, 24, 11, $FF8795A8);
  FEmail := CriarCampo(Cartao, 'E-mail', 'seu@email.com', 120);
  FEmail.KeyboardType := TVirtualKeyboardType.EmailAddress;
  FSenha := CriarCampo(Cartao, 'Senha', 'Digite sua senha', 206, True);

  FCaretVisual := TRectangle.Create(Self);
  FCaretVisual.Parent := FEmail;
  FCaretVisual.Width := 2;
  FCaretVisual.Height := 20;
  FCaretVisual.Fill.Color := $FFFFFFFF;
  FCaretVisual.Stroke.Kind := TBrushKind.None;
  FCaretVisual.HitTest := False;
  FCaretVisual.Visible := False;

  FTimerCaret := TTimer.Create(Self);
  FTimerCaret.Interval := 500;
  FTimerCaret.Enabled := True;
  FTimerCaret.OnTimer := AtualizarCaretVisual;

  FErro := CriarRotulo(Cartao, '', 36, 280, 348, 42, 10, $FFFF6B75);
  FErro.WordWrap := True;
  FErro.Visible := False;

  FBotao := TRectangle.Create(Self);
  FBotao.Parent := Cartao;
  FBotao.Position.Point := PointF(36, 342);
  FBotao.Width := 348;
  FBotao.Height := 46;
  FBotao.Fill.Color := $FF8C63FF;
  FBotao.Stroke.Kind := TBrushKind.None;
  FBotao.XRadius := 9;
  FBotao.YRadius := 9;
  FBotao.Cursor := crHandPoint;
  FBotao.OnClick := EntrarClick;
  TextoBotao := CriarRotulo(FBotao, 'Entrar', 0, 0, 348, 46, 12, $FFFFFFFF);
  TextoBotao.TextSettings.HorzAlign := TTextAlign.Center;
  TextoBotao.TextSettings.VertAlign := TTextAlign.Center;
  TextoBotao.TextSettings.Font.Style := [TFontStyle.fsBold];
  TextoBotao.HitTest := False;

  CriarRotulo(Cartao, 'Acesso protegido por autenticação segura.',
    36, 410, 348, 22, 10, $FF68768A).TextSettings.HorzAlign := TTextAlign.Center;
end;

procedure TfrmLogin.EntrarClick(Sender: TObject);
var
  Erro: string;
begin
  FErro.Visible := False;
  if FEmail.Text.Trim.IsEmpty or FSenha.Text.IsEmpty then
  begin
    FErro.Text := 'Informe o e-mail e a senha.';
    FErro.Visible := True;
    Exit;
  end;

  FBotao.Enabled := False;
  try
    if TSessaoAdmin.Login(FEmail.Text, FSenha.Text, Erro) then
      ModalResult := mrOk
    else
    begin
      FErro.Text := Erro;
      FErro.Visible := True;
      FSenha.SetFocus;
    end;
  finally
    FBotao.Enabled := True;
  end;
end;

procedure TfrmLogin.CampoKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkUp then
  begin
    Key := 0;
    KeyChar := #0;
    if Sender = FSenha then
      FEmail.SetFocus;
    Exit;
  end;

  if Key = vkReturn then
  begin
    Key := 0;
    KeyChar := #0;
    if Sender = FEmail then
      FSenha.SetFocus
    else
      EntrarClick(FBotao);
  end;
end;

end.
