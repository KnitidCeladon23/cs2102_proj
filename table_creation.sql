CREATE TABLE Employees (
    eid                 Serial,
    employee_name       TEXT NOT NULL,
    employee_address    TEXT NOT NULL,
    email               TEXT NOT NULL unique,
    depart_date         DATE,
    join_date           DATE NOT NULL,  
    phone               TEXT NOT NULL unique,
    PRIMARY KEY         (eid)
);
 
CREATE TABLE Instructors (
    eid INTEGER primary key references Employees
        on delete cascade
);
 
CREATE TABLE Part_time_Emp (
    eid integer primary key references Employees
        on delete cascade,
    hourly_rate numeric not null
);
 
create table Full_time_Emp (
    eid integer primary key references Employees
        on delete cascade,
    monthly_salary numeric not null
);
 
create table Part_time_instructors (
    eid integer primary key references Instructors
        on delete cascade   
);
 
create table Full_time_instructors (
    eid integer primary key references Instructors
        on delete cascade   
);
 
create table Managers (
    eid integer primary key references Full_time_Emp
        on delete cascade
);
 
CREATE TABLE Course_areas (
    area_name TEXT,
    eid INTEGER,
    PRIMARY KEY (area_name),
    foreign key (eid) references Managers
);
 
create table Administrators (
    eid integer primary key references Full_time_Emp
        on delete cascade
);
 
create table Employee_pay_slips (
    payment_date Date,
    amount numeric,
    num_work_hours int check (num_work_hours <= 30),
    num_work_days int not null,
    eid int,
    primary key (payment_date, eid),
    foreign key (eid) references Employees
        on delete cascade
);
 
create table Specialises (
    eid integer,
    area_name text references Course_areas,
    primary key (eid, area_name),
    foreign key (eid) references Instructors
        on delete cascade
);
 
create table Customers (
    cust_id SERIAL,
    customer_address TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT NOT NULL,
    PRIMARY KEY (cust_id)
);
 
create table Credit_cards (
    cc_number INTEGER,
    cvv INTEGER UNIQUE NOT NULL,
    cc_expiry_date DATE NOT NULL,
    PRIMARY KEY (cc_number)
);
 
create table Owns (
    cc_number INTEGER,
    cust_id INTEGER,
    PRIMARY KEY (cc_number, cust_id),
    FOREIGN KEY (cc_number) REFERENCES Credit_cards,
    FOREIGN KEY (cust_id) REFERENCES Customers
);
 
CREATE TABLE Rooms (
    rid                 INTEGER,
    room_location       TEXT not null,
    seating_capacity    INTEGER not null,
    PRIMARY KEY (rid)
);
 
CREATE TABLE Course_packages (
    package_id              SERIAL,
    num_free_registrations  INTEGER not null,
    sale_start_date         DATE not null,
    sale_end_date           DATE not null,
    pkg_name                TEXT not null,
    price                   NUMERIC not null,
    PRIMARY KEY             (package_id),
);
 
CREATE TABLE Buys (
    buys_date                   DATE,
    package_id                  INTEGER,
    num_remaining_redemptions   INTEGER not null,
    cc_number                   INTEGER,
    cust_id                     INTEGER,
    PRIMARY KEY                 (buys_date, package_id, cust_id),
    FOREIGN KEY                 (cc_number, cust_id) REFERENCES Owns,
    FOREIGN KEY                 (package_id) REFERENCES Course_packages
);
 
CREATE TABLE Courses (
    course_id               Serial UNIQUE NOT NULL,
    duration                NUMERIC(2,2) NOT NULL,
    course_description      TEXT NOT NULL,
    title                   TEXT NOT NULL, 
    area_name               TEXT,
    PRIMARY KEY             (course_id, area_name),
    foreign key             (area_name) references Course_areas
);
 
