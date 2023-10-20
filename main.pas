unit main;

interface

uses
  Classes, SysUtils;

procedure MainProgram(PL0FileName: string);

implementation

uses
  defs, parser, interpreter;

procedure MainProgram(PL0FileName: string);
begin
  InitParser(PL0FileName);
  GetSymbol;
  Block(0, 0, [period] + DeclBegSys + StatBegSys);
  ExitParser;
  if Symbol <> period then
    Error(9);
  if ErrorCount = 0 then
    Interpret
  else
    Write('Errors found in PL/0 program');
  Writeln;
end;

end.
