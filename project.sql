CREATE database project 
USE project;

CREATE TABLE transactions (
    date_new DATE,
    Id_check INT,
    ID_client INT,
    Count_products INT,
    Sum_payment DECIMAL(10, 2)
);

SELECT * FROM customer 

UPDATE customer
SET Gender = NULL
WHERE Gender = '';

UPDATE customer
SET AGE = NULL
WHERE AGE = '';


WITH continuous_clients AS (
    SELECT 
        ID_client
    FROM transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY ID_client
    HAVING COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) = 12
)

SELECT 
    c.ID_client,
    AVG(t.Sum_payment) AS avg_check,
    AVG(monthly_total) AS avg_monthly_spending,
    COUNT(t.Id_check) AS total_operations
FROM transactions t
JOIN continuous_clients c ON t.ID_client = c.ID_client
JOIN (
    SELECT 
        ID_client,
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        SUM(Sum_payment) AS monthly_total
    FROM transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY ID_client, month
) monthly_totals ON t.ID_client = monthly_totals.ID_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY c.ID_client;




# 1. Средняя сумма чека в месяц

SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    AVG(Sum_payment) AS avg_check
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY month;

# 2. Среднее количество операций в месяц

SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(Id_check) AS total_operations,
    COUNT(Id_check) / COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) AS avg_operations_per_month
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY month;

# 3. Среднее количество клиентов, которые совершали операции

SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(DISTINCT ID_client) AS total_clients,
    COUNT(DISTINCT ID_client) / COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) AS avg_clients_per_month
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY month;

# 4. Доля от общего количества операций за год и доля в месяц от общей суммы операций

WITH monthly_data AS (
    SELECT 
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        COUNT(Id_check) AS total_operations,
        SUM(Sum_payment) AS total_amount
    FROM transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY month
),
yearly_totals AS (
    SELECT 
        SUM(total_operations) AS yearly_operations,
        SUM(total_amount) AS yearly_amount
    FROM monthly_data
)

SELECT 
    m.month,
    m.total_operations,
    m.total_operations / y.yearly_operations AS operations_share,
    m.total_amount,
    m.total_amount / y.yearly_amount AS amount_share
FROM monthly_data m, yearly_totals y;

# 5. Процентное соотношение M/F/NA по гендеру и их доля в затратах

WITH gender_data AS (
    SELECT 
        DATE_FORMAT(t.date_new, '%Y-%m') AS month,
        c.Gender,
        COUNT(*) AS gender_count,
        SUM(t.Sum_payment) AS gender_total
    FROM transactions t
    JOIN customer c ON t.ID_client = c.Id_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY month, c.Gender
),
monthly_totals AS (
    SELECT 
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        COUNT(*) AS total_count,
        SUM(Sum_payment) AS total_amount
    FROM transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY month
)

SELECT 
    g.month,
    g.Gender,
    g.gender_count,
    g.gender_total,
    g.gender_count / m.total_count AS gender_count_percentage,
    g.gender_total / m.total_amount AS gender_amount_percentage
FROM gender_data g
JOIN monthly_totals m ON g.month = m.month;


# Возрастные группы и клиенты без возраста

SELECT
    CASE
        WHEN c.Age IS NULL THEN 'Unknown'
        WHEN c.Age BETWEEN 0 AND 9 THEN '0-9'
        WHEN c.Age BETWEEN 10 AND 19 THEN '10-19'
        WHEN c.Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN c.Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN c.Age BETWEEN 40 AND 49 THEN '40-49'
        WHEN c.Age BETWEEN 50 AND 59 THEN '50-59'
        WHEN c.Age BETWEEN 60 AND 69 THEN '60-69'
        WHEN c.Age BETWEEN 70 AND 79 THEN '70-79'
        ELSE '80+'
    END AS age_group,
    COUNT(DISTINCT c.Id_client) AS total_clients,
    SUM(t.Sum_payment) AS total_amount,
    COUNT(t.Id_check) AS total_operations
FROM transactions t
JOIN customer c ON t.ID_client = c.Id_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY age_group
ORDER BY age_group;

# Анализ возрастных групп поквартально