CREATE TABLE CourseOfferings (
    course_offering_id          TEXT UNIQUE NOT NULL,
    launch_date                 DATE NOT NULL,
    course_start_date           DATE NOT NULL,
    course_end_date             DATE NOT NULL,
    registration_deadline       DATE NOT NULL
                                constraint offerings_registration_deadline 
                                check(DATE_PART('day', course_start_date::DATE) 
                                - DATE_PART('day', registration_deadline::DATE) 
                                >= 10),
    target_number_registrations INTEGER NOT NULL,
    seating_capacity            INTEGER NOT NULL,
    fees                        NUMERIC NOT NULL,
    course_id                   INTEGER,
    eid                         INTEGER,
    PRIMARY KEY                 (course_offering_id),
    FOREIGN KEY                 (eid) references Administrators(eid),
    FOREIGN KEY                 (course_id) references Courses(course_id) ON DELETE CASCADE
);
 
CREATE TABLE OfferingSessions (
    sid             INTEGER NOT NULL,
    start_time      INTEGER
                    constraint sessions_start_time check ((start_time >= 9 and start_time < 12) or (start_time >= 14 and start_time <= 18)),
    end_time        INTEGER
                    constraint sessions_end_time check ((end_time >= 9 and end_time < 12) or (end_time >= 14 and end_time <= 18)),
    sessions_date   DATE
                    constraint weekday_constraint check (DATE_PART('isodow', sessions_date::DATE) in (2,3,4,5,6)),
    course_offering_id TEXT,
    PRIMARY KEY     (sid, course_offering_id),
    FOREIGN KEY     (course_offering_id) REFERENCES CourseOfferings(course_offering_id) ON DELETE CASCADE
);
 
CREATE TABLE Conducts (
    rid         INTEGER NOT NULL,
    sid         INTEGER NOT NULL,
    eid         INTEGER NOT NULL,
    course_offering_id TEXT NOT NULL,
    PRIMARY KEY (rid, sid, course_offering_id, eid),
    FOREIGN KEY (rid) REFERENCES Rooms(rid),
    FOREIGN KEY (sid, course_offering_id) REFERENCES OfferingSessions(sid, course_offering_id),
    FOREIGN KEY (eid) REFERENCES Instructors(eid)
);
 
create table Registers (
    register_date   DATE,
    cc_number       INTEGER NOT NULL,
    cust_id         INTEGER NOT NULL,
    sid             INTEGER NOT NULL,
    course_offering_id TEXT NOT NULL,
    PRIMARY KEY     (cc_number, cust_id, register_date, sid, course_offering_id),
    FOREIGN KEY     (cc_number, cust_id) REFERENCES Owns(cc_number, cust_id),
    FOREIGN KEY     (sid, course_offering_id ) REFERENCES OfferingSessions(sid, course_offering_id)
 );
 
create table Cancels (
    cancel_date     DATE,
    sid             INTEGER UNIQUE NOT NULL,
    course_offering_id TEXT NOT NULL,
    cust_id         INTEGER UNIQUE NOT NULL,
    refund_amount   NUMERIC NOT NULL
                    constraint refund_constraint check (refund_amount >= 0),
    package_credit  INTEGER NOT NULL
                    constraint package_credit_constraint check (package_credit >= 0),
    PRIMARY KEY     (cancel_date, sid, cust_id),
    FOREIGN KEY     (sid, course_offering_id) REFERENCES OfferingSessions(sid, course_offering_id),
    FOREIGN KEY     (cust_id) REFERENCES Customers(cust_id)    
);
 
CREATE TABLE Redeems (
    buys_date       DATE NOT NULL,
    redeems_date    DATE NOT NULL,
    sid             INTEGER NOT NULL,
    course_offering_id TEXT NOT NULL,
    PRIMARY KEY     (redeems_date, buys_date, sid, course_offering_id),
    FOREIGN KEY     (buys_date) REFERENCES Buys(buys_date),
    FOREIGN KEY     (sid, course_offering_id) REFERENCES OfferingSessions(sid, course_offering_id)
);