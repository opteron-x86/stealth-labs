<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Deliberately unsafe input handling for the lab
    $userCommand = $_POST['command']; 
    $commandArgs = explode(" ", $userCommand); // Splitting command into an array

    // Vulnerable call to proc_open
    $descriptorspec = [
        0 => ["pipe", "r"],  // stdin
        1 => ["pipe", "w"],  // stdout
        2 => ["pipe", "w"]   // stderr
    ];

    $process = proc_open($commandArgs, $descriptorspec, $pipes, null, null);

    if (is_resource($process)) {
        $output = stream_get_contents($pipes[1]);
        $error = stream_get_contents($pipes[2]);

        echo "<h2>Command Output:</h2><pre>$output</pre>";
        if (!empty($error)) {
            echo "<h2>Error Output:</h2><pre>$error</pre>";
        }
        
        fclose($pipes[0]);
        fclose($pipes[1]);
        fclose($pipes[2]);
        proc_close($process);
    }
}
?>
<form method="POST">
    <input type="text" name="command" placeholder="Enter command and arguments">
    <input type="submit" value="Execute">
</form>
