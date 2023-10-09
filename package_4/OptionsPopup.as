// package_4.OptionsPopup = package_4.class_200

package package_4
{
    import com.jiggmin.data.Data;
    import com.jiggmin.data.Settings;
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import fl.events.SliderEvent;
    import flash.net.URLRequest;
    import sounds.SoundEffects;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;

    public class OptionsPopup extends Popup 
    {

        private var m:OptionsPopupGraphic = new OptionsPopupGraphic();
        private var filterSwears:Boolean = Settings.getValue(Settings.FILTER_SWEARS, true);
        private var drawArt:Boolean = Settings.getValue(Settings.DRAW_ART, true);
        private var altCtrl:Object = Settings.getValue(Settings.ALTERNATE_CONTROLS, Settings.DEFAULT_ALT_CONTROLS);
        private var hTrueY:Number = -71.5;
        private var hFalseY:Number = -43.5;
        private var buttonStartPos:int = 80; // var_437
        private var hoverActive:HoverPopup;

        public function OptionsPopup()
        {
            addChild(this.m);
            this.m.musicSlider.value = Settings.musicLevel;
            this.m.musicSlider.addEventListener(SliderEvent.CHANGE, musicSliderChange, false, 0, true);
            this.m.soundSlider.value = Settings.soundLevel;
            this.m.soundSlider.addEventListener(SliderEvent.CHANGE, soundSliderChange, false, 0, true);
            this.m.soundSlider.addEventListener(SliderEvent.THUMB_RELEASE, soundSliderRelease, false, 0, true);
            this.m.musicPercentBox.text = Settings.musicLevel + '%';
            this.m.soundPercentBox.text = Settings.soundLevel + '%';
            this.m.wasdUp.maxChars = this.m.wasdRight.maxChars = this.m.wasdDown.maxChars = this.m.wasdLeft.maxChars = this.m.wasdItem.maxChars = 1;
            this.m.wasdUp.restrict = this.m.wasdRight.restrict = this.m.wasdDown.restrict = this.m.wasdLeft.restrict = this.m.wasdItem.restrict = "0-9 A-Z";
            this.m.wasdUp.text = String.fromCharCode(this.altCtrl.up).toUpperCase();
            this.m.wasdRight.text = String.fromCharCode(this.altCtrl.right).toUpperCase();
            this.m.wasdDown.text = String.fromCharCode(this.altCtrl.down).toUpperCase();
            this.m.wasdLeft.text = String.fromCharCode(this.altCtrl.left).toUpperCase();
            this.m.wasdItem.text = String.fromCharCode(this.altCtrl.item).toUpperCase();
            this.m.filterHighlight.y = this.filterSwears === false ? this.hFalseY : this.hTrueY;
            this.m.artHighlight.y = this.drawArt === false ? this.hFalseY : this.hTrueY;
            this.m.filterOn_bt.addEventListener(MouseEvent.CLICK, toggleFilterOn, false, 0, true);
            this.m.filterOff_bt.addEventListener(MouseEvent.CLICK, toggleFilterOff, false, 0, true);
            this.m.artOn_bt.addEventListener(MouseEvent.CLICK, toggleArtOn, false, 0, true);
            this.m.artOff_bt.addEventListener(MouseEvent.CLICK, toggleArtOff, false, 0, true);
            this.m.music_bt.addEventListener(MouseEvent.CLICK, clickMusic, false, 0, true);
            this.m.music_bt.addEventListener(MouseEvent.MOUSE_OVER, hoverMusic, false, 0, true);
            this.m.music_bt.addEventListener(MouseEvent.MOUSE_OUT, hoverOut, false, 0, true);
            this.toggleArtBtnListeners(this.drawArt);
            this.m.removeChild(this.m.changePass_bt);
            this.m.removeChild(this.m.changeEmail_bt);
            this.m.removeChild(this.m.guildLeave_bt);
            this.m.removeChild(this.m.guildCreate_bt);
            this.m.removeChild(this.m.guildEdit_bt);
            this.m.removeChild(this.m.guildTransfer_bt);
            if (Main.group != 0) {
                this.addOptionsButton(this.m.changePass_bt, this.clickChangePass);
                this.addOptionsButton(this.m.changeEmail_bt, this.clickChangeEmail);
                if (Main.guild != 0) {
                    if (Main.guildOwner == 0) {
                        this.addOptionsButton(this.m.guildLeave_bt, this.clickLeaveGuild);
                    } else {
                        this.addOptionsButton(this.m.guildTransfer_bt, this.clickGuildTransfer);
                        this.addOptionsButton(this.m.guildEdit_bt, this.clickGuildEdit);
                    }
                } else {
                    this.addOptionsButton(this.m.guildCreate_bt, this.clickGuildCreate);
                }
            }
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose, false, 0, true);
        }

        private function toggleArtBtnListeners(on:Boolean)
        {
            this.m.artOffText.visible = !on;
            this.m.art_bt.visible = on;
            this.m.art_bt.removeEventListener(MouseEvent.CLICK, clickArt);
            this.m.art_bt.removeEventListener(MouseEvent.MOUSE_OVER, hoverArt);
            this.m.art_bt.removeEventListener(MouseEvent.MOUSE_OUT, hoverOut);
            if (on) {
                this.m.art_bt.addEventListener(MouseEvent.CLICK, clickArt, false, 0, true);
                this.m.art_bt.addEventListener(MouseEvent.MOUSE_OVER, hoverArt, false, 0, true);
                this.m.art_bt.addEventListener(MouseEvent.MOUSE_OUT, hoverOut, false, 0, true);
            }
        }

        private function musicSliderChange(e:SliderEvent)
        {
            var newLevel:int = Data.numLimit(e.value, 0, 100);
            if (Settings.musicLevel === 0 && newLevel > 0) {
                Main.noodleTown.startPlaying();
            }
            Settings.setValue(Settings.MUSIC_VOLUME, newLevel);
            this.m.musicPercentBox.text = Settings.musicLevel + '%';
            Main.noodleTown.setTargetVolume(0.6 * (Settings.musicLevel / 100));
        }

        private function soundSliderChange(e:SliderEvent)
        {
            Settings.setValue(Settings.SOUND_VOLUME, Data.numLimit(e.value, 0, 100));
            this.m.soundPercentBox.text = Settings.soundLevel + '%';
        }

        private function soundSliderRelease(e:SliderEvent)
        {
            SoundEffects.playSound(new JumpSound(), 0.75 * (Settings.soundLevel / 100));
        }

        private function toggleFilterOn(e:MouseEvent)
        {
            this.m.filterHighlight.y = this.hTrueY;
            this.filterSwears = true;
        }

        private function toggleFilterOff(e:MouseEvent)
        {
            this.m.filterHighlight.y = this.hFalseY;
            this.filterSwears = false;
        }

        private function toggleArtOn(e:MouseEvent)
        {
            this.m.artHighlight.y = this.hTrueY;
            this.drawArt = true;
            this.toggleArtBtnListeners(true);
        }

        private function toggleArtOff(e:MouseEvent)
        {
            this.m.artHighlight.y = this.hFalseY;
            this.drawArt = false;
            this.toggleArtBtnListeners(false);
        }

        private function clickArt(e:MouseEvent)
        {
            new OptionsArtQualityMenu(e.currentTarget);
        }

        private function hoverArt(e:MouseEvent)
        {
            this.hoverActive = new HoverPopup("Choose Art Quality", "Choose whether to draw art with lossless quality. This setting may degrade performance on some systems.", this.m.art_bt);
            this.hoverActive.x += 5;
        }

        private function clickMusic(e:MouseEvent)
        {
            new OptionsSongsMenu(e.currentTarget);
        }

        private function hoverMusic(e:MouseEvent)
        {
            this.hoverOut();
            this.hoverActive = new HoverPopup("Choose Music", "Choose which songs are allowed to play in a level.", this.m.music_bt);
        }

        private function hoverOut(e:* = null)
        {
            if (this.hoverActive != null) {
                this.hoverActive.remove();
                this.hoverActive = null;
            }
        }

        // method_75 = addOptionsButton
        private function addOptionsButton(button:DisplayObject, fn:Function)
        {
            this.m.addChild(button);
            button.y = this.buttonStartPos;
            this.buttonStartPos = this.buttonStartPos - 20;
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
            var req:URLRequest = new URLRequest(Main.baseURL + "/guild_leave.php");
            req.data = new URLVariables();
            req.method = URLRequestMethod.POST;
            var uploadingPopup:UploadingPopup = new UploadingPopup(req, 'json', 'Leaving guild...');
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

        private function clickGuildTransfer(e:MouseEvent)
        {
            new TransferGuildPopup()
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
            if (OptionsSongsMenu.instance != null) {
                OptionsSongsMenu.instance.remove();
            }
            this.m.changePass_bt.removeEventListener(MouseEvent.CLICK, this.clickChangePass);
            this.m.changeEmail_bt.removeEventListener(MouseEvent.CLICK, this.clickChangeEmail);
            this.m.guildLeave_bt.removeEventListener(MouseEvent.CLICK, this.clickLeaveGuild);
            this.m.guildCreate_bt.removeEventListener(MouseEvent.CLICK, this.clickGuildCreate);
            this.m.guildEdit_bt.removeEventListener(MouseEvent.CLICK, this.clickGuildEdit);
            this.m.guildTransfer_bt.removeEventListener(MouseEvent.CLICK, this.clickGuildTransfer);
            this.m.music_bt.removeEventListener(MouseEvent.CLICK, clickMusic);
            this.m.music_bt.removeEventListener(MouseEvent.MOUSE_OVER, hoverMusic);
            this.m.music_bt.removeEventListener(MouseEvent.MOUSE_OUT, hoverOut);
            this.toggleArtBtnListeners(false);
            this.hoverOut();
            if (this.m.wasdUp.text == "") {
                this.m.wasdUp.text = "W";
            }
            if (this.m.wasdRight.text == "") {
                this.m.wasdRight.text = "D";
            }
            if (this.m.wasdDown.text == "") {
                this.m.wasdDown.text = "S";
            }
            if (this.m.wasdLeft.text == "") {
                this.m.wasdLeft.text = "A";
            }
            if (this.m.wasdItem.text == "") {
                this.m.wasdItem.text = "I";
            }
            this.altCtrl.up = this.m.wasdUp.text.toUpperCase().charCodeAt(0);
            this.altCtrl.right = this.m.wasdRight.text.toUpperCase().charCodeAt(0);
            this.altCtrl.down = this.m.wasdDown.text.toUpperCase().charCodeAt(0);
            this.altCtrl.left = this.m.wasdLeft.text.toUpperCase().charCodeAt(0);
            this.altCtrl.item = this.m.wasdItem.text.toUpperCase().charCodeAt(0);
            Settings.setValue(Settings.ALTERNATE_CONTROLS, this.altCtrl);
            Settings.setValue(Settings.DRAW_ART, this.drawArt);
            Settings.setValue(Settings.FILTER_SWEARS, this.filterSwears);
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}//package package_4

