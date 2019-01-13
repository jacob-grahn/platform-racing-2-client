// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.MoveBlock = blocks.class_47

package blocks
{
    import data.Objects;

    public class MoveBlock extends Block 
    {

        private var var_672:int = 0;
        private var var_675:int = 0;
        private var arrow:MoveArrow = new MoveArrow();
        private var dir:int;

        public function MoveBlock()
        {
            super(Objects.MoveBlockCode);
            var_34 = false;
        }

        public function method_731(_arg_1:int)
        {
            this.dir = _arg_1;
            this.method_634();
        }

        public function shift()
        {
            this.method_367();
            if (this.dir == 3) {
                move(-1, 0);
            } else {
                if (this.dir == 2) {
                    move(1, 0);
                } else {
                    if (this.dir == 1) {
                        move(0, -1);
                    } else {
                        if (this.dir == 0) {
                            move(0, 1);
                        }
                    }
                }
            }
        }

        private function method_634()
        {
            addChild(this.arrow);
            this.arrow.x = (this.arrow.y = 15);
            if (this.dir == 3) {
                this.arrow.rotation = 270;
            } else {
                if (this.dir == 2) {
                    this.arrow.rotation = 90;
                } else {
                    if (this.dir == 1) {
                        this.arrow.rotation = 0;
                    } else {
                        if (this.dir == 0) {
                            this.arrow.rotation = 180;
                        }
                    }
                }
            }
        }

        private function method_367()
        {
            if (this.arrow.parent != null) {
                this.arrow.parent.removeChild(this.arrow);
            }
        }

        override public function remove()
        {
            this.method_367();
            super.remove();
        }


    }
}//package blocks

