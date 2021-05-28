-- create category enums
create table if not exists income (
                                      id integer primary key generated always as identity,
                                      amount integer not null ,
                                      category text,
                                      txn_date date default date(now()),
                                      savings_acc_id integer not null ,
                                      constraint fk_savings_account foreign key (savings_acc_id) references savings_account (id) on delete restrict,
                                      description text,
                                      is_active boolean default true
);

create or replace function record_income()
    returns trigger as
$$
BEGIN
    UPDATE savings_account set balance = balance + NEW.amount where id=NEW.savings_acc_id;
    return NEW;
end;
$$
    language 'plpgsql';

DO
$$
    BEGIN
        CREATE TRIGGER trigger_new_income
            AFTER INSERT ON income
            FOR EACH ROW
        EXECUTE FUNCTION record_income();
    EXCEPTION
        WHEN OTHERS THEN null ;
    end;
$$;
