-- EMPLOYEE PERFORMANCE DATA ANALYSIS --

-- I used t-SQL to solve queries.

USE Company  --Selecting required database

-- KNOWING ABOUT DATA

SELECT TOP 20 * FROM results;  --getting some sense of data

SELECT COUNT(Employee_ID) FROM results;  -- Looking at number of records

--Questions

-- 1.Retrieve the employee(s) with the lowest salary in each department

SELECT * FROM 
(SELECT *, DENSE_RANK() OVER(PARTITION BY Department ORDER BY Monthly_Salary) AS rank_sal FROM results) AS ranked_table
WHERE rank_sal = 1;

-- 2.Find the average salary of employees with the role of "Technician" who have been with the company for more than 5 years.

SELECT AVG(Monthly_Salary) AS avg_sal FROM results 
WHERE Job_Title = 'Technician' AND Years_At_Company>5;

--3.Calculate the total salary expense for each department in the company.

SELECT Department, SUM(Monthly_Salary) AS salary_expense 
FROM  results
GROUP BY Department;

--4.Retrieve employees who have been with the company for less than 3 years, have a salary greater than 6000, and work in "Engineering."

SELECT Employee_ID FROM results
WHERE Years_At_Company < 3 AND Monthly_Salary > 6000 AND Department = 'Engineering';

--5.Find the difference between the highest and lowest salary in each department and return the department name along with the difference.

SELECT Department, MAX(Monthly_Salary) - MIN(Monthly_Salary) AS salary_diff 
FROM results
GROUP BY Department;

--6.Retrieve the names and roles of employees who have the highest salary in their department.

SELECT Employee_ID, Job_Title FROM (SELECT Employee_ID, Job_Title, DENSE_RANK() OVER(PARTITION BY Department ORDER BY Monthly_Salary DESC) AS sal_ranked
FROM results) AS table_ranked
WHERE sal_ranked = 1;

--7.Find the top 3 highest-paid employees, but exclude those with a salary above 8000.

SELECT * FROM (SELECT *, DENSE_RANK() OVER(PARTITION BY Department ORDER BY Monthly_Salary DESC) AS sal_ranked
FROM results WHERE Monthly_Salary <=5000) AS table_ranked
WHERE  sal_ranked <=3;

--8.Calculate the cumulative salary for each department ordered by experience.
SELECT *, SUM(Monthly_Salary) OVER(PARTITION BY Department ORDER BY Years_At_Company ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cummulative_salary
FROM results;

--9.Retrieve the department with the highest average experience.

SELECT TOP 1 Department, AVG(Monthly_Salary) AS avg_dept_sal
FROM results
GROUP BY Department  --But this answer does not correct when two department have same max average
ORDER BY avg_dept_sal DESC;

-- Better solution

SELECT Department,avg_dept_sal FROM 
(SELECT Department,avg_dept_sal, DENSE_RANK() OVER(ORDER BY avg_dept_sal DESC) AS dept_avg_rank FROM
(SELECT Department, AVG(Monthly_Salary) AS avg_dept_sal
FROM results
GROUP BY Department)  AS avg_table) AS ranked_table
WHERE dept_avg_rank = 1;

--10.Find the employees who are older than 40 and earn above the median salary.

SELECT Employee_ID, Monthly_Salary, Age FROM (SELECT *, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Monthly_Salary) OVER() AS median
FROM results
WHERE Age > 40) AS median_table
WHERE Monthly_Salary > median;

--11.List employees who have been with the company for more than 5 years and earn a salary within the top 10% of their department.

SELECT Employee_ID, Years_At_Company, Monthly_Salary FROM (SELECT *, PERCENT_RANK() OVER(PARTITION BY Department ORDER BY Monthly_Salary DESC) AS sal_ranked
FROM results WHERE Years_At_Company>5) AS table_ranked
WHERE sal_ranked <=0.1;



--12.Identify the top 3 departments with the highest combined years of experience.

SELECT TOP 3 Department, SUM(Years_At_Company) AS total_workexp
FROM results
GROUP BY Department
ORDER BY total_workexp DESC;

--13.Retrieve the employee with the highest salary for each gender.

