CREATE TABLE IF NOT EXISTS monthly_category_budget (
                                                       id integer primary key generated always as identity,
                                                       category_id integer not null ,
                                                       constraint fk_category_id foreign key (category_id) references category (id) on delete cascade,
                                                       month date not null check (extract( 'day' from  "month") = 1 ),
                                                       amount integer default 0,
                                                       description text,
                                                       unique (category_id, month)
);

create or replace procedure create_monthly_budget_for_exising_categories() language 'plpgsql' AS
$$
BEGIN
    insert into monthly_category_budget (category_id, month,amount)
        (
            select  id,
                    DATE '2021-05-01' + (interval '1' month * generate_series(0,19)),
                    default_monthly_budget
            from category
        ) on conflict do nothing ;
end;
$$;

call create_monthly_budget_for_exising_categories();


create or replace view category_spend_current_month  AS
select * from category_spend_for_month(date_trunc('month', now())::date);

create or replace function category_spend_for_month (input_month date) RETURNS
    table (name text, total bigint, budget_remaining bigint, budget_utilized numeric) AS
$$
BEGIN
    RETURN QUERY
        select c.name,
               sum(e.amount) as "total",
               (mcb.amount -  sum(e.amount) ) as "budget_remaining",
               round(cast(sum(e.amount)::float4/mcb.amount*100 as numeric),2) as "budget_utlized"
        from category c left join expense e on c.id = e.category_id
                        left join monthly_category_budget mcb on c.id = mcb.category_id
        where
                date_trunc('month', e.expense_date) = date_trunc('month', input_month)
          and date_trunc('month', e.expense_date) = mcb.month
        group by c.name, mcb.amount;
end
$$
language 'plpgsql';

create or replace view budget_for_current_month AS
    select c.name, mcb.amount from category c left join monthly_category_budget mcb on c.id = mcb.category_id
    where mcb.month = date_trunc('month',now()::date) order by mcb.amount desc nulls last ;

