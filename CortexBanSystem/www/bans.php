<?php
session_start();

if (!isset($_SESSION['username'])) {
    header('Location: index.php');
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['logout'])) {
    session_destroy();
    header('Location: index.php');
    exit();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
	<meta http-equiv="Permissions-Policy" content="attribution-reporting=('none'), run-ad-auction=('none'), join-ad-interest-group=('none'), browsing-topics=('none')">
    <title>Cortex Ban System</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css"
        integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
	<link rel="stylesheet" href="assets/css/styles.css">
	<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.7.1/jquery.min.js"integrity="sha512-v2CJ7UaYy4JwqLDIrZUI/4hqeoQieOmAZNXBeQyjo21dadnwR+8ZaIJVT8EE2iyI61OV8e6M8PP2/4hpQINQ/g==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
</head>
<body>
<div class="row justify-content-end mt-3 mr-3">
    <div class="col-md-6 text-right">
        <a href="?logout" class="btn btn-danger">Logout</a>
    </div>
</div>

<div class="row justify-content-center">
    <div class="col-12 text-center">
        <img src="https://i.postimg.cc/7ZhFSkXz/logo.png" class="logo">
    </div>
</div>

<div class="row justify-content-center mt-3 mb-3">
    <div class="col-md-6">
        <div class="input-group">
            <input type="text" class="form-control" id="searchInput" placeholder="Search by Nick or SteamID">
            <div class="input-group-append">
                <button class="btn btn-outline-secondary" type="button" onclick="searchBans()">Search</button>
            </div>
        </div>
    </div>
</div>

<table class="table table-striped table-dark">
    <thead>
    <tr>
        <th scope="col">#</th>
        <th scope="col">Nick</th>
        <th scope="col">SteamID</th>
        <th scope="col">IP</th>
        <th scope="col">Time</th>
        <th scope="col">Length</th>
        <th scope="col">Reason</th>
        <th scope="col">Admin</th>
        <th scope="col">Admin SteamID</th>
        <th scope="col">Server</th>
        <th scope="col">Actions</th>
    </tr>
    </thead>
    <tbody id="ccs">

<?php
require_once 'geoip2.phar';
use GeoIp2\Database\Reader;

require_once 'inc/config.php';

$resultsPerPage = 15;
$currentPage = isset($_GET['page']) ? (int)$_GET['page'] : 1;

try {
    $conn = new mysqli($db_credentials['host'], $db_credentials['user'], $db_credentials['password'], $db_credentials['name']);

    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }

    $sqlCount = "SELECT COUNT(*) AS count FROM cortex_bans";
    $resultCount = $conn->query($sqlCount);
    $rowCount = $resultCount->fetch_assoc()['count'];
    $totalPages = ceil($rowCount / $resultsPerPage);

    $startLimit = ($currentPage - 1) * $resultsPerPage;
    $searchTerm = isset($_GET['search']) ? $_GET['search'] : '';

	$sql = "SELECT * FROM cortex_bans WHERE name LIKE ? OR authid LIKE ? ORDER BY unbantime DESC LIMIT $startLimit, $resultsPerPage";
    $stmt = $conn->prepare($sql);
    $searchPattern = "%$searchTerm%";
    $stmt->bind_param("ss", $searchPattern, $searchPattern);
    $stmt->execute();
    $result = $stmt->get_result();
    $stmt->close();

    $bans = [];

    if ($result->num_rows > 0) {
        $i = $startLimit + 1;
        while ($row = $result->fetch_assoc()) {
            $bans[] = [
                'nick' => $row['name'],
                'steamid' => $row['authid'],
                'ip' => $row['ip'],
                'time' => ($row['bantime'] == -1) ? 'PERMANENT' : $row['bantime'] . ' minutes',
                'length' => $row['unbantime'],
                'reason' => $row['reason'],
                'admin' => $row['adminname'],
                'adminsteamid' => ($row['adminauthid'] == 'PANEL') ? 'NONE' : $row['adminauthid'],
                'server' => $row['serverip'],
            ];

            $countryCode = getCountryFromIP($row['ip']);
            $countryFlagPath = "/images/flags/{$countryCode}.png";

            ?>
            <tr>
                <th scope='row'><?= $i ?></th>
                <td><?= $row['name'] ?></td>
                <td><?= $row['authid'] ?></td>
                <td><img src='<?= $countryFlagPath ?>' class='flag'><?= $row['ip'] ?></td>
                <td><?= ($row['bantime'] == -1) ? 'PERMANENT' : $row['bantime'] . ' minutes' ?></td>
                <td><?= $row['unbantime'] ?></td>
                <td><?= $row['reason'] ?></td>
                <td><?= $row['adminname'] ?></td>
                <td><?= $row['adminauthid'] ?></td>
                <td><?= $row['serverip'] ?></td>
                <td><button class='unban-btn' data-steamid="<?= $row['authid'] ?>">Unban</button></td>
            </tr>
            <?php
            $i++;
        }
    }

    if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['unbanSteamID'])) {
        $unbanSteamID = $_POST['unbanSteamID'];

        $sql = "DELETE FROM cortex_bans WHERE authid = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("s", $unbanSteamID);
        $stmt->execute();
        $stmt->close();

        header("Location: {$_SERVER['PHP_SELF']}");
        exit();
    }

    $conn->close();
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}

