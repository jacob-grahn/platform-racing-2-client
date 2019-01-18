// package_18.LoadoutsPopup = package_18.class_290

package package_18
{
    import package_4.GetLevelsPopup;
    import package_8.Character;
    import ui.StatsSelect;
    import ui.class_229;

    public class LoadoutsPopup extends GetLevelsPopup 
    {

        private var character:Character; // var_5
        private var statsSelect:StatsSelect; // var_158
        private var var_495:class_262;

        public function LoadoutsPopup(c:Character, ss:StatsSelect, _arg_3:class_262)
        {
            this.character = c;
            this.statsSelect = ss;
            this.var_495 = _arg_3;
            this.var_454 = 68;
            m.titleBox.text = "--- Loadouts ---";
            m.delete_bt.label = "Save";
            hideLoadingGraphic();
            this.method_751();
        }

        private function method_751()
        {
            var _local_2:class_263;
            var _local_3:class_306;
            var _local_1:Vector.<class_263> = class_211.method_766();
            for each (_local_2 in _local_1) {
                _local_3 = new class_306(_local_2);
                this.method_455(_local_3);
            }
        }

        override protected function loadListing(_arg_1:class_229)
        {
            var _local_2:class_306 = class_306(_arg_1);
            var _local_3:class_263 = _local_2.method_239();
            class_211.apply(_local_3, this.character, this.statsSelect, this.var_495);
            startFadeOut();
        }

        override protected function deleteListing(_arg_1:class_229)
        {
            var _local_2:class_306 = class_306(_arg_1);
            var _local_3:Object = _local_2.method_239();
            var _local_4:Object = this.statsSelect.getStats();
            _local_3.speed = _local_4.speed;
            _local_3.acceleration = _local_4.acceleration;
            _local_3.jumping = _local_4.jumping;
            _local_3.hat = this.character.hat1;
            _local_3.head = this.character.head;
            _local_3.body = this.character.body;
            _local_3.feet = this.character.feet;
            _local_3.hatColor = this.character.hat1Color;
            _local_3.headColor = this.character.headColor;
            _local_3.bodyColor = this.character.bodyColor;
            _local_3.feetColor = this.character.feetColor;
            _local_3.hatColor2 = this.character.hat1Color2;
            _local_3.headColor2 = this.character.headColor2;
            _local_3.bodyColor2 = this.character.bodyColor2;
            _local_3.feetColor2 = this.character.feetColor2;
            class_211.method_533();
            startFadeOut();
        }

        override public function remove()
        {
            this.character = null;
            this.statsSelect = null;
            this.var_495 = null;
            super.remove();
        }


    }
}//package package_18

