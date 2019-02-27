// blocks.MoveBlock = blocks.class_47

package blocks
{
    import data.Objects;
    import background.Map;

    public class MoveBlock extends Block 
    {

        // removed: var_672, var_675 (unused)
        private var arrow:MoveArrow = new MoveArrow();
        private var dir:int;

        public function MoveBlock()
        {
            super(Objects.MoveBlockCode);
            var_34 = false;
        }

        // method_731 = setDirection
        public function setDirection(i:int)
        {
            this.dir = i;
            this.displayArrow();
        }

        public function shift(map:Map)
        {
            this.removeArrow();
            if (this.dir == 3) {
                move(-1, 0, map);
            } else if (this.dir == 2) {
                move(1, 0, map);
            } else if (this.dir == 1) {
                move(0, -1, map);
            } else if (this.dir == 0) {
                move(0, 1, map);
            }
        }

        // method_634 = displayArrow
        private function displayArrow()
        {
            addChild(this.arrow);
            this.arrow.x = this.arrow.y = 15;
            if (this.dir == 3) {
                this.arrow.rotation = 270;
            } else if (this.dir == 2) {
                this.arrow.rotation = 90;
            } else if (this.dir == 1) {
                this.arrow.rotation = 0;
            } else if (this.dir == 0) {
                this.arrow.rotation = 180;
            }
        }

        // method_367 = removeArrow
        private function removeArrow()
        {
            if (this.arrow.parent != null) {
                this.arrow.parent.removeChild(this.arrow);
            }
        }

        override public function remove()
        {
            this.removeArrow();
            super.remove();
        }


    }
}
