CREATE TABLE IF NOT EXISTS credit_card_bill (
                                                id integer primary key generated always as identity,
                                                cc_id integer not null,
                                                constraint fk_cc_id foreign key (cc_id) references credit_card (id) on delete restrict,
                                                amount integer not null ,
                                                status text default 'billed',
                                                constraint status_options check ( status in ('billed','paid','overdue')),
                                                due_date date not null,
                                                paid_date date,
                                                acc_paid_from_id integer,
                                                constraint fk_savings_acc foreign key (acc_paid_from_id) references savings_account (id) on delete set null
);

create or replace function add_cc_bill()
    returns trigger as
$$
BEGIN
    if ABS(NEW.amount - (select sum(amount) from expense where cc_status = 'unbilled' and cc_id=NEW.cc_id )) > 100
    then
        raise exception 'Difference between sum of unbilled expense and cc amount is greater than 100. Check the expenses';
    else
        update expense set cc_status='billed' where cc_status = 'unbilled' and cc_id=NEW.cc_id;
    end if;
    RETURN NEW;
end;
$$
    language 'plpgsql';

DO
$$
    BEGIN
        CREATE TRIGGER trigger_add_cc_bill
            AFTER INSERT ON credit_card_bill
            FOR EACH ROW
        EXECUTE FUNCTION add_cc_bill();
    EXCEPTION
        WHEN OTHERS THEN null ;
    end;
$$;

--- Pay credit card bill in full!!
CREATE OR REPLACE PROCEDURE pay_cc_bill(cc_bill_id integer, savings_acc_id integer, payment_date date default date(now()))
    LANGUAGE 'plpgsql'
AS
$$
BEGIN
    UPDATE savings_account set balance = balance - (select amount from credit_card_bill where id=cc_bill_id) where id=savings_acc_id;
    UPDATE credit_card_bill set status = 'paid', paid_date = payment_date, acc_paid_from_id = savings_acc_id where id=cc_bill_id;
    UPDATE expense set cc_status = 'paid' where cc_id=(select cc_id from credit_card_bill where id=cc_bill_id) and cc_status='billed';
end;
$$;
