<?php
session_start();

if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['logout'])) {
    session_destroy();
    header('Location: index.php');
    exit();
}

require_once 'inc/config.php';

$cssFilePath = 'assets/css/styles.css';
$version = md5_file($cssFilePath);
$cssUrl = "assets/css/styles.css?v=$version";
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
                <script src="https://kit.fontawesome.com/66a103f21e.js" crossorigin="anonymous"></script>
	<link rel="stylesheet" href="<?php echo $cssUrl; ?>">
	<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.7.1/jquery.min.js"integrity="sha512-v2CJ7UaYy4JwqLDIrZUI/4hqeoQieOmAZNXBeQyjo21dadnwR+8ZaIJVT8EE2iyI61OV8e6M8PP2/4hpQINQ/g==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
	<script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js"></script>
</head>
<body>
<div class="row justify-content-end mt-3 mr-3">
    <div class="col-md-6 text-right">
        <!-- Button to trigger the modal -->
        <button type="button" class="btn btn-secondary icon-link-hover" style="font-size: 23px; margin-right: 10px;" data-toggle="modal" data-target="#addnew">
            <i class="fa-solid fa-plus"></i>
        </button>
        <a href="?logout" class="btn btn-secondary icon-link-hover" style="font-size: 23px;">
            <i class="fa-solid fa-arrow-right-from-bracket"></i>
        </a>
    </div>
</div>

<!-- Include the modal -->
<?php include('inc/add_modal.php'); ?>

<div class="row justify-content-center">
    <div class="col-12 text-center">
        <div class="logo-container">
            <img src="https://i.postimg.cc/7ZhFSkXz/logo.png" class="logo">
            <div class="redot"></div>
        </div>
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
        <th scope="col">Ban Length</th>
        <th scope="col">Date</th>
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
    $sqlCount = "SELECT COUNT(*) AS count FROM $ban_table";
    $stmt = $conn->query($sqlCount);
    $rowCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    $totalPages = ceil($rowCount / $resultsPerPage);

    $startLimit = ($currentPage - 1) * $resultsPerPage;

    function sanitizeInput($input)
    {
        return htmlspecialchars(trim($input), ENT_QUOTES, 'UTF-8');
    }
	
	function formatUnixTimestamp($timestamp)
    {
        return date('H:i:s d/m/Y', $timestamp);
    }

    $searchTerm = isset($_GET['search']) ? sanitizeInput($_GET['search']) : '';

    $sql = "SELECT * FROM $ban_table WHERE player_nick LIKE ? OR player_id LIKE ? ORDER BY ban_length DESC LIMIT ?, ?";
    $stmt = $conn->prepare($sql);
    $searchPattern = "%$searchTerm%";
    $stmt->bindParam(1, $searchPattern, PDO::PARAM_STR);
    $stmt->bindParam(2, $searchPattern, PDO::PARAM_STR);
    $stmt->bindParam(3, $startLimit, PDO::PARAM_INT);
    $stmt->bindParam(4, $resultsPerPage, PDO::PARAM_INT);
    $stmt->execute();
    $bans = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $stmt->closeCursor();

    if (count($bans) > 0) {
        $i = $startLimit + 1;
        foreach ($bans as $row) {
            $countryCode = getCountryFromIP($row['player_ip']);
            $countryFlagPath = "/bans/assets/images/flags/{$countryCode}.png";
            ?>
            <tr>
                <th scope='row'><?= $i ?></th>
                <td><?= $row['player_nick'] ?></td>
                <td><?= $row['player_id'] ?></td>
                <td><img src='<?= $countryFlagPath ?>' class='flag'><?= $row['player_ip'] ?></td>
                <td><?= ($row['ban_length'] == 0) ? 'PERMANENT' : formatTime($row['ban_length']) ?></td>
                <td><?= formatUnixTimestamp($row['ban_created']) ?></td>
                <td><?= $row['ban_reason'] ?></td>
                <td><?= $row['admin_nick'] ?></td>
                <td><?= $row['admin_id'] ?></td>
                <td><?= $row['server_ip'] ?></td>
                <td class="bg-danger unban-btn" data-steamid="<?= $row['player_id'] ?>">Unban</td>
            </tr>
            <?php
            $i++;
        }
    }

    if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['unbanSteamID'])) {
        $unbanSteamID = sanitizeInput($_POST['unbanSteamID']);

        $sql = "DELETE FROM $ban_table WHERE player_id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(1, $unbanSteamID, PDO::PARAM_STR);
        $stmt->execute();

        echo '<script>window.location.href = window.location.href;</script>';
        exit();
    }
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}
$conn = null;

function getCountryFromIP($ip) {
    $databasePath = __DIR__ . '/GeoLite2-City.mmdb';
    try {
        $reader = new Reader($databasePath);
        $record = $reader->city($ip);
        return $record->country->isoCode;
    } catch (Exception $e) {
        return 'Unknown';
    }
}

