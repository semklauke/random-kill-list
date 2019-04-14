<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous">
    <script   src="https://code.jquery.com/jquery-2.2.3.min.js"   integrity="sha256-a23g1Nt4dtEYOj7bR+vTu7+T8VP13humZFBJNIYoEJo="   crossorigin="anonymous"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js" integrity="sha384-0mSbJDEHialfmuBBQP6A4Qrprq5OVfW37PRR3j5ELqxss1yVqOtnepnHVP9aJ7xS" crossorigin="anonymous"></script>
    <!--script type="text/javascript" src="index.js"></script>
    <link rel="stylesheet" type="text/css" href="index.css" /-->
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>The List: TTT - by semTEX</title>
</head>
<body>
    <main class="container">
        <h3>Total</h3>
        <table class="stats_table table" id="total">
            <thead>
            <tr>
                <th scope="col">Player </th>
                <th scope="col">Random Kills</th>
            </tr>
            </thead>
            <tbody>
        <?php
    
    
        $replace_strings = array('<' => '&lt;', '>' => '&gt;');
        $alphas = array_merge(range('A', 'Z'), range('a', 'z'));
    
        try {
            $db = new PDO('sqlite:../randomKillsList.db');
            // {DEBUG}
            $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_WARNING);
        } catch (PDOException $e) {
            echo $e->getMessage();
        }
    
        $totalStmt = $db->prepare("SELECT COUNT(*) AS rks, pl.current_nick FROM randome_kills as rk LEFT JOIN player AS pl ON rk.attacker_id = pl.`rec_id` GROUP BY rk.attacker_id ORDER BY rks DESC");
    
        $totalStmt->execute();
        while ($totalStat = $totalStmt->fetch(PDO::FETCH_OBJ)) { ?>
        <tr>
            <td><?php echo $totalStat->curren_nick; ?></td>
            <td><?php echo $totalStat->rks; ?></td>
        </tr>
        <?php } echo '</tbody></table>', PHP_EOL;
            $totalStmt->closeCursor();
        
            $monthQueryString = "SELECT COUNT(*) AS rks, pl.curren_nick, pl.`rec_id` as rec_id FROM randome_kills as rk";
            $monthQueryString .= "LEFT JOIN player AS pl ON rk.attacker_id = pl.`rec_id` ";
            $monthQueryString .= "WHERE strftime('%m', rk.time) = strftime('%m', date('now'))";
            $monthQueryString .= "AND strftime('%y', rk.time) = strftime('%y', date('now')) GROUP BY rk.attacker_id ORDER BY rks DESC";
        
            $monthStmt = $db->prepare($monthQueryString);
            $monthStmt->execute();
        ?>
        <h3>This Month</h3>
        <table class="stats_table table" id="month">
            <thead>
                <tr>
                    <th>Player </th>
                    <th>Random Kills</th>
                </tr>
            </thead>
            <tbody>
            <?php while ($monthStat = $monthStmt->fetch(PDO::FETCH_OBJ)) { ?>
                <tr>
                    <td><?php echo $monthStat->current_nick; ?></td>
                    <td><?php echo $monthStat->rks; ?></td>
                </tr>
        <?php } echo '</tbody></table>', PHP_EOL;
            $monthStmt->execute();
            $monthStmt->closeCursor()
        ?>
        <h3>This Month (Avg. on Round)</h3>
        <table class="stats_table table" id="monthOnRound">
           <thead>
               <tr>
                   <th>Player </th>
                   <th>Ran. Kill/Round </th>
                   <th>Rounds</th>
               </tr>
            </thead>
            <tbody>
            <?php 
                $month2Stmt = $db->prepare($monthQueryString);
                $month2Stmt->execute();
                $month2String = "SELECT COUNT(*) AS 'c' FROM rounds_played WHERE player_id = ? ";
                $month2String .= " strftime('%m', date) = strftime('%m', date('now')) strftime('%y', date) = strftime('%y', date('now'))");
                $roundsStmt = $db->prepare(month2String)
                while ($monthStat = $month2Stmt->fetch(PDO::FETCH_OBJ)) { ?>
                    <tr>
                        <td><?php echo $monthStat->current_nick; ?></td>
                        <td><?php
                            $roundsStmt->execute(array($monthStat->rec_id));
                            $roundStat = $roundsStmt->fetch(PDO::FETCH_OBJ);
                                if (intval($monthStat->rks) > 0) {
                                    echo round((intval($monthStat->rks) / intval($roundStat->c)), 2);
                                } else {
                                    echo "0.00";
                                }
                            ?>
                        </td>
                        <td><?php echo intval($roundStat->c); ?></td>
                    </tr>
            <?php } echo '</tbody></table>', PHP_EOL; ?>
    </main>  


</body>
</html>