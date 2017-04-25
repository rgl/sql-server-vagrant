package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	_ "github.com/denisenkom/go-mssqldb"
)

func sqlExecuteScalar(connectionString string, sqlStatement string) string {
	db, err := sql.Open("sqlserver", connectionString)
	if err != nil {
		log.Fatal("Open connection failed:", err.Error())
	}
	defer db.Close()

	err = db.Ping()
	if err != nil {
		log.Fatal("Ping failed:", err.Error())
	}

	var scalar string

	err = db.QueryRow(sqlStatement).Scan(&scalar)
	if err != nil {
		log.Fatal("Scan failed:", err.Error())
	}

	return scalar
}

func main() {
	connectionString := fmt.Sprintf(
		"Server=%s; Port=1433; Database=master; User ID=alice.doe; Password=HeyH0Password",
		os.Getenv("COMPUTERNAME"))

	fmt.Println("SQL Server Version:")
	fmt.Println(sqlExecuteScalar(connectionString, "select @@version"))

	fmt.Println("SQL Server User Name (alice.doe; username/password credentials; TCP/IP connection):")
	fmt.Println(sqlExecuteScalar(connectionString, "select suser_name()"))

	fmt.Println("Is this SQL Server connection encrypted? (alice.doe; username/password credentials; Encrypted TCP/IP connection):")
	fmt.Println(sqlExecuteScalar(connectionString+"; Encrypt=true", "select encrypt_option from sys.dm_exec_connections where session_id=@@SPID"))
}
