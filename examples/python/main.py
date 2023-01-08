import os
import pyodbc

# see http://mkleehammer.github.io/pyodbc/
def sql_execute_scalar(connection_string, sql):
    with pyodbc.connect(connection_string) as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            return cursor.fetchval()

connection_string = 'DRIVER={ODBC Driver 18 for SQL Server};SERVER=%s;PORT=1433;DATABASE=master;UID=alice.doe;PWD=HeyH0Password' % os.environ['COMPUTERNAME']

print('SQL Server Version:')
print(sql_execute_scalar(connection_string, 'select @@version'))

print('SQL Server User Name (alice.doe; username/password credentials; TCP/IP connection):')
print(sql_execute_scalar(connection_string, 'select suser_name()'))

print('Is this SQL Server connection encrypted? (alice.doe; username/password credentials; Encrypted TCP/IP connection):')
print(sql_execute_scalar(connection_string + ';Encrypt=strict', 'select encrypt_option from sys.dm_exec_connections where session_id=@@SPID'))
