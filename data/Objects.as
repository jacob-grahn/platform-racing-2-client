// data.Objects = data.class_19

package data
{
    import flash.display.DisplayObject;
    import blocks.BasicBlock;
    import blocks.BrickBlock;
    import blocks.CrumbleBlock;
    import blocks.FinishBlock;
    import blocks.HappyBlock;
    import blocks.IceBlock;
    import blocks.InfItemBlock;
    import blocks.ItemBlock;
    import blocks.MineBlock;
    import blocks.MoveBlock;
    import blocks.PushBlock;
    import blocks.RotateLeftBlock;
    import blocks.RotateRightBlock;
    import blocks.SadBlock;
    import blocks.SafetyBlock;
    import blocks.StartBlock;
    import blocks.VanishBlock;
    import blocks.WaterBlock;
    import blocks.DownBlock;
    import blocks.LeftBlock;
    import blocks.RightBlock;
    import blocks.UpBlock;
    import blocks.HeartBlock;
    import blocks.TimeBlock;

    public class Objects 
    {

        private static const TreeCode:int = 0; // const_88
        private static const Tree2Code:int = 1;
        private static const Tree3Code:int = 2;
        private static const PetrifiedTreeCode:int = 3; // const_77
        private static const CactusCode:int = 4; // const_75
        private static const RockCode:int = 5; // const_81
        private static const Rock2Code:int = 6; // const_84
        private static const SpireCode:int = 7; // const_86
        private static const Spire2Code:int = 8; // const_89
        private static const Building1Code:int = 9; // const_83
        public static const Basic1BlockCode:int = 100;
        public static const Basic2BlockCode:int = 101;
        public static const Basic3BlockCode:int = 102;
        public static const Basic4BlockCode:int = 103;
        public static const BrickBlockCode:int = 104; // const_37
        public static const DownBlockCode:int = 105; // const_28
        public static const UpBlockCode:int = 106; // const_16
        public static const LeftBlockCode:int = 107; // const_20
        public static const RightBlockCode:int = 108; // const_15
        public static const MineBlockCode:int = 109; // const_17
        public static const ItemBlockCode:int = 110; // const_57
        public static const Start1BlockCode:int = 111;
        public static const Start2BlockCode:int = 112;
        public static const Start3BlockCode:int = 113;
        public static const Start4BlockCode:int = 114;
        public static const IceBlockCode:int = 115; // const_10
        public static const FinishBlockCode:int = 116; // const_14
        public static const CrumbleBlockCode:int = 117; // const_24
        public static const VanishBlockCode:int = 118; // const_29
        public static const MoveBlockCode:int = 119; // const_26
        public static const WaterBlockCode:int = 120; // const_30
        public static const RotateRightBlockCode:int = 121; // const_41
        public static const RotateLeftBlockCode:int = 122; // const_47
        public static const PushBlockCode:int = 123; // const_50
        public static const SafetyBlockCode:int = 124; // const_33
        public static const InfItemBlockCode:int = 125; // const_39
        public static const HappyBlockCode:int = 126; // const_38
        public static const SadBlockCode:int = 127; // const_32
        public static const HeartBlockCode:int = 128; // const_43
        public static const TimeBlockCode:int = 129; // const_42
        public static const EggMinionBlockCode:int = 130; // const_58
        public static const BG1Code:int = 201;
        public static const BG2Code:int = 202;
        public static const BG3Code:int = 203;
        public static const BG4Code:int = 204;
        public static const BG5Code:int = 205;
        public static const BG6Code:int = 206;
        public static const BG7Code:int = 207;
        public static const TextCode:int = 300; // const_61


        // method_29 = getFromCode
        public static function getFromCode(code:int):DisplayObject
        {
            var d:DisplayObject;
            if (code == TreeCode) {
                d = new Tree();
            } else if (code == Tree2Code) {
                d = new Tree2();
            } else if (code == Tree3Code) {
                d = new Tree3();
            } else if (code == PetrifiedTreeCode) {
                d = new PetrifiedTree();
            } else if (code == CactusCode) {
                d = new Cactus();
            } else if (code == RockCode) {
                d = new Rock();
            } else if (code == Rock2Code) {
                d = new Rock2();
            } else if (code == SpireCode) {
                d = new Spire();
            } else if (code == Spire2Code) {
                d = new Spire2();
            } else if (code == Building1Code) {
                d = new Building1();
            } else if (code == Basic1BlockCode) {
                d = new BasicBlock(Basic1BlockCode);
            } else if (code == Basic2BlockCode) {
                d = new BasicBlock(Basic2BlockCode);
            } else if (code == Basic3BlockCode) {
                d = new BasicBlock(Basic3BlockCode);
            } else if (code == Basic4BlockCode) {
                d = new BasicBlock(Basic4BlockCode);
            } else if (code == BrickBlockCode) {
                d = new BrickBlock();
            } else if (code == CrumbleBlockCode) {
                d = new CrumbleBlock();
            } else if (code == FinishBlockCode) {
                d = new FinishBlock();
            } else if (code == HappyBlockCode) {
                d = new HappyBlock();
            } else if (code == IceBlockCode) {
                d = new IceBlock();
            } else if (code == InfItemBlockCode) {
                d = new InfItemBlock();
            } else if (code == ItemBlockCode) {
                d = new ItemBlock();
            } else if (code == MineBlockCode) {
                d = new MineBlock();
            } else if (code == MoveBlockCode) {
                d = new MoveBlock();
            } else if (code == PushBlockCode) {
                d = new PushBlock();
            } else if (code == RotateLeftBlockCode) {
                d = new RotateLeftBlock();
            } else if (code == RotateRightBlockCode) {
                d = new RotateRightBlock();
            } else if (code == SadBlockCode) {
                d = new SadBlock();
            } else if (code == SafetyBlockCode) {
                d = new SafetyBlock();
            } else if (code == Start1BlockCode) {
                d = new StartBlock(Start1BlockCode, 1);
            } else if (code == Start2BlockCode) {
                d = new StartBlock(Start2BlockCode, 2);
            } else if (code == Start3BlockCode) {
                d = new StartBlock(Start3BlockCode, 3);
            } else if (code == Start4BlockCode) {
                d = new StartBlock(Start4BlockCode, 4);
            } else if (code == VanishBlockCode) {
                d = new VanishBlock();
            } else if (code == WaterBlockCode) {
                d = new WaterBlock();
            } else if (code == DownBlockCode) {
                d = new DownBlock();
            } else if (code == LeftBlockCode) {
                d = new LeftBlock();
            } else if (code == RightBlockCode) {
                d = new RightBlock();
            } else if (code == UpBlockCode) {
                d = new UpBlock();
            } else if (code == HeartBlockCode) {
                d = new HeartBlock();
            } else if (code == TimeBlockCode) {
                d = new TimeBlock();
            } else if (code == EggMinionBlockCode) {
                d = new EggBlockGraphic();
            } else if (code == BG1Code) {
                d = new BG1();
            } else if (code == BG2Code) {
                d = new BG2();
            } else if (code == BG3Code) {
                d = new BG3();
            } else if (code == BG4Code) {
                d = new BG4();
            } else if (code == BG5Code) {
                d = new BG5();
            } else if (code == BG6Code) {
                d = new BG6();
            } else if (code == BG7Code) {
                d = new BG7();
            } else if (code == TextCode) {
                d = new TextObjectGraphic().textBox;
            }
            return d;
        }


    }
}
