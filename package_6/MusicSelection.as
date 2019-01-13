// package_6.MusicSelection = package_6.class_85

package package_6
{
    import ui.GameSound;

    public class MusicSelection extends class_7 
    {

        private var m:MusicSelectionGraphic = new MusicSelectionGraphic();
        public var dropdown:GameSound = new GameSound(); // var_216

        public function MusicSelection()
        {
            addChild(this.m);
            this.dropdown.x = 7;
            this.dropdown.y = 7;
            addChild(this.dropdown);
        }

        public function setSong(s:String)
        {
            this.dropdown.setSong(s);
        }

        override public function remove()
        {
            this.dropdown.remove();
            super.remove();
        }


    }
}
