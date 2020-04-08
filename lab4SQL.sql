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


/*Функция для проверки*/ 

create or replace function fn_check(i int,j int, k int)
return Boolean
IS
exp_result Boolean;
begin
    exp_result:=i*i+j*j=k*k;
    return exp_result;
end;


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





6) 
create or replace function fn_test(
     p_first_name in customers.cust_first_name%type,
     p_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type
  is 
    v_customer_id customers.customer_id%type;
    v_order_id orders.order_id%type;
    v_line_item_id order_items.line_item_id%type := 1;
    v_order_total orders.order_total%type := 0;
  begin
  
    /* добавляем данные клиента в таблицу customers */
    insert into customers (cust_first_name)
      values (p_first_name)
      returning customer_id into v_customer_id;
	  
	/* создаем новый заказ */
    insert into orders (order_date, customer_id)
      values (sysdate, v_customer_id)
      returning order_id into v_order_id;
    
	/*в цикле получаем все продукты которые есть в складе с id warehouse_id количество которых >0*/
    for productX in (
      select pi.*
        from  inventories i
              join product_information pi on 
                pi.product_id = i.product_id
        where i.warehouse_id = p_warehouse_id and
              i.quantity_on_hand > 0
    ) loop
	  /* оформляем заказ */
      insert into order_items (order_id, line_item_id, product_id, unit_price, quantity)
        values (v_order_id, v_line_item_id, productX.product_id, productX.list_price, 1);
      v_line_item_id := v_line_item_id + 1;
      v_order_total := v_order_total + productX.list_price;
    end loop;
    update  orders 
       set  order_total = v_order_total
      where order_id = v_order_id;
    return v_customer_id;
  end;
  
  
		
 /*
 7) Добавить в предыдущую функцию проверку на существование склада с переданным ID. 
  Для этого выбрать склад в переменную типа «запись о складе» и перехватить исключение no_data_found, 
  если оно возникнет. В обработчике исключения выйти из функции, вернув null.
  */
create or replace function fn_test(
     p_first_name in customers.cust_first_name%type,
     p_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type
  is 
    v_customer_id customers.customer_id%type;
    v_order_id orders.order_id%type;
    v_line_item_id order_items.line_item_id%type := 1;
    v_order_total orders.order_total%type := 0;
  begin

	/*Проверка */
	begin
      select  *
        into  v_warehouse
        from  warehouses w
        where w.warehouse_id = p_warehouse_id;
    exception
    when no_data_found then
      return null;
    end;
    /* добавляем данные клиента в таблицу customers */
    insert into customers (cust_first_name)
      values (p_first_name)
      returning customer_id into v_customer_id;
	  
	/* создаем новый заказ */
    insert into orders (order_date, customer_id)
      values (sysdate, v_customer_id)
      returning order_id into v_order_id;
    
	/*в цикле получаем все продукты которые есть в складе с id warehouse_id количество которых >0*/
    for productX in (
      select pi.*
        from  inventories i
              join product_information pi on 
                pi.product_id = i.product_id
        where i.warehouse_id = p_warehouse_id and
              i.quantity_on_hand > 0
    ) loop
	  /* оформляем заказ */
      insert into order_items (order_id, line_item_id, product_id, unit_price, quantity)
        values (v_order_id, v_line_item_id, productX.product_id, productX.list_price, 1);
      v_line_item_id := v_line_item_id + 1;
      v_order_total := v_order_total + productX.list_price;
    end loop;
    update  orders 
       set  order_total = v_order_total
      where order_id = v_order_id;
    return v_customer_id;
  end;
  
  
declare
	begin
	  dbms_output.put_line(fn_test('testName', 4));
	end;
	