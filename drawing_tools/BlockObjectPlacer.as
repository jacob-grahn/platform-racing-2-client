package drawing_tools
{
    import background.BlockBackground;
    import levelEditor.LevelEditor;
    import background.ObjectBackground;
    import flash.geom.Point;
    import levelEditor.BlockObject;
    import flash.events.MouseEvent;

    public class BlockObjectPlacer extends ObjectPlacer 
    {

        private var blockBackground:BlockBackground = LevelEditor.editor.blockBG;

        public function BlockObjectPlacer(code:int)
        {
            super(code);
        }

        override protected function dropObject(dropX:int, dropY:int)
        {
            var block:BlockObject = this.getBlock(dropX, dropY);
            if (block == null) {
                var layer:ObjectBackground = editor.cur;
                var pt:Point = new Point(dropX, dropY);
                pt = editor.cur.globalToLocal(pt);
                pt.x = (pt.x - 15);
                pt.y = (pt.y - 15);
                pt.x = Math.round(pt.x);
                pt.y = Math.round(pt.y);
                layer.addObject(displayCode, pt.x, pt.y);
            }
        }

        override protected function mouseMoveHandler(e:MouseEvent)
        {
            super.mouseMoveHandler(e);
            if (isMouseDown()) {
                if (!editor.cur.hitTestPoint(e.stageX, e.stageY, true)) {
                    this.dropObject(e.stageX, e.stageY);
                }
            }
        }

        private function getBlock(x:int, y:int):BlockObject
        {
            var pt:Point = new Point(x, y);
            pt = this.blockBackground.globalToLocal(pt);
            var block:BlockObject = this.blockBackground.getBlockAt((pt.x - 15), (pt.y - 15));
            return (block);
        }

        override public function remove()
        {
            this.blockBackground = null;
            super.remove();
        }


    }
}//package drawing_tools

