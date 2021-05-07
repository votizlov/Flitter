<?php 

  include("conn.php");

  $queryResult = $connection->
      query("SELECT * FROM users");//change your_table with your database table that you want to fetch values
	//echo $queryResult;
  $result = array();
  while ($fetchdata=$queryResult->fetch_assoc()) {
      $result[] = $fetchdata;
  }

  echo json_encode($result);
 ?>