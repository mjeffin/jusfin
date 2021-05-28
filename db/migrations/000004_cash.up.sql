create table if not exists cash_account (
                                            id integer primary key generated always as identity,
                                            name text not null unique,
                                            slug text not null unique,
                                            balance integer not null default 0,
                                            description text
);

create table if not exists cash_withdrawal (
                                               id integer primary key generated always as identity,
                                               txn_date  date default date(now()),
                                               amount integer not null ,
                                               savings_acc_id integer,
                                               constraint fk_savings_account foreign key (savings_acc_id) references savings_account (id) on delete restrict,
                                               cash_acc_id integer,
                                               constraint fk_cash_account foreign key (cash_acc_id) references cash_account (id) on delete  restrict
);

alter table expense add column IF NOT EXISTS  cash_acc_id integer;

DO $$
    BEGIN
        BEGIN
            alter table expense add constraint  fk_savings_acc foreign key (cash_acc_id) references cash_account (id) on delete set null;
        EXCEPTION
            WHEN duplicate_object THEN RAISE NOTICE 'Table constraint cash_acc_id already exists';
        END;
    END $$;



create or replace function withdraw_cash()
    returns trigger as
$$
BEGIN
    if NEW.amount > (select balance from savings_account where id=NEW.savings_acc_id)
    then
        raise exception 'Insufficient balance. check the amount';
    else
        update savings_account set  balance = balance - NEW.amount where id = NEW.savings_acc_id;
        update cash_account set balance = balance + NEW.amount where id = NEW.cash_acc_id;
    end if;
    RETURN NEW;
end;
$$
    language 'plpgsql';

DO
$$
    BEGIN
        CREATE TRIGGER record_cash_withdrawal
            AFTER INSERT ON cash_withdrawal
            FOR EACH ROW
        EXECUTE FUNCTION withdraw_cash();
    EXCEPTION
        WHEN OTHERS THEN null ;
    end;
$$;


create or replace function record_cash_expense()
    returns trigger as
$$
BEGIN
    if  NEW.cash_acc_id is null
    then
        raise EXCEPTION 'Cash account not provided and status=cash. Aborting';
    elsif (select balance from cash_account where id=NEW.cash_acc_id) < NEW.amount
    then
        raise EXCEPTION 'Insufficient balance in cash account. Check the amount again';
    else
        UPDATE cash_account set balance = balance - NEW.amount where id=NEW.cash_acc_id;
    end if;
    return NEW;
end;
$$
    language 'plpgsql';

DO
$$
    BEGIN
        CREATE TRIGGER trigger_cash_expense
            AFTER INSERT ON expense
            FOR EACH ROW
            when ( NEW.payment_method='cash' )
        EXECUTE FUNCTION record_cash_expense();
    EXCEPTION
        WHEN others THEN null;
    END
$$;