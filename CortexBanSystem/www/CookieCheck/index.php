<?php
include '../inc/config.php';

$cookie_name = "ban";
$cookie_lifetime = time() + (2 * 31536000);
$userindex = filter_input(INPUT_GET, 'uid', FILTER_SANITIZE_SPECIAL_CHARS) ?? '0';
$server = filter_input(INPUT_GET, 'srv', FILTER_SANITIZE_SPECIAL_CHARS) ?? '0';
$player_ip = filter_input(INPUT_GET, 'pip', FILTER_SANITIZE_SPECIAL_CHARS) ?? '0';

header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");

function getRandomWord(int $len = 32): string {
    return bin2hex(random_bytes($len / 2));
}

function checkVPN(string $ip, array $api_keys, array &$cache): bool {
    if (isset($cache[$ip])) {
        return $cache[$ip];
    }

    $mh = curl_multi_init();
    $handles = [];
    foreach ($api_keys as $key) {
        $ch = curl_init();
        curl_setopt_array($ch, [
            CURLOPT_URL => "http://v2.api.iphub.info/ip/{$ip}",
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => ["X-Key: $key"],
            CURLOPT_TIMEOUT => 2,
        ]);
        curl_multi_add_handle($mh, $ch);
        $handles[] = $ch;
    }

    $running = null;
    do {
        curl_multi_exec($mh, $running);
        curl_multi_select($mh);
    } while ($running);

    foreach ($handles as $ch) {
        $response = curl_multi_getcontent($ch);
        $data = json_decode($response, true);
        curl_multi_remove_handle($mh, $ch);
        curl_close($ch);

        if (isset($data["block"]) && in_array($data["block"], [1, 2])) {
            $cache[$ip] = true;
            curl_multi_close($mh);
            return true;
        }
    }

    curl_multi_close($mh);
    $cache[$ip] = false;
    return false;
}

function saveCache(array $cache, string $filename = 'cache.json'): void {
    file_put_contents($filename, json_encode($cache, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
}

function loadCache(string $filename = 'cache.json'): array {
    if (file_exists($filename)) {
        return json_decode(file_get_contents($filename), true) ?? [];
    }
    return [];
}

try {
    $cookie = $_COOKIE[$cookie_name] ?? getRandomWord();
    if (!isset($_COOKIE[$cookie_name])) {
        setcookie($cookie_name, $cookie, [
            'expires' => $cookie_lifetime,
            'path' => '/',
            'secure' => true,
            'httponly' => true,
            'samesite' => 'Lax'
        ]);
    }

    if ($userindex !== '0') {
        $cache = loadCache();
        $vpn_proxy = checkVPN($player_ip, $iphub_api_keys, $cache);
        saveCache($cache);

        $stmt = $conn->prepare("REPLACE INTO $table_check (uid, c_code, server, p_ip, vpn_proxy) VALUES (?, ?, ?, ?, ?)");
        $stmt->execute([$userindex, $cookie, $server, $player_ip, $vpn_proxy]);
    }
} catch (Exception $e) {
    error_log($e->getMessage());
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
        document.addEventListener('DOMContentLoaded', function() {
            var cookies = document.cookie.split(';');
            cookies.some(function(cookie) {
                return cookie.trim().startsWith('ban=') && (document.body.style.display = 'block');
            });
        });
    </script>
</head>
<body>
</body>
</html>