SELECT * FROM
(SELECT *, DENSE_RANK() OVER(PARTITION BY Gender ORDER BY Monthly_Salary DESC) AS ranked_sal
FROM results) AS ranked_table
WHERE ranked_sal = 1;

--14.Calculate the total number of years of experience for employees who have a "Bachelor" degree and earn more than 6000.

SELECT SUM(Years_At_Company) AS total_exp
FROM results WHERE Education_Level = 'Bachelor' AND Monthly_Salary > 6000;

--15.Retrieve the departments where the average salary is higher than the average salary of all employees.

SELECT * FROM (SELECT Department, AVG(Monthly_Salary) AS avg_sal
FROM results
GROUP BY Department) AS grouped_table
WHERE avg_sal > 
 (SELECT AVG(Monthly_Salary) FROM results);

--16.Find the employees who have been with the company for the longest time in each department.

SELECT * FROM (SELECT *, DENSE_RANK() OVER(PARTITION BY Department ORDER BY Years_At_Company DESC) AS years_rank
FROM results) AS ranked_table
WHERE years_rank = 1;

--17.Retrieve the role with the highest average salary in each department.

SELECT DISTINCT Department, Job_title FROM (SELECT *, DENSE_RANK() OVER(PARTITION BY Department ORDER BY Monthly_Salary DESC) AS sal_rank
FROM results) AS ranked_table
WHERE sal_rank =1
ORDER BY Department , Job_Title;

--18.Find employees whose salary is greater than the average salary in their department but less than the department's maximum salary.
SELECT * FROM 
(SELECT *, MAX(Monthly_Salary) OVER(PARTITION BY Department ) AS max_sal, AVG(Monthly_Salary) OVER(PARTITION BY Department ) AS avg_sal
FROM results) AS ranked_table
WHERE Monthly_Salary > avg_sal AND Monthly_Salary < max_sal;

--19.List the employees whose salary is within one standard deviation above the average salary in their department.
SELECT * FROM (
SELECT *,STDEV(Monthly_Salary) OVER(PARTITION BY Department) AS std_sal,AVG(Monthly_Salary) OVER(PARTITION BY Department) AS avg_sal FROM results) std_table
WHERE Monthly_Salary >= avg_sal 
  AND Monthly_Salary <= (avg_sal + std_sal);

--20.Determine which role has the highest salary gap between male and female employees.
WITH CTE AS 
(SELECT Job_Title,AVG(Monthly_Salary) AS male_avg_gender_sal
FROM results
WHERE Gender = 'Male'
GROUP BY Job_Title ),
CTE2 AS (SELECT Job_Title,AVG(Monthly_Salary) AS female_avg_gender_sal
FROM results
WHERE Gender = 'Female'
GROUP BY Job_Title );
SELECT TOP 1 c1.*,c2.*, ABS(c1.male_avg_gender_sal - c2.female_avg_gender_sal) AS gender_gap
FROM CTE AS c1
LEFT JOIN CTE2 AS c2
ON c1.Job_Title = c2.Job_Title
ORDER BY gender_gap DESC;

--21.Identify the department that has the highest total salary expense per employee.
-- Same as average salary per department 
SELECT TOP 1 Department, AVG(Monthly_Salary) AS dept_avg_sal
FROM results
GROUP BY Department
ORDER BY dept_avg_sal DESC;

--22.Retrieve the employee(s) whose salary is exactly equal to the average salary of their department.

SELECT * FROM (SELECT *, AVG(Monthly_Salary) OVER(PARTITION BY Department) AS avg_dept_sal
FROM results) AS avg_table
WHERE Monthly_Salary = avg_dept_sal;

--23.Calculate the percentage of employees in each department whose salary exceeds the average salary for that department.

WITH CTE1 AS (SELECT Department, COUNT(*) AS inner_sum FROM (SELECT *, AVG(Monthly_Salary) OVER(PARTITION BY Department) AS avg_dept_sal
FROM results) AS avg_table
WHERE Monthly_Salary > avg_dept_sal
GROUP BY Department),
CTE2 AS (SELECT Department, COUNT(*) AS outer_sum
FROM results
GROUP BY Department);

