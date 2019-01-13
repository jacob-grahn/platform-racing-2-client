// package_20.TextTool = package_20.class_273

package package_20
{
    import background.class_77;
    import flash.geom.Point;
    import levelEditor.class_131;

    public class TextTool extends class_269 
    {

        public function TextTool()
        {
            super(-1);
            method_63(new TextToolCursorGraphic());
            method_332();
        }

        override protected function dropObject(_arg_1:int, _arg_2:int)
        {
            var _local_3:class_77 = editor.cur;
            var _local_4:Point = new Point((_arg_1 - 5), (_arg_2 - 16));
            _local_4 = editor.cur.globalToLocal(_local_4);
            var _local_5:class_131 = _local_3.method_129(" ", _local_4.x, _local_4.y, class_131.var_380, true);
            _local_5.select();
            _local_5.method_270();
            remove();
        }


    }
}
