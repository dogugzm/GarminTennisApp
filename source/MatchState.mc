import Toybox.ActivityRecording;
import Toybox.FitContributor;
import Toybox.Position;
import Toybox.System;
import Toybox.Lang;

class MatchState {

    // FIT Session & Custom Fields
    var session = null;
    var fitField1stServe = null;
    var fitField2ndServe = null;
    var fitFieldDoubleFaults = null;
    var fitFieldP1Sets = null;
    var fitFieldP2Sets = null;
    var fitFieldGamesWon = null;
    var fitFieldGamesLost = null;

    // 0=0, 1=15, 2=30, 3=40
    var p1Points = 0;
    var p2Points = 0;
    
    var p1Games = 0;
    var p2Games = 0;

    var p1Sets = 0;
    var p2Sets = 0;
    var maxSets = 3; // 1, 3, or 5
    var gamesPerSet = 6; // 4 or 6 games per set
    var isNoAd = false; // false = Advantage (Deuce), true = Karar Puanı (No-Ad)

    // Serve state tracking
    var isActivityStarted = false;
    var isMatchStarted = false;
    var isPaused = false;
    var server = 1; // 1 = Me, 2 = Opponent
    var serveState = 1; // 1 = 1st Serve, 2 = 2nd Serve

    // Timer tracking
    var elapsedTime = 0;
    var lastTimerStart = 0;

    // Stats
    var firstServesTotal = 0;
    var firstServesIn = 0;
    var secondServesTotal = 0;
    var secondServesIn = 0;
    var doubleFaults = 0;

    // History array for undo functionality
    var history = [];
    var completedSets = [];

    function initialize() {
        resetMatch();
    }

    function resetMatch() {
        if (Toybox has :Position) {
            Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        }

        if (session != null) {
            if (session.isRecording()) {
                session.stop();
            }
            session = null;
        }
        
        fitField1stServe = null;
        fitField2ndServe = null;
        fitFieldDoubleFaults = null;
        fitFieldP1Sets = null;
        fitFieldP2Sets = null;
        fitFieldGamesWon = null;
        fitFieldGamesLost = null;

        p1Points = 0;
        p2Points = 0;
        p1Games = 0;
        p2Games = 0;
        p1Sets = 0;
        p2Sets = 0;
        
        isActivityStarted = false;
        isMatchStarted = false;
        isPaused = false;
        server = 1;
        serveState = 1;
        elapsedTime = 0;
        lastTimerStart = 0;

        firstServesTotal = 0;
        firstServesIn = 0;
        secondServesTotal = 0;
        secondServesIn = 0;
        doubleFaults = 0;

        history = [];
        completedSets = [];
    }

    function startActivity() {
        if (isActivityStarted) { return; }
        
        isActivityStarted = true;
        isMatchStarted = false;
        isPaused = false;
        lastTimerStart = System.getTimer();

        // Enable GPS Location Tracking
        if (Toybox has :Position) {
            Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        }

        if (Toybox has :ActivityRecording) {
            session = ActivityRecording.createSession({
                :name => "Tennis Match",
                :sport => ActivityRecording.SPORT_TENNIS,
                :subSport => ActivityRecording.SUB_SPORT_GENERIC
            });

            // Create Custom FIT Fields for Garmin Connect
            if (session has :createField) {
                fitField1stServe = session.createField("1st_serve_pct", 0, FitContributor.DATA_TYPE_UINT8, {:units => "%"});
                fitField2ndServe = session.createField("2nd_serve_pct", 1, FitContributor.DATA_TYPE_UINT8, {:units => "%"});
                fitFieldDoubleFaults = session.createField("double_faults", 2, FitContributor.DATA_TYPE_UINT8, {:units => "count"});
                fitFieldP1Sets = session.createField("p1_sets", 3, FitContributor.DATA_TYPE_UINT8, {:units => "sets"});
                fitFieldP2Sets = session.createField("p2_sets", 4, FitContributor.DATA_TYPE_UINT8, {:units => "sets"});
                fitFieldGamesWon = session.createField("games_won", 5, FitContributor.DATA_TYPE_UINT8, {:units => "games"});
                fitFieldGamesLost = session.createField("games_lost", 6, FitContributor.DATA_TYPE_UINT8, {:units => "games"});
            }

            session.start();
            updateFitFields();
        }
    }
    
