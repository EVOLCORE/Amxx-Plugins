<?php
include '../inc/config.php';

$cookie_name = "ban";
$userindex = $_GET['uid'] ?? 0;
$server = $_GET['srv'] ?? '0';
$player_ip = $_GET['pip'] ?? '0';

function getRandomWord($len = 32) {
    return substr(str_shuffle(str_repeat('abcdefghijklmnopqrstuvwxyz', $len)), 0, $len);
}

function checkVPN($ip, $api_keys) {
    foreach ($api_keys as $api_key) {
        $ch = curl_init();
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => ["X-Key: $api_key"],
            CURLOPT_URL => "http://v2.api.iphub.info/ip/{$ip}"
        ]);

        $result = curl_exec($ch);
        curl_close($ch);
        $result = json_decode($result, true);

        if (isset($result["block"]) && ($result["block"] == 1 || $result["block"] == 2)) {
            return 1; // VPN or proxy detected
        }
    }
    return 0; // Not a VPN or proxy
}

if ($userindex != 0) {
    if (!isset($_COOKIE[$cookie_name])) {
        $cookie = getRandomWord();
        setcookie($cookie_name, $cookie, time() + (2 * 31536000)); // 2 years
    } else {
        $cookie = $_COOKIE[$cookie_name];
    }

    $vpn_proxy = checkVPN($player_ip, $iphub_api_keys);

    $stmt = $conn->prepare("REPLACE INTO $table_check (id, uid, c_code, server, p_ip, vpn_proxy) VALUES (NULL, ?, ?, ?, ?, ?)");
    $stmt->execute([$userindex, $cookie, $server, $player_ip, $vpn_proxy]);

    if ($stmt->rowCount()) {
        echo "Welcome to server";
    } else {
        echo "Error: Could not update the record.";
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Redirecting</title>
    <script>
        function checkCookie() {
            var cookieName = 'ban';
            var cookies = document.cookie.split('; ');
            var cookieFound = false;

            for (var i = 0; i < cookies.length; i++) {
                var cookie = cookies[i].split('=');
                if (cookie[0] === cookieName) {
                    cookieFound = true;
                    break;
                }
            }

            if (!cookieFound) {
                location.reload();
            }
        }
        window.onload = checkCookie;
    </script>
</head>
<body>
</body>
</html>
