// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_20.class_275

package package_20
{
    import background.class_78;
    import levelEditor.LevelEditor;
    import background.class_77;
    import flash.geom.Point;
    import levelEditor.class_132;
    import flash.events.MouseEvent;

    public class class_275 extends class_269 
    {

        private var blockBackground:class_78 = LevelEditor.editor.blockBG;

        public function class_275(_arg_1:int)
        {
            super(_arg_1);
        }

        override protected function dropObject(_arg_1:int, _arg_2:int)
        {
            var _local_4:class_77;
            var _local_5:Point;
            var _local_3:class_132 = this.getBlock(_arg_1, _arg_2);
            if (_local_3 == null) {
                _local_4 = editor.cur;
                _local_5 = new Point(_arg_1, _arg_2);
                _local_5 = editor.cur.globalToLocal(_local_5);
                _local_5.x = (_local_5.x - 15);
                _local_5.y = (_local_5.y - 15);
                _local_5.x = Math.round(_local_5.x);
                _local_5.y = Math.round(_local_5.y);
                _local_4.addObject(displayCode, _local_5.x, _local_5.y);
            }
        }

        override protected function mouseMoveHandler(_arg_1:MouseEvent)
        {
            super.mouseMoveHandler(_arg_1);
            if (method_131()) {
                if (!editor.cur.hitTestPoint(_arg_1.stageX, _arg_1.stageY, true)) {
                    this.dropObject(_arg_1.stageX, _arg_1.stageY);
                }
            }
        }

        private function getBlock(_arg_1:int, _arg_2:int):class_132
        {
            var _local_3:Point = new Point(_arg_1, _arg_2);
            _local_3 = this.blockBackground.globalToLocal(_local_3);
            var _local_4:class_132 = this.blockBackground.getBlockAt((_local_3.x - 15), (_local_3.y - 15));
            return (_local_4);
        }

        override public function remove()
        {
            this.blockBackground = null;
            super.remove();
        }


    }
}//package package_20

