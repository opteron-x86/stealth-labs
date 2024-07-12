<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Vulnerable Code (Demonstrating CVE-2024-1874)
    $command = $_POST['command'];
    $descriptorspec = array(
        0 => array("pipe", "r"),
        1 => array("pipe", "w"),
        2 => array("pipe", "w")
    );

    // Unsafe argument injection (This is the key issue)
    $process = proc_open([$command], $descriptorspec, $pipes); 

    if (is_resource($process)) {
        echo "<h2>Command Output:</h2><pre>" . stream_get_contents($pipes[1]) . "</pre>";
        fclose($pipes[0]);
        fclose($pipes[1]);
        fclose($pipes[2]);
        proc_close($process);
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Vulnerable PHP Lab (CVE-2024-1874)</title>
</head>
<body>
    <h1>Command Execution Lab</h1>
    <p>This lab demonstrates a vulnerability in PHP's `proc_open()` function (CVE-2024-1874).</p>
    <p><strong>Warning:</strong> Do not use this on a production server.</p>
    <form method="POST">
        <label for="command">Enter Command:</label><br>
        <input type="text" id="command" name="command" placeholder="e.g., cmd /c dir"><br><br>
        <input type="submit" value="Execute">
    </form>
</body>
</html>
