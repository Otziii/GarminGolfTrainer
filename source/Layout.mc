import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

// The display is a 260px circle, so the usable width at a given height is the
// chord of that circle, not the full screen width. Drawing centred text at
// full width near the top or bottom pushes glyphs under the bezel, which is
// why the old screens read "WING TO LOG A SHO" and "ANGE SUMMAR".
module Layout {

    // Half the drawable width at vertical offset y, with a small inset so
    // glyphs never touch the bezel. Returns 0 outside the circle.
    function halfWidthAt(dc as Graphics.Dc, y as Lang.Number) as Lang.Number {
        var r = dc.getWidth() / 2;
        var dy = y - (dc.getHeight() / 2);
        if (dy < 0) { dy = -dy; }
        if (dy >= r) { return 0; }
        return Math.sqrt((r * r) - (dy * dy)).toNumber() - 6;
    }

    // Text is drawn vertically centred on y, so the narrowest chord it has to
    // fit through is at whichever edge of the glyph box sits further out.
    function availableWidth(dc as Graphics.Dc, y as Lang.Number, font as Graphics.FontType) as Lang.Number {
        var half = (dc.getFontHeight(font) / 2).toNumber();
        var top = halfWidthAt(dc, y - half);
        var bottom = halfWidthAt(dc, y + half);
        return 2 * (top < bottom ? top : bottom);
    }

    // Draws text centred on (centre, y) in the largest supplied font that
    // fits. Fonts must be ordered largest first. Falls back to the smallest.
    function drawFitted(
        dc as Graphics.Dc,
        y as Lang.Number,
        fonts as Lang.Array,
        text as Lang.String
    ) as Void {
        var cx = dc.getWidth() / 2;
        for (var i = 0; i < fonts.size(); i++) {
            var font = fonts[i] as Graphics.FontType;
            if (dc.getTextWidthInPixels(text, font) <= availableWidth(dc, y, font)
                    || i == fonts.size() - 1) {
                dc.drawText(cx, y, font, text,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                return;
            }
        }
    }

    // A field label above its value, the way native activity pages stack them.
    function drawField(
        dc as Graphics.Dc,
        labelY as Lang.Number,
        valueY as Lang.Number,
        label as Lang.String,
        value as Lang.String,
        valueFonts as Lang.Array
    ) as Void {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawFitted(dc, labelY, [Graphics.FONT_XTINY] as Lang.Array, label);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawFitted(dc, valueY, valueFonts, value);
    }

    // The paused indicator native activities show. There is no pause glyph in
    // the device resources, so it is drawn: two rounded bars.
    function drawPauseIcon(dc as Graphics.Dc, y as Lang.Number, size as Lang.Number) as Void {
        var cx = dc.getWidth() / 2;
        var barW = (size * 0.32).toNumber();
        var gap = (size * 0.28).toNumber();
        var top = y - (size / 2);
        dc.fillRoundedRectangle(cx - (gap / 2) - barW, top, barW, size, 2);
        dc.fillRoundedRectangle(cx + (gap / 2), top, barW, size, 2);
    }

    // Native pre-start screens show a status bar that fills green once the
    // watch is ready. No GPS here, so readiness means a heart rate lock.
    function drawStatusBar(dc as Graphics.Dc, y as Lang.Number, ready as Lang.Boolean) as Void {
        var cx = dc.getWidth() / 2;
        var barW = (dc.getWidth() * 0.44).toNumber();
        var barH = 8;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(cx - (barW / 2), y - (barH / 2), barW, barH, barH / 2);
        if (ready) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(cx - (barW / 2), y - (barH / 2), barW, barH, barH / 2);
        }
    }

    // Native data pages show which page you are on; dots keep it unobtrusive.
    function drawPageDots(dc as Graphics.Dc, count as Lang.Number, active as Lang.Number) as Void {
        var cx = dc.getWidth() / 2;
        var y = (dc.getHeight() * 0.93).toNumber();
        var spacing = 12;
        var startX = cx - (((count - 1) * spacing) / 2);
        for (var i = 0; i < count; i++) {
            dc.setColor(i == active ? Graphics.COLOR_WHITE : Graphics.COLOR_DK_GRAY,
                Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(startX + (i * spacing), y, 3);
        }
    }
}
