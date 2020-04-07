/*
1) В анонимном PL/SQL блоке распечатать все пифагоровы числа, меньшие 25 
(для печати использовать пакет dbms_output, процедуру put_line).
*/   
  declare
  c_max int := 25;
begin
  for i in 1..c_max loop
    for j in i..c_max loop
      for k in j..c_max loop
        if i*i + j*j = k*k then
          dbms_output.put_line(i || ' ' || j || ' ' || k);
        end if;
      end loop;
    end loop;
  end loop;
end;
/

/*
2) Переделать предыдущий пример, чтобы для определения, что 3 числа пифагоровы использовалась функция.
*/


// Функция для проверки 

CREATE OR REPLACE FUNCTION fn_check(i int,j int, k int)
return Boolean
IS
exp_result Boolean;
BEGIN
    exp_result:=i*i+j*j=k*k;
    return exp_result;
END;


declare
  c_max int := 25;
begin
  for i in 1..c_max loop
    for j in i..c_max loop
      for k in j..c_max loop
        if fn_check(i, j, k) then
          dbms_output.put_line(i || ' ' || j || ' ' || k);
        end if;
      end loop;
    end loop;
  end loop;
end;
