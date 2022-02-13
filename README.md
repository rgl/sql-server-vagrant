This is an example Vagrant environment for a SQL Server 2019 Express installation.

It will:

* Change the SQL Server Settings
  * Mixed mode authentication
  * Allow TCP/IP connections
  * Allow encrypted connections (using a private CA)
* Create Users
  * SQL Server Users: `alice.doe` (in the `sysadmin` role), `carol.doe`, `eve.doe` and `grace.doe`.
  * Windows Users: `bob.doe`, `dave.doe`, `frank.doe` and `henry.doe`.
  * All have the `HeyH0Password` password.
* Create the `TheSimpsons` Database
  * Create the `db_executor` database role with permissions to execute stored procedures.
  * Add users to database roles
    * `carol.doe` in the `db_datawriter`, `db_datareader` and `db_executor` roles.
    * `eve.doe` in the `db_datareader` and `db_executor` roles.
* Install the [DBeaver](http://dbeaver.jkiss.org/) Universal SQL Client.
* Run PowerShell, Python, Java, C# and Go [examples](examples/).


# Usage

Install the [Windows 2022 base box](https://github.com/rgl/windows-vagrant).

Run `vagrant up --no-destroy-on-error` to launch the environment.


# Example queries

## List active connections

List active connections details:

```sql
select
  c.client_net_address,
  s.login_name,
  db_name(s.database_id) as database_name,
  s.program_name,
  c.encrypt_option,
  c.connect_time
from
  sys.dm_exec_connections as c
  inner join sys.dm_exec_sessions as s
    on c.session_id = s.session_id
order by
  c.client_net_address,
  s.login_name,
  s.program_name
```

**NB** you can customize what appears on `s.program_name` by setting the `Application Name`
connection string property, e.g., `Application Name=Example Application;`.

## List database principals permissions

```sql
select
  principals.principal_id,
  principals.name,
  principals.type_desc, 
  principals.authentication_type_desc,
  permissions.state_desc,
  permissions.permission_name
from
  sys.database_principals as principals
  inner join sys.database_permissions as permissions
    on principals.principal_id = permissions.grantee_principal_id
order by
  principals.name,
  principals.type_desc,
  principals.authentication_type_desc,
  permissions.state_desc,
  permissions.permission_name
```

## List database schema tables row count

```sql
select
  schema_name(schema_id) as schema_name,
  t.name as table_name,
  sum(p.rows) as row_count
from
  sys.tables as t
  inner join sys.partitions as p
    on t.object_id = p.object_id
    and p.index_id in (0, 1)
group by
  schema_name(schema_id),
  t.name
```

## List database row count and storage usage

```sql
select
  sum(p.rows) as row_count,
  (select sum(case when type = 1 then size end) * cast(8 * 1024 as bigint) from sys.master_files where database_id = db_id()) as data_size_bytes,
  (select sum(case when type = 0 then size end) * cast(8 * 1024 as bigint) from sys.master_files where database_id = db_id()) as log_size_bytes
from
  sys.tables as t
  inner join sys.partitions as p
    on t.object_id = p.object_id
    and p.index_id in (0, 1)
```

## List databases storage usage

```sql
select
  db_name(database_id) as database_name,
  sum(case when type = 1 then size end) * cast(8 * 1024 as bigint) as data_size_bytes,
  sum(case when type = 0 then size end) * cast(8 * 1024 as bigint) as log_size_bytes
from
  sys.master_files
group by
  database_id
```
