// data.Objects = data.class_19

package com.jiggmin.data
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
    import blocks.ArrowDownBlock;
    import blocks.ArrowLeftBlock;
    import blocks.ArrowRightBlock;
    import blocks.ArrowUpBlock;
    import blocks.HeartBlock;
    import blocks.TimeBlock;

    public class Objects 
    {

        private static const STAMP_TREE:int = 0; // const_88
        private static const STAMP_TREE2:int = 1; // Tree2Code
        private static const STAMP_TREE3:int = 2; // Tree3Code
        private static const STAMP_PETRIFIED_TREE:int = 3; // const_77
        private static const STAMP_CACTUS:int = 4; // const_75
        private static const STAMP_ROCK:int = 5; // const_81
        private static const STAMP_ROCK2:int = 6; // const_84
        private static const STAMP_SPIRE:int = 7; // const_86
        private static const STAMP_SPIRE2:int = 8; // const_89
        private static const STAMP_BUILDING1:int = 9; // const_83

        public static const BLOCK_BASIC1:int = 100; // Basic1BlockCode
        public static const BLOCK_BASIC2:int = 101; // Basic2BlockCode
        public static const BLOCK_BASIC3:int = 102; // Basic3BlockCode
        public static const BLOCK_BASIC4:int = 103; // Basic4BlockCode
        public static const BLOCK_BRICK:int = 104; // const_37
        public static const BLOCK_ARROW_DOWN:int = 105; // const_28
        public static const BLOCK_ARROW_UP:int = 106; // const_16
        public static const BLOCK_ARROW_LEFT:int = 107; // const_20
        public static const BLOCK_ARROW_RIGHT:int = 108; // const_15
        public static const BLOCK_MINE:int = 109; // const_17
        public static const BLOCK_ITEM:int = 110; // const_57
        public static const BLOCK_START1:int = 111; // Start1BlockCode
        public static const BLOCK_START2:int = 112; // Start2BlockCode
        public static const BLOCK_START3:int = 113; // Start3BlockCode
        public static const BLOCK_START4:int = 114; // Start4BlockCode
        public static const BLOCK_ICE:int = 115; // const_10
        public static const BLOCK_FINISH:int = 116; // const_14
        public static const BLOCK_CRUMBLE:int = 117; // const_24
        public static const BLOCK_VANISH:int = 118; // const_29
        public static const BLOCK_MOVE:int = 119; // const_26
        public static const BLOCK_WATER:int = 120; // const_30
        public static const BLOCK_ROTATE_RIGHT:int = 121; // const_41
        public static const BLOCK_ROTATE_LEFT:int = 122; // const_47
        public static const BLOCK_PUSH:int = 123; // const_50
        public static const BLOCK_SAFETY:int = 124; // const_33
        public static const BLOCK_ITEM_INF:int = 125; // const_39
        public static const BLOCK_HAPPY:int = 126; // const_38
        public static const BLOCK_SAD:int = 127; // const_32
        public static const BLOCK_HEART:int = 128; // const_43
        public static const BLOCK_TIME:int = 129; // const_42
        public static const BLOCK_MINION_EGG:int = 130; // const_58

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
            if (code == STAMP_TREE) {
                d = new Tree();
            } else if (code == STAMP_TREE2) {
                d = new Tree2();
            } else if (code == STAMP_TREE3) {
                d = new Tree3();
            } else if (code == STAMP_PETRIFIED_TREE) {
                d = new PetrifiedTree();
            } else if (code == STAMP_CACTUS) {
                d = new Cactus();
            } else if (code == STAMP_ROCK) {
                d = new Rock();
            } else if (code == STAMP_ROCK2) {
                d = new Rock2();
            } else if (code == STAMP_SPIRE) {
                d = new Spire();
            } else if (code == STAMP_SPIRE2) {
                d = new Spire2();
            } else if (code == STAMP_BUILDING1) {
                d = new Building1();
            } else if (code == BLOCK_BASIC1) {
                d = new BasicBlock(BLOCK_BASIC1);
            } else if (code == BLOCK_BASIC2) {
                d = new BasicBlock(BLOCK_BASIC2);
            } else if (code == BLOCK_BASIC3) {
                d = new BasicBlock(BLOCK_BASIC3);
            } else if (code == BLOCK_BASIC4) {
                d = new BasicBlock(BLOCK_BASIC4);
            } else if (code == BLOCK_BRICK) {
                d = new BrickBlock();
            } else if (code == BLOCK_CRUMBLE) {
                d = new CrumbleBlock();
            } else if (code == BLOCK_FINISH) {
                d = new FinishBlock();
            } else if (code == BLOCK_HAPPY) {
                d = new HappyBlock();
            } else if (code == BLOCK_ICE) {
                d = new IceBlock();
            } else if (code == BLOCK_ITEM_INF) {
                d = new InfItemBlock();
            } else if (code == BLOCK_ITEM) {
                d = new ItemBlock();
            } else if (code == BLOCK_MINE) {
                d = new MineBlock();
            } else if (code == BLOCK_MOVE) {
                d = new MoveBlock();
            } else if (code == BLOCK_PUSH) {
                d = new PushBlock();
            } else if (code == BLOCK_ROTATE_LEFT) {
                d = new RotateLeftBlock();
            } else if (code == BLOCK_ROTATE_RIGHT) {
                d = new RotateRightBlock();
            } else if (code == BLOCK_SAD) {
                d = new SadBlock();
            } else if (code == BLOCK_SAFETY) {
                d = new SafetyBlock();
            } else if (code == BLOCK_START1) {
                d = new StartBlock(BLOCK_START1, 1);
            } else if (code == BLOCK_START2) {
                d = new StartBlock(BLOCK_START2, 2);
            } else if (code == BLOCK_START3) {
                d = new StartBlock(BLOCK_START3, 3);
            } else if (code == BLOCK_START4) {
                d = new StartBlock(BLOCK_START4, 4);
            } else if (code == BLOCK_VANISH) {
                d = new VanishBlock();
            } else if (code == BLOCK_WATER) {
                d = new WaterBlock();
            } else if (code == BLOCK_ARROW_DOWN) {
                d = new ArrowDownBlock();
            } else if (code == BLOCK_ARROW_LEFT) {
                d = new ArrowLeftBlock();
            } else if (code == BLOCK_ARROW_RIGHT) {
                d = new ArrowRightBlock();
            } else if (code == BLOCK_ARROW_UP) {
                d = new ArrowUpBlock();
            } else if (code == BLOCK_HEART) {
                d = new HeartBlock();
            } else if (code == BLOCK_TIME) {
                d = new TimeBlock();
            } else if (code == BLOCK_MINION_EGG) {
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
