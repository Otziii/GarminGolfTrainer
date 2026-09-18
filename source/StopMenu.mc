import Toybox.Lang;
import Toybox.WatchUi;

// The stop menu a native activity shows when you press START/STOP while
// recording. There is no SDK class for this, so it is a Menu2 -- which picks
// up the system menu styling -- with the native wording and ordering.
class StopMenu extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({ :title => "Driving Range" });
        addItem(new WatchUi.MenuItem("Resume",  null, :resume,  {}));
        addItem(new WatchUi.MenuItem("Save",    null, :save,    {}));
        addItem(new WatchUi.MenuItem("Discard", null, :discard, {}));
    }
}

class StopMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();

        if (id == :resume) {
            getApp().resumeRangeSession();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else if (id == :save) {
            var shots = getApp().getRangeShots();
            getApp().saveRangeSession();
            // Unwind the stop menu and the activity screen, then show the
            // summary over the pre-start screen.
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.pushView(
                new SessionSummaryView(shots),
                new SessionSummaryDelegate(),
                WatchUi.SLIDE_UP
            );
        } else if (id == :discard) {
            // Discarding throws away the recording, so it is confirmed the
            // same way native activities confirm it.
            WatchUi.pushView(
                new WatchUi.Confirmation("Discard activity?"),
                new DiscardConfirmationDelegate(),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
    }

    // BACK out of the stop menu resumes, matching native behaviour.
    function onBack() as Void {
        getApp().resumeRangeSession();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

class DiscardConfirmationDelegate extends WatchUi.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response as WatchUi.Confirm) as Lang.Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            getApp().discardRangeSession();
            // Unwind the stop menu and the activity screen back to pre-start.
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
        return true;
    }
}
