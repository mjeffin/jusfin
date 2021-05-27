create table if not exists savings_account(
                                id integer primary key generated always as identity,
                                name text unique not null ,
                                slug text unique not null ,
                                balance integer not null default 0,
                                comments text
);
-- drop table savings_account;

alter table expense add column IF NOT EXISTS  savings_acc_id integer;

DO $$
BEGIN
BEGIN
alter table expense add constraint  fk_savings_acc foreign key (savings_acc_id) references savings_account (id) on delete set null;
EXCEPTION
            WHEN duplicate_object THEN RAISE NOTICE 'Table constraint savings_acc_id already exists';
END;
END $$;


create or replace function add_upi_expense()
    returns trigger as
$$
BEGIN
    if  NEW.savings_acc_id is null
    then
        raise EXCEPTION 'Debit account not provided and status=upi. Aborting';
    elsif (select balance from savings_account where id=NEW.savings_acc_id) < NEW.amount
    then
       raise EXCEPTION 'Insufficient balance in debit account. Check the amount again';
else
UPDATE savings_account set balance = balance - NEW.amount where id=NEW.savings_acc_id;
end if;
return NEW;
end;
$$
language 'plpgsql';

DO
$$
BEGIN
CREATE TRIGGER trigger_upi_expense
    AFTER INSERT ON expense
    FOR EACH ROW
    when ( NEW.payment_method='upi' )
    EXECUTE FUNCTION add_upi_expense();
EXCEPTION
  WHEN others THEN null;
END
$$;