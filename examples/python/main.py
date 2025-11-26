import os
import mssql_python

# see https://github.com/microsoft/mssql-python
# see https://github.com/microsoft/mssql-python/wiki/Connection-to-SQL-Database
def sql_execute_scalar(connection_string, sql):
    with mssql_python.connect(connection_string) as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            return cursor.fetchval()

connection_string = 'Server=%s,1433;Database=master;UID=alice.doe;PWD=HeyH0Password' % os.environ['COMPUTERNAME']

print('SQL Server Version:')
print(sql_execute_scalar(connection_string, 'select @@version'))

print('SQL Server User Name (alice.doe; username/password credentials; TCP/IP connection):')
print(sql_execute_scalar(connection_string, 'select suser_name()'))

print('Is this SQL Server connection encrypted? (alice.doe; username/password credentials; Encrypted TCP/IP connection):')
print(sql_execute_scalar(connection_string + ';Encrypt=strict', 'select encrypt_option from sys.dm_exec_connections where session_id=@@SPID'))
