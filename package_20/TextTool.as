// package_20.TextTool = package_20.class_273

package package_20
{
    import background.ObjectBackground;
    import flash.geom.Point;
    import levelEditor.TextObject;

    public class TextTool extends class_269 
    {

        public function TextTool()
        {
            super(-1);
            applyCursorGraphic(new TextToolCursorGraphic());
            hideMouse();
        }

        // _loc3 = layer
        // _loc4 = dropPt
        // _loc5 = textObj
        override protected function dropObject(dropX:int, dropY:int)
        {
            var layer:ObjectBackground = editor.cur;
            var dropPt:Point = editor.cur.globalToLocal(new Point(dropX - 5, dropY - 16));
            var textObj:TextObject = layer.addText(" ", dropPt.x, dropPt.y, TextObject.var_380, true);
            textObj.select();
            textObj.startEditing();
            remove();
        }


    }
}
