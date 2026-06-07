package dialogs
{
    import fl.controls.CheckBox;
    import dialogs.AutoDismissPopup;
    import flash.display.DisplayObject;
    import com.jiggmin.data.Settings;

    public class OptionsArtQualityMenu extends AutoDismissPopup 
    {
        public static var instance;

        private var m:OptionsArtQualityMenuGraphic = new OptionsArtQualityMenuGraphic();

        public function OptionsArtQualityMenu(d:DisplayObject)
        {
            if (OptionsArtQualityMenu.instance != null) {
                OptionsArtQualityMenu.instance.remove();
            }
            OptionsArtQualityMenu.instance = this;
            addChild(this.m);
            super(d);
            this.m.lossless_chk.selected = Settings.getValue(Settings.ART_LOSSLESS_QUALITY, false);
        }

        override public function remove()
        {
            if (OptionsArtQualityMenu.instance === this) {
                OptionsArtQualityMenu.instance = null;
            }
            Settings.setValue(Settings.ART_LOSSLESS_QUALITY, this.m.lossless_chk.selected);
            super.remove();
        }


    }
}
