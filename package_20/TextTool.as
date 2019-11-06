// package_20.TextTool = package_20.class_273

package package_20
{
    import background.class_77;
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

        // _loc5 = textObj
        override protected function dropObject(_arg_1:int, _arg_2:int)
        {
            var _local_3:class_77 = editor.cur;
            var _local_4:Point = new Point((_arg_1 - 5), (_arg_2 - 16));
            _local_4 = editor.cur.globalToLocal(_local_4);
            var textObj:TextObject = _local_3.method_129(" ", _local_4.x, _local_4.y, TextObject.var_380, true);
            textObj.select();
            textObj.startEditing();
            remove();
        }


    }
}
