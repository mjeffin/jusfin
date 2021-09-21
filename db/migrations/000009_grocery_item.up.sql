CREATE TABLE IF NOT EXISTS grocery_item (
                                            id integer primary key generated always as identity,
                                            name text not null unique ,
                                            unit text,
                                            default_quantity numeric,
                                            default_freq text
);

CREATE TABLE IF NOT EXISTS grocery_order (
                                             id integer primary key generated always as identity,
                                             grocery_item_id integer not null,
                                             constraint fk_grocery_item foreign key (grocery_item_id) references grocery_item (id),
                                             expense_date date default now()::date,
                                             amount integer not null
);