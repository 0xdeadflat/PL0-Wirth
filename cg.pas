unit codegen;

interface

uses
  Classes, SysUtils, defs;

procedure GenerateCode(instruction: fct; level, address: integer);

implementation

procedure GenerateCode(instruction: fct; level, address: integer);
begin
  if cx > CODE_ARR_SIZE then
  begin
    Write('Program is too long');
    exitprog;
  end;
  with code[cx] do
  begin
    f := instruction;
    l := level;
    a := address;
  end;
  cx := cx + 1;
end;

end.
