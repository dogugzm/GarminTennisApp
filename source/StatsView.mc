import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Activity;
import Toybox.Application;
import Toybox.Lang;

class StatsView extends WatchUi.View {

    public static var page = 0; // 0 = Performance/Calories, 1 = Serve Stats, 2 = Set History
    var updateTimer;

    function initialize() {
        View.initialize();
        updateTimer = new Timer.Timer();
    }

    function onShow() as Void {
        updateTimer.start(method(:onTimerTick), 1000, true);
    }

    function onHide() as Void {
        updateTimer.stop();
    }

    function onTimerTick() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var app = Application.getApp() as GarminTennisApp;
        var state = app.matchState;

        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var centerVc = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var leftVc = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
        var rightVc = Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER;

        // 3-Dot Page Indicator (Top)
        for (var i = 0; i < 3; i++) {
            var dotX = cx - 20 + i * 20;
            if (i == page) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, 22, 4);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, 22, 3);
            }
        }

        if (page == 0) {
            // --- PAGE 0: PERFORMANCE ---
            var info = Activity.getActivityInfo();
            var calories = "--";
            var distance = "--";
            var hr = "--";

            if (info != null) {
                if (info.calories != null) { calories = info.calories.toString(); }
                if (info.elapsedDistance != null) {
                    var km = info.elapsedDistance / 1000.0;
                    distance = km.format("%.2f");
                }
                if (info.currentHeartRate != null) { hr = info.currentHeartRate.toString(); }
            }

            // Header
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 52, Graphics.FONT_XTINY, "PERFORMANCE", centerVc);

            var mainW = 280;
            var mainX = cx - (mainW / 2);

            // CARD 1: CALORIES
            dc.setColor(0x221100, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(mainX, 80, mainW, 60, 10);
            dc.setColor(0xFF6600, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 110, Graphics.FONT_SMALL, calories + " kcal", centerVc);

            // CARD 2: DISTANCE & HEART RATE
            var miniW = 135;
            var leftX = cx - miniW - 5;
            var rightX = cx + 5;
            
            // Left: DISTANCE
            dc.setColor(0x002233, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(leftX, 155, miniW, 60, 10);
            dc.setColor(0x00E5FF, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftX + (miniW / 2), 185, Graphics.FONT_XTINY, distance + " km", centerVc);

            // Right: HEART RATE
            dc.setColor(0x330011, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(rightX, 155, miniW, 60, 10);
            dc.setColor(0xFF3333, Graphics.COLOR_TRANSPARENT);
            dc.drawText(rightX + (miniW / 2), 185, Graphics.FONT_XTINY, hr + " bpm", centerVc);

            // CARD 3: MATCH TIMER
            var totalSecs = state.getMatchDurationSeconds();
            var mins = (totalSecs / 60).toNumber();
            var secs = (totalSecs % 60).toNumber();
            var timerStr = mins.format("%02d") + ":" + secs.format("%02d");

            dc.setColor(0x111111, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(mainX, 230, mainW, 60, 10);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 260, Graphics.FONT_SMALL, timerStr, centerVc);

            // Footer hint
            dc.setColor(0x00FF66, Graphics.COLOR_TRANSPARENT);
            if (!state.isMatchStarted) {
                dc.drawText(cx, 375, Graphics.FONT_XTINY, "SELECT: Start Match  |  DOWN: Stats >", centerVc);
            } else {
                dc.drawText(cx, 375, Graphics.FONT_XTINY, "Serve Stats >", centerVc);
            }

        } else if (page == 1) {
            // --- PAGE 1: SERVE STATS ---
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 52, Graphics.FONT_XTINY, "SERVE STATS", centerVc);

            var barW = 280;
            var barX = cx - (barW / 2);

            // 1. 1ST SERVE GRAPH
            var p1st = (state.firstServesTotal > 0) ? ((state.firstServesIn * 100) / state.firstServesTotal).toNumber() : 0;
            var text1st = p1st.toString() + "%  (" + state.firstServesIn + "/" + state.firstServesTotal + ")";
            
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(barX, 100, Graphics.FONT_XTINY, "1st", leftVc);
            dc.setColor(0x00FF66, Graphics.COLOR_TRANSPARENT);
            dc.drawText(barX + barW, 100, Graphics.FONT_XTINY, text1st, rightVc);

            // Progress Bar (1st Serve)
            dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(barX, 120, barW, 10, 5);
            if (p1st > 0) {
                var fillW1 = (barW * p1st) / 100;
                dc.setColor(0x00FF66, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(barX, 120, fillW1, 10, 5);
            }

            // 2. 2ND SERVE GRAPH
            var p2nd = (state.secondServesTotal > 0) ? ((state.secondServesIn * 100) / state.secondServesTotal).toNumber() : 0;
            var text2nd = p2nd.toString() + "%  (" + state.secondServesIn + "/" + state.secondServesTotal + ")";
            
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(barX, 175, Graphics.FONT_XTINY, "2nd", leftVc);
            dc.setColor(0x00E5FF, Graphics.COLOR_TRANSPARENT);
            dc.drawText(barX + barW, 175, Graphics.FONT_XTINY, text2nd, rightVc);

            // Progress Bar (2nd Serve)
            dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(barX, 195, barW, 10, 5);
            if (p2nd > 0) {
                var fillW2 = (barW * p2nd) / 100;
                dc.setColor(0x00E5FF, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(barX, 195, fillW2, 10, 5);
            }

            // 3. DOUBLE FAULTS
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(barX, 250, Graphics.FONT_XTINY, "DF", leftVc);
            dc.setColor(0xFF3333, Graphics.COLOR_TRANSPARENT);
            dc.drawText(barX + barW, 250, Graphics.FONT_XTINY, state.doubleFaults.toString(), rightVc);

            // Progress Bar / Indicator (Double Faults)
            dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(barX, 270, barW, 10, 5);
            if (state.doubleFaults > 0) {
                var dfW = (barW * state.doubleFaults) / 10;
                if (dfW > barW) { dfW = barW; }
                dc.setColor(0xFF3333, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(barX, 270, dfW, 10, 5);
            }

            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 375, Graphics.FONT_XTINY, "Set Details >", centerVc);

        } else if (page == 2) {
            // --- PAGE 2: SET SUMMARY ---
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 52, Graphics.FONT_XTINY, "SET SUMMARY", centerVc);

            var cardW = 280;
            var cardX = cx - (cardW / 2);
            var startY = 100;
            var numSets = state.completedSets.size();

            if (numSets == 0) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, cy, Graphics.FONT_SMALL, "No Sets Completed", centerVc);
            } else {
                for (var i = 0; i < numSets; i++) {
                    var sData = state.completedSets[i];
                    var winnerColor = (sData[0] > sData[1]) ? 0x00E5FF : 0xFF3333;
                    
                    dc.setColor(0x111111, Graphics.COLOR_TRANSPARENT);
                    dc.fillRoundedRectangle(cardX, startY + i * 65, cardW, 52, 10);

                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(cardX + 25, startY + i * 65 + 26, Graphics.FONT_XTINY, "SET " + (i + 1), leftVc);
                    
                    dc.setColor(winnerColor, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(cardX + cardW - 25, startY + i * 65 + 26, Graphics.FONT_SMALL, sData[0] + " - " + sData[1], rightVc);
                }
            }

            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 375, Graphics.FONT_XTINY, "< Performance", centerVc);
        }
    }
}

class StatsDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        var app = Application.getApp() as GarminTennisApp;
        WatchUi.pushView(new GarminTennisView(), new GarminTennisDelegate(), WatchUi.SLIDE_LEFT);
        return true;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            return onSelect();
        } else if (key == WatchUi.KEY_DOWN) {
            StatsView.page = (StatsView.page + 1) % 3;
            WatchUi.requestUpdate();
            return true;
        } else if (key == WatchUi.KEY_UP) {
            StatsView.page = (StatsView.page + 2) % 3;
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var dir = swipeEvent.getDirection();
        if (dir == WatchUi.SWIPE_DOWN || dir == WatchUi.SWIPE_LEFT) {
            StatsView.page = (StatsView.page + 1) % 3;
            WatchUi.requestUpdate();
            return true;
        } else if (dir == WatchUi.SWIPE_UP || dir == WatchUi.SWIPE_RIGHT) {
            StatsView.page = (StatsView.page + 2) % 3;
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
