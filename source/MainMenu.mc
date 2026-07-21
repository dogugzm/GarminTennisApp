import Toybox.WatchUi;
import Toybox.System;
import Toybox.Application;
import Toybox.Lang;

class GarminTennisMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Garmin Tennis"});
        
        var app = Application.getApp() as GarminTennisApp;
        var setsLabel = "3 (Best of 3)";
        if (app.matchState.maxSets == 1) {
            setsLabel = "1 Set Match";
        } else if (app.matchState.maxSets == 5) {
            setsLabel = "5 (Best of 5)";
        }
        
        var modeLabel = app.matchState.isNoAd ? "No-Ad Scoring" : "Advantage Scoring";
        
        addItem(new WatchUi.MenuItem("Start Match", "Play Tennis", "start", null));
        addItem(new WatchUi.MenuItem("Match Stats", "View Statistics", "stats", null));
        addItem(new WatchUi.MenuItem("Sets", setsLabel, "sets", null));
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
        
        if (id.equals("start")) {
            app.matchState.resetMatch();
            WatchUi.pushView(new GarminTennisView(), new GarminTennisDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id.equals("stats")) {
            WatchUi.pushView(new StatsView(), new StatsDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id.equals("sets")) {
            if (app.matchState.maxSets == 1) {
                app.matchState.maxSets = 3;
                item.setSubLabel("3 (Best of 3)");
            } else if (app.matchState.maxSets == 3) {
                app.matchState.maxSets = 5;
                item.setSubLabel("5 (Best of 5)");
            } else {
                app.matchState.maxSets = 1;
                item.setSubLabel("1 Set Match");
            }
        } else if (id.equals("mode")) {
            app.matchState.isNoAd = !app.matchState.isNoAd;
            if (app.matchState.isNoAd) {
                item.setSubLabel("No-Ad Scoring");
            } else {
                item.setSubLabel("Advantage Scoring");
            }
        }
    }
}
