// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_18.class_290

package package_18
{
    import package_4.GetLevelsPopup;
    import package_8.Character;
    import ui.StatsSelect;
    import __AS3__.vec.Vector;
    import ui.class_229;

    public class class_290 extends GetLevelsPopup 
    {

        private var var_5:Character;
        private var var_158:StatsSelect;
        private var var_495:class_262;

        public function class_290(_arg_1:Character, _arg_2:StatsSelect, _arg_3:class_262)
        {
            this.var_5 = _arg_1;
            this.var_158 = _arg_2;
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
            class_211.apply(_local_3, this.var_5, this.var_158, this.var_495);
            startFadeOut();
        }

        override protected function deleteListing(_arg_1:class_229)
        {
            var _local_2:class_306 = class_306(_arg_1);
            var _local_3:Object = _local_2.method_239();
            var _local_4:Object = this.var_158.method_550();
            _local_3.speed = _local_4.speed;
            _local_3.acceleration = _local_4.acceleration;
            _local_3.jumping = _local_4.jumping;
            _local_3.hat = this.var_5.hat1;
            _local_3.head = this.var_5.head;
            _local_3.body = this.var_5.body;
            _local_3.feet = this.var_5.feet;
            _local_3.hatColor = this.var_5.hat1Color;
            _local_3.headColor = this.var_5.headColor;
            _local_3.bodyColor = this.var_5.bodyColor;
            _local_3.feetColor = this.var_5.feetColor;
            _local_3.hatColor2 = this.var_5.hat1Color2;
            _local_3.headColor2 = this.var_5.headColor2;
            _local_3.bodyColor2 = this.var_5.bodyColor2;
            _local_3.feetColor2 = this.var_5.feetColor2;
            class_211.method_533();
            startFadeOut();
        }

        override public function remove()
        {
            this.var_5 = null;
            this.var_158 = null;
            this.var_495 = null;
            super.remove();
        }


    }
}//package package_18

