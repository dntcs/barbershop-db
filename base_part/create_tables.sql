BEGIN;

CREATE TABLE public.branch (
    branch_id SERIAL,
    name character varying(100) NOT NULL,
    address character varying(255) NOT NULL,
    phone character varying(20) NOT NULL,
    working_hours character varying(100) NOT NULL,
    CONSTRAINT branch_address_key UNIQUE (address),
    CONSTRAINT branch_phone_key UNIQUE (phone),
    CONSTRAINT branch_pkey PRIMARY KEY (branch_id)
);

CREATE TABLE public.master (
    master_id SERIAL,
    branch_id integer NOT NULL,
    last_name character varying(50) NOT NULL,
    first_name character varying(50) NOT NULL,
    middle_name character varying(50),
    specialization character varying(100) NOT NULL,
    CONSTRAINT master_pkey PRIMARY KEY (master_id),
    CONSTRAINT master_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE public.shift (
    shift_id SERIAL,
    master_id integer NOT NULL,
    shift_date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    CONSTRAINT chk_shift_time CHECK ((end_time > start_time)),
    CONSTRAINT shift_pkey PRIMARY KEY (shift_id),
    CONSTRAINT uq_master_shift_date UNIQUE (master_id, shift_date),
    CONSTRAINT shift_master_id_fkey FOREIGN KEY (master_id) REFERENCES public.master(master_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE public.service (
    service_id SERIAL,
    name character varying(100) NOT NULL,
    description text,
    duration_min integer NOT NULL,
    CONSTRAINT service_duration_min_check CHECK (((duration_min > 0) AND (duration_min <= 480))),
    CONSTRAINT service_name_key UNIQUE (name),
    CONSTRAINT service_pkey PRIMARY KEY (service_id)
);

CREATE TABLE public.price (
    price_id SERIAL,
    branch_id integer NOT NULL,
    service_id integer NOT NULL,
    amount numeric(10,2) NOT NULL,
    valid_from date DEFAULT CURRENT_DATE NOT NULL,
    valid_to date,
    CONSTRAINT chk_price_dates CHECK (((valid_to IS NULL) OR (valid_to >= valid_from))),
    CONSTRAINT price_amount_check CHECK ((amount >= (0)::numeric)),
    CONSTRAINT price_pkey PRIMARY KEY (price_id),
    CONSTRAINT price_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT price_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.service(service_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE public.supplier (
    supplier_id SERIAL,
    name character varying(150) NOT NULL,
    inn character varying(12) NOT NULL,
    phone character varying(20) NOT NULL,
    email character varying(100),
    contact_person character varying(100),
    CONSTRAINT supplier_inn_check CHECK (((inn) ~ '^[0-9]{10}$|^[0-9]{12}$')),
    CONSTRAINT supplier_inn_key UNIQUE (inn),
    CONSTRAINT supplier_pkey PRIMARY KEY (supplier_id)
);

CREATE TABLE public.consumable (
    consumable_id SERIAL,
    name character varying(100) NOT NULL,
    unit character varying(20) NOT NULL,
    min_stock numeric(10,2) DEFAULT 0 NOT NULL,
    CONSTRAINT consumable_min_stock_check CHECK ((min_stock >= (0)::numeric)),
    CONSTRAINT consumable_name_key UNIQUE (name),
    CONSTRAINT consumable_pkey PRIMARY KEY (consumable_id)
);

CREATE TABLE public.supply (
    supply_id SERIAL,
    branch_id integer NOT NULL,
    supplier_id integer NOT NULL,
    supply_date date DEFAULT CURRENT_DATE NOT NULL,
    status character varying(30) DEFAULT 'pending' NOT NULL,
    CONSTRAINT supply_status_check CHECK (status IN ('pending', 'in_transit', 'delivered', 'cancelled')),
    CONSTRAINT supply_pkey PRIMARY KEY (supply_id),
    CONSTRAINT supply_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT supply_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier(supplier_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE public.supply_item (
    supply_id integer NOT NULL,
    consumable_id integer NOT NULL,
    quantity numeric(10,2) NOT NULL,
    purchase_price numeric(10,2) NOT NULL,
    CONSTRAINT supply_item_purchase_price_check CHECK ((purchase_price >= (0)::numeric)),
    CONSTRAINT supply_item_quantity_check CHECK ((quantity > (0)::numeric)),
    CONSTRAINT supply_item_pkey PRIMARY KEY (supply_id, consumable_id),
    CONSTRAINT supply_item_consumable_id_fkey FOREIGN KEY (consumable_id) REFERENCES public.consumable(consumable_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT supply_item_supply_id_fkey FOREIGN KEY (supply_id) REFERENCES public.supply(supply_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE public.client (
    client_id SERIAL,
    name character varying(100) NOT NULL,
    phone character varying(20) NOT NULL,
    birth_date date,
    CONSTRAINT client_birth_date_check CHECK ((birth_date <= CURRENT_DATE)),
    CONSTRAINT client_phone_key UNIQUE (phone),
    CONSTRAINT client_pkey PRIMARY KEY (client_id)
);

CREATE TABLE public.booking (
    booking_id SERIAL,
    client_id integer NOT NULL,
    master_id integer NOT NULL,
    booking_datetime timestamp without time zone NOT NULL,
    status character varying(30) DEFAULT 'scheduled' NOT NULL,
    CONSTRAINT booking_status_check CHECK (status IN ('scheduled', 'confirmed', 'completed', 'cancelled', 'no_show')),
    CONSTRAINT booking_pkey PRIMARY KEY (booking_id),
    CONSTRAINT booking_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.client(client_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT booking_master_id_fkey FOREIGN KEY (master_id) REFERENCES public.master(master_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE public.visit (
    visit_id SERIAL,
    booking_id integer NOT NULL,
    master_id integer NOT NULL,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    total_amount numeric(10,2) DEFAULT 0 NOT NULL,
    CONSTRAINT chk_visit_time CHECK ((end_time >= start_time)),
    CONSTRAINT visit_total_amount_check CHECK ((total_amount >= (0)::numeric)),
    CONSTRAINT visit_booking_id_key UNIQUE (booking_id),
    CONSTRAINT visit_pkey PRIMARY KEY (visit_id),
    CONSTRAINT visit_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.booking(booking_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT visit_master_id_fkey FOREIGN KEY (master_id) REFERENCES public.master(master_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE public.review (
    review_id SERIAL,
    visit_id integer NOT NULL,
    rating smallint NOT NULL,
    comment text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT review_rating_check CHECK (((rating >= 1) AND (rating <= 5))),
    CONSTRAINT review_pkey PRIMARY KEY (review_id),
    CONSTRAINT review_visit_id_key UNIQUE (visit_id),
    CONSTRAINT review_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.visit(visit_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE public.booking_service (
    booking_id integer NOT NULL,
    service_id integer NOT NULL,
    CONSTRAINT booking_service_pkey PRIMARY KEY (booking_id, service_id),
    CONSTRAINT booking_service_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.booking(booking_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT booking_service_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.service(service_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE public.visit_service (
    visit_id integer NOT NULL,
    service_id integer NOT NULL,
    price_at_moment numeric(10,2) NOT NULL,
    CONSTRAINT visit_service_price_at_moment_check CHECK ((price_at_moment >= (0)::numeric)),
    CONSTRAINT visit_service_pkey PRIMARY KEY (visit_id, service_id),
    CONSTRAINT visit_service_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.service(service_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT visit_service_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.visit(visit_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE public.visit_consumable (
    visit_id integer NOT NULL,
    consumable_id integer NOT NULL,
    quantity_used numeric(10,2) NOT NULL,
    CONSTRAINT visit_consumable_quantity_used_check CHECK ((quantity_used > (0)::numeric)),
    CONSTRAINT visit_consumable_pkey PRIMARY KEY (visit_id, consumable_id),
    CONSTRAINT visit_consumable_consumable_id_fkey FOREIGN KEY (consumable_id) REFERENCES public.consumable(consumable_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT visit_consumable_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.visit(visit_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE FUNCTION public.check_required_items()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $$
DECLARE
    parent_id_column text := TG_ARGV[0];
    parent_table regclass := TG_ARGV[1]::regclass;
    item_table regclass := TG_ARGV[2]::regclass;
    affected_id integer;
    existing_id integer;
    has_items boolean;
BEGIN
    IF TG_RELID = parent_table THEN
        affected_id := (to_jsonb(NEW) ->> parent_id_column)::integer;
    ELSE
        affected_id := (to_jsonb(OLD) ->> parent_id_column)::integer;
        IF TG_OP = 'UPDATE'
           AND affected_id = (to_jsonb(NEW) ->> parent_id_column)::integer THEN
            RETURN NULL;
        END IF;
    END IF;

    EXECUTE format('UPDATE %s SET %I = %I WHERE %I = $1 RETURNING %I',
                   parent_table, parent_id_column, parent_id_column,
                   parent_id_column, parent_id_column)
        INTO existing_id USING affected_id;
    IF existing_id IS NULL THEN
        RETURN NULL;
    END IF;

    EXECUTE format('SELECT EXISTS (SELECT FROM %s WHERE %I = $1)',
                   item_table, parent_id_column)
        INTO has_items USING affected_id;
    IF NOT has_items THEN
        RAISE EXCEPTION '% id % must have at least one row in %',
            parent_table, affected_id, item_table USING ERRCODE = '23514';
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER booking_requires_items
AFTER INSERT ON public.booking
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION public.check_required_items('booking_id', 'public.booking', 'public.booking_service');

CREATE CONSTRAINT TRIGGER booking_key_requires_items
AFTER UPDATE ON public.booking
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
WHEN (OLD.booking_id IS DISTINCT FROM NEW.booking_id)
EXECUTE FUNCTION public.check_required_items('booking_id', 'public.booking', 'public.booking_service');

CREATE CONSTRAINT TRIGGER booking_service_requires_parent_items
AFTER DELETE OR UPDATE ON public.booking_service
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION public.check_required_items('booking_id', 'public.booking', 'public.booking_service');

CREATE CONSTRAINT TRIGGER visit_requires_items
AFTER INSERT ON public.visit
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION public.check_required_items('visit_id', 'public.visit', 'public.visit_service');

CREATE CONSTRAINT TRIGGER visit_key_requires_items
AFTER UPDATE ON public.visit
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
WHEN (OLD.visit_id IS DISTINCT FROM NEW.visit_id)
EXECUTE FUNCTION public.check_required_items('visit_id', 'public.visit', 'public.visit_service');

CREATE CONSTRAINT TRIGGER visit_service_requires_parent_items
AFTER DELETE OR UPDATE ON public.visit_service
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION public.check_required_items('visit_id', 'public.visit', 'public.visit_service');

CREATE CONSTRAINT TRIGGER supply_requires_items
AFTER INSERT ON public.supply
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION public.check_required_items('supply_id', 'public.supply', 'public.supply_item');

CREATE CONSTRAINT TRIGGER supply_key_requires_items
AFTER UPDATE ON public.supply
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
WHEN (OLD.supply_id IS DISTINCT FROM NEW.supply_id)
EXECUTE FUNCTION public.check_required_items('supply_id', 'public.supply', 'public.supply_item');

CREATE CONSTRAINT TRIGGER supply_item_requires_parent_items
AFTER DELETE OR UPDATE ON public.supply_item
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION public.check_required_items('supply_id', 'public.supply', 'public.supply_item');

COMMIT;
