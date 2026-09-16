unit Sensor.Components.Base;

interface

uses
  System.Classes,
  System.UITypes,
  FMX.Types,
  FMX.Graphics,
  FMX.Objects,
  Sensor.Components.Theme;

type
  TSensorControl = class(TRectangle)
  private
    FUseTheme: Boolean;

    FBackgroundColor: TAlphaColor;
    FBorderColor: TAlphaColor;

    FBorderThickness: Single;
    FCornerRadius: Single;

    procedure SetUseTheme(const Value: Boolean);
    procedure SetBackgroundColor(const Value: TAlphaColor);
    procedure SetBorderColor(const Value: TAlphaColor);
    procedure SetBorderThickness(const Value: Single);
    procedure SetCornerRadius(const Value: Single);

  protected
    procedure ApplyTheme; virtual;
    procedure ApplyStyle; virtual;

  public
    constructor Create(AOwner: TComponent); override;

    procedure RefreshTheme; virtual;

  published
    property UseTheme: Boolean
      read FUseTheme
      write SetUseTheme
      default True;

    property BackgroundColor: TAlphaColor
      read FBackgroundColor
      write SetBackgroundColor;

    property BorderColor: TAlphaColor
      read FBorderColor
      write SetBorderColor;

    property BorderThickness: Single
      read FBorderThickness
      write SetBorderThickness;

    property CornerRadius: Single
      read FCornerRadius
      write SetCornerRadius;
  end;

implementation

{ TSensorControl }

constructor TSensorControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Width := 160;
  Height := 44;

  HitTest := True;
  ClipChildren := False;

  FUseTheme := True;
  FBorderThickness := 1;
  FCornerRadius := 10;

  ApplyTheme;
  ApplyStyle;
end;

procedure TSensorControl.ApplyTheme;
begin
  FBackgroundColor := TSensorTheme.Surface;
  FBorderColor := TSensorTheme.Border;
end;

procedure TSensorControl.ApplyStyle;
begin
  Fill.Kind := TBrushKind.Solid;
  Fill.Color := FBackgroundColor;

  Stroke.Kind := TBrushKind.Solid;
  Stroke.Color := FBorderColor;
  Stroke.Thickness := FBorderThickness;

  XRadius := FCornerRadius;
  YRadius := FCornerRadius;

  Repaint;
end;

procedure TSensorControl.RefreshTheme;
begin
  if FUseTheme then
    ApplyTheme;

  ApplyStyle;
end;

procedure TSensorControl.SetUseTheme(const Value: Boolean);
begin
  if FUseTheme = Value then
    Exit;

  FUseTheme := Value;

  if FUseTheme then
    ApplyTheme;

  ApplyStyle;
end;

procedure TSensorControl.SetBackgroundColor(
  const Value: TAlphaColor);
begin
  if FBackgroundColor = Value then
    Exit;

  FBackgroundColor := Value;
  FUseTheme := False;

  ApplyStyle;
end;

procedure TSensorControl.SetBorderColor(
  const Value: TAlphaColor);
begin
  if FBorderColor = Value then
    Exit;

  FBorderColor := Value;
  FUseTheme := False;

  ApplyStyle;
end;

procedure TSensorControl.SetBorderThickness(
  const Value: Single);
begin
  if FBorderThickness = Value then
    Exit;

  FBorderThickness := Value;

  ApplyStyle;
end;

procedure TSensorControl.SetCornerRadius(
  const Value: Single);
begin
  if FCornerRadius = Value then
    Exit;

  FCornerRadius := Value;

  ApplyStyle;
end;

end.
