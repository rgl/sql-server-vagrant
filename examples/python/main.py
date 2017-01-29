import pyodbc

# see http://mkleehammer.github.io/pyodbc/
def sql_execute_scalar(sql):
    with pyodbc.connect('DRIVER={SQL Server};SERVER=localhost;PORT=1433;DATABASE=master;UID=alice.doe;PWD=HeyH0Password') as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            return cursor.fetchval()

print('SQL Server Version:')
print(sql_execute_scalar('select @@version'))

print('SQL Server User Name (alice.doe; username/password credentials; TCP/IP connection):')
print(sql_execute_scalar('select suser_name()'))
