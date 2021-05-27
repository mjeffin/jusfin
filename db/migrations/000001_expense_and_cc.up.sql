
-- payment methods - cc,imps,cash. may be move to an enum type maybe.
create table if not exists expense (
    id integer primary key generated always as identity,
    expense_date date not null default date(now()),
    amount integer not null ,
    payment_method text ,
    constraint fk_cc foreign key (cc_id) references credit_card(id) on delete set null,
    cc_id integer,
    cc_status text
);

create or replace function set_cc_status_to_unbilled()
    returns trigger as
$$
BEGIN
    if  NEW.cc_id is null
    then
        raise EXCEPTION 'Credit card id  not provided and status=cc';
else
UPDATE expense set cc_status = 'unbilled' where id=NEW.id;
end if;
return NEW;
end;
$$
language 'plpgsql';

DO $$
 BEGIN
CREATE TRIGGER  set_cc_status
    AFTER INSERT ON expense
    FOR EACH ROW
    when ( NEW.payment_method='cc' )
    EXECUTE FUNCTION set_cc_status_to_unbilled();
EXCEPTION
  WHEN others THEN null;
END $$;

-- CREDIT CARD TABLES

create table if not exists credit_card (
   id integer primary key generated always as identity ,
   name text unique ,
   slug text unique,
   billing_date integer check ( billing_date <31 and billing_date > 0 ),
   payment_interval interval day,
   next_billing_date date,
   next_payment_date date
);

-- TODO: adjust if month is december!!
create or replace function get_next_billing_date(billing_date integer)
    returns date as
    $$
BEGIN
        if date(now()) < make_date(extract(year from now())::int, extract(month from now())::int,billing_date)
            then
            return make_date(extract(year from now())::int, extract(month from now())::int,billing_date);
else
            return make_date(extract(year from now())::int, extract(month from now())::int + 1,billing_date);
end if;
end;
    $$
language 'plpgsql';


CREATE OR REPLACE FUNCTION get_next_payment_date(billing_date integer,payment_interval interval)
    RETURNS date as
    $$
BEGIN
        IF make_date(extract(year from now())::int, extract(month from now())::int,billing_date) - now() < payment_interval
            THEN
            RETURN make_date(extract(year from now())::int, extract(month from now())::int,billing_date) + payment_interval;
ELSE
            RETURN make_date(extract(year from now())::int, extract(month from now())::int + 1,billing_date) + payment_interval;
END IF;
end;
    $$
language 'plpgsql';

CREATE OR REPLACE  VIEW cc_total_to_pay AS
select sum(amount) from expense where payment_method='cc' and cc_status != 'paid';

CREATE OR REPLACE VIEW cc_to_pay AS
select c.name, sum(e.amount) from credit_card c left join expense e on c.id = e.cc_id  where e.payment_method='cc' and e.cc_status != 'paid' group by c.name;
