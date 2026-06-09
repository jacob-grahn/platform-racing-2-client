// com.jiggmin.data.Objects = data.class_19

package com.jiggmin.data
{
    import flash.display.DisplayObject;
    import blocks.*;

    public class Objects 
    {

        private static const STAMP_TREE:int = 0;
        private static const STAMP_TREE2:int = 1; // Tree2Code
        private static const STAMP_TREE3:int = 2; // Tree3Code
        private static const STAMP_PETRIFIED_TREE:int = 3;
        private static const STAMP_CACTUS:int = 4;
        private static const STAMP_ROCK:int = 5;
        private static const STAMP_ROCK2:int = 6;
        private static const STAMP_SPIRE:int = 7;
        private static const STAMP_SPIRE2:int = 8;
        private static const STAMP_BUILDING1:int = 9;

        public static const BLOCK_BASIC1:int = 100; // Basic1BlockCode
        public static const BLOCK_BASIC2:int = 101; // Basic2BlockCode
        public static const BLOCK_BASIC3:int = 102; // Basic3BlockCode
        public static const BLOCK_BASIC4:int = 103; // Basic4BlockCode
        public static const BLOCK_BRICK:int = 104;
        public static const BLOCK_ARROW_DOWN:int = 105;
        public static const BLOCK_ARROW_UP:int = 106;
        public static const BLOCK_ARROW_LEFT:int = 107;
        public static const BLOCK_ARROW_RIGHT:int = 108;
        public static const BLOCK_MINE:int = 109;
        public static const BLOCK_ITEM:int = 110;
        public static const BLOCK_START1:int = 111; // Start1BlockCode
        public static const BLOCK_START2:int = 112; // Start2BlockCode
        public static const BLOCK_START3:int = 113; // Start3BlockCode
        public static const BLOCK_START4:int = 114; // Start4BlockCode
        public static const BLOCK_ICE:int = 115;
        public static const BLOCK_FINISH:int = 116;
        public static const BLOCK_CRUMBLE:int = 117;
        public static const BLOCK_VANISH:int = 118;
        public static const BLOCK_MOVE:int = 119;
        public static const BLOCK_WATER:int = 120;
        public static const BLOCK_ROTATE_RIGHT:int = 121;
        public static const BLOCK_ROTATE_LEFT:int = 122;
        public static const BLOCK_PUSH:int = 123;
        public static const BLOCK_SAFETY:int = 124;
        public static const BLOCK_ITEM_INF:int = 125;
        public static const BLOCK_HAPPY:int = 126;
        public static const BLOCK_SAD:int = 127;
        public static const BLOCK_HEART:int = 128;
        public static const BLOCK_TIME:int = 129;
        public static const BLOCK_MINION_EGG:int = 130;
        public static const BLOCK_CUSTOM_STATS:int = 131;
        public static const BLOCK_TELEPORT:int = 132;

        public static const BG1Code:int = 201;
        public static const BG2Code:int = 202;
        public static const BG3Code:int = 203;
        public static const BG4Code:int = 204;
        public static const BG5Code:int = 205;
        public static const BG6Code:int = 206;
        public static const BG7Code:int = 207;

        public static const TextCode:int = 300;


        // removed _loc2 (direct return instead)
        public static function getFromCode(code:int):DisplayObject
        {
            if (code == STAMP_TREE) {
                return new Tree();
            } else if (code == STAMP_TREE2) {
                return new Tree2();
            } else if (code == STAMP_TREE3) {
                return new Tree3();
            } else if (code == STAMP_PETRIFIED_TREE) {
                return new PetrifiedTree();
            } else if (code == STAMP_CACTUS) {
                return new Cactus();
            } else if (code == STAMP_ROCK) {
                return new Rock();
            } else if (code == STAMP_ROCK2) {
                return new Rock2();
            } else if (code == STAMP_SPIRE) {
                return new Spire();
            } else if (code == STAMP_SPIRE2) {
                return new Spire2();
            } else if (code == STAMP_BUILDING1) {
                return new Building1();
            } else if (code == BLOCK_BASIC1) {
                return new BasicBlock(BLOCK_BASIC1);
            } else if (code == BLOCK_BASIC2) {
                return new BasicBlock(BLOCK_BASIC2);
            } else if (code == BLOCK_BASIC3) {
                return new BasicBlock(BLOCK_BASIC3);
            } else if (code == BLOCK_BASIC4) {
                return new BasicBlock(BLOCK_BASIC4);
            } else if (code == BLOCK_BRICK) {
                return new BrickBlock();
            } else if (code == BLOCK_CRUMBLE) {
                return new CrumbleBlock();
            } else if (code == BLOCK_FINISH) {
                return new FinishBlock();
            } else if (code == BLOCK_HAPPY) {
                return new HappyBlock();
            } else if (code == BLOCK_ICE) {
                return new IceBlock();
            } else if (code == BLOCK_ITEM_INF) {
                return new InfItemBlock();
            } else if (code == BLOCK_ITEM) {
                return new ItemBlock();
            } else if (code == BLOCK_MINE) {
                return new MineBlock();
            } else if (code == BLOCK_MOVE) {
                return new MoveBlock();
            } else if (code == BLOCK_PUSH) {
                return new PushBlock();
            } else if (code == BLOCK_ROTATE_LEFT) {
                return new RotateLeftBlock();
            } else if (code == BLOCK_ROTATE_RIGHT) {
                return new RotateRightBlock();
            } else if (code == BLOCK_SAD) {
                return new SadBlock();
            } else if (code == BLOCK_SAFETY) {
                return new SafetyBlock();
            } else if (code == BLOCK_START1) {
                return new StartBlock(BLOCK_START1, 1);
            } else if (code == BLOCK_START2) {
                return new StartBlock(BLOCK_START2, 2);
            } else if (code == BLOCK_START3) {
                return new StartBlock(BLOCK_START3, 3);
            } else if (code == BLOCK_START4) {
                return new StartBlock(BLOCK_START4, 4);
            } else if (code == BLOCK_VANISH) {
                return new VanishBlock();
            } else if (code == BLOCK_WATER) {
                return new WaterBlock();
            } else if (code == BLOCK_ARROW_DOWN) {
                return new ArrowDownBlock();
            } else if (code == BLOCK_ARROW_LEFT) {
                return new ArrowLeftBlock();
            } else if (code == BLOCK_ARROW_RIGHT) {
                return new ArrowRightBlock();
            } else if (code == BLOCK_ARROW_UP) {
                return new ArrowUpBlock();
            } else if (code == BLOCK_HEART) {
                return new HeartBlock();
            } else if (code == BLOCK_TIME) {
                return new TimeBlock();
            } else if (code == BLOCK_MINION_EGG) {
                return new EggBlockGraphic();
            } else if (code == BLOCK_CUSTOM_STATS) {
                return new CustomStatsBlock();
            } else if (code == BLOCK_TELEPORT) {
                return new TeleportBlock();
            } else if (code == BG1Code) {
                return new BG1();
            } else if (code == BG2Code) {
                return new BG2();
            } else if (code == BG3Code) {
                return new BG3();
            } else if (code == BG4Code) {
                return new BG4();
            } else if (code == BG5Code) {
                return new BG5();
            } else if (code == BG6Code) {
                return new BG6();
            } else if (code == BG7Code) {
                return new BG7();
            } else if (code == TextCode) {
                return new TextObjectGraphic().textBox;
            }
            return null;
        }


    }
}
