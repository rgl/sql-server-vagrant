This is an example Vagrant environment for a SQL Server 2014 Express installation.

It will:

* Change the SQL Server Settings
  * Mixed mode authentication
  * Allow TCP/IP connections
* Create Users
  * SQL Server Users: `alice.doe` (in the `sysadmin` role), `carol.doe`, `eve.doe` and `grace.doe`.
  * Windows Users: `bob.doe`, `dave.doe`, `frank.doe` and `henry.doe`.
  * All have the `HeyH0Password` password.
* Create the `TheSimpsons` Database
  * Create the `db_executor` database role with permissions to execute stored procedures.
  * Add users to database roles
    * `carol.doe` in the `db_datawriter`, `db_datareader` and `db_executor` roles.
    * `eve.doe` in the `db_datareader` and `db_executor` roles.
* Run PowerShell, Python, Java and C# [examples](examples/).


# Usage

Install the [base box](https://github.com/rgl/windows-2016-vagrant).

Run `vagrant up` to launch the environment.
