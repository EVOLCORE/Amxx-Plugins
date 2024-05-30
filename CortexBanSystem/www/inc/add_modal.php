<?php
    if ($_SERVER['REQUEST_METHOD'] == 'GET' && realpath(__FILE__) == realpath($_SERVER['SCRIPT_FILENAME'])) {        
        header('HTTP/1.0 403 Forbidden', TRUE, 403);
        die(header('location: bans.php'));
    }
    $cssFilePath = 'assets/css/styles.css';
$version = md5_file($cssFilePath);
$cssUrl = "assets/css/styles.css?v=$version";
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="<?php echo $cssUrl; ?>">
    <title>Add New Ban</title>
</head>
<body>
    <!-- Add New -->
    <div class="modal fade" id="addnew" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg"> <!-- Updated to modal-lg for larger size -->
            <div class="modal-content">
                <div class="modal-header">
                    <h4 class="modal-title" id="myModalLabel">Add New Ban</h4>
                    <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
                </div>
                <div class="modal-body">
                    <div class="container-fluid">
                        <form method="POST" action="add.php">
                            <div class="row form-group">
                                <div class="col-sm-2">
                                    <label class="control-label modal-label">Nick*:</label>
                                </div>
                                <div class="col-sm-10">
                                    <input type="text" class="form-control" name="player_nick" required>
                                </div>
                            </div>
                            <div class="row form-group">
                                <div class="col-sm-2">
                                    <label class="control-label modal-label">SteamID:</label>
                                </div>
                                <div class="col-sm-10">
                                    <input type="text" class="form-control" name="player_id">
                                </div>
                            </div>
                            <div class="row form-group">
                                <div class="col-sm-2">
                                    <label class="control-label modal-label">IP:</label>
                                </div>
                                <div class="col-sm-10">
                                    <input type="text" class="form-control" name="player_ip">
                                </div>
                            </div>
                            <div class="row form-group">
                                <div class="col-sm-2">
                                    <label class="control-label modal-label">Reason*:</label>
                                </div>
                                <div class="col-sm-10">
                                    <input type="text" class="form-control" name="ban_reason" required>
                                </div>
                            </div>
                            <div class="row form-group">
                                <div class="col-sm-2">
                                    <label class="control-label modal-label">Length*:</label>
                                </div>
                                <div class="col-sm-10">
                                    <input type="number" class="form-control" name="ban_length" required>
                                </div>
                            </div>
                            <div class="row form-group">
                                <div class="col-sm-2">
                                    <label class="control-label modal-label">Server IP*:</label>
                                </div>
                                <div class="col-sm-10">
                                    <input type="text" class="form-control" name="server_ip" required>
                                </div>
                            </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-default" data-dismiss="modal"><span class="glyphicon glyphicon-remove"></span> Cancel</button>
                    <button type="submit" name="add" class="btn btn-primary"><span class="glyphicon glyphicon-floppy-disk"></span> Save</button>
                </form>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
