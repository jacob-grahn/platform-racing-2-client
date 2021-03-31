// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//levelEditor.BlockObject = levelEditor.class_132

package levelEditor
{
    import flash.geom.Point;
    import com.jiggmin.data.Objects;
    import flash.events.MouseEvent;
    import levelEditor.LevelEditor;

    public class BlockObject extends DrawObject 
    {

        private var segSize:Number = LevelEditor.segSize;
        private var optionsButton:BlockOptionsButton;
        private var lastX:Number;
        private var lastY:Number;
        public var segX:int;
        public var segY:int;
        public var posX:Number;
        public var posY:Number;
        // property m in parent class is the block

        public function BlockObject(blockId:int, blockX:Number, blockY:Number, blockOpts:String = '')
        {
            super(blockId, blockX, blockY);
            this.displayCode = blockId;
            this.lastX = x = this.method_103(blockX);
            this.lastY = y = this.method_103(blockY);
            this.segX = Math.floor(x / this.segSize);
            this.segY = Math.floor(y / this.segSize);
            this.posX = x;
            this.posY = y;
            resizable = false;
            if (this.displayCode != Objects.BLOCK_MINION_EGG && blockOpts != '') {
                this.setOptionsString(blockOpts);
            }
        }

        public function setSeg(newX:int, newY:int)
        {
            this.segX = newX;
            this.segY = newY;
            this.posX = x = this.segX * this.segSize;
            this.posY = y = this.segY * this.segSize;
        }

        public function getSeg():Point
        {
            return new Point(this.segX, this.segY);
        }

        // _loc2 = newPtSegX
        // _loc3 = newPtSegY
        // _loc4 = blockAtNewPt
        // _loc5 = overwriteExisting
        override protected function endDrag(e:MouseEvent)
        {
            var newPtSegX:Number = this.method_103(x);
            var newPtSegY:Number = this.method_103(y);
            x = this.lastX;
            y = this.lastY;
            var blockAtNewPt:BlockObject = editor.blockBG.getBlockAt(newPtSegX, newPtSegY);
            var overwriteExisting:Boolean = true;
            if (blockAtNewPt != null && blockAtNewPt != this) {
                if (blockAtNewPt.displayCode == Objects.BLOCK_START1 || blockAtNewPt.displayCode == Objects.BLOCK_START2 || blockAtNewPt.displayCode == Objects.BLOCK_START3 || blockAtNewPt.displayCode == Objects.BLOCK_START4) {
                    overwriteExisting = false;
                } else {
                    editor.cur.recordDelete(this);
                    blockAtNewPt.remove();
                }
            }
            if (overwriteExisting) {
                this.lastX = x = newPtSegX;
                this.lastY = y = newPtSegY;
            }
            editor.blockBG.moveBlock(new Point(this.segX, this.segY), new Point(Math.round(x / this.segSize), Math.round(y / this.segSize)));
            super.endDrag(e);
        }

        public function onOptionsPress(e:MouseEvent)
        {
            e.stopImmediatePropagation();
            m.openOptions();
        }

        public function getOptionsString()
        {
            return m.options;
        }

        public function setOptionsString(optsStr:String)
        {
            m.applyOptions(optsStr);
        }

        override public function select()
        {
            super.select();
            if (deleteable && m.hasOptions) {
                this.showOptionsButton();
            }
            this.positionInternals();
        }

        override public function deselect()
        {
            super.deselect();
            this.hideOptionsButton();
        }

        private function showOptionsButton()
        {
            this.optionsButton = new BlockOptionsButton();
            this.optionsButton.addEventListener(MouseEvent.MOUSE_DOWN, this.onOptionsPress, false, 0, true);
            addChild(this.optionsButton);
        }

        private function hideOptionsButton()
        {
            if (this.optionsButton != null) {
                this.optionsButton.removeEventListener(MouseEvent.MOUSE_DOWN, this.onOptionsPress);
                removeChild(this.optionsButton);
                this.optionsButton = null;
            }
        }

        override protected function positionInternals()
        {
            super.positionInternals();
            if (this.optionsButton != null) {
                this.optionsButton.x = m.width;
                this.optionsButton.y = m.height;
                this.optionsButton.scaleX = buttonScaleX;
                this.optionsButton.scaleY = buttonScaleY;
            }
        }

        // converts coordinate number in seg -> pos
        private function method_103(_arg_1:Number):Number
        {
            return Math.round(_arg_1 / this.segSize) * this.segSize;
        }

        override public function remove()
        {
            this.hideOptionsButton();
            LevelEditor.editor.blockBG.removeBlock(this);
            LevelEditor.editor.blockBG.blocksAttached--;
            super.remove();
        }


    }
}//package levelEditor

