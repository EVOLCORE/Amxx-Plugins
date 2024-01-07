<?php

$db_credentials = [
    'host' => "localhost",
    'user' => "",
    'password' => "",
    'name' => "",
];

try {
    // Create a PDO connection
    $dsn = "mysql:host={$db_credentials['host']};dbname={$db_credentials['name']}";
    $conn = new PDO($dsn, $db_credentials['user'], $db_credentials['password']);

    // Set the PDO error mode to exception
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    // Log the error or handle it appropriately
    error_log("Connection failed: " . $e->getMessage());
    exit("An error occurred. Please try again later.");
}

?>
