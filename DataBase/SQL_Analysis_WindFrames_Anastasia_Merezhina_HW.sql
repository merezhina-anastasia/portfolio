--Task 1 
WITH cte_table AS 
(SELECT country_region, calendar_year, channel_desc, amount_sold, sales_percentage,
		LAG (sales_percentage,1) OVER (ORDER BY country_region, channel_desc, calendar_year) AS previous_year
		--here we are getting the sales_percentage for previous yeay
FROM (
SELECT c.country_region, 
		t.calendar_year , 
		ch.channel_desc, 
		sum(s.amount_sold) AS amount_sold, --amount sold per EACH channel EACH year
		ROUND ((SUM(amount_sold)/SUM(SUM(amount_sold)) --counting persantage how much was sold FOR this YEAR through this channel
		OVER (PARTITION BY country_region, calendar_year))*100, 2) AS sales_percentage
FROM sh.sales s 
JOIN sh.channels ch
ON s.channel_id = ch.channel_id 
JOIN sh.customers cust 
ON s.cust_id=cust.cust_id 
JOIN sh.countries c
ON cust.country_id = c.country_id 
JOIN sh.times t 
ON s.time_id =t.time_id 
WHERE lower(c.country_region) IN ('americas', 'asia', 'europe') 
GROUP BY 1,2,3) AS t)

SELECT country_region, 
	  calendar_year, 
	  channel_desc, 
	  amount_sold, --|| ' $' AS amount_sold, 
	  sales_percentage, -- || ' %' AS "% BY CHANNELS", 
	  previous_year,-- ||' %' AS "% PREVIOUS PERIOD", 
	  (sales_percentage-previous_year)-- ||' %' AS "% DIFF" --difeerence BETWEEN sales_persantage FOR this YEAR AND previous one
FROM cte_table
WHERE calendar_year IN (1999, 2000, 2001) --we need purchases FOR 1999,2000,2001
ORDER BY 1,2,3;

--Task 2 
SELECT t.calendar_week_number, t.time_id, t.day_name, sum(amount_sold) AS sales,
		SUM(SUM(amount_sold)) OVER w AS cum_sales,
		
			CASE 
				/* if the day Tuesday,Wednesday, Thursday, Saturday, sunday 
				 * we just count the average for day before+current day+day after
				 */
				WHEN t.day_number_in_week  IN (2,3,4,6,7) 
				THEN ROUND(AVG(SUM(amount_sold)) OVER (ORDER BY t.time_id RANGE BETWEEN 
											INTERVAL '1' DAY PRECEDING AND 
											INTERVAL '1' DAY FOLLOWING),2) 
				/*for Monday we count the average weekend sales+Monday+Tuesday*/
				WHEN t.day_number_in_week = 1 
				THEN ROUND(AVG(SUM(amount_sold)) OVER (ORDER BY t.time_id RANGE BETWEEN 
											INTERVAL '2' DAY PRECEDING AND 
											INTERVAL '1' DAY FOLLOWING),2)
				/*for Friday average sales for Thursday+Friday+weekend*/
				WHEN t.day_number_in_week= 5
				THEN ROUND(AVG(SUM(amount_sold)) OVER (ORDER BY t.time_id RANGE BETWEEN 
											INTERVAL '1' DAY PRECEDING AND 
											INTERVAL '2' DAY FOLLOWING),2)
			END AS centered_3_day_avg
FROM sh.sales s 
JOIN sh.times t 
ON t.time_id = s.time_id 
WHERE t.calendar_year = 1999 AND (t.calendar_week_number IN (49,50,51)) --we need TO GET DATA FOR 3 weeks IN 19998
GROUP BY 1,2,3
WINDOW w AS (PARTITION BY t.calendar_week_number
			ORDER BY t.time_id
			RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)	
ORDER BY 1,2;

--Task 3 
--for conting average amount customer spend in our shop we can use different practices 
SELECT s.time_id, s.cust_id,s.amount_sold,
 /* in groups we will count  the average of the two groups before and including the current one
  * a group in this case is defined as a unique combination of time_id and cust_id 
  */
       AVG(s.amount_sold) OVER (
         PARTITION BY s.cust_id 
         ORDER BY s.cust_id, s.time_id 
         GROUPS  BETWEEN 2 PRECEDING AND CURRENT ROW
       ) AS groups_rolling_avg_spend, 
 /*in rows we simply compute the average of the last two purchases and the current one
  * in this case does not take into account whether the purchases were made on the same day or different days
  */
       AVG(s.amount_sold) OVER (
         PARTITION BY s.cust_id 
         ORDER BY s.cust_id, s.time_id 
         ROWS BETWEEN 2 PRECEDING  AND CURRENT ROW
       ) AS rows_rolling_avg_spend,
 /*in range  we compute the average of the amount sold for each customer for the two days before
  * and including the current day
  * the difference with the group in this case - if we want to take into account previous purchases for one customer
  * he needs to have purchases two or one day before 
  * in groups it doesn't matter how much days interval was - the main point is that it was just previuos purchase 
  * on different day 
 */
       AVG(s.amount_sold) OVER (
         PARTITION BY s.cust_id 
         ORDER BY s.time_id 
         RANGE BETWEEN INTERVAL '2' DAY PRECEDING AND INTERVAL '0' DAY FOLLOWING
       ) AS range_rolling_avg_spend
FROM sh.sales s 
WHERE s.time_id > '2000-01-01' --used WHERE juct TO cut OFF DATA 
ORDER BY 2,1;
