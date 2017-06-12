require 'sqlite3'

db = SQLite3::Database.new "database.db"

rows = db.execute <<-SQL
  create table users (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    name varchar(250),
    chat_id int,
    phone varchar(50),
    command varchar(250),
    object_id integer,
    subject_id integer,
    registred boolean default 0,
    department_id integer default 1,
    rifle_id integer
  );
SQL

rows = db.execute <<-SQL
  create table donations (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id integer,
    sum integer,
    created_at date
  );
SQL

rows = db.execute <<-SQL
  create table departments (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    title varchar(250),
    emblem varchar(250)
  );
SQL

rows = db.execute <<-SQL
  create table rifles (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    title varchar(250),
    condition boolean default 1,
    user_id integer,
    comment varchar(250)
  );
SQL

rows = db.execute <<-SQL
  create table expenses (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    title varchar(250),
    sum integer,
    created_at date
  );
SQL

rows = db.execute <<-SQL
  create table votes (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    voted varchar(250),
    button_text varchar(250),
    message_id integer
  );
SQL


#ОТДЕЛЕНИЯ
db.execute "insert into departments (title) values ('Ванильный Урал')"
db.execute "insert into departments (title) values ('Zloy Ural')"

#СТВОЛЫ
db.execute "insert into rifles (title, condition, comment) values ('Мп5 №666',            0, 'Треснула стенка гирбокса')"
db.execute "insert into rifles (title, condition, comment) values ('МП5 №154',            0, 'Соскакивает спусковой крючек с контактной группы. в магазине клинят шары.')"
db.execute "insert into rifles (title, condition, comment) values ('МП5K',                1, 'Косо стреляет')"
db.execute "insert into rifles (title, condition, comment) values ('АКМ',                 1, 'Сломан приклад, в магазине клинят шары, переводчик огня плохо притягивается.')"
db.execute "insert into rifles (title, condition, comment) values ('АКсУ 75384',          1, 'Самострел, в магазине клинят шары. Заедает переводчик огня.')"
db.execute "insert into rifles (title, condition, comment) values ('АК-104',              1, 'Люфт цевья. в магазине клинят шары. ')"
db.execute "insert into rifles (title, condition, comment) values ('АКсУ SLT-13CMJ1499',  1, 'Косит, в магазине клинят шары. ')"
db.execute "insert into rifles (title, condition, comment) values ('Г36Ц',                1, 'Магазин лопнул, заклинили шары.')"
db.execute "insert into rifles (title, condition, comment) values ('АС ВАЛ (силумин)',    1, 'У магазина толоман зуб, отломался приклад, отломалась мушка. ')"
db.execute "insert into rifles (title, condition, comment) values ('АС ВАЛ (сталь)',      1, 'Слетает переводчик огня прекращая стрельбу. ')"
db.execute "insert into rifles (title, condition, comment) values ('Г3',                  0, 'Разобрана на запчасти')"
db.execute "insert into rifles (title, condition, comment) values ('ХК-94',	          0, 'Треснули стенки гирбокса')"
db.execute "insert into rifles (title, condition, comment) values ('М4A1',                0, 'Треснули стенки гербокса, отвалилось крепление штыка, разваливается цивье, перекосило мушку и вообще он говно.')"
db.execute "insert into rifles (title, condition, comment) values ('Г36',                 1, 'Награда за совместный просмотр кетайских мультиков про пидоров.')"


