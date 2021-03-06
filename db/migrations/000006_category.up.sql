CREATE TABLE IF NOT EXISTS category (
                                        id integer primary key generated always as identity,
                                        name text not null unique ,
                                        slug text not null unique,
                                        description text,
                                        default_monthly_budget integer default 0
);

alter table expense add column IF NOT EXISTS  category_id integer;
alter table expense add column IF NOT EXISTS  description integer;


DO $$
    BEGIN
        BEGIN
            alter table expense add constraint  fk_category foreign key (category_id) references category (id) on delete set null;
        EXCEPTION
            WHEN duplicate_object THEN RAISE NOTICE 'Table constraint category_id already exists';
        END;
    END $$;


create or replace view expense_with_category  AS
select  e.expense_date,c.name as "category",e.amount,e.payment_method,e.description  from category c left join expense e on c.id = e.category_id
where  date_trunc('month', e.expense_date) = date_trunc('month', now())
order by e.amount desc ;
