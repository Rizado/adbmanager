unit SDCommandTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, ComCtrls;

type
  StartSDCommand = class(TThread)
  private

    { Private declarations }
  protected
  var
    S: TStringList;

    procedure Execute; override;

    procedure StartProgress;
    procedure StopProgress;
    procedure ShowSDLog;

  end;

implementation

uses SDCardManager;

{ TRD }

procedure StartSDCommand.Execute;
var
  ExProcess: TProcess;
begin
  try //Вывод лога и прогресса

    S := TStringList.Create;

    Synchronize(@StartProgress);

    FreeOnTerminate := True; //Уничтожить по завершении

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);

    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(sdcmd);

    ExProcess.Options := [poUsePipes, poStderrToOutPut]; //poWaitOnExit,

    ExProcess.Execute;

    while ExProcess.Running do
    begin
      S.LoadFromStream(ExProcess.Output);
      //Выводим лог
      S.Text := Trim(S.Text);

      //sleep(100);
      if S.Count <> 0 then
        Synchronize(@ShowSDLog);
    end;

  finally
    Synchronize(@StopProgress);
    S.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ ЛОГА }

procedure StartSDCommand.ShowSDLog;
var
  i: integer;
begin
  //Вывод построчно
  for i := 0 to S.Count - 1 do
    SDForm.SDMemo.Lines.Append(S[i]);
  //  SDForm.SDMemo.Lines.Assign(S);
end;


//Старт индикатора
procedure StartSDCommand.StartProgress;
begin
  SDForm.SDMemo.Clear;
  SDForm.ProgressBar1.Style := pbstMarquee;
  SDForm.ProgressBar1.Visible := True;
end;

//Стоп индикатора
procedure StartSDCommand.StopProgress;
var
  i: integer;
begin
  with SDForm do
  begin
    //Обновление каталога назначения на компе
    if Pos('pull', sdcmd) <> 0 then
    begin
      //Запоминаем позицию курсора
      i := CompDir.Selected.AbsoluteIndex;
      //Обновляем  выбранного родителя
      CompDir.Refresh(CompDir.Selected.Parent);
      //Возвращаем курсор на исходную
      CompDir.Select(CompDir.Items[i], [ssCtrl]);
      //Если был раскрыт - переоткрываем
      if not CompDir.Selected.Expanded then
        CompDir.Refresh(CompDir.Selected);

      CompDir.SetFocus;
    end
    else
      //Обновление каталога назначения на смартфоне
      StartLS;

    ProgressBar1.Style := pbstNormal;
    ProgressBar1.Visible := False;
    //ProgressBar1.Position := 0;
  end;
end;

end.
