<?php

    $connection = new mysqli("127.0.0.1", "root", "", "flitter");

    if (!$connection) {
        echo "connection failed!";
        exit();
    }
?>