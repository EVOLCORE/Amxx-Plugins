<?php
$db_credentials = [
    'host' => "localhost",
    'user' => "root",
    'password' => "",
    'name' => "",
];

try {
    $dsn = "mysql:host={$db_credentials['host']};dbname={$db_credentials['name']}";
    $conn = new PDO($dsn, $db_credentials['user'], $db_credentials['password']);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    error_log("Connection failed: " . $e->getMessage());
    exit("An error occurred. Please try again later.");
}

// Define IPHub API keys
$iphub_api_keys = [
    'MjQwMTk6WnM2Q0dneVZEREt3Yk1DYjA1MlBTalZvMDJrVVJTV2Q=',
    'MjQwMjA6RlR4YUNzekdMTWIzTFljRUlXOUdzcktRTlkxOUx5d1M=',
    'MTAzNTQ6TGgwSUhpZmRCS3BaVUEwaVY3bWhhUDcxbWpZQkMyZ2o=',
    'MjQwMjE6UGpVbnd6bkVXNlY1d3drV1lwVThDbGdtS3F1NGhqY3I='
];

// Define table name
$table_check = "db_ccheck";
$ban_table = "cortex_bans"
?>
