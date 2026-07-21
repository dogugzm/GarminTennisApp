import Toybox.WatchUi;
import Toybox.System;
import Toybox.Application;
import Toybox.Lang;

class GarminTennisMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Garmin Tennis"});
        
        var app = Application.getApp() as GarminTennisApp;
        var state = app.matchState;

        var setsLabel = "3 (Best of 3)";
        if (state.maxSets == 1) {
            setsLabel = "1 Set Match";
        } else if (state.maxSets == 5) {
            setsLabel = "5 (Best of 5)";
        }
        
        var modeLabel = state.isNoAd ? "No-Ad Scoring" : "Advantage Scoring";
        
        if (!state.isActivityStarted) {
            addItem(new WatchUi.MenuItem("Start Activity", "Warmup / Calorie Track", "activity", null));
            addItem(new WatchUi.MenuItem("Start Match", "Play & Track Tennis", "start", null));
        } else if (!state.isMatchStarted) {
            addItem(new WatchUi.MenuItem("Start Match", "Begin Tennis Scoring", "start", null));
            addItem(new WatchUi.MenuItem("Match Stats", "View Activity Stats", "stats", null));
            addItem(new WatchUi.MenuItem("End Activity", "Finish Session", "end", null));
        } else {
            addItem(new WatchUi.MenuItem("Resume Match", "Back to Scoreboard", "resume", null));
            addItem(new WatchUi.MenuItem("Match Stats", "View Statistics", "stats", null));
            addItem(new WatchUi.MenuItem("End Match", "Finish & Save", "end", null));
        }
        
        var gamesLabel = (state.gamesPerSet == 4) ? "4 Games (Fast4)" : "6 Games / Set";
        
        addItem(new WatchUi.MenuItem("Sets", setsLabel, "sets", null));
        addItem(new WatchUi.MenuItem("Set Length", gamesLabel, "length", null));
        addItem(new WatchUi.MenuItem("Game Mode", modeLabel, "mode", null));
    }
}

class GarminTennisMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId() as String;
        var app = Application.getApp() as GarminTennisApp;
        var state = app.matchState;
        
        if (id.equals("activity")) {
            state.startActivity();
            StatsView.page = 0;
            WatchUi.pushView(new StatsView(), new StatsDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id.equals("start")) {
            if (!state.isActivityStarted) {
                state.startActivity();
            }
            WatchUi.pushView(new GarminTennisView(), new GarminTennisDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id.equals("resume")) {
            WatchUi.pushView(new GarminTennisView(), new GarminTennisDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id.equals("stats")) {
            WatchUi.pushView(new StatsView(), new StatsDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id.equals("end")) {
            WatchUi.pushView(new SaveConfirmationView(), new SaveConfirmationDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id.equals("sets")) {
            if (state.maxSets == 1) {
                state.maxSets = 3;
                item.setSubLabel("3 (Best of 3)");
            } else if (state.maxSets == 3) {
                state.maxSets = 5;
                item.setSubLabel("5 (Best of 5)");
            } else {
                state.maxSets = 1;
                item.setSubLabel("1 Set Match");
            }
        } else if (id.equals("length")) {
            if (state.gamesPerSet == 6) {
                state.gamesPerSet = 4;
                item.setSubLabel("4 Games (Fast4)");
            } else {
                state.gamesPerSet = 6;
                item.setSubLabel("6 Games / Set");
            }
        } else if (id.equals("mode")) {
            state.isNoAd = !state.isNoAd;
            if (state.isNoAd) {
                item.setSubLabel("No-Ad Scoring");
            } else {
                item.setSubLabel("Advantage Scoring");
            }
        }
    }
}
