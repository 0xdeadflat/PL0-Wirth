unit interpreter;

interface

uses
  Classes, SysUtils;

procedure interpret;

implementation

uses defs;

procedure interpret;

const
  stacksize = 500;

var
  p, b, t: integer; // program-, base-, topstack-registers
  i: instruction;   // instruction register
  s: array [1..stacksize] of integer; // data store

  function base(l: integer): integer;

  var
    b1: integer;
  begin
    b1 := b; // find base l levels down
    while l > 0 do
    begin
      b1 := s[b1];
      l := l - 1;
    end;
    base := b1;
  end;

begin
  writeln('Start PL/0');
  t := 0;
  b := 1;
  p := 0;
  s[1] := 0;
  s[2] := 0;
  s[3] := 0;
  repeat
    i := code[p];
    p := p + 1;
    with i do
      case f of
        lit:
        begin
          t := t + 1;
          s[t] := a; // load constant a
        end;
        opr: case a of // operator
            0:
            begin // return
              t := b - 1;
              p := s[t + 3];
              b := s[t + 2];
            end;
            1: s[t] := -s[t];
            2:
            begin
              t := t - 1;
              s[t] := s[t] + s[t + 1];
            end;
            3:
            begin
              t := t - 1;
              s[t] := s[t] - s[t + 1];
            end;
            4:
            begin
              t := t - 1;
              s[t] := s[t] * s[t + 1];
            end;
            5:
            begin
              t := t - 1;
              s[t] := s[t] div s[t + 1];
            end;
            6: s[t] := Ord(odd(s[t]));
            8:
            begin
              t := t - 1;
              s[t] := Ord(s[t] = s[t + 1]);
            end;
            9:
            begin
              t := t - 1;
              s[t] := Ord(s[t] <> s[t + 1]);
            end;
            10:
            begin
              t := t - 1;
              s[t] := Ord(s[t] < s[t + 1]);
            end;
            11:
            begin
              t := t - 1;
              s[t] := Ord(s[t] >= s[t + 1]);
            end;
            12:
            begin
              t := t - 1;
              s[t] := Ord(s[t] > s[t + 1]);
            end;
            13:
            begin
              t := t - 1;
              s[t] := Ord(s[t] <= s[t + 1]);
            end;
            14:
            begin
              t := t + 1;
              Readln(s[t]);
            end;
            15:
            begin
              Writeln(s[t]);
            end;
          end;
        lod:
        begin
          t := t + 1;
          s[t] := s[base(l) + a]; // load variable l, a
        end;
        sto:
        begin
          s[base(l) + a] := s[t];
          t := t - 1;
        end;
        cal:
        begin
          s[t + 1] := base(l);
          s[t + 2] := b;
          s[t + 3] := p;
          b := t + 1;
          p := a; // generate new block mark
        end;
        int: t := t + a;
        jmp: p := a;
        jpc:
        begin
          if s[t] = 0 then
            p := a;
          t := t - 1;
        end
      end;
  until p = 0;
  Write('End PL/0');
end;

end.
