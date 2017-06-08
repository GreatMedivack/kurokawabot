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
    registred boolean default 0
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
  create table rifles (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    title varchar(250),
    condition integer,
    user_id integer,
    comment varchar(250)
  );
SQL



