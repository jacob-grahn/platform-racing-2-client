// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_4.OptionsPopup = package_4.class_200

package package_4
{
    import data.Settings;
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.URLRequest;

    public class OptionsPopup extends Popup 
    {

        private var m:OptionsPopupGraphic = new OptionsPopupGraphic();
        private var var_437:int = -22;

        public function OptionsPopup()
        {
            addChild(this.m);
            this.m.wasdUp.maxChars = this.m.wasdRight.maxChars = this.m.wasdDown.maxChars = this.m.wasdLeft.maxChars = this.m.wasdItem.maxChars = 1;
            this.m.wasdUp.restrict = this.m.wasdRight.restrict = this.m.wasdDown.restrict = this.m.wasdLeft.restrict = this.m.wasdItem.restrict = "0-9 A-Z a-Z";
            this.m.wasdUp.text = String.fromCharCode(Main.wasdUp).toLowerCase();
            this.m.wasdRight.text = String.fromCharCode(Main.wasdRight).toLowerCase();
            this.m.wasdDown.text = String.fromCharCode(Main.wasdDown).toLowerCase();
            this.m.wasdLeft.text = String.fromCharCode(Main.wasdLeft).toLowerCase();
            this.m.wasdItem.text = String.fromCharCode(Main.wasdItem).toLowerCase();
            this.m.toggleMusic.selected = (Main.musicLevel != "none");
            this.m.toggleBGs.selected = Main.drawBackgrounds;
            this.m.toggleSwears.selected = Settings.method_135(Settings.filterSwears, true);
            this.m.removeChild(this.m.changePass_bt);
            this.m.removeChild(this.m.changeEmail_bt);
            this.m.removeChild(this.m.guildLeave_bt);
            this.m.removeChild(this.m.guildCreate_bt);
            this.m.removeChild(this.m.guildEdit_bt);
            if (Main.group != 0) {
                this.addOptionsButton(this.m.changePass_bt, this.clickChangePass);
                this.addOptionsButton(this.m.changeEmail_bt, this.clickChangeEmail);
                if (Main.guild != 0) {
                    this.addOptionsButton(this.m.guildLeave_bt, this.clickLeaveGuild);
                } else {
                    this.addOptionsButton(this.m.guildCreate_bt, this.clickGuildCreate);
                }
                if (Main.guildOwner == 1) {
                    this.addOptionsButton(this.m.guildEdit_bt, this.clickGuildEdit);
                }
            }
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose, false, 0, true);
        }

        // method_75 = addOptionsButton
        private function addOptionsButton(button:DisplayObject, fn:Function)
        {
            this.m.addChild(button);
            button.y = this.var_437;
            this.var_437 = this.var_437 + 20;
            button.addEventListener(MouseEvent.CLICK, fn, false, 0, true);
        }

        // method_420 = clickChangePass
        private function clickChangePass(e:MouseEvent)
        {
            new ChangePasswordPopup();
            startFadeOut();
        }

        // method_444 = clickChangeEmail
        private function clickChangeEmail(e:MouseEvent)
        {
            new SetEmailPopup();
            Main.hasEmail = true;
            startFadeOut();
        }

        // method_471 = clickLeaveGuild
        private function clickLeaveGuild(e:MouseEvent)
        {
            new ConfirmPopup(this.confirmLeaveGuild, "Are you sure you want to leave your guild?");
        }

        // method_579 = confirmLeaveGuild
        private function confirmLeaveGuild()
        {
            var uploadingPopup:UploadingPopup = new UploadingPopup(new URLRequest(Main.baseURL + "/guild_leave.php"), 'json');
            uploadingPopup.addEventListener(Event.COMPLETE, this.doLeaveGuild, false, 0, true);
            startFadeOut();
        }

        private function doLeaveGuild(e:Event)
        {
			var ret:Object = JSON.parse(e.target.data);
			if (ret && ret.success === true) {
                Main.guild = 0;
                Main.guildOwner = 0;
                Main.emblem = "";
                Main.guildName = "";
                Main.instance.dispatchEvent(new Event(Main.accountChange));
			}
        }

        // method_296 = clickGuildCreate
        private function clickGuildCreate(e:MouseEvent)
        {
            new CreateGuildPopup(0);
            startFadeOut();
        }

        // method_283 = clickGuildEdit
        private function clickGuildEdit(e:MouseEvent)
        {
            new CreateGuildPopup(Main.guild);
            startFadeOut();
        }

        // method_292 = clickClose
        private function clickClose(e:MouseEvent)
        {
            startFadeOut();
        }

        // unused?
        /*private function method_834(_arg_1:Object, _arg_2:MovieClip)
        {
            _arg_2.x = _arg_1.x + (_arg_1.width / 2);
            _arg_2.y = _arg_1.y + (_arg_1.height / 2);
        }*/

        override public function remove()
        {
            this.m.changePass_bt.removeEventListener(MouseEvent.CLICK, this.clickChangePass);
            this.m.changeEmail_bt.removeEventListener(MouseEvent.CLICK, this.clickChangeEmail);
            this.m.guildLeave_bt.removeEventListener(MouseEvent.CLICK, this.clickLeaveGuild);
            this.m.guildCreate_bt.removeEventListener(MouseEvent.CLICK, this.clickGuildCreate);
            this.m.guildEdit_bt.removeEventListener(MouseEvent.CLICK, this.clickGuildEdit);
            if (this.m.wasdUp.text == "") {
                this.m.wasdUp.text = "w";
            }
            if (this.m.wasdRight.text == "") {
                this.m.wasdRight.text = "d";
            }
            if (this.m.wasdDown.text == "") {
                this.m.wasdDown.text = "s";
            }
            if (this.m.wasdLeft.text == "") {
                this.m.wasdLeft.text = "a";
            }
            if (this.m.wasdItem.text == "") {
                this.m.wasdItem.text = "i";
            }
            Main.wasdUp = this.m.wasdUp.text.toUpperCase().charCodeAt(0);
            Main.wasdRight = this.m.wasdRight.text.toUpperCase().charCodeAt(0);
            Main.wasdDown = this.m.wasdDown.text.toUpperCase().charCodeAt(0);
            Main.wasdLeft = this.m.wasdLeft.text.toUpperCase().charCodeAt(0);
            Main.wasdItem = this.m.wasdItem.text.toUpperCase().charCodeAt(0);
            if (this.m.toggleMusic.selected) {
                if (Main.musicLevel == "none") {
                    Main.noodleTown.startPlaying();
                    Main.noodleTown.setTargetVolume(0.6);
                }
                Main.musicLevel = "medium";
            } else {
                Main.noodleTown.setTargetVolume(0);
                Main.musicLevel = "none";
            }
            Main.drawBackgrounds = this.m.toggleBGs.selected;
            Settings.method_390(Settings.filterSwears, this.m.toggleSwears.selected);
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}//package package_4

