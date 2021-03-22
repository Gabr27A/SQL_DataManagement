
-- 1.	Create a report to show how many cars each sales representant has sold in the quarter of year 2020.
SELECT s.employee_id, emp.hire_date, emp.salary AS 'base_salary', count(cd.status) AS 'cars_sold'
FROM sales_track AS s, invoice_details AS invd, car_details AS cd, employees as emp
WHERE s.sale_date = invd.sale_date
AND invd.auto_id = cd.auto_id
AND s.employee_id = emp.employee_id
AND s.sale_date BETWEEN '2020-01-10' AND '2020-12-31'
AND cd.status = 'Sold'
GROUP BY s.employee_id;

-- 2.	Create a report that shows the highest type of car sold in the last 6 months of operation including its price.
SELECT cinv.type, count(cinv.type) AS 'Count', c.gender
FROM cars_inventory AS cinv, car_details AS cd, invoice_details AS invd, customers AS c, invoice AS inv
WHERE cinv.auto_id = cd.auto_id
AND cd.auto_id = invd.auto_id
AND c.customer_id = inv.customer_id
AND invd.sale_date BETWEEN '2020-07-01' AND '2020-12-31'
AND cd.status = 'Sold'
GROUP BY cinv.type, c.gender
ORDER BY cinv.type;

-- 3.	Show the total amount of cars in stock by make, type of car, and location.
SELECT ci.make, ci.type, count(ci.type) AS 'amt_in_stock' , cd.current_location
FROM cars_inventory AS ci, car_details AS cd
WHERE ci.auto_id = cd.auto_id
AND cd.status = 'Available'
GROUP BY cd.current_location, ci.make, ci.type
ORDER BY cd.Current_Location;

-- 4.	Create a report to show a list of cars expected to be delivered in the next 2 weeks. 
-- 		Show the supplier id, make, model, type, and expected delivery date
-- Hacer el assumption/note  -- And ord.expected_date = date_add(curdate(), interval 14 day)
SELECT s.supplier_id, s.supplier_name, io.expected_delivery, io.auto_id, ci.make, ci.model, ci.type
FROM suppliers AS s, inventory_orders AS io, cars_inventory AS ci
WHERE s.supplier_id = io.supplier_id
AND io.auto_id = ci.auto_id
AND io.expected_delivery > '2020-12-31';

-- 5.	Create a report that shows the top 5 most used spare parts. Show their name, type, and quantity used.
SELECT part_id, item_name, type, sold_amt AS 'amount_used'
FROM spare_parts
GROUP BY part_id
ORDER BY amount_used DESC
LIMIT 5;


-- 6.	The service department has been slow with the amount of car services appointments. 
-- The marketing department wants a list with the customers who have bought a car but are 
-- not using the dealership’s services. They want a detailed customer information, 
-- from their names, contact information, and auto type and make purchased

select c.customer_id, c.first_name, c.last_name, c.gender, c.email, car.auto_id, car.make, car.type, inv.sale_date
from customers c, cars_inventory car, invoice_details invd, invoice inv
where c.customer_id = inv.customer_id 
and inv.invoice_id = invd.invoice_id 
and invd.auto_id = car.auto_id
and inv.customer_id NOT IN (select customer_id
                              from service);
                              
-- 7.	Determine which channel brings the highest incoming leads for clients.
SELECT channel, count(channel) AS “amt_leads”
FROM customers 
GROUP BY channel;

-- 8.	Create a report showing the average commission for the employees with the oldest hire date 
-- 		vs that of the newest hire for the last quarter. 
SELECT emp.employee_id, emp.first_name, emp.last_name, emp.hire_date, ROUND(AVG(comission_value),2) AS 'Average_comission'
FROM sales_track AS st, employees AS emp
WHERE st.employee_id = emp.employee_id
GROUP BY emp.employee_id;

-- 9.	Create a report to show the cars that has more than 6 months without being sold 
select car.auto_id, car.make, car.model, car.type, ord.delivery_date, unit_sale_price
from cars_inventory car, inventory_orders ord, car_details cd
where car.auto_id = ord.auto_id 
and ord.auto_id = cd.auto_id
and ord.delivery_date < '2020-07-01'
and cd.status = 'Available';

-----------
-- CURSOR 
-----------
ALTER TABLE dealership.inventory_orders
ADD delivery_status VARCHAR(15) NULL;

call del_ontime_cursor( );

select *
from inventory_orders;

-- PROCEDURE CURSOR CODE
CREATE DEFINER=`root`@`localhost` PROCEDURE `del_ontime_cursor`( )
BEGIN

DECLARE done INT DEFAULT FALSE; 
DECLARE v_del_date DATE;

DECLARE ship1 CURSOR FOR
	select delivery_date 
    from inventory_orders
    where expected_delivery = delivery_date;
    
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

OPEN ship1;
read_loop: LOOP
	fetch ship1 into v_del_date;
IF done THEN 
	LEAVE read_loop; 
END IF;

update inventory_orders 
set delivery_status = "On Time"
where delivery_date = v_del_date;

update inventory_orders 
set delivery_status = "Delayed"
where expected_delivery < delivery_date or delivery_date is null;

update inventory_orders 
set delivery_status = "Early"
where expected_delivery > delivery_date;


END LOOP;
END
