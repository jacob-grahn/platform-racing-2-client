package drawing_tools
{
    import background.ObjectBackground;
    import flash.geom.Point;
    import levelEditor.TextObject;

    public class TextTool extends ObjectPlacer 
    {

        public function TextTool()
        {
            super(-1);
            applyCursorGraphic(new TextToolCursorGraphic());
            hideMouse();
        }

        override protected function dropObject(dropX:int, dropY:int)
        {
            var layer:ObjectBackground = editor.cur;
            var dropPt:Point = editor.cur.globalToLocal(new Point(dropX - 5, dropY - 16));
            var textObj:TextObject = layer.addText("", dropPt.x, dropPt.y, TextObject.lastColor, true);
            textObj.select();
            textObj.startEditing();
            remove();
        }


    }
}
