unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, mvMapViewer, SysUtils, csvdataset, DB, Forms, Controls, Graphics,
  Dialogs, DBGrids, ExtCtrls, Buttons, StdCtrls, Menus, mvTypes;

type

  { TForm1 }

  TForm1 = class(TForm)
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    CSV_Poligono: TCSVDataset;
    CSV_Pontos: TCSVDataset;
    DataSource1: TDataSource;
    DataSource2: TDataSource;
    DBGridTeste: TDBGrid;
    DBGridPoligono: TDBGrid;
    ImageList1: TImageList;
    Label1: TLabel;
    Label2: TLabel;
    MainMenu1: TMainMenu;
    MapView1: TMapView;
    MenuItem1: TMenuItem;
    mnuGoogleMaps: TMenuItem;
    mnuWaze: TMenuItem;
    mnuOpenStreetMaps: TMenuItem;
    mnuArcGIS: TMenuItem;
    mnuPontosAbrirCSV: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    mnuPoligonoAbrirCSV: TMenuItem;
    mnuPoligonoClassificar: TMenuItem;
    mnuPoligonoCarregar: TMenuItem;
    mnuPontosTestar: TMenuItem;
    mnuPontosDesenhar: TMenuItem;
    OpenDialog1: TOpenDialog;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure mnuArcGISClick(Sender: TObject);
    procedure mnuGoogleMapsClick(Sender: TObject);
    procedure mnuOpenStreetMapsClick(Sender: TObject);
    procedure mnuPoligonoAbrirCSVClick(Sender: TObject);
    procedure mnuPoligonoCarregarClick(Sender: TObject);
    procedure mnuPoligonoClassificarClick(Sender: TObject);
    procedure mnuPontosAbrirCSVClick(Sender: TObject);
    procedure mnuPontosDesenharClick(Sender: TObject);
    procedure mnuPontosTestarClick(Sender: TObject);
    procedure mnuWazeClick(Sender: TObject);
  private
    function RetornaCor(Cor: String): integer;
    procedure CarregarPontosPoligono;
    procedure TestarPontos;
    procedure DesenharMapa;
    procedure PontosAbrirCSV;
    procedure PoligonoAbrirCSV;
    function PontoDentroDoPoligono(lat, long: Double): Boolean;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }


function TForm1.PontoDentroDoPoligono(lat, long: Double): Boolean;
var
  lat_new, long_new: Double;
  lat_old, long_old: Double;
  x1,y1: Double;
  x2,y2: Double;
  i, npoints: Integer;
  inside: Integer = 0;
begin
  Result := False;
  npoints := CSV_Poligono.RecordCount;
  if (npoints < 3) then Exit;
  CSV_Poligono.First;
  lat_old := CSV_Poligono.Fields[0].AsFloat;
  long_old := CSV_Poligono.Fields[1].AsFloat;
  for i := 0 to npoints - 1 do
  begin
    CSV_Poligono.Next;
    lat_new := CSV_Poligono.Fields[0].AsFloat;
    long_new := CSV_Poligono.Fields[1].AsFloat;
    if (lat_new > lat_old) then begin
      x1:=lat_old;
      x2:=lat_new;
      y1:=long_old;
      y2:=long_new;
    end
    else begin
      x1:=lat_new;
      x2:=lat_old;
      y1:=long_new;
      y2:=long_old;
    end;
    if ((((y1<=long) and (long<y2)) or
      ((y2<=long) and (long<y1))) and
      (lat<(x2-x1)*(long-y1)/(y2-y1)+x1)) then begin
      inside := not inside;
    end;
    lat_old:=lat_new;
    long_old:=long_new;
  end;
  Result := inside <> 0;
end;


procedure TForm1.CarregarPontosPoligono;
var
  i: Integer;
  A: TMapAreaPoint;
begin
  CSV_Poligono.First;
  for i := 0 to CSV_Poligono.RecordCount - 1 do begin
    A := MapView1.Layers[0].Areas[0].Points.Add As TMapAreaPoint;
    A.Latitude := CSV_Poligono.Fields[0].AsFloat;
    A.Longitude := CSV_Poligono.Fields[1].AsFloat;
    CSV_Poligono.Next;
  end;
end;


procedure TForm1.TestarPontos;
var
  P: TMapPointOfInterest;
  lat, long: Double;
