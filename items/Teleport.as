// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//items.Teleport

package items
{
    import package_8.LocalCharacter;
    import package_6.Course;
    import blocks.Block;
    import package_9.TeleportPop;

    public class Teleport extends Item 
    {

        public function Teleport(r:LocalCharacter)
        {
            super(r);
        }

        override public function useItem()
        {
            var _local_3:int;
            var _local_4:int;
            var _local_1:int = -120;
            if (racer.scaleX > 0) {
                _local_1 = 120;
            }
            var _local_2:Block = Course.course.blockBackground.method_24(racer.x + _local_1, racer.y - 5, true);
            if (_local_2 == null || !_local_2.method_23()) {
                _local_3 = racer.x;
                _local_4 = racer.y - 25;
                new TeleportPop(_local_3, _local_4);
                Main.socket.write("add_effect`Teleport`" + _local_3 + "`" + _local_4);
                racer.x = racer.x + _local_1;
                _local_3 = racer.x;
                _local_4 = racer.y - 25;
                new TeleportPop(_local_3, _local_4);
                Main.socket.write("add_effect`Teleport`" + _local_3 + "`" + _local_4);
                super.useItem();
            }
        }


    }
}//package items