    function startMatch(startingServer) {
        if (!isActivityStarted) {
            startActivity();
        }
        server = startingServer;
        isMatchStarted = true;
        isPaused = false;
    }

    function onPosition(info as Position.Info) as Void {
        // Position callback - automatically recorded to FIT track points by Garmin
    }

    function updateFitFields() {
        if (fitField1stServe != null) {
            var p1st = (firstServesTotal > 0) ? ((firstServesIn * 100) / firstServesTotal).toNumber() : 0;
            fitField1stServe.setData(p1st);
        }
        if (fitField2ndServe != null) {
            var p2nd = (secondServesTotal > 0) ? ((secondServesIn * 100) / secondServesTotal).toNumber() : 0;
            fitField2ndServe.setData(p2nd);
        }
        if (fitFieldDoubleFaults != null) {
            fitFieldDoubleFaults.setData(doubleFaults);
        }
        if (fitFieldP1Sets != null) {
            fitFieldP1Sets.setData(p1Sets);
        }
        if (fitFieldP2Sets != null) {
            fitFieldP2Sets.setData(p2Sets);
        }
        
        var totalGamesWon = p1Games;
        var totalGamesLost = p2Games;
        for(var i=0; i<completedSets.size(); i++) {
            totalGamesWon += completedSets[i][0];
            totalGamesLost += completedSets[i][1];
        }
        
        if (fitFieldGamesWon != null) {
            fitFieldGamesWon.setData(totalGamesWon);
        }
        if (fitFieldGamesLost != null) {
            fitFieldGamesLost.setData(totalGamesLost);
        }
    }

    function togglePause() {
        if (!isActivityStarted) { return; }
        
        if (isPaused) {
            // Resume
            isPaused = false;
            lastTimerStart = System.getTimer();
            if (session != null && !session.isRecording()) {
                session.start();
            }
        } else {
            // Pause
            isPaused = true;
            elapsedTime += (System.getTimer() - lastTimerStart);
            if (session != null && session.isRecording()) {
                session.stop();
            }
        }
    }

    function saveMatch() {
        updateFitFields();
        if (session != null) {
            if (session.isRecording()) {
                session.stop();
            }
            session.save();
            session = null;
        }
        resetMatch();
    }

    function discardMatch() {
        if (session != null) {
            if (session.isRecording()) {
                session.stop();
            }
            session.discard();
            session = null;
        }
        resetMatch();
    }

    function getMatchDurationSeconds() {
        if (!isActivityStarted) { return 0; }
        
        var totalMs = elapsedTime;
        if (!isPaused) {
            totalMs += (System.getTimer() - lastTimerStart);
        }
        return totalMs / 1000;
    }

    function saveState() {
        var setsCopy = [];
        for(var i=0; i<completedSets.size(); i++) {
            setsCopy.add([completedSets[i][0], completedSets[i][1]]);
        }
        
        // Add current state to history before changing
        var state = {
            "p1Points" => p1Points,
            "p2Points" => p2Points,
            "p1Games" => p1Games,
            "p2Games" => p2Games,
            "p1Sets" => p1Sets,
            "p2Sets" => p2Sets,
            "server" => server,
            "serveState" => serveState,
            "firstServesTotal" => firstServesTotal,
            "firstServesIn" => firstServesIn,
            "secondServesTotal" => secondServesTotal,
            "secondServesIn" => secondServesIn,
            "doubleFaults" => doubleFaults,
            "completedSets" => setsCopy
        };
        history.add(state);
    }

