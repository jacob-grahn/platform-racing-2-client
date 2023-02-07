package package_4
{
    import com.jiggmin.data.Settings;
    import fl.controls.CheckBox;
    import flash.display.DisplayObject;
    import package_4.class_264;

    public class OptionsSongsMenu extends class_264 
    {
        public static var instance;
        private var m:OptionsSongsMenuGraphic = new OptionsSongsMenuGraphic();

        public function OptionsSongsMenu(d:DisplayObject)
        {
            if (OptionsSongsMenu.instance != null) {
                OptionsSongsMenu.instance.remove();
            }
            OptionsSongsMenu.instance = this;
            y -= 45;
            addChild(this.m);
            super(d);
            var blacklist:Array = Settings.getValue(Settings.DISABLED_SONGS);
            for (var i in blacklist) {
                this.m['song' + blacklist[i]].selected = false;
            }
        }

        override public function remove()
        {
            if (OptionsSongsMenu.instance === this) {
                OptionsSongsMenu.instance = null;
            }
            var blacklist:Array = [];
            for (var i:int = 1; i <= 21; i++) {
                if (i == 9 || i == 16) {
                    continue; // skip songs #9 (desert rose) and #16 (we are loud)
                }
                if (this.m['song' + i].selected == false) {
                    blacklist.push(i);
                }
            }
            Settings.setValue(Settings.DISABLED_SONGS, blacklist);
            super.remove();
        }


    }
}
