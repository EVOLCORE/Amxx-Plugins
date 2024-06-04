<?php
include '../inc/config.php';

$cookie_name = "ban";
$userindex = isset($_GET['uid']) ? intval($_GET['uid']) : 0;
$server = isset($_GET['srv']) ? htmlspecialchars($_GET['srv'], ENT_QUOTES, 'UTF-8') : '0';
$player_ip = isset($_GET['pip']) ? htmlspecialchars($_GET['pip'], ENT_QUOTES, 'UTF-8') : '0';

header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");

function getRandomWord($len = 32) {
    return bin2hex(random_bytes($len / 2));
}

function checkVPN($ip, $api_keys) {
    $multi_handle = curl_multi_init();
    $curl_handles = [];
    $results = [];
    
    foreach ($api_keys as $api_key) {
        $ch = curl_init();
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => ["X-Key: $api_key"],
            CURLOPT_URL => "http://v2.api.iphub.info/ip/{$ip}"
        ]);
        curl_multi_add_handle($multi_handle, $ch);
        $curl_handles[] = $ch;
    }

    $running = null;
    do {
        curl_multi_exec($multi_handle, $running);
        curl_multi_select($multi_handle);
    } while ($running > 0);

    foreach ($curl_handles as $ch) {
        $result = curl_multi_getcontent($ch);
        $results[] = json_decode($result, true);
        curl_multi_remove_handle($multi_handle, $ch);
    }

    curl_multi_close($multi_handle);

    foreach ($results as $result) {
        if (isset($result["block"]) && ($result["block"] == 1 || $result["block"] == 2)) {
            return 1;
        }
    }
    return 0;
}

if ($userindex !== 0) {
    if (!isset($_COOKIE[$cookie_name])) {
        $cookie = getRandomWord();
        setcookie($cookie_name, $cookie, time() + (2 * 31536000), "/", "", true, true); // Secure and HttpOnly flags
    } else {
        $cookie = $_COOKIE[$cookie_name];
    }

    $vpn_proxy = checkVPN($player_ip, $iphub_api_keys);

    $stmt = $conn->prepare("REPLACE INTO $table_check (uid, c_code, server, p_ip, vpn_proxy) VALUES (?, ?, ?, ?, ?)");
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
    <style>
        body { display: none; }
    </style>
    <script>
        function checkCookie() {
            var cookieName = 'ban';
            var cookies = document.cookie.split('; ');
            var cookieFound = cookies.some(cookie => cookie.split('=')[0] === cookieName);

            if (!cookieFound) {
                location.reload();
            } else {
                document.body.style.display = 'block';
            }
        }
        window.onload = checkCookie;
    </script>
</head>
<body>
</body>
</html>