function formatTime($minutes) {
    $days = floor($minutes / 1440);
    $hours = floor(($minutes % 1440) / 60);
    $remainingMinutes = $minutes % 60;

    $formattedTime = '';

    if ($days > 0) {
        $formattedTime .= ($days == 1) ? '1 day' : $days . ' days';
        if ($hours > 0) {
            $formattedTime .= ', ';
            $formattedTime .= ($hours == 1) ? '1 hour' : $hours . ' hours';
        }
    } else {
        if ($hours > 0) {
            $formattedTime .= ($hours == 1) ? '1 hour' : $hours . ' hours';
            if ($remainingMinutes > 0) {
                $formattedTime .= ', ';
            }
        }

        if ($remainingMinutes > 0 || empty($formattedTime)) {
            $formattedTime .= ($remainingMinutes == 1) ? '1 minute' : $remainingMinutes . ' minutes';
        }
    }

    return $formattedTime;
}
?>
    </tbody>
</table>

<div class="pagination">
    <?php
    // Constants
    $maxVisiblePages = 5;

    // Previous button
    if ($currentPage > 1) {
        echo '<a href="#" data-page="' . ($currentPage - 1) . '">Prev</a>';
    }

    // Page links
    $startPage = max(1, min($totalPages - $maxVisiblePages + 1, $currentPage - floor($maxVisiblePages / 2)));
    $endPage = min($totalPages, $startPage + $maxVisiblePages - 1);

    if ($startPage > 1) {
        echo '<a href="#" data-page="1">1</a>';
        if ($startPage > 2) {
            echo '<span>...</span>';
        }
    }

    for ($i = $startPage; $i <= $endPage; $i++) {
        echo '<a href="#"' . ($i == $currentPage ? ' class="active"' : '') . ' data-page="' . $i . '">' . $i . '</a>';
    }

    if ($endPage < $totalPages) {
        if ($endPage < $totalPages - 1) {
            echo '<span>...</span>';
        }
        echo '<a href="#" data-page="' . $totalPages . '">' . $totalPages . '</a>';
    }

    // Next button
    if ($currentPage < $totalPages) {
        echo '<a href="#" data-page="' . ($currentPage + 1) . '">Next</a>';
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
    var currentPage = 1;
    var totalPages = <?php echo $totalPages; ?>;
    var maxVisiblePages = 5;

    function loadData() {
        var searchTerm = document.getElementById("searchInput").value;
        var url = '<?= $_SERVER['PHP_SELF'] ?>' + '?page=' + currentPage + '&search=' + searchTerm;

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

	function updatePagination() {
		$('.pagination').empty();

		// Update the range of visible pages based on the clicked page
		var startPage = Math.max(1, Math.min(totalPages - maxVisiblePages + 1, currentPage - Math.floor(maxVisiblePages / 2)));
		var endPage = Math.min(totalPages, startPage + maxVisiblePages - 1);

		if (startPage > 1) {
			$('.pagination').append('<a href="#" data-page="1">First</a>');
			if (startPage > 2) {
				$('.pagination').append('<span>...</span>');
			}
		}

		for (var i = startPage; i <= endPage; i++) {
			var link;
			if (i === 1) {
				link = '<a href="#"' + (i === currentPage ? ' class="active"' : '') + ' data-page="' + i + '">First</a>';
			} else if (i === totalPages) {
				link = '<a href="#"' + (i === currentPage ? ' class="active"' : '') + ' data-page="' + i + '">Last</a>';
			} else {
				link = '<a href="#"' + (i === currentPage ? ' class="active"' : '') + ' data-page="' + i + '">' + i + '</a>';
			}
			$('.pagination').append(link);
		}

		if (endPage < totalPages) {
			if (endPage < totalPages - 1) {
				$('.pagination').append('<span>...</span>');
			}
			var lastPageLink = '<a href="#" data-page="' + totalPages + '">Last</a>';
			$('.pagination').append(lastPageLink);
		}

		if (currentPage > 1) {
			$('.pagination').prepend('<a href="#" data-page="' + (currentPage - 1) + '">Prev</a>');
		}

		if (currentPage < totalPages) {
			$('.pagination').append('<a href="#" data-page="' + (currentPage + 1) + '">Next</a>');
		}
	}


    loadData();
    updatePagination();

	$(document).on('click', '.pagination a', function (e) {
		e.preventDefault();

		var buttonText = $(this).text().toLowerCase();
		var clickedPage = $(this).data('page');

		if (buttonText === 'prev' && currentPage > 1) {
			currentPage = currentPage - 1;
		} else if (buttonText === 'next' && currentPage < totalPages) {
			currentPage = currentPage + 1;
		} else if (!isNaN(parseInt(clickedPage))) {
			currentPage = parseInt(clickedPage);
		}

		loadData();
		updatePagination();
	});

    $(document).on('click', '.unban-btn', function () {
        var steamid = $(this).data('steamid');
        unbanPlayer(steamid);
    });

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
        <p class="text-muted mb-0">Cortex Ban System &copy; <?= date('Y') ?></p>
        <p class="text-muted mb-0">Powered by <a href="https://www.cs-down.me/" target="_blank" style="color: #3498db; text-decoration: none; font-weight: bold;">mIDnight</a></p>
		<br>
    </div>
</footer>
</body>
</html>
