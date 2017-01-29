// see https://github.com/Microsoft/mssql-jdbc
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class Example {
    public static void main(String[] args) throws Exception {
        String connectionString = "jdbc:sqlserver://localhost:1433;database=master;user=alice.doe;password=HeyH0Password;";

        System.out.println("SQL Server Version:");
        System.out.println(queryScalar(connectionString, "select @@version"));

        System.out.println("SQL Server User Name (alice.doe; username/password credentials; TCP/IP connection):");
        System.out.println(queryScalar(connectionString, "select suser_name()"));
    }

    private static String queryScalar(String connectionString, String sql) throws Exception {
        try (Connection connection = DriverManager.getConnection(connectionString)) {
            try (Statement statement = connection.createStatement()) {
                try (ResultSet resultSet = statement.executeQuery(sql)) {
                    if (resultSet.next()) {
                        return resultSet.getString(1);
                    }
                    return null;
                }
            }
        }
    }
}
