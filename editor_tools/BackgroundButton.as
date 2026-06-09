

package editor_tools
{
    import levelEditor.LevelEditor;
    import flash.events.MouseEvent;

    public class BackgroundButton extends StampButton 
    {

        private var color:Number;

        public function BackgroundButton(code:int, color:Number=0)
        {
            super(code);
            this.color = color;
        }

        override protected function select(e:MouseEvent)
        {
            e.stopImmediatePropagation();
            LevelEditor.editor.setColor(this.color);
            LevelEditor.editor.bg.setArtBackground(displayCode);
        }


    }
}

