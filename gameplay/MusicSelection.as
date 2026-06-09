// gameplay.MusicSelection = gameplay.class_85

package gameplay
{
    import ui.GameSound;

    public class MusicSelection extends Removable 
    {

        private var m:MusicSelectionGraphic = new MusicSelectionGraphic();
        public var dropdown:GameSound = new GameSound();

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
