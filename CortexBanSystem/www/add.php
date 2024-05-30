<?php
session_start();
include_once('inc/config.php');

if (isset($_POST['add'])) {
    $nick = $_POST['player_nick'];
    $steamid = $_POST['player_id'];
    $ip = $_POST['player_ip'];
    $reason = $_POST['ban_reason'];
    $length = $_POST['ban_length'];
    $server_ip = $_POST['server_ip'];
    $ban_type = "";
    $_SESSION['error'] = "";

    if (empty($nick)) {
        $_SESSION['error'] .= "* Nick cannot be empty<br>";
    }
    if (empty($steamid)) {
        if (empty($ip)) {
            $_SESSION['error'] .= "* IP and SteamID cannot be both empty.<br>";
        }
    } else {
        $ban_type = "S";
        if (strcmp("STEAM_", substr($steamid, 0, 6)) != 0) {
            $_SESSION['error'] .= "* SteamID is invalid.<br>";
        }
    }
    if (empty($reason)) {
        $_SESSION['error'] .= "* Reason cannot be empty.<br>";
    }
    if ($length !== '0' && empty($length)) {
        $_SESSION['error'] .= "* Length cannot be empty.<br>";
    } else {
        if ($length < 0) {
            $_SESSION['error'] .= "* Ban length is invalid.<br>";
        }
    }

    if (empty($server_ip)) {
        $_SESSION['error'] .= "* Server IP cannot be empty.<br>";
    }

    if (empty($_SESSION['error'])) {
        try {
            $stmt = $conn->prepare("INSERT INTO $ban_table 
                (player_ip, player_id, player_nick, admin_ip, admin_nick, admin_id, 
                ban_type, ban_reason, ban_created, ban_length, ban_kicks, expired, server_ip) 
                VALUES (:ip, :steamid, :nick, 'IP_WEBSITE', 'WEBSITE', 'STEAM_WEBSITE', 
                :ban_type, :reason, UNIX_TIMESTAMP(), :length, 0, 0, :server_ip)");

            $stmt->bindParam(':ip', $ip);
            $stmt->bindParam(':steamid', $steamid);
            $stmt->bindParam(':nick', $nick);
            $stmt->bindParam(':ban_type', $ban_type);
            $stmt->bindParam(':reason', $reason);
            $stmt->bindParam(':length', $length, PDO::PARAM_INT);
            $stmt->bindParam(':server_ip', $server_ip);

            if ($stmt->execute()) {
                $_SESSION['success'] = 'Record added successfully';
            } else {
                $_SESSION['error'] = 'Failed to add record';
            }
        } catch (PDOException $e) {
            $_SESSION['error'] = "Database error: " . $e->getMessage();
        }
    }

    // Remove substr() function call, as it's not needed here

} else {
    $_SESSION['error'] = 'Fill up add form first';
}

// Redirect only after all processing is done
header('location: bans.php');
exit();
?>
