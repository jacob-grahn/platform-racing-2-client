// package_18.LoadoutsPopup = package_18.class_290

package package_18
{
    import com.jiggmin.data.Settings;
    import package_4.GetLevelsPopup;
    import package_8.Character;
    import ui.StatsSelect;
    import ui.class_229;
    import package_4.MessagePopup;

    public class LoadoutsPopup extends GetLevelsPopup 
    {

        private var character:Character; // var_5
        private var statsSelect:StatsSelect; // var_158
        private var playerDisplay:PlayerDisplay; // var_495

        public function LoadoutsPopup(c:Character, ss:StatsSelect, pd:PlayerDisplay)
        {
            this.character = c;
            this.statsSelect = ss;
            this.playerDisplay = pd;
            this.var_454 = 68;
            m.titleBox.text = "-- Loadouts --";
            m.delete_bt.label = "Save";
            hideLoadingGraphic();
            this.populate();
        }

        // _loc1 = presets
        // _loc2 = preset
        // _loc3 = listing
        // method_751 = populate
        private function populate()
        {
            var presets:Vector.<Preset> = Presets.getPresets();
            for each (var preset:Preset in presets) {
                var listing:PresetListing = new PresetListing(preset);
                this.method_455(listing);
            }
        }

        // _loc2 = listing
        // _loc3 = preset
        override protected function loadListing(_arg_1:class_229)
        {
            if (!Settings.isNameSet()) {
                new MessagePopup('Error: You are not logged in.');
                startFadeOut();
                return;
            }
            var listing:PresetListing = PresetListing(_arg_1);
            var preset:Preset = listing.getPreset();
            Presets.apply(preset, this.character, this.statsSelect, this.playerDisplay);
            startFadeOut();
        }

        // _loc2 = loadout
        // _loc3 = preset
        // _loc4 = stats
        // actually saves; named deleteListing to replace the delete button on GetLevelsPopup
        override protected function deleteListing(_arg_1:class_229)
        {
            var listing:PresetListing = PresetListing(_arg_1);
            var preset:Object = listing.getPreset();
            var stats:Object = this.statsSelect.getStats();
            preset.speed = stats.speed;
            preset.acceleration = stats.acceleration;
            preset.jumping = stats.jumping;
            preset.hat = this.character.hat1;
            preset.head = this.character.head;
            preset.body = this.character.body;
            preset.feet = this.character.feet;
            preset.hatColor = this.character.hat1Color;
            preset.headColor = this.character.headColor;
            preset.bodyColor = this.character.bodyColor;
            preset.feetColor = this.character.feetColor;
            preset.hatColor2 = this.playerDisplay.hasOwnProperty('hatSelect') ? this.playerDisplay.hatSelect.getColorCP2() : this.character.hat1Color2;
            preset.headColor2 = this.playerDisplay.hasOwnProperty('headSelect') ? this.playerDisplay.headSelect.getColorCP2() : this.character.headColor2;
            preset.bodyColor2 = this.playerDisplay.hasOwnProperty('bodySelect') ? this.playerDisplay.bodySelect.getColorCP2() : this.character.bodyColor2;
            preset.feetColor2 = this.playerDisplay.hasOwnProperty('feetSelect') ? this.playerDisplay.feetSelect.getColorCP2() : this.character.feetColor2;
            Presets.savePresets();
            startFadeOut();
        }

        override public function remove()
        {
            this.character = null;
            this.statsSelect = null;
            this.playerDisplay = null;
            super.remove();
        }


    }
}//package package_18

