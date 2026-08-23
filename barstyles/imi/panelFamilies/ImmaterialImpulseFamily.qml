import QtQuick
import Quickshell

import "../modules/common"
import ".."
import ".."
import "../modules/imi/bar"
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."
import ".."

Scope {
    PanelLoader { extraCondition: !Config.options.bar.vertical; component: Bar {} }
    // No extraCondition: the vertical bar loads the same widget files, so one
    // overlay serves whichever bar is up.
    PanelLoader { component: BarPopupOverlay {} }
    PanelLoader { component: Background {} }
    PanelLoader { component: Cheatsheet {} }
    PanelLoader { component: ClockDepthSelect {} }
    PanelLoader { component: EditModeChrome {} }
    PanelLoader { extraCondition: Config.options.dock.enable; component: Dock {} }
    PanelLoader { component: Lock {} }
    PanelLoader { component: MediaControls {} }
    PanelLoader { component: NotificationPopup {} }
    PanelLoader { component: OnScreenDisplay {} }
    PanelLoader { component: OnScreenKeyboard {} }
    PanelLoader { component: Overlay {} }
    PanelLoader { component: Overview {} }
    PanelLoader { component: Polkit {} }
    PanelLoader { component: RegionSelector {} }
    PanelLoader { component: ScreenCorners {} }
    PanelLoader { component: Screensaver {} }
    PanelLoader { component: ScreenTranslator {} }
    PanelLoader { component: SessionScreen {} }
    PanelLoader { component: SidebarLeft {} }
    PanelLoader { component: SidebarRight {} }
    PanelLoader { extraCondition: Config.options.bar.vertical; component: VerticalBar {} }
    PanelLoader { component: WallpaperSelector {} }
    PanelLoader { component: Settings {} }
    PanelLoader { component: DesktopMenu {} }
    PanelLoader { component: DropShelfPanel {} }
    PanelLoader { component: ScreenshotResultPanel {} }
    PanelLoader { component: RecordingRegionPanel {} }
}
