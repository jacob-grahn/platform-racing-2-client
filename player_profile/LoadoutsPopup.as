// player_profile.LoadoutsPopup = player_profile.class_290

package player_profile
{
    import com.jiggmin.data.Settings;
    import dialogs.GetLevelsPopup;
    import character.Character;
    import ui.StatsSelect;
    import ui.SelectableButton;
    import dialogs.MessagePopup;

    public class LoadoutsPopup extends GetLevelsPopup 
    {
        private var charModel:Character; // var_5
        private var statsSelect:StatsSelect; // var_158
        private var playerDisplay:PlayerDisplay; // var_495

        public function LoadoutsPopup(c:Character, ss:StatsSelect, pd:PlayerDisplay)
        {
            this.charModel = c;
            this.statsSelect = ss;
            this.playerDisplay = pd;
            this.itemSpacing = 68;
            m.titleBox.text = "-- Loadouts --";
            m.delete_bt.label = "Save";
            hideLoadingGraphic();
            this.populate();
        }

        private function populate()
        {
            var presets:Vector.<Preset> = Presets.getPresets();
            for each (var preset:Preset in presets) {
                var listing:PresetListing = new PresetListing(preset, this.playerDisplay);
                this.addListing(listing);
            }
        }

        override protected function loadListing(btn:SelectableButton)
        {
            if (!Settings.isNameSet()) {
                new MessagePopup('Error: You are not logged in.');
                startFadeOut();
                return;
            }
            var listing:PresetListing = PresetListing(btn);
            var preset:Preset = listing.getPreset();
            Presets.apply(preset, this.charModel, this.statsSelect, this.playerDisplay);
            startFadeOut();
        }

        // actually saves; named deleteListing to replace the delete button on GetLevelsPopup
        override protected function deleteListing(btn:SelectableButton)
        {
            var listing:PresetListing = PresetListing(btn);
            var preset:Object = listing.getPreset();
            var stats:Object = this.statsSelect.getStats();
            preset.speed = stats.speed;
            preset.acceleration = stats.acceleration;
            preset.jumping = stats.jumping;
            preset.hat = this.charModel.hat1;
            preset.head = this.charModel.head;
            preset.body = this.charModel.body;
            preset.feet = this.charModel.feet;
            preset.hatColor = this.charModel.hat1Color;
            preset.headColor = this.charModel.headColor;
            preset.bodyColor = this.charModel.bodyColor;
            preset.feetColor = this.charModel.feetColor;
            preset.hatColor2 = this.playerDisplay.hasOwnProperty('hatSelect') ? this.playerDisplay.hatSelect.getColorCP2() : this.charModel.hat1Color2;
            preset.headColor2 = this.playerDisplay.hasOwnProperty('headSelect') ? this.playerDisplay.headSelect.getColorCP2() : this.charModel.headColor2;
            preset.bodyColor2 = this.playerDisplay.hasOwnProperty('bodySelect') ? this.playerDisplay.bodySelect.getColorCP2() : this.charModel.bodyColor2;
            preset.feetColor2 = this.playerDisplay.hasOwnProperty('feetSelect') ? this.playerDisplay.feetSelect.getColorCP2() : this.charModel.feetColor2;
            Presets.savePresets();
            startFadeOut();
        }

        override public function remove()
        {
            this.charModel = null;
            this.statsSelect = null;
            this.playerDisplay = null;
            super.remove();
        }


    }
}//package player_profile