SELECT
    CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new)) AS quarter,
    CASE
        WHEN c.Age IS NULL THEN 'Unknown'
        WHEN c.Age BETWEEN 0 AND 9 THEN '0-9'
        WHEN c.Age BETWEEN 10 AND 19 THEN '10-19'
        WHEN c.Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN c.Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN c.Age BETWEEN 40 AND 49 THEN '40-49'
        WHEN c.Age BETWEEN 50 AND 59 THEN '50-59'
        WHEN c.Age BETWEEN 60 AND 69 THEN '60-69'
        WHEN c.Age BETWEEN 70 AND 79 THEN '70-79'
        ELSE '80+'
    END AS age_group,
    COUNT(DISTINCT c.Id_client) AS total_clients,
    SUM(t.Sum_payment) AS total_amount,
    COUNT(t.Id_check) AS total_operations
FROM transactions t
JOIN customer c ON t.ID_client = c.Id_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY quarter, age_group
ORDER BY quarter, age_group;


# Подсчет средних показателей и процентов

# Среднее количество клиентов в возрастных группах


WITH total_data AS (
    SELECT
        CASE
            WHEN c.Age IS NULL THEN 'Unknown'
            WHEN c.Age BETWEEN 0 AND 9 THEN '0-9'
            WHEN c.Age BETWEEN 10 AND 19 THEN '10-19'
            WHEN c.Age BETWEEN 20 AND 29 THEN '20-29'
            WHEN c.Age BETWEEN 30 AND 39 THEN '30-39'
            WHEN c.Age BETWEEN 40 AND 49 THEN '40-49'
            WHEN c.Age BETWEEN 50 AND 59 THEN '50-59'
            WHEN c.Age BETWEEN 60 AND 69 THEN '60-69'
            WHEN c.Age BETWEEN 70 AND 79 THEN '70-79'
            ELSE '80+'
        END AS age_group,
        COUNT(DISTINCT c.Id_client) AS total_clients,
        SUM(t.Sum_payment) AS total_amount,
        COUNT(t.Id_check) AS total_operations
    FROM transactions t
    JOIN customer c ON t.ID_client = c.Id_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY age_group
)
SELECT
    age_group,
    AVG(total_clients) AS avg_clients,
    AVG(total_amount) AS avg_amount,
    AVG(total_operations) AS avg_operations
FROM total_data
GROUP BY age_group;

# Поквартальные средние показатели

WITH quarterly_data AS (
    SELECT
        CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new)) AS quarter,
        CASE
            WHEN c.Age IS NULL THEN 'Unknown'
            WHEN c.Age BETWEEN 0 AND 9 THEN '0-9'
            WHEN c.Age BETWEEN 10 AND 19 THEN '10-19'
            WHEN c.Age BETWEEN 20 AND 29 THEN '20-29'
            WHEN c.Age BETWEEN 30 AND 39 THEN '30-39'
            WHEN c.Age BETWEEN 40 AND 49 THEN '40-49'
            WHEN c.Age BETWEEN 50 AND 59 THEN '50-59'
            WHEN c.Age BETWEEN 60 AND 69 THEN '60-69'
            WHEN c.Age BETWEEN 70 AND 79 THEN '70-79'
            ELSE '80+'
        END AS age_group,
        COUNT(DISTINCT c.Id_client) AS total_clients,
        SUM(t.Sum_payment) AS total_amount,
        COUNT(t.Id_check) AS total_operations
    FROM transactions t
    JOIN customer c ON t.ID_client = c.Id_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY quarter, age_group
),
overall_totals AS (
    SELECT
        SUM(total_clients) AS overall_clients,
        SUM(total_amount) AS overall_amount,
        SUM(total_operations) AS overall_operations
    FROM quarterly_data
)
SELECT
    q.quarter,
    q.age_group,
    q.total_clients,
    q.total_amount,
    q.total_operations,
    q.total_clients / o.overall_clients * 100 AS percent_clients,
    q.total_amount / o.overall_amount * 100 AS percent_amount,
    q.total_operations / o.overall_operations * 100 AS percent_operations
FROM quarterly_data q
JOIN overall_totals o;

