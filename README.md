This is an example Vagrant environment for a SQL Server 2016 Express installation.

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

Install the [base box](https://github.com/rgl/windows-2016-vagrant).

Run `vagrant up` to launch the environment.


# Example queries

## List active connections

List active connections details:

```sql
select
  c.client_net_address,
  s.login_name,
  DB_NAME(s.database_id) as db_name,
  s.program_name,
  c.encrypt_option,
  c.connect_time
from
  sys.dm_exec_connections as c
  inner join sys.dm_exec_sessions as s
    on c.session_id=s.session_id
order by
  c.client_net_address, s.login_name, s.program_name
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
    on principals.principal_id=permissions.grantee_principal_id
order by
  principals.name,
  principals.type_desc,
  principals.authentication_type_desc,
  permissions.state_desc,
  permissions.permission_name
```
