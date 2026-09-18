import Toybox.Lang;
import Toybox.WatchUi;

// Reached by holding MENU on the pre-start screen, where native activities
// keep their options.
class PreStartMenu extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({ :title => "Driving Range" });
        addItem(new WatchUi.MenuItem("History",  null, :history,  {}));
        addItem(new WatchUi.MenuItem("Log Shot", null, :logShot,  {}));
        addItem(new WatchUi.MenuItem("Settings", null, :settings, {}));
    }
}

class PreStartMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();

        if (id == :history) {
            var view = new StatsView();
            WatchUi.pushView(view, new StatsDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :logShot) {
            // Logging outside a session stays available, as before.
            WatchUi.pushView(
                new ClubMenu(),
                new ClubDelegate({} as Lang.Dictionary),
                WatchUi.SLIDE_LEFT
            );
        } else if (id == :settings) {
            WatchUi.pushView(
                new SettingsMenuView(),
                new SettingsMenuDelegate(),
                WatchUi.SLIDE_LEFT
            );
        }
    }
}
