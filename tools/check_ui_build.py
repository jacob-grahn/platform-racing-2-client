#!/usr/bin/env python3
"""Verify the HTML5 presentation boundary after DCE/minification."""
from pathlib import Path
import argparse
import shutil


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("configuration", choices=["classic", "mobile", "preview"])
    args = parser.parse_args()
    root = Path("export/html5/bin")
    source = (root / "PlatformRacing2.js").read_text()
    expected = {
        "LoginPage": args.configuration != "mobile",
        "LobbyPage": args.configuration != "mobile",
        "MobileLoginPage": args.configuration != "classic",
        "MobileLobbyPage": args.configuration != "classic",
    }
    for name, included in expected.items():
        actual = ('"pr2.page.' + name + '"') in source
        if actual != included:
            raise SystemExit(f"UI build boundary failed: {name}, included={actual}, expected={included}")
    for name, included in {
        "pr2.page.auth.ClassicAuthDialog": args.configuration != "mobile",
        "pr2.mobile.MobileAuthDialog": args.configuration != "classic",
        "pr2.mobile.MobileLevelBrowser": args.configuration != "classic",
        "pr2.mobile.LobbyView": args.configuration != "classic",
        "pr2.mobile.MobileGameHud": args.configuration != "classic",
        "pr2.mobile.MobileResultsPage": args.configuration != "classic",
        "pr2.mobile.MobileRacerPage": args.configuration != "classic",
        "pr2.mobile.MobilePlayersPage": args.configuration != "classic",
        "pr2.mobile.MobileMessagesPage": args.configuration != "classic",
        "pr2.mobile.MobileProfilePopup": args.configuration != "classic",
        "pr2.mobile.MobileGuildPopup": args.configuration != "classic",
        "pr2.mobile.MobileGuildEditorPopup": args.configuration != "classic",
        "pr2.mobile.MobileGuildTransferPopup": args.configuration != "classic",
        "pr2.mobile.MobileLevelInfoPopup": args.configuration != "classic",
        "pr2.mobile.MobileConfirmPopup": args.configuration != "classic",
        "pr2.mobile.MobileRequestPopup": args.configuration != "classic",
        "pr2.mobile.MobilePartInfoPopup": args.configuration != "classic",
        "pr2.mobile.MobileStaffPopup": args.configuration != "classic",
        "pr2.mobile.MobileMessagePopup": args.configuration != "classic",
        "pr2.mobile.MobilePrizePopup": args.configuration != "classic",
        "pr2.mobile.MobileLuxPopup": args.configuration != "classic",
        "pr2.mobile.MobileOptionsPopup": args.configuration != "classic",
        "pr2.mobile.MobileCredentialPopup": args.configuration != "classic",
        "pr2.mobile.MobileCreditsPopup": args.configuration != "classic",
        "pr2.mobile.MobileComposePopup": args.configuration != "classic",
        "pr2.lobby.dialogs.PlayerPopup": args.configuration != "mobile",
        "pr2.lobby.dialogs.PlayerGuestPopup": args.configuration != "mobile",
        "pr2.lobby.dialogs.PlayerView": args.configuration != "mobile",
        "pr2.lobby.dialogs.SendMessagePopup": args.configuration != "mobile",
        "pr2.lobby.dialogs.SendMessageView": args.configuration != "mobile",
        "pr2.lobby.tabs.MessagesTab": args.configuration != "mobile",
        "pr2.lobby.tabs.MessagesView": args.configuration != "mobile",
        "pr2.lobby.tabs.PlayersTab": args.configuration != "mobile",
        "pr2.lobby.players.PlayersTabListView": args.configuration != "mobile",
        "pr2.lobby.tabs.AccountTab": args.configuration != "mobile",
        "pr2.lobby.tabs.AccountInfoView": args.configuration != "mobile",
        "pr2.gameplay.FinishedPage": args.configuration != "mobile",
        "pr2.gameplay.FinishedPageView": args.configuration != "mobile",
        "pr2.gameplay.ClassicGameHud": args.configuration != "mobile",
    }.items():
        if ('"' + name + '"' in source) != included:
            raise SystemExit(f"Presentation build boundary failed: {name}")
    if ("pr2-ui-preview" in source) != (args.configuration == "preview"):
        raise SystemExit("Preview selector leaked into a release or is missing from preview")
    html = (root / "index.html").read_text()
    for font in ["LilitaOne-Regular.ttf", "Nunito-Bold.ttf"]:
        if (font in html) != (args.configuration != "classic"):
            raise SystemExit(f"UI font registration failed for {font}")
    # Lime retains copied files when rebuilding into the same output folder.
    # Only remove this build-owned directory, never source assets.
    if args.configuration == "classic":
        shutil.rmtree(root / "assets/mobile", ignore_errors=True)
    print(f"UI build boundary passed: {args.configuration}")


if __name__ == "__main__":
    main()