SELECT (CAST(c1.inner_sum AS DECIMAL) / c2.outer_sum) * 100 AS req_percent, c1.*,c2.*
FROM CTE1 AS c1
INNER JOIN CTE2 AS c2
ON c1.Department = c2.Department;

--SELECT * FROM (SELECT *, AVG(Monthly_Salary) OVER(PARTITION BY Department) AS avg_dept_sal
--FROM results) AS avg_table
--WHERE Monthly_Salary > avg_dept_sal


--24.List employees who have been with the company for more than 5 years and whose role is "Technician" or "Developer".
SELECT * 
FROM results
WHERE Years_At_Company > 5 AND Job_Title IN ('Technician','Developer');
--Find the average salary of employees with a "High School" education and compare it with the average salary of employees with a "Bachelor" degree.
SELECT Education_Level, AVG(Monthly_Salary) AS avg_sal
FROM results
WHERE Education_Level IN ('High School','Bachelor')
GROUP BY Education_Level;

--25.Retrieve the department with the most diverse roles (i.e., the department with the highest number of unique roles).
SELECT Department, COUNT(DISTINCT Job_Title) AS diverse_role_cnt
FROM results
GROUP BY Department;

--26.Show the department(s) with the greatest variance in salary.
SELECT TOP 1 Department, VAR(Monthly_Salary) AS sal_var
FROM  results
GROUP BY Department
ORDER BY sal_var DESC;

--27.Find the employees who earn more than the average salary but have less experience than the median experience in their department.

SELECT *, AVG(Monthly_Salary) OVER(PARTITION BY Department) AS avg_sal, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Years_At_Company) OVER (PARTITION BY Department ) AS median_sal
FROM results;


--28.Identify employees who have the same number of years of experience and the same role but have different salaries.
SELECT r1.*,r2.*
FROM results  AS r1
CROSS JOIN results AS r2
WHERE r1.Years_At_Company = r2.Years_At_Company AND r1.Job_Title = r2.Job_Title AND r1.Monthly_Salary<> r2.Monthly_Salary AND r1.Employee_ID <>r2.Employee_ID;

SELECT  DISTINCT r1.Employee_ID, r1.Years_At_Company, r1.Job_Title, r1.Monthly_Salary
FROM results AS r1
JOIN results AS r2 
    ON r1.Years_At_Company = r2.Years_At_Company 
    AND r1.Job_Title = r2.Job_Title 
    AND r1.Monthly_Salary <> r2.Monthly_Salary 
    AND r1.Employee_ID < r2.Employee_ID;


--29.Find the department with the smallest difference between the highest and lowest salary.
SELECT TOP 1 Department, MAX(Monthly_Salary)-MIN(Monthly_Salary) AS sal_diff
FROM results
GROUP BY Department
ORDER BY sal_diff ASC;

--30.Retrieve employees who earn more than the average salary but have less than 5 years of experience.
SELECT *
FROM results
WHERE Monthly_Salary > (SELECT AVG(Monthly_Salary) FROM results)
AND Years_At_Company < 5;

--31.Identify the role with the highest number of employees earning below 5000.
SELECT Job_Title, COUNT(*) AS cnt
FROM results
WHERE Monthly_Salary < 5000
GROUP BY Job_Title;

--32.List departments where more than 50% of employees earn less than the department's average salary.
-- We have to compare to each then partition by is better

WITH CTE1 AS (SELECT Department,COUNT(*) AS inner_sum FROM 
(
SELECT *, AVG(Monthly_Salary) OVER(PARTITION BY Department) AS avg_sal, count(*) OVER(PARTITION BY Department) cnt1
FROM results
) AS avg_table
WHERE Monthly_Salary < avg_sal
GROUP BY Department),
CTE2 AS (
SELECT Department, COUNT(*) AS big_sum
FROM results
GROUP BY Department
);

SELECT c1.*,c2.*
FROM CTE1 AS c1
INNER JOIN CTE2 AS c2
ON c1.Department = c2.Department
WHERE c1.inner_sum < c2.big_sum*0.5;


--HAVING COUNT(*) > (SELECT COUNT(*)*0.5 FROM results GROUP BY Department) --wrong, since subquery returns more than one value, always checks that subquery returns one value



