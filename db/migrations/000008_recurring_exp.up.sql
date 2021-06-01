CREATE TABLE IF NOT EXISTS recurring_expense (
                                                 id integer primary key generated always as identity,
                                                 amount integer default 0,
                                                 payment_method text check ( payment_method in ('cash','upi','cc') ),
                                                 cc_id integer
                                                     constraint fk_cc
                                                         references credit_card
                                                         on delete set null,
                                                 savings_acc_id integer
                                                     constraint fk_savings_acc
                                                         references savings_account
                                                         on delete set null,
                                                 cash_acc_id integer,
                                                 category_id integer
                                                     constraint fk_category
                                                         references category
                                                         on delete set null,
                                                 description integer,
                                                 is_active boolean default true
);

alter table expense add column if not exists is_recurring boolean default false;

create or replace procedure add_recurring_expenses() language 'plpgsql' AS
$$
BEGIN
    insert into expense (amount, payment_method, cc_id, savings_acc_id, cash_acc_id, category_id, description, is_recurring)
    select amount, payment_method, cc_id, savings_acc_id, cash_acc_id, category_id, description,true
    from recurring_expense where is_active = true;
end;
$$;