    function undo() {
        if (history.size() > 0) {
            var state = history[history.size() - 1];
            p1Points = state["p1Points"];
            p2Points = state["p2Points"];
            p1Games = state["p1Games"];
            p2Games = state["p2Games"];
            p1Sets = state["p1Sets"];
            p2Sets = state["p2Sets"];
            server = state["server"];
            serveState = state["serveState"];
            firstServesTotal = state["firstServesTotal"];
            firstServesIn = state["firstServesIn"];
            secondServesTotal = state["secondServesTotal"];
            secondServesIn = state["secondServesIn"];
            doubleFaults = state["doubleFaults"];
            
            var savedSets = state["completedSets"];
            completedSets = [];
            if (savedSets != null) {
                for(var i=0; i<savedSets.size(); i++) {
                    completedSets.add([savedSets[i][0], savedSets[i][1]]);
                }
            }
            
            // Remove the last state from history
            history = history.slice(0, history.size() - 1);
            updateFitFields();
        }
    }

    // IMPLICIT IN LOGIC
    function pointWonBy(player) {
        saveState();

        // If I am serving, registering a point means the serve was implicitly successful
        if (server == 1) {
            if (serveState == 1) {
                firstServesTotal++;
                firstServesIn++;
            } else if (serveState == 2) {
                secondServesTotal++;
                secondServesIn++;
            }
        }

        if (player == 1) {
            p1Points++;
        } else {
            p2Points++;
        }

        // Reset serve state for the next point
        serveState = 1;

        checkGameWin();
        updateFitFields();
    }

    // EXPLICIT MISS LOGIC
    function serveFault() {
        // MISS button only works if I am the server
        if (server == 1) {
            saveState();

            if (serveState == 1) {
                firstServesTotal++;
                serveState = 2; // Move to 2nd serve
            } else if (serveState == 2) {
                secondServesTotal++;
                doubleFaults++;
                
                // Opponent wins point on double fault
                p2Points++;
                serveState = 1; // Reset to 1st serve for next point
                
                checkGameWin();
            }
            updateFitFields();
        }
    }

    function checkGameWin() {
        if (isNoAd) {
            // Karar Puanı (No-Ad): 40-40 sonrası alınan ilk puan oyunu kazandırır
            if (p1Points >= 4) {
                p1Games++;
                p1Points = 0;
                p2Points = 0;
                toggleServer();
                checkSetWin();
            } else if (p2Points >= 4) {
                p2Games++;
                p1Points = 0;
                p2Points = 0;
                toggleServer();
                checkSetWin();
            }
        } else {
            // Klasik Avantajlı Oyun Logic
            if (p1Points >= 4 && (p1Points - p2Points) >= 2) {
                p1Games++;
                p1Points = 0;
                p2Points = 0;
                toggleServer();
                checkSetWin();
            } else if (p2Points >= 4 && (p2Points - p1Points) >= 2) {
                p2Games++;
                p1Points = 0;
                p2Points = 0;
                toggleServer();
                checkSetWin();
            } else if (p1Points >= 4 && p2Points >= 4 && p1Points == p2Points) {
                // Deuce durumunda tekrar 3-3'e eşitle (AD mantığı için)
                p1Points = 3;
                p2Points = 3;
            }
        }
    }

    function toggleServer() {
        if (server == 1) {
            server = 2;
        } else {
            server = 1;
        }
    }

    function checkSetWin() {
        if (p1Games >= gamesPerSet && (p1Games - p2Games) >= 2) {
            p1Sets++;
            completedSets.add([p1Games, p2Games]);
            p1Games = 0;
            p2Games = 0;
        } else if (p2Games >= gamesPerSet && (p2Games - p1Games) >= 2) {
            p2Sets++;
            completedSets.add([p1Games, p2Games]);
            p1Games = 0;
            p2Games = 0;
        }
    }

    // Translate point counters into tennis scores
    function getPointString(points, oppPoints) {
        if (points == 0) { return "0"; }
        if (points == 1) { return "15"; }
        if (points == 2) { return "30"; }
        if (points == 3) { return "40"; }
        
        // Deuce / Advantage Logic
        if (points >= 4) {
            if (points == oppPoints) {
                return "40"; // Actually Deuce, but UI can just show 40
            } else if (points > oppPoints) {
                return "AD";
            }
        }
        return points.toString();
    }

    function getP1PointString() {
        return getPointString(p1Points, p2Points);
    }

    function getP2PointString() {
        return getPointString(p2Points, p1Points);
    }
}
