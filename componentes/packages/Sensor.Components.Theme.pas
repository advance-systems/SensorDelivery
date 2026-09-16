unit Sensor.Components.Theme;

interface

uses
  System.UITypes,
  FMX.Graphics;

type
  TSensorThemeMode = (
    stmDark,
    stmLight
  );

  TSensorTheme = class
  private
    class var FMode: TSensorThemeMode;

    class var FBackground: TAlphaColor;
    class var FSurface: TAlphaColor;
    class var FSurfaceHover: TAlphaColor;
    class var FSurfacePressed: TAlphaColor;
    class var FSurfaceDisabled: TAlphaColor;

    class var FBorder: TAlphaColor;
    class var FBorderHover: TAlphaColor;
    class var FBorderPressed: TAlphaColor;
    class var FBorderDisabled: TAlphaColor;

    class var FPrimary: TAlphaColor;
    class var FPrimaryHover: TAlphaColor;

    class var FTextPrimary: TAlphaColor;
    class var FTextSecondary: TAlphaColor;
    class var FTextDisabled: TAlphaColor;

    class var FSuccess: TAlphaColor;
    class var FWarning: TAlphaColor;
    class var FDanger: TAlphaColor;
    class var FInfo: TAlphaColor;

    class var FFontFamily: string;
    class var FIconFontFamily: string;

    class procedure ApplyDarkTheme; static;
    class procedure ApplyLightTheme; static;

  public
    class constructor Create;

    class procedure SetMode(const AMode: TSensorThemeMode); static;
    class procedure Reset; static;

    class property Mode: TSensorThemeMode
      read FMode write SetMode;

    class property Background: TAlphaColor
      read FBackground;

    class property Surface: TAlphaColor
      read FSurface;

    class property SurfaceHover: TAlphaColor
      read FSurfaceHover;

    class property SurfacePressed: TAlphaColor
      read FSurfacePressed;

    class property SurfaceDisabled: TAlphaColor
      read FSurfaceDisabled;

    class property Border: TAlphaColor
      read FBorder;

    class property BorderHover: TAlphaColor
      read FBorderHover;

    class property BorderPressed: TAlphaColor
      read FBorderPressed;

    class property BorderDisabled: TAlphaColor
      read FBorderDisabled;

    class property Primary: TAlphaColor
      read FPrimary;

    class property PrimaryHover: TAlphaColor
      read FPrimaryHover;

    class property TextPrimary: TAlphaColor
      read FTextPrimary;

    class property TextSecondary: TAlphaColor
      read FTextSecondary;

    class property TextDisabled: TAlphaColor
      read FTextDisabled;

    class property Success: TAlphaColor
      read FSuccess;

    class property Warning: TAlphaColor
      read FWarning;

    class property Danger: TAlphaColor
      read FDanger;

    class property Info: TAlphaColor
      read FInfo;

    class property FontFamily: string
      read FFontFamily;

    class property IconFontFamily: string
      read FIconFontFamily;
  end;

implementation

{ TSensorTheme }

class constructor TSensorTheme.Create;
begin
  FMode := stmDark;
  ApplyDarkTheme;
end;

class procedure TSensorTheme.SetMode(const AMode: TSensorThemeMode);
begin
  if FMode = AMode then
    Exit;

  FMode := AMode;

  case FMode of
    stmDark:
      ApplyDarkTheme;

    stmLight:
      ApplyLightTheme;
  end;
end;

class procedure TSensorTheme.Reset;
begin
  SetMode(stmDark);
  ApplyDarkTheme;
end;

class procedure TSensorTheme.ApplyDarkTheme;
begin
  FBackground := $FF0F1118;

  FSurface := $FF171A24;
  FSurfaceHover := $FF222638;
  FSurfacePressed := $FF2D3248;
  FSurfaceDisabled := $FF151720;

  FBorder := $FF2D3142;
  FBorderHover := $FF444A64;
  FBorderPressed := $FF7857FF;
  FBorderDisabled := $FF252733;

  FPrimary := $FF7857FF;
  FPrimaryHover := $FF8B70FF;

  FTextPrimary := $FFF4F5FA;
  FTextSecondary := $FFA7ADBE;
  FTextDisabled := $FF626779;

  FSuccess := $FF32B768;
  FWarning := $FFFFB020;
  FDanger := $FFFF4D5A;
  FInfo := $FF3478E5;

  FFontFamily := 'Urbanist';
  FIconFontFamily := 'Segoe MDL2 Assets';
end;

class procedure TSensorTheme.ApplyLightTheme;
begin
  FBackground := $FFF4F5FA;

  FSurface := $FFFFFFFF;
  FSurfaceHover := $FFF1F2F7;
  FSurfacePressed := $FFE6E8F0;
  FSurfaceDisabled := $FFECEEF3;

  FBorder := $FFD9DCE6;
  FBorderHover := $FFB8BECE;
  FBorderPressed := $FF7857FF;
  FBorderDisabled := $FFE0E2E8;

  FPrimary := $FF6948D9;
  FPrimaryHover := $FF7857FF;

  FTextPrimary := $FF171A24;
  FTextSecondary := $FF626779;
  FTextDisabled := $FFA0A5B2;

  FSuccess := $FF269E57;
  FWarning := $FFE89600;
  FDanger := $FFE33D4A;
  FInfo := $FF2F6FD0;

  FFontFamily := 'Urbanist';
  FIconFontFamily := 'Segoe MDL2 Assets';
end;

end.
