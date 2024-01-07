<?php
session_start();
include('inc/config.php');

$error_message = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'];
    $password = $_POST['password'];

    try {
        // Prepare the SQL query
        $query = "SELECT * FROM accounts WHERE account = :username AND password = :password";
        $stmt = $conn->prepare($query);

        // Bind parameters
        $stmt->bindParam(':username', $username);
        $stmt->bindParam(':password', $password);

        // Execute the statement
        $stmt->execute();

        // Check if there is a matching row
        if ($stmt->rowCount() > 0) {
            // Authentication successful
            // Set the username in the session
            $_SESSION['username'] = $username;

            // Redirect to bans.php
            header('Location: bans.php');
            exit();
        } else {
            // Authentication failed
            // Set an error message
            $error_message = 'Invalid username or password';
        }
    } catch (PDOException $e) {
        // Log the error or handle it appropriately
        error_log("Error: " . $e->getMessage());
        exit("An error occurred. Please try again later.");
    }
}

?>

<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cortex Bans Login</title>
    <link rel="stylesheet" href="assets/css/stylelogin.css">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
</head>

<body>

    <div class="wrapper">
        <form action="" method="post">
            <h1>Login</h1>
            <?php
            // Check if there is an error message
            if (!empty($error_message)) {
                // Display the error message
                echo '<p>' . $error_message . '</p>';
            }
            ?>
            <div class="input-box">
                <input type="text" name="username" placeholder="Username" required>
                <i class='bx bxs-user'></i>
            </div>
            <div class="input-box">
                <input type="password" name="password" placeholder="Password" required>
                <i class='bx bxs-lock-alt'></i>
            </div>

            <div class="remember-forgot">
                <label><input type="checkbox" name="remember"> Remember me</label>
            </div>

            <button type="submit" class="btn">Login</button>
        </form>
    </div>

</body>

</html>