--33.Retrieve the names of employees who have the lowest salary and have been with the company for more than 10 years.
SELECT * FROM results
WHERE Monthly_Salary = (SELECT MIN(Monthly_Salary) FROM results) AND Years_At_Company > 10;

--34.Calculate the difference in salary between the highest and lowest-paid employees, but only for employees who have been with the company for more than 5 years.
SELECT MAX(Monthly_Salary) - MIN(Monthly_Salary)
FROM results
WHERE Years_At_Company > 5;

--35.Determine the average salary of employees in each department with the role "Technician" who have been with the company for more than 5 years.
SELECT Department, AVG(Monthly_Salary)  AS avg_sal
FROM results
WHERE Job_Title = 'Technician' AND Years_At_Company > 5
GROUP BY Department;
--36.Find the employees whose experience is greater than the department average but have a salary lower than the department's median salary.
SELECT * FROM (SELECT * , AVG(Years_At_Company) OVER(PARTITION BY Department) AS avg_exp, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Monthly_Salary) OVER (PARTITION BY Department) AS med_sal
FROM results) AS avg_table
WHERE Years_At_Company > avg_exp AND Monthly_Salary < med_sal;

--37.Retrieve the top 5 departments with the highest number of female employees earning more than 6000.
SELECT TOP 5 Department, COUNT(*) AS cnt1 FROM
(SELECT *
FROM results
WHERE Gender = 'Female'
AND Monthly_Salary > 6000) AS filter_table
GROUP BY Department
ORDER BY COUNT(*) DESC;


--38.Identify departments where the ratio of the highest salary to the lowest salary is greater than 3.

SELECT * FROM (SELECT Department, MAX(Monthly_Salary)/MIN(Monthly_Salary) AS ratio
FROM results
GROUP BY Department) AS ratio_table
WHERE ratio > 3;

--39.Retrieve the names of employees who have the same experience but different roles within the same department.
SELECT DISTINCT r1.Employee_ID, r1.Years_At_Company, r1.Department, r1.Job_Title
FROM results AS r1
 JOIN results AS r2
ON r1.Employee_ID <>r2.Employee_ID
AND r1.Years_At_Company = r2.Years_At_Company
AND r1.Department = r2.Department
AND r1.Job_Title <> r2.Job_Title;

--40.Calculate the total salary paid to employees in each department, excluding the top 10% highest-paid employees in that department.
SELECT Department, SUM(Monthly_Salary) AS sum_sal FROM (SELECT *, PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY Monthly_Salary) OVER (PARTITION BY Department) AS per_sal
FROM results) As per_table
WHERE Monthly_Salary <= per_sal
GROUP BY Department;



--41.Retrieve the roles where the average salary of employees exceeds 7000 but the median salary is below 6000.

SELECT Job_Title FROM (
SELECT *, AVG(Monthly_Salary)  OVER (PARTITION BY Job_Title) AS avg_sal, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Monthly_Salary) 
       OVER (PARTITION BY Job_Title) AS med_sal
FROM results
) AS grp_table
WHERE avg_sal > 5000 AND med_sal < 6000
GROUP BY Job_Title;

--42.Identify the department with the highest percentage of employees who have a "Bachelor" degree.
WITH CTE1 AS (SELECT Department, COUNT(*) AS inner_sum
FROM results
WHERE Education_Level = 'Bachelor'
GROUP BY Department),
CTE2 AS (SELECT Department, COUNT(*) AS outer_sum
FROM results
GROUP BY Department);

SELECT c1.Department,(CAST(c1.inner_sum AS decimal)/c2.outer_sum)*100 AS req_percent
FROM CTE1 AS c1
INNER JOIN CTE2 AS c2
ON c1.Department = c2.Department;

--43.List all employees whose role is "Technician" or "Developer" and whose salary is above the average for their department but below the highest salary.
SELECT * FROM (SELECT *, AVG(Monthly_Salary) OVER(PARTITION BY Department) AS avg_sal, MAX(Monthly_Salary) OVER(PARTITION BY Department) AS max_sal
FROM results
WHERE Job_Title IN ('Technician', 'Developer')) AS rank_table
WHERE Monthly_Salary < max_sal AND Monthly_Salary > avg_sal;

----END OF EXERCISE----
