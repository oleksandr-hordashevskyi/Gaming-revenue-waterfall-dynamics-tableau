WITH user_monthly_revenue AS (
    -- CTE 1: Агрегація помісячного доходу кожного користувача
    SELECT 
        user_id,
        DATE_TRUNC('month', payment_date)::date AS payment_month,
        SUM(revenue_amount_usd)                 AS revenue_amount
    FROM project.games_payments
    GROUP BY 
        user_id,
        DATE_TRUNC('month', payment_date)::date
),
user_revenue_lag_lead AS (
    -- CTE 2: Віконні зміщення та розрахункові календарні місяці
    SELECT 
        user_id,
        payment_month,
        revenue_amount,
        LAG(payment_month) OVER (
            PARTITION BY user_id 
            ORDER BY payment_month
        ) AS prev_payment_month,
        LAG(revenue_amount) OVER (
            PARTITION BY user_id 
            ORDER BY payment_month
        ) AS prev_revenue_amount,
        LEAD(payment_month) OVER (
            PARTITION BY user_id 
            ORDER BY payment_month
        ) AS next_payment_month,
        (payment_month - INTERVAL '1 month')::date AS prev_calendar_month,
        (payment_month + INTERVAL '1 month')::date AS next_calendar_month,
        ROW_NUMBER() OVER (
            PARTITION BY user_id 
            ORDER BY payment_month
        ) AS user_payment_number
    FROM user_monthly_revenue
),
user_revenue_metrics AS (
    -- CTE 3: Обчислення метрик поведінки та динаміки доходу
    SELECT 
        user_id,
        payment_month,
        revenue_amount AS mrr,
        user_payment_number,
        -- Новий платний користувач та його виручка
        CASE 
            WHEN prev_payment_month IS NULL THEN 1 
            ELSE 0 
        END AS is_new_user,
        CASE 
            WHEN prev_payment_month IS NULL THEN revenue_amount 
            ELSE 0 
        END AS new_mrr,
        -- Збільшення виручки (Expansion MRR)
        CASE 
            WHEN prev_payment_month = prev_calendar_month 
                 AND revenue_amount > prev_revenue_amount 
            THEN revenue_amount - prev_revenue_amount 
            ELSE 0 
        END AS expansion_mrr,
        -- Зменшення виручки (Contraction MRR)
        CASE 
            WHEN prev_payment_month = prev_calendar_month 
                 AND revenue_amount < prev_revenue_amount 
            THEN -(prev_revenue_amount - revenue_amount) 
            ELSE 0 
        END AS contraction_mrr,
        -- Користувачі, які відпали у наступному місяці
        CASE 
            WHEN next_payment_month IS NULL 
                 OR next_payment_month != next_calendar_month 
            THEN 1 
            ELSE 0 
        END AS is_churned_user,
        -- Втрачена виручка через відвал наступного місяця
        CASE 
            WHEN next_payment_month IS NULL 
                 OR next_payment_month != next_calendar_month 
            THEN revenue_amount 
            ELSE 0 
        END AS churned_revenue,
        -- Користувачі, що повернулися після паузи в платежах
        CASE 
            WHEN prev_payment_month IS NOT NULL 
                 AND prev_payment_month != prev_calendar_month 
            THEN 1 
            ELSE 0 
        END AS is_back_from_churn
    FROM user_revenue_lag_lead
)
-- Основний запит: об'єднання з довідником користувачів для фільтрів у Tableau
SELECT 
    m.user_id,
    m.payment_month,
    m.mrr,
    m.user_payment_number,
    m.is_new_user,
    m.new_mrr,
    m.expansion_mrr,
    m.contraction_mrr,
    m.is_churned_user,
    m.churned_revenue,
    m.is_back_from_churn,
    u.game_name,
    u.language,
    u.age,
    u.has_older_device_model
FROM user_revenue_metrics m
LEFT JOIN project.games_paid_users u 
    ON m.user_id = u.user_id
ORDER BY 
    m.payment_month,
    m.user_id;