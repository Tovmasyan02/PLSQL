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


/*3) Написать хранимую процедуру, которой передается ID сотрудника и которая увеличивает ему зарплату на 10%,
если в 2000 году у сотрудника были продажи. Использовать выборку количества заказов за 2000 год в переменную.
А затем, если переменная больше 0, выполнить update данных.*/


 create or replace procedure pr_сheck_salary(p_employee_id employees.employee_id%type)
  is
    v_order_count int;
  begin
   /*Получаем количество заказов сотрудника с id p_employee_id за период 2000-2001 */
    select  count(o.order_id)
      into  v_order_count
      from  orders o
      where o.sales_rep_id = p_employee_id and
            date'2000-01-01' <= o.order_date and o.order_date < date'2001-01-01';
    /*если количество больше 0 то увеличиваем зарплату*/
    if v_order_count > 0 then
      update  employees e
        set   e.salary = e.salary * 1.1
        where e.employee_id = p_employee_id;
    end if;
  end;
  
/*4. Проверить корректность данных о заказах, а именно, что поле ORDER_TOTAL равно сумме UNIT_PRICE * QUANTITY 
по позициям каждого заказа. Для этого создать хранимую процедуру, в которой будет в цикле for проход по всем заказам,
далее по конкретному заказу отдельным select-запросом будет выбираться сумма по позициям данного заказа 
и сравниваться с ORDER_TOTAL. Для «некорректных» заказов распечатать код заказа, дату заказа, заказчика и менеджера.
*/

create or replace procedure pr_check_order_total
  is
    v_order_total orders.order_total%type;
    v_real_price number;
  begin
  /*получаем все заказы в цикле*/
    for i_order in (
      select *
        from orders
    ) loop
      v_order_total := i_order.order_total;
      /* считаем реальную сумму заказ для каждого заказа*/
      select  sum(oi.unit_price * oi.quantity)
        into v_real_price
        from  order_items oi
        where oi.order_id = i_order.order_id;
      /*проверяем если сумма заказа не правильный то вызываем функцию dbms_output*/
      if v_real_price != v_order_total then
        dbms_output.put_line(i_order.order_id || ' ' || i_order.order_date || ' ' || i_order.customer_id);
      end if;
    end loop;        
  end;


/*5) Переписать предыдущее задание с использованием явного курсора */ 
create or replace procedure pr_check_order_total_with_cursor
  is
    /*Запрос явно объяляемь как курсор*/
    cursor cursor_check is
      select  o.order_id,
              oi.real_price,
              o.order_total,
              o.customer_id,
              o.order_date
        from  orders o
              join (select  sum(oi.unit_price * oi.quantity) as real_price,
                            oi.order_id
                      from  order_items oi
                      group by oi.order_id
              ) oi on
                oi.order_id = o.order_id;
                
    v_order cursor_check%rowtype;
  begin
    /*открываем курсор*/
    open cursor_check;
    loop
      /*проверяем для всех заказов total price*/
      fetch cursor_check into v_order;
      exit when cursor_check%notfound;
      if v_order.order_total != v_order.real_price then
        dbms_output.put_line(v_order.order_id || ' ' || v_order.order_date || ' ' || v_order.customer_id);
      end if;
    end loop;        
  end;
  


/* 6) Написать функцию, в которой будет создан тестовый клиент, которому будет сделан заказ
  на текущую дату из одной позиции каждого товара на складе. Имя тестового клиента и ID склада передаются в качестве параметров.
  Функция возвращает ID созданного клиента.*/
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
	

