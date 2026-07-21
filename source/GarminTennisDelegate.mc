import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class GarminTennisDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        var app = Application.getApp() as GarminTennisApp;
        // UP Button Hold (Menu) is mapped to MISS (Serve Fault)
        app.matchState.serveFault();
        WatchUi.requestUpdate();
        return true;
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        var app = Application.getApp() as GarminTennisApp;

        if (!app.matchState.isMatchStarted) {
            // SERVER SELECTION SCREEN
            if (key == WatchUi.KEY_DOWN) {
                // DOWN: Me
                app.matchState.startMatch(1);
                WatchUi.requestUpdate();
                return true;
            } else if (key == WatchUi.KEY_UP) {
                // UP: Opponent
                app.matchState.startMatch(2);
                WatchUi.requestUpdate();
                return true;
            }
            return false;
        }

        // MATCH SCREEN
        if (key == WatchUi.KEY_DOWN) {
            // DOWN: My Point
            app.matchState.pointWonBy(1);
            WatchUi.requestUpdate();
            return true;
        } else if (key == WatchUi.KEY_UP) {
            // UP: Opponent Point
            app.matchState.pointWonBy(2);
            WatchUi.requestUpdate();
            return true;
        } else if (key == WatchUi.KEY_LIGHT) {
            // LIGHT: Serve Fault (Miss)
            app.matchState.serveFault();
            WatchUi.requestUpdate();
            return true;
        } else if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            // SELECT/START Button: Open In-Match Menu
            WatchUi.pushView(new InMatchMenu(), new InMatchMenuDelegate(), WatchUi.SLIDE_UP);
            return true;
        }
        return false;
    }

    // SELECT/START Physical Button
    function onSelect() as Boolean {
        var app = Application.getApp() as GarminTennisApp;
        if (app.matchState.isMatchStarted) {
            WatchUi.pushView(new InMatchMenu(), new InMatchMenuDelegate(), WatchUi.SLIDE_UP);
            return true;
        }
        return false;
    }
    
    // BACK/LAP: Undo
    function onBack() {
        var app = Application.getApp() as GarminTennisApp;
        app.matchState.undo();
        WatchUi.requestUpdate();
        return true;
    }

    // TOUCH TAP SELECTION
    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var app = Application.getApp() as GarminTennisApp;
        if (!app.matchState.isMatchStarted) {
            var coords = clickEvent.getCoordinates();
            var y = coords[1];
            var dev = System.getDeviceSettings();
            var cy = dev.screenHeight / 2;
            if (y < cy) {
                // Top Half: Opponent
                app.matchState.startMatch(2);
            } else {
                // Bottom Half: Me
                app.matchState.startMatch(1);
            }
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    // SWIPE (DOKUNMATİK KAYDIRMA İLE İSTATİSTİKLERE GEÇİŞ)
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var app = Application.getApp() as GarminTennisApp;
        if (!app.matchState.isMatchStarted) {
            return false;
        }
        var dir = swipeEvent.getDirection();
        if (dir == WatchUi.SWIPE_DOWN) {
            WatchUi.pushView(new StatsView(), new StatsDelegate(), WatchUi.SLIDE_UP);
            return true;
        }
        return false;
    }

    // FİZİKSEL TUŞLAR (SADECE SKOR SAYAR)
    function onNextPage() as Boolean {
        var app = Application.getApp() as GarminTennisApp;
        if (!app.matchState.isMatchStarted) {
            app.matchState.startMatch(1); // DOWN -> ME
            WatchUi.requestUpdate();
            return true;
        }
        // Maç esnasında DOWN tuşu her zaman BENİM Puanım!
        app.matchState.pointWonBy(1);
        WatchUi.requestUpdate();
        return true;
    }

    function onPreviousPage() as Boolean {
        var app = Application.getApp() as GarminTennisApp;
        if (!app.matchState.isMatchStarted) {
            app.matchState.startMatch(2); // UP -> OPPONENT
            WatchUi.requestUpdate();
            return true;
        }
        // Maç esnasında UP tuşu her zaman RAKİBİN Puanı!
        app.matchState.pointWonBy(2);
        WatchUi.requestUpdate();
        return true;
    }
}
