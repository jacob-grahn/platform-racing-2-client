// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_19.class_267

package package_19
{
    import package_4.class_264;
    import ui.GameSound;
    import flash.events.Event;
    import levelEditor.LevelEditor;

    public class class_267 extends class_264 
    {

        private var list:GameSound = new GameSound(true);
        private var target:class_218;

        public function class_267(_arg_1:class_218, _arg_2:String)
        {
            this.target = _arg_1;
            this.list.x = (-(this.list.width) / 2);
            this.list.y = -15;
            this.list.setSong(_arg_2);
            addChild(new MusicMenuGraphic());
            addChild(this.list);
            super(_arg_1);
            this.list.addEventListener(Event.CHANGE, this.changeSong, false, 0, true);
        }

        // method_65 = changeSong
        private function changeSong(e:Event)
        {
            LevelEditor.editor.setSong(e.target.selectedItem.id);
        }

        override public function remove()
        {
            this.list.removeEventListener(Event.CHANGE, this.changeSong);
            this.list.remove();
            super.remove();
        }


    }
}//package package_19

