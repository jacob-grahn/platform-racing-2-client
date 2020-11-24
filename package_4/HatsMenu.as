package package_4
{
    import fl.controls.CheckBox;
    import flash.display.DisplayObject;

    public class HatsMenu extends InfoPopup
    {
        private var m:HatsMenuGraphic = new HatsMenuGraphic();
        private var highestHatID:int = Parts.getPartArray('HAT').length + 1;

        public function HatsMenu(hatsStr:String, gameMode:String, d:DisplayObject)
        {
            this.parseHats(hatsStr, gameMode);
            for (var i = 2; i <= highestHatID; i++) {
                this.m["hat" + i].enabled = false;
            }
            addChild(this.m);
            super(d);
        }

        private function parseHats(hatsStr:String, gameMode:String)
        {
            if (gameMode == 'Hat Attack') { // explicitly disable arti for hat attack (for hat attack levels made prior to 161)
                this.m.hat14.selected = false;
            }
            if (hatsStr == '' || hatsStr == null) {
                return;
            } else {
                var badHatsArr:Array = hatsStr.split(',');
                for (var i:int in badHatsArr) {
                    var hatID:int = badHatsArr[i];
                    if ((!isNaN(hatID) && hatID > 1 && hatID <= this.highestHatID)) {
                        this.m["hat" + hatID].selected = false;
                    }
                }
            }
        }

        override public function remove()
        {
            super.remove();
        }


    }
}