begin
  CSV_Pontos.First;
  while not CSV_Pontos.Eof do
  begin
    lat := CSV_Pontos.Fields[0].AsFloat;
    long := CSV_Pontos.Fields[1].AsFloat;

    if PontoDentroDoPoligono(lat, long) then begin
      P := MapView1.Layers[0].PointsOfInterest.Add as TMapPointOfInterest;
      P.RealPoint := RealPoint(lat, long);
      P.ImageIndex := RetornaCor('Verde');
      P.Caption := '';
      if CSV_Pontos.State = dsBrowse then
        CSV_Pontos.Edit;
      CSV_Pontos.FieldByName('Status').AsString := 'Dentro';
      CSV_Pontos.Post;
    end
    else begin
      P := MapView1.Layers[0].PointsOfInterest.Add as TMapPointOfInterest;
      P.RealPoint := RealPoint(lat, long);
      P.ImageIndex := RetornaCor('Vermelho');
      P.Caption := '';
      if CSV_Pontos.State = dsBrowse then
        CSV_Pontos.Edit;
      CSV_Pontos.FieldByName('Status').AsString := 'Fora';
      CSV_Pontos.Post;
    end;

    CSV_Pontos.Next;
  end;
  CSV_Pontos.SaveToCSVFile('arquivo.csv');
end;

procedure TForm1.DesenharMapa;
var
  P: TMapPointOfInterest;
begin
  // Desenha os pontos de teste
  CSV_Pontos.First;
  while not CSV_Pontos.Eof do
  begin
    P := MapView1.Layers[0].PointsOfInterest.Add as TMapPointOfInterest;
    P.RealPoint := RealPoint(CSV_Pontos.Fields[0].AsFloat, CSV_Pontos.Fields[1].AsFloat);
    P.ImageIndex := RetornaCor(CSV_Pontos.Fields[2].AsString);
    P.Caption := '';

    CSV_Pontos.Next;
  end;
end;

procedure TForm1.PoligonoAbrirCSV;
begin
  if OpenDialog1.Execute then
  begin
    CSV_Poligono.FileName := OpenDialog1.FileName;

    CSV_Poligono.CSVOptions.FirstLineAsFieldNames := True;
    CSV_Poligono.CSVOptions.QuoteChar := '"';

    CSV_Poligono.Active := True;

    DBGridPoligono.Columns[0].Width := 60;
    DBGridPoligono.Columns[1].Width := 60;
  end;
end;

procedure TForm1.PontosAbrirCSV;
begin
  if OpenDialog1.Execute then
  begin
    CSV_Pontos.FileName := OpenDialog1.FileName;

    CSV_Pontos.CSVOptions.FirstLineAsFieldNames := True;
    CSV_Pontos.CSVOptions.QuoteChar := '"';

    CSV_Pontos.Active := True;

    DBGridTeste.Columns[0].Width := 60;
    DBGridTeste.Columns[1].Width := 60;
  end;
end;

function TForm1.RetornaCor(Cor: String): integer;
var
  retorno: integer;
begin
  if Cor = 'Azul' then
    retorno := 0
  else if Cor = 'Verde' then
    retorno := 1
  else if Cor = 'Laranja' then
    retorno := 2
  else if Cor = 'Vermelho' then
    retorno := 3
  else
    retorno := 3;
  Result := retorno;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  MapView1.Active := False;
  if CSV_Poligono.Active then
    CSV_Poligono.Active := False;
  if CSV_Pontos.Active then
    CSV_Pontos.Active := False;
  CloseAction := caFree; // Libera o formulário da memória
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  MapView1.Active := True;
end;

procedure TForm1.mnuArcGISClick(Sender: TObject);
begin
  MapView1.MapProvider:='ArcGIS World Street Map';
end;

procedure TForm1.mnuGoogleMapsClick(Sender: TObject);
begin
  MapView1.MapProvider:='Google Maps';
end;

procedure TForm1.mnuOpenStreetMapsClick(Sender: TObject);
begin
  MapView1.MapProvider:='OpenStreetMap Standard';
end;

procedure TForm1.mnuWazeClick(Sender: TObject);
begin
  MapView1.MapProvider:='Waze Background';
end;

procedure TForm1.mnuPoligonoAbrirCSVClick(Sender: TObject);
begin
  PoligonoAbrirCSV;
end;

procedure TForm1.mnuPoligonoCarregarClick(Sender: TObject);
begin
  CarregarPontosPoligono;
end;

procedure TForm1.mnuPoligonoClassificarClick(Sender: TObject);
begin
  //TO DO: Algoritmo para Classificar os Pontos com propósito de Desenhar o Polígono.
end;

procedure TForm1.mnuPontosAbrirCSVClick(Sender: TObject);
begin
  PontosAbrirCSV;
end;

procedure TForm1.mnuPontosDesenharClick(Sender: TObject);
begin
  DesenharMapa;
end;

procedure TForm1.mnuPontosTestarClick(Sender: TObject);
begin
  TestarPontos;
end;

end.