function getCountryFromIP($ip) {
    // Specify the path to the GeoLite2 City database
    $databasePath = __DIR__ . '/GeoLite2-City.mmdb';

    try {
        // Create a GeoIP2 reader
        $reader = new Reader($databasePath);

        // Get the country information based on the IP address
        $record = $reader->city($ip);

        // Return the country code (two letters)
        return $record->country->isoCode;
    } catch (Exception $e) {
        // Handle exceptions, for example, log the error
        return 'Unknown';
    }
}
?>

    </tbody>
</table>

<div class="pagination">
    <?php
    for ($i = 1; $i <= $totalPages; $i++) {
        echo '<a href="?page=' . $i . '"' . ($i == $currentPage ? ' class="active"' : '') . '>' . $i . '</a>';
    }
    ?>
</div>

<script>
	// Debounce function
    var debounce = function (func, delay) {
        var timeout;
        return function () {
            var context = this, args = arguments;
            clearTimeout(timeout);
            timeout = setTimeout(function () {
                func.apply(context, args);
            }, delay);
        };
    };

    // Existing searchBans function
    function searchBans() {
        document.querySelectorAll('.pagination a').forEach(link => link.classList.remove('active'));
        var input, filter, table, tr, td1, td2, i, txtValue1, txtValue2;
        input = document.getElementById("searchInput");
        filter = input.value.toUpperCase();
        table = document.getElementById("ccs");
        tr = table.getElementsByTagName("tr");

        for (i = 0; i < tr.length; i++) {
            // Assuming you want to search by Nick (index 1) and SteamID (index 2)
            td1 = tr[i].getElementsByTagName("td")[0];
            td2 = tr[i].getElementsByTagName("td")[1];

            if (td1 || td2) {
                txtValue1 = td1.textContent || td1.innerText;
                txtValue2 = td2.textContent || td2.innerText;

                if (txtValue1.toUpperCase().indexOf(filter) > -1 || txtValue2.toUpperCase().indexOf(filter) > -1) {
                    tr[i].style.display = "";
                } else {
                    tr[i].style.display = "none";
                }
            }
        }
    }

    // Debounce the search function
    var debouncedSearch = debounce(searchBans, 300);

    // Existing event listener for searchBans
    var input = document.getElementById("searchInput");
    input.addEventListener("input", debouncedSearch);

    var formSubmitted = false;
</script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.13.2/jquery-ui.min.js" integrity="sha512-57oZ/vW8ANMjR/KQ6Be9v/+/h6bq9/l3f0Oc7vn6qMqyhvPd1cvKBRWWpzu0QoneImqr2SkmO4MSqU+RpHom3Q==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
<script>
    $(document).ready(function () {
        var page = 1;

        function loadData() {
			var searchTerm = document.getElementById("searchInput").value;
			var url = '<?= $_SERVER['PHP_SELF'] ?>' + '?page=' + page + '&search=' + searchTerm;

			$.ajax({
				url: url,
				method: 'GET',
				dataType: 'html',
				success: function (data) {
					var start = data.indexOf('<tbody id="ccs">') + 16;
					var end = data.indexOf('</tbody>', start);
					var newContent = data.substring(start, end);
					$('#ccs').html(newContent);
				},
				error: function (xhr, status, error) {
					console.error('Error fetching data:', error);
				}
			});
		}

        // Initial load
        loadData();

        // Handle pagination click
        $(document).on('click', '.pagination a', function (e) {
            e.preventDefault();

            // Remove "active" class from all pagination links
            $('.pagination a').removeClass('active');

            // Add "active" class to the clicked link
            $(this).addClass('active');

            page = parseInt($(this).attr('href').split('=')[1]);
            loadData();
        });

		// Handle Unban button click
		$(document).on('click', '.unban-btn', function () {
			var steamid = $(this).data('steamid');
			unbanPlayer(steamid);
		});

        // Regular refresh
        setInterval(function () {
            loadData();
        }, 5000);
    });

    function unbanPlayer(steamid) {
        if (confirm("Are you sure you want to unban this player?")) {
            var formData = {
                unbanSteamID: steamid
            };

            $.ajax({
                type: 'POST',
                url: '',
                data: formData,
                success: function () {
                    // Reload the data after successful unban
                    loadData();
                },
                error: function (xhr, status, error) {
                    console.error('Error during unban:', error);
                }
            });
        }
    }
</script>
<footer class="footer mt-5">
    <div class="container text-center">
        <hr class="my-4">
        <p class="text-muted mb-0">Cortex Ban System &copy; 2023</p>
        <p class="text-muted mb-0">Powered by <a href="https://www.cs-down.me/" target="_blank" style="color: #3498db; text-decoration: none; font-weight: bold;">mIDnight</a></p>
		<br>
    </div>
</footer>
</body>
</html>
