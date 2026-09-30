-- Crafty recipe progression (Wowhead-sourced, tbc)
-- [recipeID] = {learn, item, min, max, skillupCnt, source={...}, colors={o,y,g,grey}}
-- yield is min..max (equal for fixed-yield; a range for bombs/dynamite/some cooking)
local _, Addon = ...
Addon.data = Addon.data or {}
Addon.data.recipeProgression = {
  -- skillLine 129
  [3275] = {learn=1, item=1251, min=1, max=1, skillupCnt=1, source={}, colors={1,30,45,60}},  -- Linen Bandage
  [3276] = {learn=40, item=2581, min=1, max=1, skillupCnt=1, source={}, colors={40,50,75,100}},  -- Heavy Linen Bandage
  [3277] = {learn=80, item=3530, min=1, max=1, skillupCnt=1, source={}, colors={80,80,115,150}},  -- Wool Bandage
  [7934] = {learn=80, item=6452, min=3, max=3, skillupCnt=1, source={}, colors={80,80,115,150}},  -- Anti-Venom
  [3278] = {learn=115, item=3531, min=1, max=1, skillupCnt=1, source={}, colors={115,115,150,185}},  -- Heavy Wool Bandage
  [7935] = {learn=130, item=6453, min=3, max=3, skillupCnt=1, source={2}, colors={130,130,165,200}},  -- Strong Anti-Venom
  [7928] = {learn=150, item=6450, min=1, max=1, skillupCnt=1, source={}, colors={150,150,180,210}},  -- Silk Bandage
  [7929] = {learn=180, item=6451, min=1, max=1, skillupCnt=1, source={5}, colors={180,180,210,240}},  -- Heavy Silk Bandage
  [10840] = {learn=210, item=8544, min=1, max=1, skillupCnt=1, source={5}, colors={210,210,240,270}},  -- Mageweave Bandage
  [10841] = {learn=240, item=8545, min=1, max=1, skillupCnt=1, source={}, colors={240,240,270,300}},  -- Heavy Mageweave Bandage
  [18629] = {learn=260, item=14529, min=1, max=1, skillupCnt=1, source={}, colors={260,260,290,320}},  -- Runecloth Bandage
  [18630] = {learn=290, item=14530, min=1, max=1, skillupCnt=1, source={}, colors={290,290,320,350}},  -- Heavy Runecloth Bandage
  [23787] = {learn=300, item=19440, min=1, max=1, skillupCnt=1, source={5}, colors={300,300,330,360}},  -- Powerful Anti-Venom
  [27032] = {learn=330, item=21990, min=1, max=1, skillupCnt=1, source={5}, colors={330,330,360,390}},  -- Netherweave Bandage
  [27033] = {learn=360, item=21991, min=1, max=1, skillupCnt=1, source={5}, colors={360,360,385,410}},  -- Heavy Netherweave Bandage
  -- skillLine 164
  [2660] = {learn=1, item=2862, min=1, max=1, skillupCnt=1, source={}, colors={1,15,35,55}},  -- Rough Sharpening Stone
  [2662] = {learn=1, item=2852, min=1, max=1, skillupCnt=1, source={6}, colors={1,50,70,90}},  -- Copper Chain Pants
  [2663] = {learn=1, item=2853, min=1, max=1, skillupCnt=1, source={}, colors={1,20,40,60}},  -- Copper Bracers
  [3115] = {learn=1, item=3239, min=1, max=1, skillupCnt=1, source={}, colors={1,15,35,55}},  -- Rough Weightstone
  [12260] = {learn=1, item=10421, min=1, max=1, skillupCnt=1, source={}, colors={1,15,35,55}},  -- Rough Copper Vest
  [2737] = {learn=15, item=2844, min=1, max=1, skillupCnt=1, source={6}, colors={15,55,75,95}},  -- Copper Mace
  [2738] = {learn=20, item=2845, min=1, max=1, skillupCnt=1, source={6}, colors={20,60,80,100}},  -- Copper Axe
  [3319] = {learn=20, item=3469, min=1, max=1, skillupCnt=1, source={6}, colors={20,60,80,100}},  -- Copper Chain Boots
  [2739] = {learn=25, item=2847, min=1, max=1, skillupCnt=1, source={6}, colors={25,65,85,105}},  -- Copper Shortsword
  [3320] = {learn=25, item=3470, min=1, max=1, skillupCnt=1, source={6}, colors={25,45,65,85}},  -- Rough Grinding Stone
  [8880] = {learn=30, item=7166, min=1, max=1, skillupCnt=1, source={6}, colors={30,70,90,110}},  -- Copper Dagger
  [9983] = {learn=30, item=7955, min=1, max=1, skillupCnt=1, source={6}, colors={30,70,90,110}},  -- Copper Claymore
  [2661] = {learn=35, item=2851, min=1, max=1, skillupCnt=1, source={6}, colors={35,75,95,115}},  -- Copper Chain Belt
  [3293] = {learn=35, item=3488, min=1, max=1, skillupCnt=1, source={6}, colors={35,75,95,115}},  -- Copper Battle Axe
  [3321] = {learn=35, item=3471, min=1, max=1, skillupCnt=1, source={2,16,21}, colors={35,75,95,115}},  -- Copper Chain Vest
  [43549] = {learn=35, item=33791, min=1, max=1, skillupCnt=1, source={4}, colors={35,75,95,115}},  -- Heavy Copper Longsword
  [3323] = {learn=40, item=3472, min=1, max=1, skillupCnt=1, source={6}, colors={40,80,100,120}},  -- Runed Copper Gauntlets
  [3324] = {learn=45, item=3473, min=1, max=1, skillupCnt=1, source={6}, colors={45,85,105,125}},  -- Runed Copper Pants
  [3325] = {learn=60, item=3474, min=1, max=1, skillupCnt=1, source={2,16,21}, colors={60,100,120,140}},  -- Gemmed Copper Gauntlets
  [2665] = {learn=65, item=2863, min=1, max=1, skillupCnt=1, source={6}, colors={65,65,72,80}},  -- Coarse Sharpening Stone
  [3116] = {learn=65, item=3240, min=1, max=1, skillupCnt=1, source={6}, colors={65,65,72,80}},  -- Coarse Weightstone
  [7408] = {learn=65, item=6214, min=1, max=1, skillupCnt=1, source={6}, colors={65,105,125,145}},  -- Heavy Copper Maul
  [2666] = {learn=70, item=2857, min=1, max=1, skillupCnt=1, source={6}, colors={70,110,130,150}},  -- Runed Copper Belt
  [3294] = {learn=70, item=3489, min=1, max=1, skillupCnt=1, source={6}, colors={70,110,130,150}},  -- Thick War Axe
  [3326] = {learn=75, item=3478, min=1, max=1, skillupCnt=1, source={6}, colors={75,75,87,100}},  -- Coarse Grinding Stone
  [2667] = {learn=80, item=2864, min=1, max=1, skillupCnt=1, source={2,21}, colors={80,120,140,160}},  -- Runed Copper Breastplate
  [2664] = {learn=90, item=2854, min=1, max=1, skillupCnt=1, source={6}, colors={90,115,127,140}},  -- Runed Copper Bracers
  [3292] = {learn=95, item=3487, min=1, max=1, skillupCnt=1, source={6}, colors={95,135,155,175}},  -- Heavy Copper Broadsword
  [7817] = {learn=95, item=6350, min=1, max=1, skillupCnt=1, source={6}, colors={95,125,140,155}},  -- Rough Bronze Boots
  [7818] = {learn=100, item=6338, min=1, max=1, skillupCnt=1, source={6}, colors={100,105,107,110}},  -- Silver Rod
  [8367] = {learn=100, item=6731, min=1, max=1, skillupCnt=1, source={4}, colors={100,140,160,180}},  -- Ironforge Breastplate
  [19666] = {learn=100, item=15869, min=2, max=2, skillupCnt=1, source={6}, colors={100,100,110,120}},  -- Silver Skeleton Key
  [34979] = {learn=100, item=29201, min=1, max=1, skillupCnt=1, source={6}, colors={100,130,145,160}},  -- Thick Bronze Darts
  [2668] = {learn=105, item=2865, min=1, max=1, skillupCnt=1, source={6}, colors={105,145,160,175}},  -- Rough Bronze Leggings
  [2670] = {learn=105, item=2866, min=1, max=1, skillupCnt=1, source={6}, colors={105,145,160,175}},  -- Rough Bronze Cuirass
  [3491] = {learn=105, item=3848, min=1, max=1, skillupCnt=1, source={6}, colors={105,135,150,165}},  -- Big Bronze Knife
  [2740] = {learn=110, item=2848, min=1, max=1, skillupCnt=1, source={6}, colors={110,140,155,170}},  -- Bronze Mace
  [3328] = {learn=110, item=3480, min=1, max=1, skillupCnt=1, source={6}, colors={110,140,155,170}},  -- Rough Bronze Shoulders
  [6517] = {learn=110, item=5540, min=1, max=1, skillupCnt=1, source={6}, colors={110,140,155,170}},  -- Pearl-handled Dagger
  [2741] = {learn=115, item=2849, min=1, max=1, skillupCnt=1, source={6}, colors={115,145,160,175}},  -- Bronze Axe
  [2672] = {learn=120, item=2868, min=1, max=1, skillupCnt=1, source={6}, colors={120,150,165,180}},  -- Patterned Bronze Bracers
  [2742] = {learn=120, item=2850, min=1, max=1, skillupCnt=1, source={6}, colors={120,150,165,180}},  -- Bronze Shortsword
  [2674] = {learn=125, item=2871, min=1, max=1, skillupCnt=1, source={6}, colors={125,125,132,140}},  -- Heavy Sharpening Stone
  [3117] = {learn=125, item=3241, min=1, max=1, skillupCnt=1, source={6}, colors={125,125,132,140}},  -- Heavy Weightstone
  [3295] = {learn=125, item=3490, min=1, max=1, skillupCnt=1, source={2,16}, colors={125,155,170,185}},  -- Deadly Bronze Poniard
  [3330] = {learn=125, item=3481, min=1, max=1, skillupCnt=1, source={2,16}, colors={125,155,170,185}},  -- Silvered Bronze Shoulders
  [3337] = {learn=125, item=3486, min=1, max=1, skillupCnt=1, source={6}, colors={125,125,137,150}},  -- Heavy Grinding Stone
  [9985] = {learn=125, item=7956, min=1, max=1, skillupCnt=1, source={6}, colors={125,155,170,185}},  -- Bronze Warhammer
  [2673] = {learn=130, item=2869, min=1, max=1, skillupCnt=1, source={2}, colors={130,160,175,190}},  -- Silvered Bronze Breastplate
  [3296] = {learn=130, item=3491, min=1, max=1, skillupCnt=1, source={6}, colors={130,160,175,190}},  -- Heavy Bronze Mace
  [3331] = {learn=130, item=3482, min=1, max=1, skillupCnt=1, source={6}, colors={130,160,175,190}},  -- Silvered Bronze Boots
  [9986] = {learn=130, item=7957, min=1, max=1, skillupCnt=1, source={6}, colors={130,160,175,190}},  -- Bronze Greatsword
  [3333] = {learn=135, item=3483, min=1, max=1, skillupCnt=1, source={6}, colors={135,165,180,195}},  -- Silvered Bronze Gauntlets
  [9987] = {learn=135, item=7958, min=1, max=1, skillupCnt=1, source={6}, colors={135,165,180,195}},  -- Bronze Battle Axe
  [6518] = {learn=140, item=5541, min=1, max=1, skillupCnt=1, source={2}, colors={140,170,185,200}},  -- Iridescent Hammer
  [2675] = {learn=145, item=2870, min=1, max=1, skillupCnt=1, source={6}, colors={145,175,190,205}},  -- Shining Silver Breastplate
  [3297] = {learn=145, item=3492, min=1, max=1, skillupCnt=1, source={2}, colors={145,175,190,205}},  -- Mighty Iron Hammer
  [3334] = {learn=145, item=3484, min=1, max=1, skillupCnt=1, source={2}, colors={145,175,190,205}},  -- Green Iron Boots
  [3336] = {learn=150, item=3485, min=1, max=1, skillupCnt=1, source={2,16}, colors={150,180,195,210}},  -- Green Iron Gauntlets
  [7221] = {learn=150, item=6042, min=1, max=1, skillupCnt=1, source={2}, colors={150,180,195,210}},  -- Iron Shield Spike
  [8768] = {learn=150, item=7071, min=2, max=2, skillupCnt=1, source={6}, colors={150,150,152,155}},  -- Iron Buckle
  [14379] = {learn=150, item=11128, min=1, max=1, skillupCnt=1, source={6}, colors={150,155,157,160}},  -- Golden Rod
  [19667] = {learn=150, item=15870, min=2, max=2, skillupCnt=1, source={6}, colors={150,150,160,170}},  -- Golden Skeleton Key
  [3494] = {learn=155, item=3851, min=1, max=1, skillupCnt=1, source={5}, colors={155,180,192,205}},  -- Solid Iron Maul
  [3506] = {learn=155, item=3842, min=1, max=1, skillupCnt=1, source={6}, colors={155,180,192,205}},  -- Green Iron Leggings
  [12259] = {learn=155, item=10423, min=1, max=1, skillupCnt=1, source={2}, colors={155,180,192,205}},  -- Silvered Bronze Leggings
  [3492] = {learn=160, item=3849, min=1, max=1, skillupCnt=1, source={5}, colors={160,185,197,210}},  -- Hardened Iron Shortsword
  [3504] = {learn=160, item=3840, min=1, max=1, skillupCnt=1, source={2}, colors={160,185,197,210}},  -- Green Iron Shoulders
  [9811] = {learn=160, item=7913, min=1, max=1, skillupCnt=1, source={4}, colors={160,185,197,210}},  -- Barbaric Iron Shoulders
  [9813] = {learn=160, item=7914, min=1, max=1, skillupCnt=1, source={4}, colors={160,185,197,210}},  -- Barbaric Iron Breastplate
  [3501] = {learn=165, item=3835, min=1, max=1, skillupCnt=1, source={6}, colors={165,190,202,215}},  -- Green Iron Bracers
  [7222] = {learn=165, item=6043, min=1, max=1, skillupCnt=1, source={2}, colors={165,190,202,215}},  -- Iron Counterweight
  [3495] = {learn=170, item=3852, min=1, max=1, skillupCnt=1, source={2}, colors={170,195,207,220}},  -- Golden Iron Destroyer
  [3502] = {learn=170, item=3836, min=1, max=1, skillupCnt=1, source={6}, colors={170,195,207,220}},  -- Green Iron Helm
  [3507] = {learn=170, item=3843, min=1, max=1, skillupCnt=1, source={2}, colors={170,195,207,220}},  -- Golden Scale Leggings
  [3493] = {learn=175, item=3850, min=1, max=1, skillupCnt=1, source={2,16}, colors={175,200,212,225}},  -- Jade Serpentblade
  [3505] = {learn=175, item=3841, min=1, max=1, skillupCnt=1, source={2}, colors={175,200,212,225}},  -- Golden Scale Shoulders
  [9814] = {learn=175, item=7915, min=1, max=1, skillupCnt=1, source={4}, colors={175,200,212,225}},  -- Barbaric Iron Helm
  [3496] = {learn=180, item=3853, min=1, max=1, skillupCnt=1, source={5}, colors={180,205,217,230}},  -- Moonsteel Broadsword
  [3508] = {learn=180, item=3844, min=1, max=1, skillupCnt=1, source={6}, colors={180,205,217,230}},  -- Green Iron Hauberk
  [9818] = {learn=180, item=7916, min=1, max=1, skillupCnt=1, source={4}, colors={180,205,217,230}},  -- Barbaric Iron Boots
  [15972] = {learn=180, item=12259, min=1, max=1, skillupCnt=1, source={6}, colors={180,205,217,230}},  -- Glinting Steel Dagger
  [3498] = {learn=185, item=3855, min=1, max=1, skillupCnt=1, source={5}, colors={185,210,222,235}},  -- Massive Iron Axe
  [3513] = {learn=185, item=3846, min=1, max=1, skillupCnt=1, source={2}, colors={185,210,222,235}},  -- Polished Steel Boots
  [7223] = {learn=185, item=6040, min=1, max=1, skillupCnt=1, source={6}, colors={185,210,222,235}},  -- Golden Scale Bracers
  [9820] = {learn=185, item=7917, min=1, max=1, skillupCnt=1, source={4}, colors={185,210,222,235}},  -- Barbaric Iron Gloves
  [3503] = {learn=190, item=3837, min=1, max=1, skillupCnt=1, source={5}, colors={190,215,227,240}},  -- Golden Scale Coif
  [7224] = {learn=190, item=6041, min=1, max=1, skillupCnt=1, source={2}, colors={190,215,227,240}},  -- Steel Weapon Chain
  [15973] = {learn=190, item=12260, min=1, max=1, skillupCnt=1, source={2}, colors={190,215,227,240}},  -- Searing Golden Blade
  [21913] = {learn=190, item=17704, min=1, max=1, skillupCnt=1, source={2}, colors={190,215,227,240}},  -- Edge of Winter
  [3511] = {learn=195, item=3845, min=1, max=1, skillupCnt=1, source={2}, colors={195,220,232,245}},  -- Golden Scale Cuirass
  [3497] = {learn=200, item=3854, min=1, max=1, skillupCnt=1, source={2}, colors={200,225,237,250}},  -- Frost Tiger Blade
  [3500] = {learn=200, item=3856, min=1, max=1, skillupCnt=1, source={2}, colors={200,225,237,250}},  -- Shadow Crescent Axe
  [3515] = {learn=200, item=3847, min=1, max=1, skillupCnt=1, source={2}, colors={200,225,237,250}},  -- Golden Scale Boots
  [9916] = {learn=200, item=7963, min=1, max=1, skillupCnt=1, source={6}, colors={200,225,237,250}},  -- Steel Breastplate
  [9918] = {learn=200, item=7964, min=1, max=1, skillupCnt=1, source={6}, colors={200,200,205,210}},  -- Solid Sharpening Stone
  [9920] = {learn=200, item=7966, min=1, max=1, skillupCnt=1, source={6}, colors={200,200,205,210}},  -- Solid Grinding Stone
  [9921] = {learn=200, item=7965, min=1, max=1, skillupCnt=1, source={6}, colors={200,200,205,210}},  -- Solid Weightstone
  [11454] = {learn=200, item=9060, min=1, max=1, skillupCnt=1, source={1}, colors={200,225,237,250}},  -- Inlaid Mithril Cylinder
  [14380] = {learn=200, item=11144, min=1, max=1, skillupCnt=1, source={6}, colors={200,205,207,210}},  -- Truesilver Rod
  [19668] = {learn=200, item=15871, min=2, max=2, skillupCnt=1, source={6}, colors={200,200,210,220}},  -- Truesilver Skeleton Key
  [34981] = {learn=200, item=29202, min=1, max=1, skillupCnt=1, source={6}, colors={200,220,230,240}},  -- Whirling Steel Axes
  [9926] = {learn=205, item=7918, min=1, max=1, skillupCnt=1, source={6}, colors={205,225,235,245}},  -- Heavy Mithril Shoulder
  [9928] = {learn=205, item=7919, min=1, max=1, skillupCnt=1, source={6}, colors={205,225,235,245}},  -- Heavy Mithril Gauntlet
  [11643] = {learn=205, item=9366, min=1, max=1, skillupCnt=1, source={4}, colors={205,225,235,245}},  -- Golden Scale Gauntlets
  [9931] = {learn=210, item=7920, min=1, max=1, skillupCnt=1, source={6}, colors={210,230,240,250}},  -- Mithril Scale Pants
  [9933] = {learn=210, item=7921, min=1, max=1, skillupCnt=1, source={2,16}, colors={210,230,240,250}},  -- Heavy Mithril Pants
  [9993] = {learn=210, item=7941, min=1, max=1, skillupCnt=1, source={6}, colors={210,235,247,260}},  -- Heavy Mithril Axe
  [9935] = {learn=215, item=7922, min=1, max=1, skillupCnt=1, source={6}, colors={215,235,245,255}},  -- Steel Plate Helm
  [9937] = {learn=215, item=7924, min=1, max=1, skillupCnt=1, source={5}, colors={215,235,245,255}},  -- Mithril Scale Bracers
  [9939] = {learn=215, item=7967, min=1, max=1, skillupCnt=1, source={2}, colors={215,235,245,255}},  -- Mithril Shield Spike
  [9945] = {learn=220, item=7926, min=1, max=1, skillupCnt=1, source={4}, colors={220,240,250,260}},  -- Ornate Mithril Pants
  [9950] = {learn=220, item=7927, min=1, max=1, skillupCnt=1, source={4}, colors={220,240,250,260}},  -- Ornate Mithril Gloves
  [9995] = {learn=220, item=7942, min=1, max=1, skillupCnt=1, source={2,16}, colors={220,245,257,270}},  -- Blue Glittering Axe
  [9952] = {learn=225, item=7928, min=1, max=1, skillupCnt=1, source={4}, colors={225,245,255,265}},  -- Ornate Mithril Shoulder
  [9954] = {learn=225, item=7938, min=1, max=1, skillupCnt=1, source={}, colors={225,245,255,265}},  -- Truesilver Gauntlets
  [9997] = {learn=225, item=7943, min=1, max=1, skillupCnt=1, source={2}, colors={225,250,262,275}},  -- Wicked Mithril Blade
  [9957] = {learn=230, item=7929, min=1, max=1, skillupCnt=1, source={}, colors={230,250,260,270}},  -- Orcish War Leggings
  [9959] = {learn=230, item=7930, min=1, max=1, skillupCnt=1, source={}, colors={230,250,260,270}},  -- Heavy Mithril Breastplate
  [9961] = {learn=230, item=7931, min=1, max=1, skillupCnt=1, source={}, colors={230,250,260,270}},  -- Mithril Coif
  [10001] = {learn=230, item=7945, min=1, max=1, skillupCnt=1, source={}, colors={230,255,267,280}},  -- Big Black Mace
  [9964] = {learn=235, item=7969, min=1, max=1, skillupCnt=1, source={2}, colors={235,255,265,275}},  -- Mithril Spurs
  [9966] = {learn=235, item=7932, min=1, max=1, skillupCnt=1, source={2}, colors={235,255,265,275}},  -- Mithril Scale Shoulders
  [9968] = {learn=235, item=7933, min=1, max=1, skillupCnt=1, source={}, colors={235,255,265,275}},  -- Heavy Mithril Boots
  [10003] = {learn=235, item=7954, min=1, max=1, skillupCnt=1, source={}, colors={235,260,272,285}},  -- The Shatterer
  [9972] = {learn=240, item=7935, min=1, max=1, skillupCnt=1, source={}, colors={240,260,270,280}},  -- Ornate Mithril Breastplate
  [10005] = {learn=240, item=7944, min=1, max=1, skillupCnt=1, source={2}, colors={240,265,277,290}},  -- Dazzling Mithril Rapier
  [9970] = {learn=245, item=7934, min=1, max=1, skillupCnt=1, source={2}, colors={245,255,265,275}},  -- Heavy Mithril Helm
  [9974] = {learn=245, item=7939, min=1, max=1, skillupCnt=1, source={}, colors={245,265,275,285}},  -- Truesilver Breastplate
  [9979] = {learn=245, item=7936, min=1, max=1, skillupCnt=1, source={}, colors={245,265,275,285}},  -- Ornate Mithril Boots
  [9980] = {learn=245, item=7937, min=1, max=1, skillupCnt=1, source={}, colors={245,265,275,285}},  -- Ornate Mithril Helm
  [10007] = {learn=245, item=7961, min=1, max=1, skillupCnt=1, source={}, colors={245,270,282,295}},  -- Phantom Blade
  [10009] = {learn=245, item=7946, min=1, max=1, skillupCnt=1, source={2}, colors={245,270,282,295}},  -- Runed Mithril Hammer
  [10011] = {learn=250, item=7959, min=1, max=1, skillupCnt=1, source={}, colors={250,275,287,300}},  -- Blight
  [16639] = {learn=250, item=12644, min=1, max=1, skillupCnt=1, source={}, colors={250,255,257,260}},  -- Dense Grinding Stone
  [16640] = {learn=250, item=12643, min=1, max=1, skillupCnt=1, source={}, colors={250,255,257,260}},  -- Dense Weightstone
  [16641] = {learn=250, item=12404, min=1, max=1, skillupCnt=1, source={}, colors={250,255,257,260}},  -- Dense Sharpening Stone
  [16642] = {learn=250, item=12405, min=1, max=1, skillupCnt=1, source={2}, colors={250,270,280,290}},  -- Thorium Armor
  [16643] = {learn=250, item=12406, min=1, max=1, skillupCnt=1, source={2}, colors={250,270,280,290}},  -- Thorium Belt
  [10013] = {learn=255, item=7947, min=1, max=1, skillupCnt=1, source={5}, colors={255,280,292,305}},  -- Ebon Shiv
  [16644] = {learn=255, item=12408, min=1, max=1, skillupCnt=1, source={2}, colors={255,275,285,295}},  -- Thorium Bracers
  [10015] = {learn=260, item=7960, min=1, max=1, skillupCnt=1, source={}, colors={260,285,297,310}},  -- Truesilver Champion
  [16645] = {learn=260, item=12416, min=1, max=1, skillupCnt=1, source={2}, colors={260,280,290,300}},  -- Radiant Belt
  [36122] = {learn=260, item=30069, min=1, max=1, skillupCnt=1, source={}, colors={260,280,290,300}},  -- Earthforged Leggings
  [36124] = {learn=260, item=30070, min=1, max=1, skillupCnt=1, source={}, colors={260,280,290,300}},  -- Windforged Leggings
  [36125] = {learn=260, item=30071, min=1, max=1, skillupCnt=1, source={}, colors={260,280,290,300}},  -- Light Earthforged Blade
  [36126] = {learn=260, item=30072, min=1, max=1, skillupCnt=1, source={}, colors={260,280,290,300}},  -- Light Skyforged Axe
  [36128] = {learn=260, item=30073, min=1, max=1, skillupCnt=1, source={}, colors={260,280,290,300}},  -- Light Emberforged Hammer
  [15292] = {learn=265, item=11608, min=1, max=1, skillupCnt=1, source={2}, colors={265,285,295,305}},  -- Dark Iron Pulverizer
  [16646] = {learn=265, item=12428, min=1, max=1, skillupCnt=1, source={4}, colors={265,285,295,305}},  -- Imperial Plate Shoulders
  [16647] = {learn=265, item=12424, min=1, max=1, skillupCnt=1, source={4}, colors={265,285,295,305}},  -- Imperial Plate Belt
  [15293] = {learn=270, item=11606, min=1, max=1, skillupCnt=1, source={2}, colors={270,290,300,310}},  -- Dark Iron Mail
  [16648] = {learn=270, item=12415, min=1, max=1, skillupCnt=1, source={2}, colors={270,290,300,310}},  -- Radiant Breastplate
  [16649] = {learn=270, item=12425, min=1, max=1, skillupCnt=1, source={4}, colors={270,290,300,310}},  -- Imperial Plate Bracers
  [16650] = {learn=270, item=12624, min=1, max=1, skillupCnt=1, source={2}, colors={270,290,300,310}},  -- Wildthorn Mail
  [15294] = {learn=275, item=11607, min=1, max=1, skillupCnt=1, source={2}, colors={275,295,305,315}},  -- Dark Iron Sunderer
  [16651] = {learn=275, item=12645, min=1, max=1, skillupCnt=1, source={2}, colors={275,295,305,315}},  -- Thorium Shield Spike
  [16969] = {learn=275, item=12773, min=1, max=1, skillupCnt=1, source={5}, colors={275,300,312,325}},  -- Ornate Thorium Handaxe
  [16970] = {learn=275, item=12774, min=1, max=1, skillupCnt=1, source={4}, colors={275,300,312,325}},  -- Dawn's Edge
  [19669] = {learn=275, item=15872, min=2, max=2, skillupCnt=1, source={}, colors={275,275,280,285}},  -- Arcanite Skeleton Key
  [20201] = {learn=275, item=16206, min=1, max=1, skillupCnt=1, source={}, colors={275,275,280,285}},  -- Arcanite Rod
  [15295] = {learn=280, item=11605, min=1, max=1, skillupCnt=1, source={2}, colors={280,300,310,320}},  -- Dark Iron Shoulders
  [16652] = {learn=280, item=12409, min=1, max=1, skillupCnt=1, source={2}, colors={280,300,310,320}},  -- Thorium Boots
  [16653] = {learn=280, item=12410, min=1, max=1, skillupCnt=1, source={2}, colors={280,300,310,320}},  -- Thorium Helm
  [16971] = {learn=280, item=12775, min=1, max=1, skillupCnt=1, source={5}, colors={280,305,317,330}},  -- Huge Thorium Battleaxe
  [16973] = {learn=280, item=12776, min=1, max=1, skillupCnt=1, source={4}, colors={280,305,317,330}},  -- Enchanted Battlehammer
  [16978] = {learn=280, item=12777, min=1, max=1, skillupCnt=1, source={4}, colors={280,305,317,330}},  -- Blazing Rapier
  [15296] = {learn=285, item=11604, min=1, max=1, skillupCnt=1, source={2}, colors={285,305,315,325}},  -- Dark Iron Plate
  [16654] = {learn=285, item=12418, min=1, max=1, skillupCnt=1, source={2}, colors={285,305,315,325}},  -- Radiant Gloves
  [16667] = {learn=285, item=12628, min=1, max=1, skillupCnt=1, source={4}, colors={285,305,315,325}},  -- Demon Forged Breastplate
  [16983] = {learn=285, item=12781, min=1, max=1, skillupCnt=1, source={2}, colors={285,310,322,335}},  -- Serenity
  [16655] = {learn=290, item=12631, min=1, max=1, skillupCnt=1, source={4}, colors={290,310,320,330}},  -- Fiery Plate Gauntlets
  [16656] = {learn=290, item=12419, min=1, max=1, skillupCnt=1, source={2}, colors={290,310,320,330}},  -- Radiant Boots
  [16660] = {learn=290, item=12625, min=1, max=1, skillupCnt=1, source={2}, colors={290,310,320,330}},  -- Dawnbringer Shoulders
  [16984] = {learn=290, item=12792, min=1, max=1, skillupCnt=1, source={2}, colors={290,315,327,340}},  -- Volcanic Hammer
  [16985] = {learn=290, item=12782, min=1, max=1, skillupCnt=1, source={2}, colors={290,315,327,340}},  -- Corruption
  [23628] = {learn=290, item=19043, min=1, max=1, skillupCnt=1, source={5}, colors={290,310,320,330}},  -- Heavy Timbermaw Belt
  [23632] = {learn=290, item=19051, min=1, max=1, skillupCnt=1, source={5}, colors={290,310,320,330}},  -- Girdle of the Dawn
  [16657] = {learn=295, item=12426, min=1, max=1, skillupCnt=1, source={4}, colors={295,315,325,335}},  -- Imperial Plate Boots
  [16658] = {learn=295, item=12427, min=1, max=1, skillupCnt=1, source={4}, colors={295,315,325,335}},  -- Imperial Plate Helm
  [16659] = {learn=295, item=12417, min=1, max=1, skillupCnt=1, source={2}, colors={295,315,325,335}},  -- Radiant Circlet
  [16661] = {learn=295, item=12632, min=1, max=1, skillupCnt=1, source={2,5}, colors={295,315,325,335}},  -- Storm Gauntlets
  [20872] = {learn=295, item=16989, min=1, max=1, skillupCnt=1, source={5}, colors={295,315,325,335}},  -- Fiery Chain Girdle
  [20874] = {learn=295, item=17014, min=1, max=1, skillupCnt=1, source={5}, colors={295,315,325,335}},  -- Dark Iron Bracers
  [16662] = {learn=300, item=12414, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Thorium Leggings
  [16663] = {learn=300, item=12422, min=1, max=1, skillupCnt=1, source={4}, colors={300,320,330,340}},  -- Imperial Plate Chest
  [16664] = {learn=300, item=12610, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Runic Plate Shoulders
  [16665] = {learn=300, item=12611, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Runic Plate Boots
  [16724] = {learn=300, item=12633, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Whitesoul Helm
  [16725] = {learn=300, item=12420, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Radiant Leggings
  [16726] = {learn=300, item=12612, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Runic Plate Helm
  [16728] = {learn=300, item=12636, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Helm of the Great Chief
  [16729] = {learn=300, item=12640, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Lionheart Helm
  [16730] = {learn=300, item=12429, min=1, max=1, skillupCnt=1, source={4}, colors={300,320,330,340}},  -- Imperial Plate Leggings
  [16731] = {learn=300, item=12613, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Runic Breastplate
  [16732] = {learn=300, item=12614, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Runic Plate Leggings
  [16741] = {learn=300, item=12639, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Stronghold Gauntlets
  [16742] = {learn=300, item=12620, min=1, max=1, skillupCnt=1, source={4}, colors={300,320,330,340}},  -- Enchanted Thorium Helm
  [16744] = {learn=300, item=12619, min=1, max=1, skillupCnt=1, source={4}, colors={300,320,330,340}},  -- Enchanted Thorium Leggings
  [16745] = {learn=300, item=12618, min=1, max=1, skillupCnt=1, source={4}, colors={300,320,330,340}},  -- Enchanted Thorium Breastplate
  [16746] = {learn=300, item=12641, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Invulnerable Mail
  [16988] = {learn=300, item=12796, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Hammer of the Titans
  [16990] = {learn=300, item=12790, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Arcanite Champion
  [16991] = {learn=300, item=12798, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Annihilator
  [16992] = {learn=300, item=12797, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Frostguard
  [16993] = {learn=300, item=12794, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Masterwork Stormhammer
  [16994] = {learn=300, item=12784, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Arcanite Reaper
  [16995] = {learn=300, item=12783, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Heartseeker
  [20873] = {learn=300, item=16988, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Fiery Chain Shoulders
  [20876] = {learn=300, item=17013, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Dark Iron Leggings
  [20890] = {learn=300, item=17015, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Dark Iron Reaver
  [20897] = {learn=300, item=17016, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Dark Iron Destroyer
  [21161] = {learn=300, item=17193, min=1, max=1, skillupCnt=1, source={4}, colors={300,325,337,350}},  -- Sulfuron Hammer
  [22757] = {learn=300, item=18262, min=1, max=1, skillupCnt=1, source={2}, colors={300,300,310,320}},  -- Elemental Sharpening Stone
  [23629] = {learn=300, item=19048, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Heavy Timbermaw Boots
  [23633] = {learn=300, item=19057, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Gloves of the Dawn
  [23636] = {learn=300, item=19148, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Dark Iron Helm
  [23637] = {learn=300, item=19164, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Dark Iron Gauntlets
  [23638] = {learn=300, item=19166, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Black Amnesty
  [23639] = {learn=300, item=19167, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Blackfury
  [23650] = {learn=300, item=19170, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Ebon Hand
  [23652] = {learn=300, item=19168, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Blackguard
  [23653] = {learn=300, item=19169, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Nightfall
  [24136] = {learn=300, item=19690, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Bloodsoul Breastplate
  [24137] = {learn=300, item=19691, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Bloodsoul Shoulders
  [24138] = {learn=300, item=19692, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Bloodsoul Gauntlets
  [24139] = {learn=300, item=19693, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Darksoul Breastplate
  [24140] = {learn=300, item=19694, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Darksoul Leggings
  [24141] = {learn=300, item=19695, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Darksoul Shoulders
  [24399] = {learn=300, item=20039, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Dark Iron Boots
  [24912] = {learn=300, item=20549, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Darkrune Gauntlets
  [24913] = {learn=300, item=20551, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Darkrune Helm
  [24914] = {learn=300, item=20550, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Darkrune Breastplate
  [27585] = {learn=300, item=22197, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Heavy Obsidian Belt
  [27586] = {learn=300, item=22198, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Jagged Obsidian Shield
  [27587] = {learn=300, item=22196, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Thick Obsidian Breastplate
  [27588] = {learn=300, item=22195, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Light Obsidian Belt
  [27589] = {learn=300, item=22194, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Black Grasp of the Destroyer
  [27590] = {learn=300, item=22191, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Obsidian Mail Tunic
  [27829] = {learn=300, item=22385, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Titanic Leggings
  [27830] = {learn=300, item=22384, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Persuader
  [27832] = {learn=300, item=22383, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Sageblade
  [28242] = {learn=300, item=22669, min=1, max=1, skillupCnt=1, source={}, colors={300,320,330,340}},  -- Icebane Breastplate
  [28243] = {learn=300, item=22670, min=1, max=1, skillupCnt=1, source={}, colors={300,320,330,340}},  -- Icebane Gauntlets
  [28244] = {learn=300, item=22671, min=1, max=1, skillupCnt=1, source={}, colors={300,320,330,340}},  -- Icebane Bracers
  [28461] = {learn=300, item=22762, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Ironvine Breastplate
  [28462] = {learn=300, item=22763, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Ironvine Gloves
  [28463] = {learn=300, item=22764, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Ironvine Belt
  [29545] = {learn=300, item=23482, min=1, max=1, skillupCnt=1, source={}, colors={300,310,320,330}},  -- Fel Iron Plate Gloves
  [29551] = {learn=300, item=23493, min=1, max=1, skillupCnt=1, source={}, colors={300,310,320,330}},  -- Fel Iron Chain Coif
  [29654] = {learn=300, item=23528, min=1, max=1, skillupCnt=1, source={}, colors={300,300,305,310}},  -- Fel Sharpening Stone
  [32655] = {learn=300, item=25843, min=1, max=1, skillupCnt=1, source={}, colors={300,300,305,310}},  -- Fel Iron Rod
  [34607] = {learn=300, item=28420, min=1, max=1, skillupCnt=1, source={}, colors={300,300,305,310}},  -- Fel Weightstone
  [34982] = {learn=300, item=29203, min=1, max=1, skillupCnt=1, source={}, colors={300,320,330,340}},  -- Enchanted Thorium Blades
  [29547] = {learn=305, item=23484, min=1, max=1, skillupCnt=1, source={}, colors={305,315,325,335}},  -- Fel Iron Plate Belt
  [29552] = {learn=310, item=23491, min=1, max=1, skillupCnt=1, source={}, colors={310,320,330,340}},  -- Fel Iron Chain Gloves
  [29557] = {learn=310, item=23497, min=1, max=1, skillupCnt=1, source={}, colors={310,320,330,340}},  -- Fel Iron Hatchet
  [29548] = {learn=315, item=23487, min=1, max=1, skillupCnt=1, source={}, colors={315,325,335,345}},  -- Fel Iron Plate Boots
  [29549] = {learn=315, item=23488, min=1, max=1, skillupCnt=1, source={}, colors={315,325,335,345}},  -- Fel Iron Plate Pants
  [29553] = {learn=315, item=23494, min=1, max=1, skillupCnt=1, source={}, colors={315,325,335,345}},  -- Fel Iron Chain Bracers
  [29558] = {learn=315, item=23498, min=1, max=1, skillupCnt=1, source={}, colors={315,325,335,345}},  -- Fel Iron Hammer
  [29556] = {learn=320, item=23490, min=1, max=1, skillupCnt=1, source={}, colors={320,330,340,350}},  -- Fel Iron Chain Tunic
  [29565] = {learn=320, item=23499, min=1, max=1, skillupCnt=1, source={}, colors={320,330,340,350}},  -- Fel Iron Greatsword
  [29550] = {learn=325, item=23489, min=1, max=1, skillupCnt=1, source={}, colors={325,335,345,355}},  -- Fel Iron Breastplate
  [29566] = {learn=325, item=23502, min=1, max=1, skillupCnt=1, source={5}, colors={325,335,345,355}},  -- Adamantite Maul
  [32284] = {learn=325, item=23559, min=1, max=1, skillupCnt=1, source={}, colors={325,325,330,335}},  -- Lesser Rune of Warding
  [29568] = {learn=330, item=23503, min=1, max=1, skillupCnt=1, source={5}, colors={330,340,350,360}},  -- Adamantite Cleaver
  [29569] = {learn=330, item=23504, min=1, max=1, skillupCnt=1, source={5}, colors={330,340,350,360}},  -- Adamantite Dagger
  [36129] = {learn=330, item=30074, min=1, max=1, skillupCnt=1, source={}, colors={330,340,350,360}},  -- Heavy Earthforged Breastplate
  [36130] = {learn=330, item=30076, min=1, max=1, skillupCnt=1, source={}, colors={330,340,350,360}},  -- Stormforged Hauberk
  [36131] = {learn=330, item=30077, min=1, max=1, skillupCnt=1, source={}, colors={330,340,350,360}},  -- Windforged Rapier
  [36133] = {learn=330, item=30086, min=1, max=1, skillupCnt=1, source={}, colors={330,340,350,360}},  -- Stoneforged Claymore
  [36134] = {learn=330, item=30087, min=1, max=1, skillupCnt=1, source={}, colors={330,340,350,360}},  -- Stormforged Axe
  [36135] = {learn=330, item=30088, min=1, max=1, skillupCnt=1, source={}, colors={330,340,350,360}},  -- Skyforged Great Axe
  [36136] = {learn=330, item=30089, min=1, max=1, skillupCnt=1, source={}, colors={330,340,350,360}},  -- Lavaforged Warhammer
  [36137] = {learn=330, item=30093, min=1, max=1, skillupCnt=1, source={}, colors={330,340,350,360}},  -- Great Earthforged Hammer
  [29571] = {learn=335, item=23505, min=1, max=1, skillupCnt=1, source={5}, colors={335,345,355,365}},  -- Adamantite Rapier
  [29603] = {learn=335, item=23506, min=1, max=1, skillupCnt=1, source={5}, colors={335,345,355,365}},  -- Adamantite Plate Bracers
  [29605] = {learn=335, item=23508, min=1, max=1, skillupCnt=1, source={5}, colors={335,345,355,365}},  -- Adamantite Plate Gloves
  [42688] = {learn=335, item=33185, min=1, max=1, skillupCnt=1, source={2}, colors={335,345,350,355}},  -- Adamantite Weapon Chain
  [29606] = {learn=340, item=23507, min=1, max=1, skillupCnt=1, source={5}, colors={340,350,360,370}},  -- Adamantite Breastplate
  [29728] = {learn=340, item=23575, min=1, max=1, skillupCnt=1, source={5}, colors={340,340,345,350}},  -- Lesser Ward of Shielding
  [29614] = {learn=350, item=23515, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Flamebane Bracers
  [29656] = {learn=350, item=23529, min=1, max=1, skillupCnt=1, source={5}, colors={350,350,355,360}},  -- Adamantite Sharpening Stone
  [32285] = {learn=350, item=25521, min=1, max=1, skillupCnt=1, source={5}, colors={350,350,355,360}},  -- Greater Rune of Warding
  [32656] = {learn=350, item=25844, min=1, max=1, skillupCnt=1, source={5}, colors={350,350,355,360}},  -- Adamantite Rod
  [34529] = {learn=350, item=23563, min=1, max=1, skillupCnt=1, source={}, colors={350,360,370,380}},  -- Nether Chain Shirt
  [34533] = {learn=350, item=28483, min=1, max=1, skillupCnt=1, source={}, colors={350,360,370,380}},  -- Breastplate of Kings
  [34535] = {learn=350, item=28425, min=1, max=1, skillupCnt=1, source={}, colors={350,360,370,380}},  -- Fireguard
  [34538] = {learn=350, item=28428, min=1, max=1, skillupCnt=1, source={}, colors={350,360,370,380}},  -- Lionheart Blade
  [34541] = {learn=350, item=28431, min=1, max=1, skillupCnt=1, source={}, colors={350,360,370,380}},  -- The Planar Edge
  [34543] = {learn=350, item=28434, min=1, max=1, skillupCnt=1, source={}, colors={350,360,370,380}},  -- Lunar Crescent
  [34545] = {learn=350, item=28437, min=1, max=1, skillupCnt=1, source={}, colors={350,360,370,380}},  -- Drakefist Hammer
  [34547] = {learn=350, item=28440, min=1, max=1, skillupCnt=1, source={}, colors={350,360,370,380}},  -- Thunder
  [34608] = {learn=350, item=28421, min=1, max=1, skillupCnt=1, source={5}, colors={350,350,355,360}},  -- Adamantite Weightstone
  [34983] = {learn=350, item=29204, min=1, max=1, skillupCnt=1, source={}, colors={350,360,370,380}},  -- Felsteel Whisper Knives
  [29608] = {learn=355, item=23510, min=1, max=1, skillupCnt=1, source={5}, colors={355,365,375,385}},  -- Enchanted Adamantite Belt
  [29611] = {learn=355, item=23511, min=1, max=1, skillupCnt=1, source={5}, colors={355,365,375,385}},  -- Enchanted Adamantite Boots
  [29615] = {learn=355, item=23516, min=1, max=1, skillupCnt=1, source={5}, colors={355,365,375,385}},  -- Flamebane Helm
  [29610] = {learn=360, item=23509, min=1, max=1, skillupCnt=1, source={5}, colors={360,370,380,390}},  -- Enchanted Adamantite Breastplate
  [29616] = {learn=360, item=23514, min=1, max=1, skillupCnt=1, source={5}, colors={360,370,380,390}},  -- Flamebane Gloves
  [29619] = {learn=360, item=23517, min=1, max=1, skillupCnt=1, source={2}, colors={360,370,380,390}},  -- Felsteel Gloves
  [29620] = {learn=360, item=23518, min=1, max=1, skillupCnt=1, source={2}, colors={360,370,380,390}},  -- Felsteel Leggings
  [29628] = {learn=360, item=23524, min=1, max=1, skillupCnt=1, source={2}, colors={360,370,380,390}},  -- Khorium Belt
  [29629] = {learn=360, item=23523, min=1, max=1, skillupCnt=1, source={2}, colors={360,370,380,390}},  -- Khorium Pants
  [29657] = {learn=360, item=23530, min=1, max=1, skillupCnt=1, source={5}, colors={360,370,380,390}},  -- Felsteel Shield Spike
  [29613] = {learn=365, item=23512, min=1, max=1, skillupCnt=1, source={5}, colors={365,375,385,395}},  -- Enchanted Adamantite Leggings
  [29617] = {learn=365, item=23513, min=1, max=1, skillupCnt=1, source={5}, colors={365,375,385,395}},  -- Flamebane Breastplate
  [29621] = {learn=365, item=23519, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Felsteel Helm
  [29622] = {learn=365, item=23532, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Gauntlets of the Iron Tower
  [29630] = {learn=365, item=23525, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Khorium Boots
  [29642] = {learn=365, item=23520, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Ragesteel Gloves
  [29643] = {learn=365, item=23521, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Ragesteel Helm
  [29658] = {learn=365, item=23531, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Felfury Gauntlets
  [29662] = {learn=365, item=23533, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Steelgrip Gauntlets
  [29663] = {learn=365, item=23534, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Storm Helm
  [29664] = {learn=365, item=23535, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Helm of the Stalwart Defender
  [29668] = {learn=365, item=23536, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Oathkeeper's Helm
  [29669] = {learn=365, item=23537, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Black Felsteel Bracers
  [29671] = {learn=365, item=23538, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Bracers of the Green Fortress
  [29672] = {learn=365, item=23539, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Blessed Bracers
  [29692] = {learn=365, item=23540, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Felsteel Longblade
  [29693] = {learn=365, item=23541, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Khorium Champion
  [29694] = {learn=365, item=23542, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Fel Edged Battleaxe
  [29695] = {learn=365, item=23543, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Felsteel Reaper
  [29696] = {learn=365, item=23544, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Runic Hammer
  [29697] = {learn=365, item=23546, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Fel Hardened Maul
  [29698] = {learn=365, item=23554, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Eternium Runed Blade
  [29699] = {learn=365, item=23555, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Dirge
  [29700] = {learn=365, item=23556, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Hand of Eternity
  [42662] = {learn=365, item=33173, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Ragesteel Shoulders
  [43846] = {learn=365, item=32854, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Hammer of Righteous Might
  [46140] = {learn=365, item=34380, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Sunblessed Gauntlets
  [46141] = {learn=365, item=34378, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Hard Khorium Battlefists
  [46142] = {learn=365, item=34379, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Sunblessed Breastplate
  [46144] = {learn=365, item=34377, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Hard Khorium Battleplate
  [29645] = {learn=370, item=23522, min=1, max=1, skillupCnt=1, source={2}, colors={370,380,390,400}},  -- Ragesteel Breastplate
  [29648] = {learn=370, item=23526, min=1, max=1, skillupCnt=1, source={2}, colors={370,380,390,400}},  -- Swiftsteel Gloves
  [29649] = {learn=370, item=23527, min=1, max=1, skillupCnt=1, source={2}, colors={370,380,390,400}},  -- Earthpeace Breastplate
  [29729] = {learn=375, item=23576, min=1, max=1, skillupCnt=1, source={2}, colors={375,375,375,375}},  -- Greater Ward of Shielding
  [32657] = {learn=375, item=25845, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,380,385}},  -- Eternium Rod
  [34530] = {learn=375, item=23564, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Twisting Nether Chain Shirt
  [34534] = {learn=375, item=28484, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Bulwark of Kings
  [34537] = {learn=375, item=28426, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Blazeguard
  [34540] = {learn=375, item=28429, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Lionheart Champion
  [34542] = {learn=375, item=28432, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Black Planar Edge
  [34544] = {learn=375, item=28435, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Mooncleaver
  [34546] = {learn=375, item=28438, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Dragonmaw
  [34548] = {learn=375, item=28441, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Deep Thunder
  [36256] = {learn=375, item=23565, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Embrace of the Twisting Nether
  [36257] = {learn=375, item=28485, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Bulwark of the Ancient Kings
  [36258] = {learn=375, item=28427, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Blazefury
  [36259] = {learn=375, item=28430, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Lionheart Executioner
  [36260] = {learn=375, item=28433, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Wicked Edge of the Planes
  [36261] = {learn=375, item=28436, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Bloodmoon
  [36262] = {learn=375, item=28439, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Dragonstrike
  [36263] = {learn=375, item=28442, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Stormherald
  [36389] = {learn=375, item=30034, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Belt of the Guardian
  [36390] = {learn=375, item=30032, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Red Belt of Battle
  [36391] = {learn=375, item=30033, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Boots of the Protector
  [36392] = {learn=375, item=30031, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Red Havoc Boots
  [38473] = {learn=375, item=31364, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- Wildguard Breastplate
  [38475] = {learn=375, item=31367, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- Wildguard Leggings
  [38476] = {learn=375, item=31368, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- Wildguard Helm
  [38477] = {learn=375, item=31369, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- Iceguard Breastplate
  [38478] = {learn=375, item=31370, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- Iceguard Leggings
  [38479] = {learn=375, item=31371, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- Iceguard Helm
  [40033] = {learn=375, item=32402, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- Shadesteel Sabots
  [40034] = {learn=375, item=32403, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- Shadesteel Bracers
  [40035] = {learn=375, item=32404, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- Shadesteel Greaves
  [40036] = {learn=375, item=32401, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- Shadesteel Girdle
  [41132] = {learn=375, item=32568, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Swiftsteel Bracers
  [41133] = {learn=375, item=32570, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Swiftsteel Shoulders
  [41134] = {learn=375, item=32571, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Dawnsteel Bracers
  [41135] = {learn=375, item=32573, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Dawnsteel Shoulders
  -- skillLine 165
  [2149] = {learn=1, item=2302, min=1, max=1, skillupCnt=1, source={}, colors={1,40,55,70}},  -- Handstitched Leather Boots
  [2152] = {learn=1, item=2304, min=1, max=1, skillupCnt=1, source={}, colors={1,30,45,60}},  -- Light Armor Kit
  [2881] = {learn=1, item=2318, min=1, max=1, skillupCnt=1, source={}, colors={1,20,30,40}},  -- Light Leather
  [7126] = {learn=1, item=5957, min=1, max=1, skillupCnt=1, source={}, colors={1,40,55,70}},  -- Handstitched Leather Vest
  [9058] = {learn=1, item=7276, min=1, max=1, skillupCnt=1, source={}, colors={1,40,55,70}},  -- Handstitched Leather Cloak
  [9059] = {learn=1, item=7277, min=1, max=1, skillupCnt=1, source={}, colors={1,40,55,70}},  -- Handstitched Leather Bracers
  [2153] = {learn=15, item=2303, min=1, max=1, skillupCnt=1, source={}, colors={15,45,60,75}},  -- Handstitched Leather Pants
  [3753] = {learn=25, item=4237, min=1, max=1, skillupCnt=1, source={}, colors={25,55,70,85}},  -- Handstitched Leather Belt
  [9060] = {learn=30, item=7278, min=1, max=1, skillupCnt=1, source={}, colors={30,60,75,90}},  -- Light Leather Quiver
  [9062] = {learn=30, item=7279, min=1, max=1, skillupCnt=1, source={}, colors={30,60,75,90}},  -- Small Leather Ammo Pouch
  [3816] = {learn=35, item=4231, min=1, max=1, skillupCnt=1, source={}, colors={35,55,65,75}},  -- Cured Light Hide
  [9064] = {learn=35, item=7280, min=1, max=1, skillupCnt=1, source={2,21}, colors={35,65,80,95}},  -- Rugged Leather Pants
  [2160] = {learn=40, item=2300, min=1, max=1, skillupCnt=1, source={}, colors={40,70,85,100}},  -- Embossed Leather Vest
  [5244] = {learn=40, item=5081, min=1, max=1, skillupCnt=1, source={4}, colors={40,70,85,100}},  -- Kodo Hide Bag
  [2161] = {learn=55, item=2309, min=1, max=1, skillupCnt=1, source={}, colors={55,85,100,115}},  -- Embossed Leather Boots
  [3756] = {learn=55, item=4239, min=1, max=1, skillupCnt=1, source={}, colors={55,85,100,115}},  -- Embossed Leather Gloves
  [2162] = {learn=60, item=2310, min=1, max=1, skillupCnt=1, source={}, colors={60,90,105,120}},  -- Embossed Leather Cloak
  [2163] = {learn=60, item=2311, min=1, max=1, skillupCnt=1, source={2,21}, colors={60,90,105,120}},  -- White Leather Jerkin
  [9065] = {learn=70, item=7281, min=1, max=1, skillupCnt=1, source={}, colors={70,100,115,130}},  -- Light Leather Bracers
  [2164] = {learn=75, item=2312, min=1, max=1, skillupCnt=1, source={2,21}, colors={75,105,120,135}},  -- Fine Leather Gloves
  [3759] = {learn=75, item=4242, min=1, max=1, skillupCnt=1, source={}, colors={75,105,120,135}},  -- Embossed Leather Pants
  [3763] = {learn=80, item=4246, min=1, max=1, skillupCnt=1, source={}, colors={80,110,125,140}},  -- Fine Leather Belt
  [2159] = {learn=85, item=2308, min=1, max=1, skillupCnt=1, source={}, colors={85,105,120,135}},  -- Fine Leather Cloak
  [3761] = {learn=85, item=4243, min=1, max=1, skillupCnt=1, source={}, colors={85,115,130,145}},  -- Fine Leather Tunic
  [2158] = {learn=90, item=2307, min=1, max=1, skillupCnt=1, source={2,16,21}, colors={90,120,135,150}},  -- Fine Leather Boots
  [6702] = {learn=90, item=5780, min=1, max=1, skillupCnt=1, source={2,5}, colors={90,120,135,150}},  -- Murloc Scale Belt
  [7953] = {learn=90, item=6466, min=1, max=1, skillupCnt=1, source={5}, colors={90,120,135,150}},  -- Deviate Scale Cloak
  [8322] = {learn=90, item=6709, min=1, max=1, skillupCnt=1, source={4}, colors={90,115,130,145}},  -- Moonglow Vest
  [6703] = {learn=95, item=5781, min=1, max=1, skillupCnt=1, source={2,5}, colors={95,125,140,155}},  -- Murloc Scale Breastplate
  [9068] = {learn=95, item=7282, min=1, max=1, skillupCnt=1, source={}, colors={95,125,140,155}},  -- Light Leather Pants
  [2165] = {learn=100, item=2313, min=1, max=1, skillupCnt=1, source={}, colors={100,115,122,130}},  -- Medium Armor Kit
  [2167] = {learn=100, item=2315, min=1, max=1, skillupCnt=1, source={}, colors={100,125,137,150}},  -- Dark Leather Boots
  [2169] = {learn=100, item=2317, min=1, max=1, skillupCnt=1, source={2,16}, colors={100,125,137,150}},  -- Dark Leather Tunic
  [3762] = {learn=100, item=4244, min=1, max=1, skillupCnt=1, source={2,16,21}, colors={100,125,137,150}},  -- Hillman's Leather Vest
  [3817] = {learn=100, item=4233, min=1, max=1, skillupCnt=1, source={}, colors={100,115,122,130}},  -- Cured Medium Hide
  [9070] = {learn=100, item=7283, min=1, max=1, skillupCnt=1, source={5}, colors={100,125,137,150}},  -- Black Whelp Cloak
  [20648] = {learn=100, item=2319, min=1, max=1, skillupCnt=1, source={}, colors={100,100,105,110}},  -- Medium Leather
  [24940] = {learn=100, item=20575, min=1, max=1, skillupCnt=1, source={5}, colors={100,125,137,150}},  -- Black Whelp Tunic
  [7133] = {learn=105, item=5958, min=1, max=1, skillupCnt=1, source={2}, colors={105,130,142,155}},  -- Fine Leather Pants
  [7954] = {learn=105, item=6467, min=1, max=1, skillupCnt=1, source={5}, colors={105,130,142,155}},  -- Deviate Scale Gloves
  [2168] = {learn=110, item=2316, min=1, max=1, skillupCnt=1, source={}, colors={110,135,147,160}},  -- Dark Leather Cloak
  [7135] = {learn=115, item=5961, min=1, max=1, skillupCnt=1, source={}, colors={115,140,152,165}},  -- Dark Leather Pants
  [7955] = {learn=115, item=6468, min=1, max=1, skillupCnt=1, source={4}, colors={115,140,152,165}},  -- Deviate Scale Belt
  [2166] = {learn=120, item=2314, min=1, max=1, skillupCnt=1, source={}, colors={120,145,157,170}},  -- Toughened Leather Armor
  [3765] = {learn=120, item=4248, min=1, max=1, skillupCnt=1, source={2}, colors={120,155,167,180}},  -- Dark Leather Gloves
  [3767] = {learn=120, item=4250, min=1, max=1, skillupCnt=1, source={2}, colors={120,145,157,170}},  -- Hillman's Belt
  [9072] = {learn=120, item=7284, min=1, max=1, skillupCnt=1, source={5}, colors={120,145,157,170}},  -- Red Whelp Gloves
  [9074] = {learn=120, item=7285, min=1, max=1, skillupCnt=1, source={}, colors={120,145,157,170}},  -- Nimble Leather Gloves
  [3766] = {learn=125, item=4249, min=1, max=1, skillupCnt=1, source={}, colors={125,150,162,175}},  -- Dark Leather Belt
  [9145] = {learn=125, item=7348, min=1, max=1, skillupCnt=1, source={}, colors={125,150,162,175}},  -- Fletcher's Gloves
  [3768] = {learn=130, item=4251, min=1, max=1, skillupCnt=1, source={}, colors={130,155,167,180}},  -- Hillman's Shoulders
  [3770] = {learn=135, item=4253, min=1, max=1, skillupCnt=1, source={}, colors={135,160,172,185}},  -- Toughened Leather Gloves
  [9146] = {learn=135, item=7349, min=1, max=1, skillupCnt=1, source={5}, colors={135,160,172,185}},  -- Herbalist's Gloves
  [9147] = {learn=135, item=7352, min=1, max=1, skillupCnt=1, source={5}, colors={135,160,172,185}},  -- Earthen Leather Shoulders
  [3769] = {learn=140, item=4252, min=1, max=1, skillupCnt=1, source={2}, colors={140,165,177,190}},  -- Dark Leather Shoulders
  [9148] = {learn=140, item=7358, min=1, max=1, skillupCnt=1, source={2}, colors={140,165,177,190}},  -- Pilferer's Gloves
  [3764] = {learn=145, item=4247, min=1, max=1, skillupCnt=1, source={}, colors={145,170,182,195}},  -- Hillman's Leather Gloves
  [9149] = {learn=145, item=7359, min=1, max=1, skillupCnt=1, source={2,16}, colors={145,170,182,195}},  -- Heavy Earthen Gloves
  [3760] = {learn=150, item=3719, min=1, max=1, skillupCnt=1, source={}, colors={150,170,180,190}},  -- Hillman's Cloak
  [3771] = {learn=150, item=4254, min=1, max=1, skillupCnt=1, source={2}, colors={150,170,180,190}},  -- Barbaric Gloves
  [3780] = {learn=150, item=4265, min=1, max=1, skillupCnt=1, source={}, colors={150,170,180,190}},  -- Heavy Armor Kit
  [3818] = {learn=150, item=4236, min=1, max=1, skillupCnt=1, source={}, colors={150,160,165,170}},  -- Cured Heavy Hide
  [9193] = {learn=150, item=7371, min=1, max=1, skillupCnt=1, source={}, colors={150,170,180,190}},  -- Heavy Quiver
  [9194] = {learn=150, item=7372, min=1, max=1, skillupCnt=1, source={}, colors={150,170,180,190}},  -- Heavy Leather Ammo Pouch
  [20649] = {learn=150, item=4234, min=1, max=1, skillupCnt=1, source={}, colors={150,150,155,160}},  -- Heavy Leather
  [23190] = {learn=150, item=18662, min=1, max=1, skillupCnt=1, source={5}, colors={150,150,155,160}},  -- Heavy Leather Ball
  [3772] = {learn=155, item=4255, min=1, max=1, skillupCnt=1, source={5}, colors={155,175,185,195}},  -- Green Leather Armor
  [23399] = {learn=155, item=18948, min=1, max=1, skillupCnt=1, source={5}, colors={155,175,185,195}},  -- Barbaric Bracers
  [3774] = {learn=160, item=4257, min=1, max=1, skillupCnt=1, source={}, colors={160,180,190,200}},  -- Green Leather Belt
  [7147] = {learn=160, item=5962, min=1, max=1, skillupCnt=1, source={}, colors={160,180,190,200}},  -- Guardian Pants
  [4096] = {learn=165, item=4455, min=1, max=1, skillupCnt=1, source={5}, colors={165,185,195,205}},  -- Raptor Hide Harness
  [4097] = {learn=165, item=4456, min=1, max=1, skillupCnt=1, source={5}, colors={165,185,195,205}},  -- Raptor Hide Belt
  [9195] = {learn=165, item=7373, min=1, max=1, skillupCnt=1, source={2}, colors={165,185,195,205}},  -- Dusky Leather Leggings
  [3775] = {learn=170, item=4258, min=1, max=1, skillupCnt=1, source={2}, colors={170,190,200,210}},  -- Guardian Belt
  [6704] = {learn=170, item=5782, min=1, max=1, skillupCnt=1, source={2,5}, colors={170,190,200,210}},  -- Thick Murloc Armor
  [7149] = {learn=170, item=5963, min=1, max=1, skillupCnt=1, source={5}, colors={170,190,200,210}},  -- Barbaric Leggings
  [3773] = {learn=175, item=4256, min=1, max=1, skillupCnt=1, source={2}, colors={175,195,205,215}},  -- Guardian Armor
  [7151] = {learn=175, item=5964, min=1, max=1, skillupCnt=1, source={}, colors={175,195,205,215}},  -- Barbaric Shoulders
  [9196] = {learn=175, item=7374, min=1, max=1, skillupCnt=1, source={}, colors={175,195,205,215}},  -- Dusky Leather Armor
  [9197] = {learn=175, item=7375, min=1, max=1, skillupCnt=1, source={2}, colors={175,195,205,215}},  -- Green Whelp Armor
  [3776] = {learn=180, item=4259, min=1, max=1, skillupCnt=1, source={}, colors={180,200,210,220}},  -- Green Leather Bracers
  [9198] = {learn=180, item=7377, min=1, max=1, skillupCnt=1, source={}, colors={180,200,210,220}},  -- Frost Leather Cloak
  [3778] = {learn=185, item=4262, min=1, max=1, skillupCnt=1, source={5}, colors={185,205,215,225}},  -- Gem-studded Leather Belt
  [7153] = {learn=185, item=5965, min=1, max=1, skillupCnt=1, source={2,16}, colors={185,205,215,225}},  -- Guardian Cloak
  [9201] = {learn=185, item=7378, min=1, max=1, skillupCnt=1, source={}, colors={185,205,215,225}},  -- Dusky Bracers
  [6661] = {learn=190, item=5739, min=1, max=1, skillupCnt=1, source={}, colors={190,210,220,230}},  -- Barbaric Harness
  [6705] = {learn=190, item=5783, min=1, max=1, skillupCnt=1, source={2,5}, colors={190,210,220,230}},  -- Murloc Scale Bracers
  [7156] = {learn=190, item=5966, min=1, max=1, skillupCnt=1, source={}, colors={190,210,220,230}},  -- Guardian Gloves
  [9202] = {learn=190, item=7386, min=1, max=1, skillupCnt=1, source={5}, colors={190,210,220,230}},  -- Green Whelp Bracers
  [21943] = {learn=190, item=17721, min=1, max=1, skillupCnt=1, source={2}, colors={190,210,220,230}},  -- Gloves of the Greatfather
  [3777] = {learn=195, item=4260, min=1, max=1, skillupCnt=1, source={2}, colors={195,215,225,235}},  -- Guardian Leather Bracers
  [9206] = {learn=195, item=7387, min=1, max=1, skillupCnt=1, source={}, colors={195,215,225,235}},  -- Dusky Belt
  [3779] = {learn=200, item=4264, min=1, max=1, skillupCnt=1, source={2}, colors={200,220,230,240}},  -- Barbaric Belt
  [9207] = {learn=200, item=7390, min=1, max=1, skillupCnt=1, source={2}, colors={200,220,230,240}},  -- Dusky Boots
  [9208] = {learn=200, item=7391, min=1, max=1, skillupCnt=1, source={2,16}, colors={200,220,230,240}},  -- Swift Boots
  [10482] = {learn=200, item=8172, min=1, max=1, skillupCnt=1, source={}, colors={200,200,200,200}},  -- Cured Thick Hide
  [10487] = {learn=200, item=8173, min=1, max=1, skillupCnt=1, source={}, colors={200,220,230,240}},  -- Thick Armor Kit
  [10490] = {learn=200, item=8174, min=1, max=1, skillupCnt=1, source={2}, colors={200,220,230,240}},  -- Comfortable Leather Hat
  [20650] = {learn=200, item=4304, min=1, max=1, skillupCnt=1, source={}, colors={200,200,202,205}},  -- Thick Leather
  [22711] = {learn=200, item=18238, min=1, max=1, skillupCnt=1, source={5}, colors={200,210,220,230}},  -- Shadowskin Gloves
  [10499] = {learn=205, item=8175, min=1, max=1, skillupCnt=1, source={}, colors={205,225,235,245}},  -- Nightscape Tunic
  [10507] = {learn=205, item=8176, min=1, max=1, skillupCnt=1, source={}, colors={205,225,235,245}},  -- Nightscape Headband
  [10509] = {learn=205, item=8187, min=1, max=1, skillupCnt=1, source={2,5}, colors={205,225,235,245}},  -- Turtle Scale Gloves
  [10511] = {learn=210, item=8189, min=1, max=1, skillupCnt=1, source={}, colors={210,230,240,250}},  -- Turtle Scale Breastplate
  [10516] = {learn=210, item=8192, min=1, max=1, skillupCnt=1, source={5}, colors={210,230,240,250}},  -- Nightscape Shoulders
  [10518] = {learn=210, item=8198, min=1, max=1, skillupCnt=1, source={}, colors={210,230,240,250}},  -- Turtle Scale Bracers
  [10520] = {learn=215, item=8200, min=1, max=1, skillupCnt=1, source={2}, colors={215,235,245,255}},  -- Big Voodoo Robe
  [10525] = {learn=220, item=8203, min=1, max=1, skillupCnt=1, source={2}, colors={220,240,250,260}},  -- Tough Scorpid Breastplate
  [10529] = {learn=220, item=8210, min=1, max=1, skillupCnt=1, source={4}, colors={220,240,250,260}},  -- Wild Leather Shoulders
  [10531] = {learn=220, item=8201, min=1, max=1, skillupCnt=1, source={2}, colors={220,240,250,260}},  -- Big Voodoo Mask
  [10533] = {learn=220, item=8205, min=1, max=1, skillupCnt=1, source={2}, colors={220,240,250,260}},  -- Tough Scorpid Bracers
  [10542] = {learn=225, item=8204, min=1, max=1, skillupCnt=1, source={2}, colors={225,245,255,265}},  -- Tough Scorpid Gloves
  [10544] = {learn=225, item=8211, min=1, max=1, skillupCnt=1, source={4}, colors={225,245,255,265}},  -- Wild Leather Vest
  [10546] = {learn=225, item=8214, min=1, max=1, skillupCnt=1, source={4}, colors={225,245,255,265}},  -- Wild Leather Helmet
  [10619] = {learn=225, item=8347, min=1, max=1, skillupCnt=1, source={}, colors={225,245,255,265}},  -- Dragonscale Gauntlets
  [10621] = {learn=225, item=8345, min=1, max=1, skillupCnt=1, source={}, colors={225,245,255,265}},  -- Wolfshead Helm
  [14930] = {learn=225, item=8217, min=1, max=1, skillupCnt=1, source={}, colors={225,245,255,265}},  -- Quickdraw Quiver
  [14932] = {learn=225, item=8218, min=1, max=1, skillupCnt=1, source={}, colors={225,245,255,265}},  -- Thick Leather Ammo Pouch
  [10548] = {learn=230, item=8193, min=1, max=1, skillupCnt=1, source={}, colors={230,250,260,270}},  -- Nightscape Pants
  [10552] = {learn=230, item=8191, min=1, max=1, skillupCnt=1, source={}, colors={230,250,260,270}},  -- Turtle Scale Helm
  [10630] = {learn=230, item=8346, min=1, max=1, skillupCnt=1, source={}, colors={230,250,260,270}},  -- Gauntlets of the Sea
  [10554] = {learn=235, item=8209, min=1, max=1, skillupCnt=1, source={2}, colors={235,255,265,275}},  -- Tough Scorpid Boots
  [10556] = {learn=235, item=8185, min=1, max=1, skillupCnt=1, source={}, colors={235,255,265,275}},  -- Turtle Scale Leggings
  [10558] = {learn=235, item=8197, min=1, max=1, skillupCnt=1, source={}, colors={235,255,265,275}},  -- Nightscape Boots
  [10560] = {learn=240, item=8202, min=1, max=1, skillupCnt=1, source={2}, colors={240,260,270,280}},  -- Big Voodoo Pants
  [10562] = {learn=240, item=8216, min=1, max=1, skillupCnt=1, source={2}, colors={240,260,270,280}},  -- Big Voodoo Cloak
  [10564] = {learn=240, item=8207, min=1, max=1, skillupCnt=1, source={2}, colors={240,260,270,280}},  -- Tough Scorpid Shoulders
  [10566] = {learn=245, item=8213, min=1, max=1, skillupCnt=1, source={4}, colors={245,265,275,285}},  -- Wild Leather Boots
  [10568] = {learn=245, item=8206, min=1, max=1, skillupCnt=1, source={2}, colors={245,265,275,285}},  -- Tough Scorpid Leggings
  [10570] = {learn=250, item=8208, min=1, max=1, skillupCnt=1, source={2}, colors={250,270,280,290}},  -- Tough Scorpid Helm
  [10572] = {learn=250, item=8212, min=1, max=1, skillupCnt=1, source={4}, colors={250,270,280,290}},  -- Wild Leather Leggings
  [10574] = {learn=250, item=8215, min=1, max=1, skillupCnt=1, source={4}, colors={250,270,280,290}},  -- Wild Leather Cloak
  [10632] = {learn=250, item=8348, min=1, max=1, skillupCnt=1, source={}, colors={250,270,280,290}},  -- Helm of Fire
  [10647] = {learn=250, item=8349, min=1, max=1, skillupCnt=1, source={}, colors={250,270,280,290}},  -- Feathered Breastplate
  [19047] = {learn=250, item=15407, min=1, max=1, skillupCnt=1, source={}, colors={250,250,255,260}},  -- Cured Rugged Hide
  [19058] = {learn=250, item=15564, min=1, max=1, skillupCnt=1, source={}, colors={250,250,260,270}},  -- Rugged Armor Kit
  [22331] = {learn=250, item=8170, min=1, max=1, skillupCnt=1, source={}, colors={250,250,250,250}},  -- Rugged Leather
  [10650] = {learn=255, item=8367, min=1, max=1, skillupCnt=1, source={}, colors={255,275,285,295}},  -- Dragonscale Breastplate
  [19048] = {learn=255, item=15077, min=1, max=1, skillupCnt=1, source={5}, colors={255,275,285,295}},  -- Heavy Scorpid Bracers
  [19049] = {learn=260, item=15083, min=1, max=1, skillupCnt=1, source={5}, colors={260,280,290,300}},  -- Wicked Leather Gauntlets
  [19050] = {learn=260, item=15045, min=1, max=1, skillupCnt=1, source={5}, colors={260,280,290,300}},  -- Green Dragonscale Breastplate
  [36074] = {learn=260, item=29964, min=1, max=1, skillupCnt=1, source={}, colors={260,280,290,300}},  -- Blackstorm Leggings
  [36075] = {learn=260, item=29970, min=1, max=1, skillupCnt=1, source={}, colors={260,280,290,300}},  -- Wildfeather Leggings
  [36076] = {learn=260, item=29971, min=1, max=1, skillupCnt=1, source={}, colors={260,280,290,300}},  -- Dragonstrike Leggings
  [19051] = {learn=265, item=15076, min=1, max=1, skillupCnt=1, source={2}, colors={265,285,295,305}},  -- Heavy Scorpid Vest
  [19052] = {learn=265, item=15084, min=1, max=1, skillupCnt=1, source={2}, colors={265,285,295,305}},  -- Wicked Leather Bracers
  [19053] = {learn=265, item=15074, min=1, max=1, skillupCnt=1, source={5}, colors={265,285,295,305}},  -- Chimeric Gloves
  [19055] = {learn=270, item=15091, min=1, max=1, skillupCnt=1, source={2}, colors={270,290,300,310}},  -- Runic Leather Gauntlets
  [19059] = {learn=270, item=15054, min=1, max=1, skillupCnt=1, source={2}, colors={270,290,300,310}},  -- Volcanic Leggings
  [19060] = {learn=270, item=15046, min=1, max=1, skillupCnt=1, source={2}, colors={270,290,300,310}},  -- Green Dragonscale Leggings
  [19061] = {learn=270, item=15061, min=1, max=1, skillupCnt=1, source={5}, colors={270,290,300,310}},  -- Living Shoulders
  [19062] = {learn=270, item=15067, min=1, max=1, skillupCnt=1, source={5}, colors={270,290,300,310}},  -- Ironfeather Shoulders
  [19063] = {learn=275, item=15073, min=1, max=1, skillupCnt=1, source={2}, colors={275,295,305,315}},  -- Chimeric Boots
  [19064] = {learn=275, item=15078, min=1, max=1, skillupCnt=1, source={2}, colors={275,295,305,315}},  -- Heavy Scorpid Gauntlets
  [19065] = {learn=275, item=15092, min=1, max=1, skillupCnt=1, source={2}, colors={275,295,305,315}},  -- Runic Leather Bracers
  [19066] = {learn=275, item=15071, min=1, max=1, skillupCnt=1, source={5}, colors={275,295,305,315}},  -- Frostsaber Boots
  [19067] = {learn=275, item=15057, min=1, max=1, skillupCnt=1, source={5}, colors={275,295,305,315}},  -- Stormshroud Pants
  [19068] = {learn=275, item=15064, min=1, max=1, skillupCnt=1, source={2,5}, colors={275,295,305,315}},  -- Warbear Harness
  [19070] = {learn=280, item=15082, min=1, max=1, skillupCnt=1, source={2,16}, colors={280,300,310,320}},  -- Heavy Scorpid Belt
  [19071] = {learn=280, item=15086, min=1, max=1, skillupCnt=1, source={2}, colors={280,300,310,320}},  -- Wicked Leather Headband
  [19072] = {learn=280, item=15093, min=1, max=1, skillupCnt=1, source={2,16}, colors={280,300,310,320}},  -- Runic Leather Belt
  [19073] = {learn=280, item=15072, min=1, max=1, skillupCnt=1, source={2,16}, colors={280,300,310,320}},  -- Chimeric Leggings
  [24655] = {learn=280, item=20296, min=1, max=1, skillupCnt=1, source={}, colors={280,300,310,320}},  -- Green Dragonscale Gauntlets
  [19074] = {learn=285, item=15069, min=1, max=1, skillupCnt=1, source={2}, colors={285,305,315,325}},  -- Frostsaber Leggings
  [19075] = {learn=285, item=15079, min=1, max=1, skillupCnt=1, source={2}, colors={285,305,315,325}},  -- Heavy Scorpid Leggings
  [19076] = {learn=285, item=15053, min=1, max=1, skillupCnt=1, source={2}, colors={285,305,315,325}},  -- Volcanic Breastplate
  [19077] = {learn=285, item=15048, min=1, max=1, skillupCnt=1, source={5}, colors={285,305,315,325}},  -- Blue Dragonscale Breastplate
  [19078] = {learn=285, item=15060, min=1, max=1, skillupCnt=1, source={2}, colors={285,305,315,325}},  -- Living Leggings
  [19079] = {learn=285, item=15056, min=1, max=1, skillupCnt=1, source={2}, colors={285,305,315,325}},  -- Stormshroud Armor
  [19080] = {learn=285, item=15065, min=1, max=1, skillupCnt=1, source={5}, colors={285,305,315,325}},  -- Warbear Woolies
  [22815] = {learn=285, item=18258, min=1, max=1, skillupCnt=1, source={}, colors={0,285,290,295}},  -- Gordok Ogre Suit
  [44953] = {learn=285, item=34086, min=1, max=1, skillupCnt=1, source={5}, colors={285,285,285,285}},  -- Winter Boots
  [19081] = {learn=290, item=15075, min=1, max=1, skillupCnt=1, source={2}, colors={290,310,320,330}},  -- Chimeric Vest
  [19082] = {learn=290, item=15094, min=1, max=1, skillupCnt=1, source={5}, colors={290,310,320,330}},  -- Runic Leather Headband
  [19083] = {learn=290, item=15087, min=1, max=1, skillupCnt=1, source={2}, colors={290,310,320,330}},  -- Wicked Leather Pants
  [19084] = {learn=290, item=15063, min=1, max=1, skillupCnt=1, source={5}, colors={290,310,320,330}},  -- Devilsaur Gauntlets
  [19085] = {learn=290, item=15050, min=1, max=1, skillupCnt=1, source={5}, colors={290,310,320,330}},  -- Black Dragonscale Breastplate
  [19086] = {learn=290, item=15066, min=1, max=1, skillupCnt=1, source={2}, colors={290,310,320,330}},  -- Ironfeather Breastplate
  [23703] = {learn=290, item=19044, min=1, max=1, skillupCnt=1, source={5}, colors={290,310,320,330}},  -- Might of the Timbermaw
  [23705] = {learn=290, item=19052, min=1, max=1, skillupCnt=1, source={5}, colors={290,310,320,330}},  -- Dawn Treaders
  [19087] = {learn=295, item=15070, min=1, max=1, skillupCnt=1, source={2}, colors={295,315,325,335}},  -- Frostsaber Gloves
  [19088] = {learn=295, item=15080, min=1, max=1, skillupCnt=1, source={5}, colors={295,315,325,335}},  -- Heavy Scorpid Helm
  [19089] = {learn=295, item=15049, min=1, max=1, skillupCnt=1, source={2}, colors={295,315,325,335}},  -- Blue Dragonscale Shoulders
  [19090] = {learn=295, item=15058, min=1, max=1, skillupCnt=1, source={2}, colors={295,315,325,335}},  -- Stormshroud Shoulders
  [20853] = {learn=295, item=16982, min=1, max=1, skillupCnt=1, source={5}, colors={295,315,325,335}},  -- Corehound Boots
  [19054] = {learn=300, item=15047, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Red Dragonscale Breastplate
  [19091] = {learn=300, item=15095, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Runic Leather Pants
  [19092] = {learn=300, item=15088, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Wicked Leather Belt
  [19093] = {learn=300, item=15138, min=1, max=1, skillupCnt=1, source={}, colors={300,320,330,340}},  -- Onyxia Scale Cloak
  [19094] = {learn=300, item=15051, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Black Dragonscale Shoulders
  [19095] = {learn=300, item=15059, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Living Breastplate
  [19097] = {learn=300, item=15062, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Devilsaur Leggings
  [19098] = {learn=300, item=15085, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Wicked Leather Armor
  [19100] = {learn=300, item=15081, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Heavy Scorpid Shoulders
  [19101] = {learn=300, item=15055, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Volcanic Shoulders
  [19102] = {learn=300, item=15090, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Runic Leather Armor
  [19103] = {learn=300, item=15096, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Runic Leather Shoulders
  [19104] = {learn=300, item=15068, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Frostsaber Tunic
  [19107] = {learn=300, item=15052, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Black Dragonscale Leggings
  [20854] = {learn=300, item=16983, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Molten Helm
  [20855] = {learn=300, item=16984, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Black Dragonscale Boots
  [22727] = {learn=300, item=18251, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Core Armor Kit
  [22921] = {learn=300, item=18504, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Girdle of Insight
  [22922] = {learn=300, item=18506, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Mongoose Boots
  [22923] = {learn=300, item=18508, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Swift Flight Bracers
  [22926] = {learn=300, item=18509, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Chromatic Cloak
  [22927] = {learn=300, item=18510, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Hide of the Wild
  [22928] = {learn=300, item=18511, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Shifting Cloak
  [23704] = {learn=300, item=19049, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Timbermaw Brawlers
  [23706] = {learn=300, item=19058, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Golden Mantle of the Dawn
  [23707] = {learn=300, item=19149, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Lava Belt
  [23708] = {learn=300, item=19157, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Chromatic Gauntlets
  [23709] = {learn=300, item=19162, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Corehound Belt
  [23710] = {learn=300, item=19163, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Molten Belt
  [24121] = {learn=300, item=19685, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Primal Batskin Jerkin
  [24122] = {learn=300, item=19686, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Primal Batskin Gloves
  [24123] = {learn=300, item=19687, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Primal Batskin Bracers
  [24124] = {learn=300, item=19688, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Blood Tiger Breastplate
  [24125] = {learn=300, item=19689, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Blood Tiger Shoulders
  [24654] = {learn=300, item=20295, min=1, max=1, skillupCnt=1, source={}, colors={300,320,330,340}},  -- Blue Dragonscale Leggings
  [24703] = {learn=300, item=20380, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Dreamscale Breastplate
  [24846] = {learn=300, item=20481, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Spitfire Bracers
  [24847] = {learn=300, item=20480, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Spitfire Gauntlets
  [24848] = {learn=300, item=20479, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Spitfire Breastplate
  [24849] = {learn=300, item=20476, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Sandstalker Bracers
  [24850] = {learn=300, item=20477, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Sandstalker Gauntlets
  [24851] = {learn=300, item=20478, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Sandstalker Breastplate
  [26279] = {learn=300, item=21278, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Stormshroud Gloves
  [28219] = {learn=300, item=22661, min=1, max=1, skillupCnt=1, source={}, colors={300,320,330,340}},  -- Polar Tunic
  [28220] = {learn=300, item=22662, min=1, max=1, skillupCnt=1, source={}, colors={300,320,330,340}},  -- Polar Gloves
  [28221] = {learn=300, item=22663, min=1, max=1, skillupCnt=1, source={}, colors={300,320,330,340}},  -- Polar Bracers
  [28222] = {learn=300, item=22664, min=1, max=1, skillupCnt=1, source={}, colors={300,320,330,340}},  -- Icy Scale Breastplate
  [28223] = {learn=300, item=22666, min=1, max=1, skillupCnt=1, source={}, colors={300,320,330,340}},  -- Icy Scale Gauntlets
  [28224] = {learn=300, item=22665, min=1, max=1, skillupCnt=1, source={}, colors={300,320,330,340}},  -- Icy Scale Bracers
  [28472] = {learn=300, item=22759, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Bramblewood Helm
  [28473] = {learn=300, item=22760, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Bramblewood Boots
  [28474] = {learn=300, item=22761, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Bramblewood Belt
  [32454] = {learn=300, item=21887, min=1, max=1, skillupCnt=1, source={}, colors={300,300,305,310}},  -- Knothide Leather
  [32456] = {learn=300, item=25650, min=1, max=1, skillupCnt=1, source={}, colors={300,310,325,340}},  -- Knothide Armor Kit
  [32462] = {learn=300, item=25654, min=1, max=1, skillupCnt=1, source={}, colors={300,310,320,330}},  -- Felscale Gloves
  [32466] = {learn=300, item=25662, min=1, max=1, skillupCnt=1, source={}, colors={300,310,320,330}},  -- Scaled Draenic Pants
  [32470] = {learn=300, item=25669, min=1, max=1, skillupCnt=1, source={}, colors={300,310,320,330}},  -- Thick Draenic Gloves
  [32478] = {learn=300, item=25673, min=1, max=1, skillupCnt=1, source={}, colors={300,310,320,330}},  -- Wild Draenish Boots
  [32482] = {learn=300, item=25679, min=1, max=1, skillupCnt=1, source={5}, colors={300,300,305,310}},  -- Comfortable Insoles
  [45100] = {learn=300, item=34482, min=1, max=1, skillupCnt=1, source={}, colors={300,310,320,330}},  -- Leatherworker's Satchel
  [32463] = {learn=310, item=25655, min=1, max=1, skillupCnt=1, source={}, colors={310,320,330,340}},  -- Felscale Boots
  [32467] = {learn=310, item=25661, min=1, max=1, skillupCnt=1, source={}, colors={310,320,330,340}},  -- Scaled Draenic Gloves
  [32479] = {learn=310, item=25674, min=1, max=1, skillupCnt=1, source={}, colors={310,320,330,340}},  -- Wild Draenish Gloves
  [32471] = {learn=315, item=25670, min=1, max=1, skillupCnt=1, source={}, colors={315,325,335,345}},  -- Thick Draenic Pants
  [44343] = {learn=315, item=34099, min=1, max=1, skillupCnt=1, source={}, colors={315,325,335,345}},  -- Knothide Ammo Pouch
  [44344] = {learn=315, item=34100, min=1, max=1, skillupCnt=1, source={}, colors={315,325,335,345}},  -- Knothide Quiver
  [32464] = {learn=320, item=25656, min=1, max=1, skillupCnt=1, source={}, colors={320,330,340,350}},  -- Felscale Pants
  [32472] = {learn=320, item=25668, min=1, max=1, skillupCnt=1, source={}, colors={320,330,340,350}},  -- Thick Draenic Boots
  [32480] = {learn=320, item=25675, min=1, max=1, skillupCnt=1, source={}, colors={320,330,340,350}},  -- Wild Draenish Leggings
  [32455] = {learn=325, item=23793, min=1, max=1, skillupCnt=1, source={5}, colors={325,325,330,335}},  -- Heavy Knothide Leather
  [32457] = {learn=325, item=25651, min=1, max=1, skillupCnt=1, source={5}, colors={325,335,340,345}},  -- Vindicator's Armor Kit
  [32458] = {learn=325, item=25652, min=1, max=1, skillupCnt=1, source={5}, colors={325,335,340,345}},  -- Magister's Armor Kit
  [32468] = {learn=325, item=25660, min=1, max=1, skillupCnt=1, source={}, colors={325,335,345,355}},  -- Scaled Draenic Vest
  [35530] = {learn=325, item=29540, min=1, max=1, skillupCnt=1, source={5}, colors={325,335,340,345}},  -- Reinforced Mining Bag
  [32473] = {learn=330, item=25671, min=1, max=1, skillupCnt=1, source={}, colors={330,340,350,360}},  -- Thick Draenic Vest
  [32481] = {learn=330, item=25676, min=1, max=1, skillupCnt=1, source={}, colors={330,340,350,360}},  -- Wild Draenish Vest
  [36077] = {learn=330, item=29973, min=1, max=1, skillupCnt=1, source={}, colors={330,350,360,370}},  -- Primalstorm Breastplate
  [36078] = {learn=330, item=29974, min=1, max=1, skillupCnt=1, source={}, colors={330,350,360,370}},  -- Living Crystal Breastplate
  [36079] = {learn=330, item=29975, min=1, max=1, skillupCnt=1, source={}, colors={330,350,360,370}},  -- Golden Dragonstrike Breastplate
  [32465] = {learn=335, item=25657, min=1, max=1, skillupCnt=1, source={}, colors={335,345,355,365}},  -- Felscale Breastplate
  [32469] = {learn=335, item=25659, min=1, max=1, skillupCnt=1, source={}, colors={335,345,355,365}},  -- Scaled Draenic Boots
  [35549] = {learn=335, item=29533, min=1, max=1, skillupCnt=1, source={5}, colors={335,335,345,355}},  -- Cobrahide Leg Armor
  [35555] = {learn=335, item=29534, min=1, max=1, skillupCnt=1, source={5}, colors={335,335,345,355}},  -- Clefthide Leg Armor
  [32490] = {learn=340, item=25685, min=1, max=1, skillupCnt=1, source={5}, colors={340,350,360,370}},  -- Fel Leather Gloves
  [32501] = {learn=340, item=25694, min=1, max=1, skillupCnt=1, source={5}, colors={340,350,360,370}},  -- Netherfury Belt
  [32502] = {learn=340, item=25692, min=1, max=1, skillupCnt=1, source={5}, colors={340,350,360,370}},  -- Netherfury Leggings
  [35520] = {learn=340, item=29483, min=1, max=1, skillupCnt=1, source={2}, colors={340,350,355,360}},  -- Shadow Armor Kit
  [35521] = {learn=340, item=29485, min=1, max=1, skillupCnt=1, source={2}, colors={340,350,355,360}},  -- Flame Armor Kit
  [35522] = {learn=340, item=29486, min=1, max=1, skillupCnt=1, source={2}, colors={340,350,355,360}},  -- Frost Armor Kit
  [35523] = {learn=340, item=29487, min=1, max=1, skillupCnt=1, source={2}, colors={340,350,355,360}},  -- Nature Armor Kit
  [35524] = {learn=340, item=29488, min=1, max=1, skillupCnt=1, source={2}, colors={340,350,355,360}},  -- Arcane Armor Kit
  [35540] = {learn=340, item=29528, min=1, max=1, skillupCnt=1, source={}, colors={340,340,347,355}},  -- Drums of War
  [351766] = {learn=340, item=185852, min=1, max=1, skillupCnt=1, source={}, colors={340,340,347,355}},  -- Greater Drums of War
  [35544] = {learn=345, item=29530, min=1, max=1, skillupCnt=1, source={5}, colors={345,345,352,360}},  -- Drums of Speed
  [351768] = {learn=345, item=185851, min=1, max=1, skillupCnt=1, source={5}, colors={345,345,352,360}},  -- Greater Drums of Speed
  [32461] = {learn=350, item=25653, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Riding Crop
  [32485] = {learn=350, item=25680, min=1, max=1, skillupCnt=1, source={2}, colors={350,360,370,380}},  -- Stylin' Purple Hat
  [32487] = {learn=350, item=25681, min=1, max=1, skillupCnt=1, source={2}, colors={350,360,370,380}},  -- Stylin' Adventure Hat
  [32488] = {learn=350, item=25683, min=1, max=1, skillupCnt=1, source={2}, colors={350,360,370,380}},  -- Stylin' Crimson Hat
  [32489] = {learn=350, item=25682, min=1, max=1, skillupCnt=1, source={2}, colors={350,360,370,380}},  -- Stylin' Jungle Hat
  [32493] = {learn=350, item=25686, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Fel Leather Boots
  [32494] = {learn=350, item=25687, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Fel Leather Leggings
  [32498] = {learn=350, item=25695, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Felstalker Belt
  [32503] = {learn=350, item=25693, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Netherfury Boots
  [35525] = {learn=350, item=29489, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Enchanted Felscale Leggings
  [35526] = {learn=350, item=29490, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Enchanted Felscale Gloves
  [35527] = {learn=350, item=29491, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Enchanted Felscale Boots
  [35528] = {learn=350, item=29493, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Flamescale Boots
  [35529] = {learn=350, item=29492, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Flamescale Leggings
  [35531] = {learn=350, item=29494, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Flamescale Belt
  [35532] = {learn=350, item=29495, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Enchanted Clefthoof Leggings
  [35533] = {learn=350, item=29496, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Enchanted Clefthoof Gloves
  [35534] = {learn=350, item=29497, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Enchanted Clefthoof Boots
  [35535] = {learn=350, item=29498, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Blastguard Pants
  [35536] = {learn=350, item=29499, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Blastguard Boots
  [35537] = {learn=350, item=29500, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Blastguard Belt
  [35539] = {learn=350, item=29531, min=1, max=1, skillupCnt=1, source={5}, colors={350,350,357,365}},  -- Drums of Restoration
  [44359] = {learn=350, item=34105, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Quiver of a Thousand Feathers
  [44768] = {learn=350, item=34106, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Netherscale Ammo Pouch
  [44770] = {learn=350, item=34207, min=1, max=1, skillupCnt=1, source={}, colors={350,355,360,365}},  -- Glove Reinforcements
  [44970] = {learn=350, item=34330, min=1, max=1, skillupCnt=1, source={}, colors={350,355,360,365}},  -- Heavy Knothide Armor Kit
  [351769] = {learn=350, item=185850, min=1, max=1, skillupCnt=1, source={5}, colors={350,350,357,365}},  -- Greater Drums of Restoration
  [32496] = {learn=355, item=25690, min=1, max=1, skillupCnt=1, source={5}, colors={355,365,375,385}},  -- Heavy Clefthoof Leggings
  [32497] = {learn=355, item=25691, min=1, max=1, skillupCnt=1, source={5}, colors={355,365,375,385}},  -- Heavy Clefthoof Boots
  [32495] = {learn=360, item=25689, min=1, max=1, skillupCnt=1, source={5}, colors={360,370,380,390}},  -- Heavy Clefthoof Vest
  [32499] = {learn=360, item=25697, min=1, max=1, skillupCnt=1, source={5}, colors={360,370,380,390}},  -- Felstalker Bracer
  [32500] = {learn=360, item=25696, min=1, max=1, skillupCnt=1, source={5}, colors={360,370,380,390}},  -- Felstalker Breastplate
  [42546] = {learn=360, item=33122, min=1, max=1, skillupCnt=1, source={5}, colors={360,370,380,390}},  -- Cloak of Darkness
  [45117] = {learn=360, item=34490, min=1, max=1, skillupCnt=1, source={2}, colors={360,370,380,390}},  -- Bag of Many Hides
  [35543] = {learn=365, item=29529, min=1, max=1, skillupCnt=1, source={5}, colors={365,365,372,380}},  -- Drums of Battle
  [35554] = {learn=365, item=29535, min=1, max=1, skillupCnt=1, source={5}, colors={365,365,375,385}},  -- Nethercobra Leg Armor
  [35557] = {learn=365, item=29536, min=1, max=1, skillupCnt=1, source={5}, colors={365,365,375,385}},  -- Nethercleft Leg Armor
  [35558] = {learn=365, item=29502, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Cobrascale Hood
  [35559] = {learn=365, item=29503, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Cobrascale Gloves
  [35560] = {learn=365, item=29504, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Windscale Hood
  [35561] = {learn=365, item=29505, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Hood of Primal Life
  [35562] = {learn=365, item=29506, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Gloves of the Living Touch
  [35563] = {learn=365, item=29507, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Windslayer Wraps
  [35564] = {learn=365, item=29508, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Living Dragonscale Helm
  [35567] = {learn=365, item=29512, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Earthen Netherscale Boots
  [35568] = {learn=365, item=29509, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Windstrike Gloves
  [35572] = {learn=365, item=29510, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Netherdrake Helm
  [35573] = {learn=365, item=29511, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Netherdrake Gloves
  [35574] = {learn=365, item=29514, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Thick Netherscale Breastplate
  [42731] = {learn=365, item=33204, min=1, max=1, skillupCnt=1, source={5}, colors={365,375,385,395}},  -- Shadowprowler's Chestguard
  [46132] = {learn=365, item=34372, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Leather Gauntlets of the Sun
  [46133] = {learn=365, item=34374, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Fletcher's Gloves of the Phoenix
  [46134] = {learn=365, item=34370, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Gloves of Immortal Dusk
  [46135] = {learn=365, item=34376, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Sun-Drenched Scale Gloves
  [46136] = {learn=365, item=34371, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Leather Chestguard of the Sun
  [46137] = {learn=365, item=34373, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Embrace of the Phoenix
  [46138] = {learn=365, item=34369, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Carapace of Sun and Shadow
  [46139] = {learn=365, item=34375, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Sun-Drenched Scale Chestguard
  [351771] = {learn=365, item=185848, min=1, max=1, skillupCnt=1, source={5}, colors={365,365,372,380}},  -- Greater Drums of Battle
  [35538] = {learn=370, item=29532, min=1, max=1, skillupCnt=1, source={5}, colors={370,370,377,385}},  -- Drums of Panic
  [351770] = {learn=370, item=185849, min=1, max=1, skillupCnt=1, source={5}, colors={370,370,377,385}},  -- Greater Drums of Panic
  [35575] = {learn=375, item=29515, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Ebon Netherscale Breastplate
  [35576] = {learn=375, item=29516, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Ebon Netherscale Belt
  [35577] = {learn=375, item=29517, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Ebon Netherscale Bracers
  [35580] = {learn=375, item=29519, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Netherstrike Breastplate
  [35582] = {learn=375, item=29520, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Netherstrike Belt
  [35584] = {learn=375, item=29521, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Netherstrike Bracers
  [35585] = {learn=375, item=29522, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Windhawk Hauberk
  [35587] = {learn=375, item=29524, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Windhawk Belt
  [35588] = {learn=375, item=29523, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Windhawk Bracers
  [35589] = {learn=375, item=29525, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Primalstrike Vest
  [35590] = {learn=375, item=29526, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Primalstrike Belt
  [35591] = {learn=375, item=29527, min=1, max=1, skillupCnt=1, source={}, colors={375,385,395,405}},  -- Primalstrike Bracers
  [36349] = {learn=375, item=30042, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Belt of Natural Power
  [36351] = {learn=375, item=30040, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Belt of Deep Shadow
  [36352] = {learn=375, item=30046, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Belt of the Black Eagle
  [36353] = {learn=375, item=30044, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Monsoon Belt
  [36355] = {learn=375, item=30041, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Boots of Natural Grace
  [36357] = {learn=375, item=30039, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Boots of Utter Darkness
  [36358] = {learn=375, item=30045, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Boots of the Crimson Hawk
  [36359] = {learn=375, item=30043, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Hurricane Boots
  [39997] = {learn=375, item=32398, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- Boots of Shackled Souls
  [40000] = {learn=375, item=32399, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- Bracers of Shackled Souls
  [40001] = {learn=375, item=32400, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- Greaves of Shackled Souls
  [40002] = {learn=375, item=32397, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- Waistguard of Shackled Souls
  [40003] = {learn=375, item=32394, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- Redeemed Soul Moccasins
  [40004] = {learn=375, item=32395, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- Redeemed Soul Wristguards
  [40005] = {learn=375, item=32396, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- Redeemed Soul Legguards
  [40006] = {learn=375, item=32393, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- Redeemed Soul Cinch
  [41156] = {learn=375, item=32582, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Bracers of Renewed Life
  [41157] = {learn=375, item=32583, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Shoulderpads of Renewed Life
  [41158] = {learn=375, item=32580, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Swiftstrike Bracers
  [41160] = {learn=375, item=32581, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Swiftstrike Shoulders
  [41161] = {learn=375, item=32574, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Bindings of Lightning Reflexes
  [41162] = {learn=375, item=32575, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Shoulders of Lightning Reflexes
  [41163] = {learn=375, item=32577, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Living Earth Bindings
  [41164] = {learn=375, item=32579, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Living Earth Shoulders
  -- skillLine 171
  [2329] = {learn=1, item=2454, min=1, max=1, skillupCnt=1, source={}, colors={1,55,75,95}},  -- Elixir of Lion's Strength
  [2330] = {learn=1, item=118, min=1, max=1, skillupCnt=1, source={}, colors={1,55,75,95}},  -- Minor Healing Potion
  [7183] = {learn=1, item=5997, min=1, max=1, skillupCnt=1, source={}, colors={1,55,75,95}},  -- Elixir of Minor Defense
  [3170] = {learn=15, item=3382, min=1, max=1, skillupCnt=1, source={}, colors={15,60,80,100}},  -- Weak Troll's Blood Potion
  [2331] = {learn=25, item=2455, min=1, max=1, skillupCnt=1, source={}, colors={25,65,85,105}},  -- Minor Mana Potion
  [2332] = {learn=40, item=2456, min=1, max=1, skillupCnt=1, source={}, colors={40,70,90,110}},  -- Minor Rejuvenation Potion
  [2334] = {learn=50, item=2458, min=1, max=1, skillupCnt=1, source={}, colors={50,80,100,120}},  -- Elixir of Minor Fortitude
  [3230] = {learn=50, item=2457, min=1, max=1, skillupCnt=1, source={2,16,21}, colors={50,80,100,120}},  -- Elixir of Minor Agility
  [4508] = {learn=50, item=4596, min=1, max=1, skillupCnt=1, source={4}, colors={50,80,100,120}},  -- Discolored Healing Potion
  [2337] = {learn=55, item=858, min=1, max=1, skillupCnt=1, source={}, colors={55,85,105,125}},  -- Lesser Healing Potion
  [2335] = {learn=60, item=2459, min=1, max=1, skillupCnt=1, source={2,21}, colors={60,90,110,130}},  -- Swiftness Potion
  [6617] = {learn=60, item=5631, min=1, max=1, skillupCnt=1, source={5}, colors={60,90,110,130}},  -- Rage Potion
  [7836] = {learn=80, item=6370, min=1, max=1, skillupCnt=1, source={}, colors={80,80,90,100}},  -- Blackmouth Oil
  [3171] = {learn=90, item=3383, min=1, max=1, skillupCnt=1, source={}, colors={90,120,140,160}},  -- Elixir of Wisdom
  [7179] = {learn=90, item=5996, min=1, max=1, skillupCnt=1, source={}, colors={90,120,140,160}},  -- Elixir of Water Breathing
  [8240] = {learn=90, item=6662, min=1, max=1, skillupCnt=1, source={2}, colors={90,120,140,160}},  -- Elixir of Giant Growth
  [7255] = {learn=100, item=6051, min=1, max=1, skillupCnt=1, source={5}, colors={100,130,150,170}},  -- Holy Protection Potion
  [7841] = {learn=100, item=6372, min=1, max=1, skillupCnt=1, source={}, colors={100,130,150,170}},  -- Swim Speed Potion
  [3172] = {learn=110, item=3384, min=1, max=1, skillupCnt=1, source={2}, colors={110,135,155,175}},  -- Minor Magic Resistance Potion
  [3447] = {learn=110, item=929, min=1, max=1, skillupCnt=1, source={}, colors={110,135,155,175}},  -- Healing Potion
  [3173] = {learn=120, item=3385, min=1, max=1, skillupCnt=1, source={}, colors={120,145,165,185}},  -- Lesser Mana Potion
  [3174] = {learn=120, item=3386, min=1, max=1, skillupCnt=1, source={2}, colors={120,145,165,185}},  -- Potion of Curing
  [3176] = {learn=125, item=3388, min=1, max=1, skillupCnt=1, source={}, colors={125,150,170,190}},  -- Strong Troll's Blood Potion
  [3177] = {learn=130, item=3389, min=1, max=1, skillupCnt=1, source={}, colors={130,155,175,195}},  -- Elixir of Defense
  [7837] = {learn=130, item=6371, min=1, max=1, skillupCnt=1, source={}, colors={130,150,160,170}},  -- Fire Oil
  [7256] = {learn=135, item=6048, min=1, max=1, skillupCnt=1, source={5}, colors={135,160,180,200}},  -- Shadow Protection Potion
  [2333] = {learn=140, item=3390, min=1, max=1, skillupCnt=1, source={2,16}, colors={140,165,185,205}},  -- Elixir of Lesser Agility
  [7845] = {learn=140, item=6373, min=1, max=1, skillupCnt=1, source={}, colors={140,165,185,205}},  -- Elixir of Firepower
  [3188] = {learn=150, item=3391, min=1, max=1, skillupCnt=1, source={2,16}, colors={150,175,195,215}},  -- Elixir of Ogre's Strength
  [6624] = {learn=150, item=5634, min=1, max=1, skillupCnt=1, source={5}, colors={150,175,195,215}},  -- Free Action Potion
  [7181] = {learn=155, item=1710, min=1, max=1, skillupCnt=1, source={}, colors={155,175,195,215}},  -- Greater Healing Potion
  [3452] = {learn=160, item=3827, min=1, max=1, skillupCnt=1, source={}, colors={160,180,200,220}},  -- Mana Potion
  [3448] = {learn=165, item=3823, min=1, max=1, skillupCnt=1, source={}, colors={165,185,205,225}},  -- Lesser Invisibility Potion
  [3449] = {learn=165, item=3824, min=1, max=1, skillupCnt=1, source={5}, colors={165,190,210,230}},  -- Shadow Oil
  [7257] = {learn=165, item=6049, min=1, max=1, skillupCnt=1, source={5}, colors={165,210,230,250}},  -- Fire Protection Potion
  [3450] = {learn=175, item=3825, min=1, max=1, skillupCnt=1, source={2}, colors={175,195,215,235}},  -- Elixir of Fortitude
  [6618] = {learn=175, item=5633, min=1, max=1, skillupCnt=1, source={5}, colors={175,195,215,235}},  -- Great Rage Potion
  [3451] = {learn=180, item=3826, min=1, max=1, skillupCnt=1, source={2}, colors={180,200,220,240}},  -- Mighty Troll's Blood Potion
  [11449] = {learn=185, item=8949, min=1, max=1, skillupCnt=1, source={}, colors={185,205,225,245}},  -- Elixir of Agility
  [7258] = {learn=190, item=6050, min=1, max=1, skillupCnt=1, source={5}, colors={190,205,225,245}},  -- Frost Protection Potion
  [7259] = {learn=190, item=6052, min=1, max=1, skillupCnt=1, source={5}, colors={190,210,230,250}},  -- Nature Protection Potion
  [21923] = {learn=190, item=17708, min=1, max=1, skillupCnt=1, source={2}, colors={190,210,230,250}},  -- Elixir of Frost Power
  [3453] = {learn=195, item=3828, min=1, max=1, skillupCnt=1, source={2}, colors={195,215,235,255}},  -- Elixir of Detect Lesser Invisibility
  [11450] = {learn=195, item=8951, min=1, max=1, skillupCnt=1, source={}, colors={195,215,235,255}},  -- Elixir of Greater Defense
  [3454] = {learn=200, item=3829, min=1, max=1, skillupCnt=1, source={5}, colors={200,220,240,260}},  -- Frost Oil
  [12609] = {learn=200, item=10592, min=1, max=1, skillupCnt=1, source={}, colors={200,220,240,260}},  -- Catseye Elixir
  [11448] = {learn=205, item=6149, min=1, max=1, skillupCnt=1, source={}, colors={205,220,240,260}},  -- Greater Mana Potion
  [11451] = {learn=205, item=8956, min=1, max=1, skillupCnt=1, source={}, colors={205,220,240,260}},  -- Oil of Immolation
  [11453] = {learn=210, item=9036, min=1, max=1, skillupCnt=1, source={2}, colors={210,225,245,265}},  -- Magic Resistance Potion
  [11456] = {learn=210, item=9061, min=1, max=1, skillupCnt=1, source={1}, colors={210,225,245,265}},  -- Goblin Rocket Fuel
  [4942] = {learn=215, item=4623, min=1, max=1, skillupCnt=1, source={4}, colors={215,230,250,270}},  -- Lesser Stoneshield Potion
  [11452] = {learn=215, item=9030, min=1, max=1, skillupCnt=1, source={}, colors={215,225,245,265}},  -- Restorative Potion
  [11457] = {learn=215, item=3928, min=1, max=1, skillupCnt=1, source={}, colors={215,230,250,270}},  -- Superior Healing Potion
  [22808] = {learn=215, item=18294, min=1, max=1, skillupCnt=1, source={}, colors={215,230,250,270}},  -- Elixir of Greater Water Breathing
  [11458] = {learn=225, item=9144, min=1, max=1, skillupCnt=1, source={2}, colors={225,240,260,280}},  -- Wildvine Potion
  [11459] = {learn=225, item=9149, min=1, max=1, skillupCnt=1, source={5}, colors={225,240,260,280}},  -- Philosopher's Stone
  [11479] = {learn=225, item=3577, min=0, max=0, skillupCnt=1, source={5}, colors={225,240,260,280}},  -- Transmute: Iron to Gold
  [11480] = {learn=225, item=6037, min=0, max=0, skillupCnt=1, source={5}, colors={225,240,260,280}},  -- Transmute: Mithril to Truesilver
  [11460] = {learn=230, item=9154, min=1, max=1, skillupCnt=1, source={}, colors={230,245,265,285}},  -- Elixir of Detect Undead
  [15833] = {learn=230, item=12190, min=1, max=1, skillupCnt=1, source={}, colors={230,245,265,285}},  -- Dreamless Sleep Potion
  [11461] = {learn=235, item=9155, min=1, max=1, skillupCnt=1, source={}, colors={235,250,270,290}},  -- Arcane Elixir
  [11464] = {learn=235, item=9172, min=1, max=1, skillupCnt=1, source={2,16}, colors={235,250,270,290}},  -- Invisibility Potion
  [11465] = {learn=235, item=9179, min=1, max=1, skillupCnt=1, source={}, colors={235,250,270,290}},  -- Elixir of Greater Intellect
  [11466] = {learn=240, item=9088, min=1, max=1, skillupCnt=1, source={2}, colors={240,255,275,295}},  -- Gift of Arthas
  [11467] = {learn=240, item=9187, min=1, max=1, skillupCnt=1, source={}, colors={240,255,275,295}},  -- Elixir of Greater Agility
  [11468] = {learn=240, item=9197, min=1, max=1, skillupCnt=1, source={2}, colors={240,255,275,295}},  -- Elixir of Dream Vision
  [11472] = {learn=245, item=9206, min=1, max=1, skillupCnt=1, source={2}, colors={245,260,280,300}},  -- Elixir of Giants
  [11473] = {learn=245, item=9210, min=1, max=1, skillupCnt=1, source={5}, colors={245,260,280,300}},  -- Ghost Dye
  [3175] = {learn=250, item=3387, min=1, max=1, skillupCnt=1, source={2,16}, colors={250,275,295,315}},  -- Limited Invulnerability Potion
  [11476] = {learn=250, item=9264, min=1, max=1, skillupCnt=1, source={5}, colors={250,265,285,305}},  -- Elixir of Shadow Power
  [11477] = {learn=250, item=9224, min=1, max=1, skillupCnt=1, source={5}, colors={250,265,285,305}},  -- Elixir of Demonslaying
  [11478] = {learn=250, item=9233, min=1, max=1, skillupCnt=1, source={}, colors={250,265,285,305}},  -- Elixir of Detect Demon
  [17551] = {learn=250, item=13423, min=1, max=1, skillupCnt=1, source={}, colors={250,250,255,260}},  -- Stonescale Oil
  [26277] = {learn=250, item=21546, min=1, max=1, skillupCnt=1, source={2}, colors={250,265,285,305}},  -- Elixir of Greater Firepower
  [17552] = {learn=255, item=13442, min=1, max=1, skillupCnt=1, source={2}, colors={255,270,290,310}},  -- Mighty Rage Potion
  [17553] = {learn=260, item=13443, min=1, max=1, skillupCnt=1, source={5}, colors={260,275,295,315}},  -- Superior Mana Potion
  [17554] = {learn=265, item=13445, min=1, max=1, skillupCnt=1, source={5}, colors={265,280,300,320}},  -- Elixir of Superior Defense
  [17555] = {learn=270, item=13447, min=1, max=1, skillupCnt=1, source={2}, colors={270,285,305,325}},  -- Elixir of the Sages
  [17187] = {learn=275, item=12360, min=0, max=0, skillupCnt=1, source={5}, colors={275,275,282,290}},  -- Transmute: Arcanite
  [17556] = {learn=275, item=13446, min=1, max=1, skillupCnt=1, source={5}, colors={275,290,310,330}},  -- Major Healing Potion
  [17557] = {learn=275, item=13453, min=1, max=1, skillupCnt=1, source={2}, colors={275,290,310,330}},  -- Elixir of Brute Force
  [17559] = {learn=275, item=7078, min=0, max=0, skillupCnt=1, source={5}, colors={275,275,282,290}},  -- Transmute: Air to Fire
  [17560] = {learn=275, item=7076, min=0, max=0, skillupCnt=1, source={5}, colors={275,275,282,290}},  -- Transmute: Fire to Earth
  [17561] = {learn=275, item=7080, min=0, max=0, skillupCnt=1, source={5}, colors={275,275,282,290}},  -- Transmute: Earth to Water
  [17562] = {learn=275, item=7082, min=0, max=0, skillupCnt=1, source={5}, colors={275,275,282,290}},  -- Transmute: Water to Air
  [17563] = {learn=275, item=7080, min=0, max=0, skillupCnt=1, source={2}, colors={275,275,282,290}},  -- Transmute: Undeath to Water
  [17564] = {learn=275, item=12808, min=0, max=0, skillupCnt=1, source={2}, colors={275,275,282,290}},  -- Transmute: Water to Undeath
  [17565] = {learn=275, item=7076, min=0, max=0, skillupCnt=1, source={2,16}, colors={275,275,282,290}},  -- Transmute: Life to Earth
  [17566] = {learn=275, item=12803, min=0, max=0, skillupCnt=1, source={2}, colors={275,275,282,290}},  -- Transmute: Earth to Life
  [24365] = {learn=275, item=20007, min=1, max=1, skillupCnt=1, source={5}, colors={275,290,310,330}},  -- Mageblood Potion
  [24366] = {learn=275, item=20002, min=1, max=1, skillupCnt=1, source={5}, colors={275,290,310,330}},  -- Greater Dreamless Sleep Potion
  [17570] = {learn=280, item=13455, min=1, max=1, skillupCnt=1, source={2}, colors={280,295,315,335}},  -- Greater Stoneshield Potion
  [17571] = {learn=280, item=13452, min=1, max=1, skillupCnt=1, source={2}, colors={280,295,315,335}},  -- Elixir of the Mongoose
  [17572] = {learn=285, item=13462, min=1, max=1, skillupCnt=1, source={2}, colors={285,300,320,340}},  -- Purification Potion
  [17573] = {learn=285, item=13454, min=1, max=1, skillupCnt=1, source={2}, colors={285,300,320,340}},  -- Greater Arcane Elixir
  [24367] = {learn=285, item=20008, min=1, max=1, skillupCnt=1, source={5}, colors={285,300,320,340}},  -- Living Action Potion
  [17574] = {learn=290, item=13457, min=1, max=1, skillupCnt=1, source={2}, colors={290,305,325,345}},  -- Greater Fire Protection Potion
  [17575] = {learn=290, item=13456, min=1, max=1, skillupCnt=1, source={2}, colors={290,305,325,345}},  -- Greater Frost Protection Potion
  [17576] = {learn=290, item=13458, min=1, max=1, skillupCnt=1, source={2}, colors={290,305,325,345}},  -- Greater Nature Protection Potion
  [17577] = {learn=290, item=13461, min=1, max=1, skillupCnt=1, source={2}, colors={290,305,325,345}},  -- Greater Arcane Protection Potion
  [17578] = {learn=290, item=13459, min=1, max=1, skillupCnt=1, source={2}, colors={290,305,325,345}},  -- Greater Shadow Protection Potion
  [24368] = {learn=290, item=20004, min=1, max=1, skillupCnt=1, source={5}, colors={290,305,325,345}},  -- Major Troll's Blood Potion
  [17580] = {learn=295, item=13444, min=1, max=1, skillupCnt=1, source={2,5}, colors={295,310,330,350}},  -- Major Mana Potion
  [17632] = {learn=300, item=13503, min=1, max=1, skillupCnt=1, source={5}, colors={300,365,372,380}},  -- Alchemist's Stone
  [17634] = {learn=300, item=13506, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,322,330}},  -- Flask of Petrification
  [17635] = {learn=300, item=13510, min=1, max=1, skillupCnt=1, source={2,5}, colors={300,315,322,330}},  -- Flask of the Titans
  [17636] = {learn=300, item=13511, min=1, max=1, skillupCnt=1, source={2,5}, colors={300,315,322,330}},  -- Flask of Distilled Wisdom
  [17637] = {learn=300, item=13512, min=1, max=1, skillupCnt=1, source={2,5}, colors={300,315,322,330}},  -- Flask of Supreme Power
  [17638] = {learn=300, item=13513, min=1, max=1, skillupCnt=1, source={2,5}, colors={300,315,322,330}},  -- Flask of Chromatic Resistance
  [22732] = {learn=300, item=18253, min=1, max=1, skillupCnt=1, source={2}, colors={300,310,320,330}},  -- Major Rejuvenation Potion
  [25146] = {learn=300, item=7068, min=3, max=3, skillupCnt=1, source={5}, colors={300,301,305,310}},  -- Transmute: Elemental Fire
  [33732] = {learn=300, item=28100, min=1, max=1, skillupCnt=1, source={}, colors={300,315,322,330}},  -- Volatile Healing Potion
  [33738] = {learn=300, item=28102, min=1, max=1, skillupCnt=1, source={}, colors={300,315,322,330}},  -- Onslaught Elixir
  [33740] = {learn=300, item=28103, min=1, max=1, skillupCnt=1, source={}, colors={300,315,322,330}},  -- Adept's Elixir
  [28543] = {learn=305, item=22823, min=1, max=1, skillupCnt=1, source={5}, colors={305,320,327,335}},  -- Elixir of Camouflage
  [28544] = {learn=305, item=22824, min=1, max=1, skillupCnt=1, source={}, colors={305,320,327,335}},  -- Elixir of Major Strength
  [28545] = {learn=310, item=22825, min=1, max=1, skillupCnt=1, source={}, colors={310,325,332,340}},  -- Elixir of Healing Power
  [33733] = {learn=310, item=28101, min=1, max=1, skillupCnt=1, source={}, colors={310,325,332,340}},  -- Unstable Mana Potion
  [39636] = {learn=310, item=32062, min=1, max=1, skillupCnt=1, source={}, colors={310,325,332,340}},  -- Elixir of Major Fortitude
  [24266] = {learn=315, item=19931, min=3, max=3, skillupCnt=1, source={}, colors={0,315,322,330}},  -- Gurubashi Mojo Madness
  [28546] = {learn=315, item=22826, min=1, max=1, skillupCnt=1, source={5}, colors={315,330,337,345}},  -- Sneaking Potion
  [33741] = {learn=315, item=28104, min=1, max=1, skillupCnt=1, source={}, colors={315,330,337,345}},  -- Elixir of Mastery
  [28549] = {learn=320, item=22827, min=1, max=1, skillupCnt=1, source={5}, colors={320,335,342,350}},  -- Elixir of Major Frost Power
  [28550] = {learn=320, item=22828, min=1, max=1, skillupCnt=1, source={2}, colors={320,335,342,350}},  -- Insane Strength Potion
  [39637] = {learn=320, item=32063, min=1, max=1, skillupCnt=1, source={5}, colors={320,335,342,350}},  -- Earthen Elixir
  [39638] = {learn=320, item=32067, min=1, max=1, skillupCnt=1, source={}, colors={320,335,342,350}},  -- Elixir of Draenic Wisdom
  [28551] = {learn=325, item=22829, min=1, max=1, skillupCnt=1, source={}, colors={325,340,347,355}},  -- Super Healing Potion
  [28552] = {learn=325, item=22830, min=1, max=1, skillupCnt=1, source={2}, colors={325,340,347,355}},  -- Elixir of the Searching Eye
  [38070] = {learn=325, item=31080, min=1, max=1, skillupCnt=1, source={}, colors={325,340,347,355}},  -- Mercurial Stone
  [45061] = {learn=325, item=34440, min=1, max=1, skillupCnt=1, source={}, colors={325,335,342,350}},  -- Mad Alchemist's Potion
  [28553] = {learn=330, item=22831, min=1, max=1, skillupCnt=1, source={5}, colors={330,345,352,360}},  -- Elixir of Major Agility
  [39639] = {learn=330, item=32068, min=1, max=1, skillupCnt=1, source={5}, colors={330,345,352,360}},  -- Elixir of Ironskin
  [28554] = {learn=335, item=22871, min=1, max=1, skillupCnt=1, source={5}, colors={335,350,357,365}},  -- Shrouding Potion
  [38960] = {learn=335, item=31679, min=1, max=1, skillupCnt=1, source={2}, colors={335,350,357,365}},  -- Fel Strength Elixir
  [28555] = {learn=340, item=22832, min=1, max=1, skillupCnt=1, source={5}, colors={340,355,362,370}},  -- Super Mana Potion
  [28556] = {learn=345, item=22833, min=1, max=1, skillupCnt=1, source={5}, colors={345,360,367,375}},  -- Elixir of Major Firepower
  [28557] = {learn=345, item=22834, min=1, max=1, skillupCnt=1, source={5}, colors={345,360,367,375}},  -- Elixir of Major Defense
  [38962] = {learn=345, item=31676, min=1, max=1, skillupCnt=1, source={2}, colors={345,360,367,375}},  -- Fel Regeneration Potion
  [28558] = {learn=350, item=22835, min=1, max=1, skillupCnt=1, source={5}, colors={350,365,372,380}},  -- Elixir of Major Shadow Power
  [28562] = {learn=350, item=22836, min=1, max=1, skillupCnt=1, source={5}, colors={350,365,372,380}},  -- Major Dreamless Sleep Potion
  [28563] = {learn=350, item=22837, min=1, max=1, skillupCnt=1, source={2}, colors={350,365,372,380}},  -- Heroic Potion
  [28564] = {learn=350, item=22838, min=1, max=1, skillupCnt=1, source={2}, colors={350,365,372,380}},  -- Haste Potion
  [28565] = {learn=350, item=22839, min=1, max=1, skillupCnt=1, source={2}, colors={350,365,372,380}},  -- Destruction Potion
  [28566] = {learn=350, item=21884, min=1, max=1, skillupCnt=1, source={5}, colors={350,365,372,380}},  -- Transmute: Primal Air to Fire
  [28567] = {learn=350, item=21885, min=1, max=1, skillupCnt=1, source={5}, colors={350,365,372,380}},  -- Transmute: Primal Earth to Water
  [28568] = {learn=350, item=22452, min=1, max=1, skillupCnt=1, source={5}, colors={350,365,372,380}},  -- Transmute: Primal Fire to Earth
  [28569] = {learn=350, item=22451, min=1, max=1, skillupCnt=1, source={5}, colors={350,365,372,380}},  -- Transmute: Primal Water to Air
  [29688] = {learn=350, item=23571, min=1, max=1, skillupCnt=1, source={5}, colors={350,365,372,380}},  -- Transmute: Primal Might
  [32765] = {learn=350, item=25867, min=1, max=1, skillupCnt=1, source={5}, colors={350,365,372,380}},  -- Transmute: Earthstorm Diamond
  [32766] = {learn=350, item=25868, min=1, max=1, skillupCnt=1, source={5}, colors={350,365,372,380}},  -- Transmute: Skyfire Diamond
  [28570] = {learn=355, item=22840, min=1, max=1, skillupCnt=1, source={2}, colors={355,370,377,385}},  -- Elixir of Major Mageblood
  [28571] = {learn=360, item=22841, min=5, max=5, skillupCnt=1, source={2}, colors={360,375,382,390}},  -- Major Fire Protection Potion
  [28572] = {learn=360, item=22842, min=5, max=5, skillupCnt=1, source={2}, colors={360,375,382,390}},  -- Major Frost Protection Potion
  [28573] = {learn=360, item=22844, min=5, max=5, skillupCnt=1, source={5}, colors={360,375,382,390}},  -- Major Nature Protection Potion
  [28575] = {learn=360, item=22845, min=5, max=5, skillupCnt=1, source={2}, colors={360,375,382,390}},  -- Major Arcane Protection Potion
  [28576] = {learn=360, item=22846, min=5, max=5, skillupCnt=1, source={2}, colors={360,375,382,390}},  -- Major Shadow Protection Potion
  [28577] = {learn=360, item=22847, min=5, max=5, skillupCnt=1, source={2}, colors={360,375,382,390}},  -- Major Holy Protection Potion
  [38961] = {learn=360, item=31677, min=1, max=1, skillupCnt=1, source={2}, colors={360,375,382,390}},  -- Fel Mana Potion
  [41458] = {learn=360, item=32839, min=1, max=1, skillupCnt=1, source={}, colors={0,360,370,380}},  -- Cauldron of Major Arcane Protection
  [41500] = {learn=360, item=32849, min=1, max=1, skillupCnt=1, source={}, colors={0,360,370,380}},  -- Cauldron of Major Fire Protection
  [41501] = {learn=360, item=32850, min=1, max=1, skillupCnt=1, source={}, colors={0,360,370,380}},  -- Cauldron of Major Frost Protection
  [41502] = {learn=360, item=32851, min=1, max=1, skillupCnt=1, source={}, colors={0,360,370,380}},  -- Cauldron of Major Nature Protection
  [41503] = {learn=360, item=32852, min=1, max=1, skillupCnt=1, source={}, colors={0,360,370,380}},  -- Cauldron of Major Shadow Protection
  [28578] = {learn=365, item=22848, min=1, max=1, skillupCnt=1, source={2}, colors={365,380,387,395}},  -- Elixir of Empowerment
  [28579] = {learn=365, item=22849, min=1, max=1, skillupCnt=1, source={2}, colors={365,380,387,395}},  -- Ironshield Potion
  [42736] = {learn=375, item=33208, min=1, max=1, skillupCnt=1, source={5}, colors={375,390,397,405}},  -- Flask of Chromatic Wonder
  [47046] = {learn=375, item=35748, min=1, max=1, skillupCnt=1, source={5}, colors={375,390,397,405}},  -- Guardian's Alchemist Stone
  [47048] = {learn=375, item=35749, min=1, max=1, skillupCnt=1, source={5}, colors={375,390,397,405}},  -- Sorcerer's Alchemist Stone
  [47049] = {learn=375, item=35750, min=1, max=1, skillupCnt=1, source={5}, colors={375,390,397,405}},  -- Redeemer's Alchemist Stone
  [47050] = {learn=375, item=35751, min=1, max=1, skillupCnt=1, source={5}, colors={375,390,397,405}},  -- Assassin's Alchemist Stone
  [28580] = {learn=385, item=21885, min=1, max=1, skillupCnt=1, source={}, colors={0,385,392,400}},  -- Transmute: Primal Shadow to Water
  [28581] = {learn=385, item=22456, min=1, max=1, skillupCnt=1, source={}, colors={0,385,392,400}},  -- Transmute: Primal Water to Shadow
  [28582] = {learn=385, item=21884, min=1, max=1, skillupCnt=1, source={}, colors={0,385,392,400}},  -- Transmute: Primal Mana to Fire
  [28583] = {learn=385, item=22457, min=1, max=1, skillupCnt=1, source={}, colors={0,385,392,400}},  -- Transmute: Primal Fire to Mana
  [28584] = {learn=385, item=22452, min=1, max=1, skillupCnt=1, source={}, colors={0,385,392,400}},  -- Transmute: Primal Life to Earth
  [28585] = {learn=385, item=21886, min=1, max=1, skillupCnt=1, source={}, colors={0,385,392,400}},  -- Transmute: Primal Earth to Life
  [28586] = {learn=390, item=22850, min=1, max=1, skillupCnt=1, source={}, colors={0,390,397,405}},  -- Super Rejuvenation Potion
  [28587] = {learn=390, item=22851, min=1, max=1, skillupCnt=1, source={}, colors={0,390,397,405}},  -- Flask of Fortification
  [28588] = {learn=390, item=22853, min=1, max=1, skillupCnt=1, source={}, colors={0,390,397,405}},  -- Flask of Mighty Restoration
  [28589] = {learn=390, item=22854, min=1, max=1, skillupCnt=1, source={}, colors={0,390,397,405}},  -- Flask of Relentless Assault
  [28590] = {learn=390, item=22861, min=1, max=1, skillupCnt=1, source={}, colors={0,390,397,405}},  -- Flask of Blinding Light
  [28591] = {learn=390, item=22866, min=1, max=1, skillupCnt=1, source={}, colors={0,390,397,405}},  -- Flask of Pure Death
  -- skillLine 185
  [2538] = {learn=0, item=2679, min=1, max=1, skillupCnt=1, source={}, colors={0,45,65,85}},  -- Charred Wolf Meat
  [2540] = {learn=0, item=2681, min=1, max=1, skillupCnt=1, source={}, colors={0,45,65,85}},  -- Roasted Boar Meat
  [7751] = {learn=1, item=6290, min=1, max=1, skillupCnt=1, source={5}, colors={1,45,65,85}},  -- Brilliant Smallfish
  [7752] = {learn=1, item=787, min=1, max=1, skillupCnt=1, source={5}, colors={1,45,65,85}},  -- Slitherskin Mackerel
  [8604] = {learn=1, item=6888, min=1, max=1, skillupCnt=1, source={}, colors={1,45,65,85}},  -- Herb Baked Egg
  [15935] = {learn=1, item=12224, min=1, max=1, skillupCnt=1, source={5}, colors={1,45,65,85}},  -- Crispy Bat Wing
  [21143] = {learn=1, item=17197, min=1, max=1, skillupCnt=1, source={5}, colors={1,45,65,85}},  -- Gingerbread Cookie
  [33276] = {learn=1, item=27635, min=1, max=1, skillupCnt=1, source={5}, colors={1,45,65,85}},  -- Lynx Steak
  [33277] = {learn=1, item=24105, min=1, max=1, skillupCnt=1, source={4}, colors={1,45,65,85}},  -- Roasted Moongraze Tenderloin
  [37836] = {learn=1, item=30816, min=1, max=1, skillupCnt=1, source={}, colors={1,30,35,40}},  -- Spice Bread
  [43779] = {learn=1, item=33924, min=1, max=1, skillupCnt=1, source={2}, colors={1,50,62,75}},  -- Delicious Chocolate Cake
  [2539] = {learn=10, item=2680, min=1, max=1, skillupCnt=1, source={}, colors={10,50,70,90}},  -- Spiced Wolf Meat
  [6412] = {learn=10, item=5472, min=1, max=1, skillupCnt=1, source={4}, colors={10,50,70,90}},  -- Kaldorei Spider Kabob
  [6413] = {learn=20, item=5473, min=1, max=1, skillupCnt=1, source={5}, colors={20,60,80,100}},  -- Scorpid Surprise
  [818] = {learn=25, item=0, min=0, max=0, skillupCnt=1, source={}, colors={0,25,50,75}},  -- Basic Campfire
  [2795] = {learn=25, item=2888, min=1, max=1, skillupCnt=1, source={4,5}, colors={25,60,80,100}},  -- Beer Basted Boar Ribs
  [6414] = {learn=35, item=5474, min=2, max=2, skillupCnt=1, source={5}, colors={35,75,95,115}},  -- Roasted Kodo Meat
  [21144] = {learn=35, item=17198, min=1, max=1, skillupCnt=1, source={5}, colors={35,75,95,115}},  -- Egg Nog
  [8607] = {learn=40, item=6890, min=1, max=1, skillupCnt=1, source={5}, colors={40,80,100,120}},  -- Smoked Bear Meat
  [2541] = {learn=50, item=2684, min=1, max=1, skillupCnt=1, source={}, colors={50,90,110,130}},  -- Coyote Steak
  [2542] = {learn=50, item=724, min=1, max=1, skillupCnt=1, source={4,5}, colors={50,90,110,130}},  -- Goretusk Liver Pie
  [6415] = {learn=50, item=5476, min=2, max=2, skillupCnt=1, source={5}, colors={50,90,110,130}},  -- Fillet of Frenzy
  [6416] = {learn=50, item=5477, min=2, max=2, skillupCnt=1, source={4,5}, colors={50,90,110,130}},  -- Strider Stew
  [6499] = {learn=50, item=5525, min=1, max=1, skillupCnt=1, source={}, colors={50,90,110,130}},  -- Boiled Clams
  [7753] = {learn=50, item=4592, min=1, max=1, skillupCnt=1, source={5}, colors={50,90,110,130}},  -- Longjaw Mud Snapper
  [7754] = {learn=50, item=6316, min=1, max=1, skillupCnt=1, source={5}, colors={50,90,110,130}},  -- Loch Frenzy Delight
  [7827] = {learn=50, item=5095, min=1, max=1, skillupCnt=1, source={5}, colors={50,90,110,130}},  -- Rainbow Fin Albacore
  [33278] = {learn=50, item=27636, min=1, max=1, skillupCnt=1, source={5}, colors={50,90,110,130}},  -- Bat Bites
  [3371] = {learn=60, item=3220, min=2, max=2, skillupCnt=1, source={4,5}, colors={60,100,120,140}},  -- Blood Sausage
  [9513] = {learn=60, item=7676, min=1, max=1, skillupCnt=1, source={4,5}, colors={60,100,120,140}},  -- Thistle Tea
  [28267] = {learn=60, item=22645, min=1, max=1, skillupCnt=1, source={4,5}, colors={60,100,120,140}},  -- Crunchy Spider Surprise
  [2543] = {learn=75, item=733, min=1, max=1, skillupCnt=1, source={4,5}, colors={75,115,135,155}},  -- Westfall Stew
  [2544] = {learn=75, item=2683, min=1, max=1, skillupCnt=1, source={}, colors={75,115,135,155}},  -- Crab Cake
  [2546] = {learn=80, item=2687, min=1, max=1, skillupCnt=1, source={}, colors={80,120,140,160}},  -- Dry Pork Ribs
  [3370] = {learn=80, item=3662, min=1, max=1, skillupCnt=1, source={4,5}, colors={80,120,140,160}},  -- Crocolisk Steak
  [25704] = {learn=80, item=21072, min=1, max=1, skillupCnt=1, source={5}, colors={80,120,140,160}},  -- Smoked Sagefish
  [2545] = {learn=85, item=2682, min=1, max=1, skillupCnt=1, source={2,5}, colors={85,125,145,165}},  -- Cooked Crab Claw
  [8238] = {learn=85, item=6657, min=1, max=1, skillupCnt=1, source={2}, colors={85,125,145,165}},  -- Savory Deviate Delight
  [3372] = {learn=90, item=3663, min=1, max=1, skillupCnt=1, source={4,5}, colors={90,130,150,170}},  -- Murloc Fin Soup
  [6417] = {learn=90, item=5478, min=2, max=2, skillupCnt=1, source={4}, colors={90,130,150,170}},  -- Dig Rat Stew
  [6501] = {learn=90, item=5526, min=1, max=1, skillupCnt=1, source={5}, colors={90,130,150,170}},  -- Clam Chowder
  [2547] = {learn=100, item=1082, min=1, max=1, skillupCnt=1, source={4,5}, colors={100,135,155,175}},  -- Redridge Goulash
  [2549] = {learn=100, item=1017, min=3, max=3, skillupCnt=1, source={4,5}, colors={100,140,160,180}},  -- Seasoned Wolf Kabob
  [6418] = {learn=100, item=5479, min=2, max=2, skillupCnt=1, source={5}, colors={100,140,160,180}},  -- Crispy Lizard Tail
  [7755] = {learn=100, item=4593, min=1, max=1, skillupCnt=1, source={5}, colors={100,140,160,180}},  -- Bristle Whisker Catfish
  [45695] = {learn=100, item=34832, min=5, max=5, skillupCnt=1, source={2}, colors={100,100,105,110}},  -- Captain Rumsey's Lager
  [2548] = {learn=110, item=2685, min=1, max=1, skillupCnt=1, source={2,5}, colors={110,130,150,170}},  -- Succulent Pork Ribs
  [3377] = {learn=110, item=3666, min=1, max=1, skillupCnt=1, source={4,5}, colors={110,150,170,190}},  -- Gooey Spider Cake
  [3397] = {learn=110, item=3726, min=1, max=1, skillupCnt=1, source={4,5}, colors={110,150,170,190}},  -- Big Bear Steak
  [6419] = {learn=110, item=5480, min=2, max=2, skillupCnt=1, source={5}, colors={110,150,170,190}},  -- Lean Venison
  [3373] = {learn=120, item=3664, min=1, max=1, skillupCnt=1, source={4,5}, colors={120,160,180,200}},  -- Crocolisk Gumbo
  [3398] = {learn=125, item=3727, min=1, max=1, skillupCnt=1, source={4,5}, colors={125,175,195,215}},  -- Hot Lion Chops
  [6500] = {learn=125, item=5527, min=1, max=1, skillupCnt=1, source={}, colors={125,165,185,205}},  -- Goblin Deviled Clams
  [15853] = {learn=125, item=12209, min=1, max=1, skillupCnt=1, source={5}, colors={125,165,185,205}},  -- Lean Wolf Steak
  [3376] = {learn=130, item=3665, min=1, max=1, skillupCnt=1, source={4,5}, colors={130,170,190,210}},  -- Curiously Tasty Omelet
  [3399] = {learn=150, item=3728, min=1, max=1, skillupCnt=1, source={4}, colors={150,190,210,230}},  -- Tasty Lion Steak
  [24418] = {learn=150, item=20074, min=1, max=1, skillupCnt=1, source={5}, colors={150,160,180,200}},  -- Heavy Crocolisk Stew
  [3400] = {learn=175, item=3729, min=1, max=1, skillupCnt=1, source={4}, colors={175,215,235,255}},  -- Soothing Turtle Bisque
  [4094] = {learn=175, item=4457, min=1, max=1, skillupCnt=1, source={4,5}, colors={175,215,235,255}},  -- Barbecued Buzzard Wing
  [7213] = {learn=175, item=6038, min=1, max=1, skillupCnt=1, source={5}, colors={175,215,235,255}},  -- Giant Clam Scorcho
  [7828] = {learn=175, item=4594, min=1, max=1, skillupCnt=1, source={5}, colors={175,190,210,230}},  -- Rockscale Cod
  [13028] = {learn=175, item=10841, min=4, max=4, skillupCnt=1, source={}, colors={175,175,190,205}},  -- Goldthorn Tea
  [15855] = {learn=175, item=12210, min=1, max=1, skillupCnt=1, source={5}, colors={175,215,235,255}},  -- Roast Raptor
  [15856] = {learn=175, item=13851, min=1, max=1, skillupCnt=1, source={5}, colors={175,215,235,255}},  -- Hot Wolf Ribs
  [15861] = {learn=175, item=12212, min=2, max=2, skillupCnt=1, source={5}, colors={175,215,235,255}},  -- Jungle Stew
  [15863] = {learn=175, item=12213, min=1, max=1, skillupCnt=1, source={5}, colors={175,215,235,255}},  -- Carrion Surprise
  [15865] = {learn=175, item=12214, min=1, max=1, skillupCnt=1, source={5}, colors={175,215,235,255}},  -- Mystery Stew
  [20916] = {learn=175, item=8364, min=1, max=1, skillupCnt=1, source={5}, colors={175,215,235,255}},  -- Mithril Headed Trout
  [25954] = {learn=175, item=21217, min=1, max=1, skillupCnt=1, source={5}, colors={175,215,235,255}},  -- Sagefish Delight
  [15906] = {learn=200, item=12217, min=1, max=1, skillupCnt=1, source={5}, colors={200,225,237,250}},  -- Dragonbreath Chili
  [15910] = {learn=200, item=12215, min=2, max=2, skillupCnt=1, source={5}, colors={200,225,237,250}},  -- Heavy Kodo Stew
  [21175] = {learn=200, item=17222, min=1, max=1, skillupCnt=1, source={}, colors={200,225,237,250}},  -- Spider Sausage
  [15915] = {learn=225, item=12216, min=1, max=1, skillupCnt=1, source={5}, colors={225,250,262,275}},  -- Spiced Chili Crab
  [15933] = {learn=225, item=12218, min=1, max=1, skillupCnt=1, source={5}, colors={225,250,262,275}},  -- Monster Omelet
  [18238] = {learn=225, item=6887, min=1, max=1, skillupCnt=1, source={5}, colors={225,250,262,275}},  -- Spotted Yellowtail
  [18239] = {learn=225, item=13927, min=1, max=1, skillupCnt=1, source={5}, colors={225,250,262,275}},  -- Cooked Glossy Mightfish
  [18241] = {learn=225, item=13930, min=1, max=1, skillupCnt=1, source={5}, colors={225,250,262,275}},  -- Filet of Redgill
  [20626] = {learn=225, item=16766, min=2, max=2, skillupCnt=1, source={5}, colors={225,250,262,275}},  -- Undermine Clam Chowder
  [22480] = {learn=225, item=18045, min=1, max=1, skillupCnt=1, source={5}, colors={225,250,262,275}},  -- Tender Wolf Steak
  [18240] = {learn=240, item=13928, min=1, max=1, skillupCnt=1, source={5}, colors={240,265,277,290}},  -- Grilled Squid
  [18242] = {learn=240, item=13929, min=1, max=1, skillupCnt=1, source={5}, colors={240,265,277,290}},  -- Hot Smoked Bass
  [18243] = {learn=250, item=13931, min=1, max=1, skillupCnt=1, source={5}, colors={250,275,285,295}},  -- Nightfin Soup
  [18244] = {learn=250, item=13932, min=1, max=1, skillupCnt=1, source={5}, colors={250,275,285,295}},  -- Poached Sunscale Salmon
  [46684] = {learn=250, item=35563, min=1, max=1, skillupCnt=1, source={5}, colors={250,275,285,295}},  -- Charred Bear Kabobs
  [46688] = {learn=250, item=35565, min=1, max=1, skillupCnt=1, source={5}, colors={250,275,285,295}},  -- Juicy Bear Burger
  [18245] = {learn=275, item=13933, min=1, max=1, skillupCnt=1, source={5}, colors={275,300,312,325}},  -- Lobster Stew
  [18246] = {learn=275, item=13934, min=1, max=1, skillupCnt=1, source={5}, colors={275,300,312,325}},  -- Mightfish Steak
  [18247] = {learn=275, item=13935, min=1, max=1, skillupCnt=1, source={5}, colors={275,300,312,325}},  -- Baked Salmon
  [22761] = {learn=275, item=18254, min=1, max=1, skillupCnt=1, source={2}, colors={275,300,312,325}},  -- Runn Tum Tuber Surprise
  [24801] = {learn=285, item=20452, min=1, max=1, skillupCnt=1, source={}, colors={285,310,322,335}},  -- Smoked Desert Dumplings
  [25659] = {learn=300, item=21023, min=5, max=5, skillupCnt=1, source={4}, colors={300,325,337,350}},  -- Dirge's Kickin' Chimaerok Chops
  [33279] = {learn=300, item=27651, min=1, max=1, skillupCnt=1, source={4}, colors={300,320,330,340}},  -- Buzzard Bites
  [33284] = {learn=300, item=27655, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Ravager Dog
  [33290] = {learn=300, item=27661, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Blackened Trout
  [33291] = {learn=300, item=27662, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Feltail Delight
  [36210] = {learn=300, item=30155, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Clam Bar
  [43758] = {learn=300, item=33866, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Stormchops
  [43761] = {learn=300, item=33867, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Broiled Bloodfin
  [43772] = {learn=300, item=33874, min=1, max=1, skillupCnt=1, source={2}, colors={300,345,355,365}},  -- Kibler's Bits
  [33285] = {learn=310, item=27656, min=1, max=1, skillupCnt=1, source={5}, colors={310,330,340,350}},  -- Sporeling Snack
  [33292] = {learn=310, item=27663, min=1, max=1, skillupCnt=1, source={5}, colors={310,330,340,350}},  -- Blackened Sporefish
  [33286] = {learn=315, item=27657, min=1, max=1, skillupCnt=1, source={5}, colors={315,335,345,355}},  -- Blackened Basilisk
  [33293] = {learn=320, item=27664, min=1, max=1, skillupCnt=1, source={5}, colors={320,340,350,360}},  -- Grilled Mudfish
  [33294] = {learn=320, item=27665, min=1, max=1, skillupCnt=1, source={5}, colors={320,340,350,360}},  -- Poached Bluefish
  [33287] = {learn=325, item=27658, min=1, max=1, skillupCnt=1, source={5}, colors={325,345,355,365}},  -- Roasted Clefthoof
  [33288] = {learn=325, item=27659, min=1, max=1, skillupCnt=1, source={5}, colors={325,345,355,365}},  -- Warp Burger
  [33289] = {learn=325, item=27660, min=1, max=1, skillupCnt=1, source={5}, colors={325,345,355,365}},  -- Talbuk Steak
  [33295] = {learn=325, item=27666, min=1, max=1, skillupCnt=1, source={5}, colors={325,345,355,365}},  -- Golden Fish Sticks
  [43707] = {learn=325, item=33825, min=1, max=1, skillupCnt=1, source={2}, colors={325,335,345,355}},  -- Skullfish Soup
  [43765] = {learn=325, item=33872, min=1, max=1, skillupCnt=1, source={2}, colors={325,335,345,355}},  -- Spicy Hot Talbuk
  [45022] = {learn=325, item=34411, min=2, max=2, skillupCnt=1, source={5}, colors={325,325,325,325}},  -- Hot Apple Cider
  [38867] = {learn=335, item=31672, min=1, max=1, skillupCnt=1, source={4,5}, colors={335,355,365,375}},  -- Mok'Nathal Shortribs
  [38868] = {learn=335, item=31673, min=1, max=1, skillupCnt=1, source={4,5}, colors={335,355,365,375}},  -- Crunchy Serpent
  [42296] = {learn=335, item=33048, min=1, max=1, skillupCnt=1, source={}, colors={0,335,345,355}},  -- Stewed Trout
  [33296] = {learn=350, item=27667, min=1, max=1, skillupCnt=1, source={5}, colors={350,370,380,390}},  -- Spicy Crawdad
  [42302] = {learn=375, item=33052, min=6, max=6, skillupCnt=1, source={}, colors={0,375,380,385}},  -- Fisherman's Feast
  [42305] = {learn=375, item=33053, min=2, max=2, skillupCnt=1, source={}, colors={0,375,380,385}},  -- Hot Buttered Trout
  -- skillLine 186
  [2657] = {learn=25, item=2840, min=1, max=1, skillupCnt=1, source={}, colors={0,25,47,70}},  -- Smelt Copper
  [2659] = {learn=65, item=2841, min=2, max=2, skillupCnt=1, source={}, colors={65,65,90,115}},  -- Smelt Bronze
  [3304] = {learn=65, item=3576, min=1, max=1, skillupCnt=1, source={}, colors={65,65,70,75}},  -- Smelt Tin
  [2658] = {learn=75, item=2842, min=1, max=1, skillupCnt=1, source={}, colors={75,115,122,130}},  -- Smelt Silver
  [3307] = {learn=125, item=3575, min=1, max=1, skillupCnt=1, source={}, colors={125,130,145,160}},  -- Smelt Iron
  [3308] = {learn=155, item=3577, min=1, max=1, skillupCnt=1, source={}, colors={155,170,177,185}},  -- Smelt Gold
  [3569] = {learn=165, item=3859, min=1, max=1, skillupCnt=1, source={}, colors={165,165,165,165}},  -- Smelt Steel
  [10097] = {learn=175, item=3860, min=1, max=1, skillupCnt=1, source={}, colors={175,175,202,230}},  -- Smelt Mithril
  [10098] = {learn=230, item=6037, min=1, max=1, skillupCnt=1, source={}, colors={230,235,242,250}},  -- Smelt Truesilver
  [16153] = {learn=250, item=12359, min=1, max=1, skillupCnt=1, source={}, colors={250,250,270,290}},  -- Smelt Thorium
  [14891] = {learn=300, item=11371, min=1, max=1, skillupCnt=1, source={}, colors={0,300,305,310}},  -- Smelt Dark Iron
  [29356] = {learn=300, item=23445, min=1, max=1, skillupCnt=1, source={}, colors={300,300,307,315}},  -- Smelt Fel Iron
  [35750] = {learn=300, item=22573, min=10, max=10, skillupCnt=1, source={}, colors={300,300,300,300}},  -- Earth Shatter
  [35751] = {learn=300, item=22574, min=10, max=10, skillupCnt=1, source={}, colors={300,300,300,300}},  -- Fire Sunder
  [29358] = {learn=325, item=23446, min=1, max=1, skillupCnt=1, source={}, colors={325,325,332,340}},  -- Smelt Adamantite
  [22967] = {learn=350, item=17771, min=1, max=1, skillupCnt=1, source={}, colors={0,350,362,375}},  -- Smelt Elementium
  [29359] = {learn=350, item=23447, min=1, max=1, skillupCnt=1, source={}, colors={350,350,357,365}},  -- Smelt Eternium
  [29360] = {learn=350, item=23448, min=1, max=1, skillupCnt=1, source={}, colors={350,355,367,380}},  -- Smelt Felsteel
  [29361] = {learn=375, item=23449, min=1, max=1, skillupCnt=1, source={}, colors={375,375,375,375}},  -- Smelt Khorium
  [29686] = {learn=375, item=23573, min=1, max=1, skillupCnt=1, source={}, colors={375,375,375,375}},  -- Smelt Hardened Adamantite
  [46353] = {learn=375, item=35128, min=1, max=1, skillupCnt=1, source={2}, colors={375,375,375,375}},  -- Smelt Hardened Khorium
  -- skillLine 197
  [2387] = {learn=1, item=2570, min=1, max=1, skillupCnt=1, source={}, colors={1,35,47,60}},  -- Linen Cloak
  [2393] = {learn=1, item=2576, min=1, max=1, skillupCnt=1, source={}, colors={1,35,47,60}},  -- White Linen Shirt
  [2963] = {learn=1, item=2996, min=1, max=1, skillupCnt=1, source={}, colors={1,25,37,50}},  -- Bolt of Linen Cloth
  [3915] = {learn=1, item=4344, min=1, max=1, skillupCnt=1, source={}, colors={1,35,47,60}},  -- Brown Linen Shirt
  [12044] = {learn=1, item=10045, min=1, max=1, skillupCnt=1, source={}, colors={1,35,47,60}},  -- Simple Linen Pants
  [2385] = {learn=10, item=2568, min=1, max=1, skillupCnt=1, source={}, colors={10,45,57,70}},  -- Brown Linen Vest
  [8776] = {learn=15, item=7026, min=1, max=1, skillupCnt=1, source={}, colors={15,50,67,85}},  -- Linen Belt
  [12045] = {learn=20, item=10046, min=1, max=1, skillupCnt=1, source={}, colors={20,50,67,85}},  -- Simple Linen Boots
  [3914] = {learn=30, item=4343, min=1, max=1, skillupCnt=1, source={}, colors={30,55,72,90}},  -- Brown Linen Pants
  [7623] = {learn=30, item=6238, min=1, max=1, skillupCnt=1, source={}, colors={30,55,72,90}},  -- Brown Linen Robe
  [7624] = {learn=30, item=6241, min=1, max=1, skillupCnt=1, source={}, colors={30,55,72,90}},  -- White Linen Robe
  [3840] = {learn=35, item=4307, min=1, max=1, skillupCnt=1, source={}, colors={35,60,77,95}},  -- Heavy Linen Gloves
  [2389] = {learn=40, item=2572, min=1, max=1, skillupCnt=1, source={2,16,21}, colors={40,65,82,100}},  -- Red Linen Robe
  [2392] = {learn=40, item=2575, min=1, max=1, skillupCnt=1, source={}, colors={40,65,82,100}},  -- Red Linen Shirt
  [2394] = {learn=40, item=2577, min=1, max=1, skillupCnt=1, source={}, colors={40,65,82,100}},  -- Blue Linen Shirt
  [8465] = {learn=40, item=6786, min=1, max=1, skillupCnt=1, source={}, colors={40,65,82,100}},  -- Simple Dress
  [3755] = {learn=45, item=4238, min=1, max=1, skillupCnt=1, source={}, colors={45,70,87,105}},  -- Linen Bag
  [7629] = {learn=55, item=6239, min=1, max=1, skillupCnt=1, source={2,21}, colors={55,80,97,115}},  -- Red Linen Vest
  [7630] = {learn=55, item=6240, min=1, max=1, skillupCnt=1, source={5}, colors={55,80,97,115}},  -- Blue Linen Vest
  [2397] = {learn=60, item=2580, min=1, max=1, skillupCnt=1, source={}, colors={60,85,102,120}},  -- Reinforced Linen Cape
  [3841] = {learn=60, item=4308, min=1, max=1, skillupCnt=1, source={}, colors={60,85,102,120}},  -- Green Linen Bracers
  [2386] = {learn=65, item=2569, min=1, max=1, skillupCnt=1, source={}, colors={65,90,107,125}},  -- Linen Boots
  [2395] = {learn=70, item=2578, min=1, max=1, skillupCnt=1, source={}, colors={70,95,112,130}},  -- Barbaric Linen Vest
  [2396] = {learn=70, item=2579, min=1, max=1, skillupCnt=1, source={}, colors={70,95,112,130}},  -- Green Linen Shirt
  [3842] = {learn=70, item=4309, min=1, max=1, skillupCnt=1, source={}, colors={70,95,112,130}},  -- Handstitched Linen Britches
  [6686] = {learn=70, item=5762, min=1, max=1, skillupCnt=1, source={2,5}, colors={70,95,112,130}},  -- Red Linen Bag
  [7633] = {learn=70, item=6242, min=1, max=1, skillupCnt=1, source={5}, colors={70,95,112,130}},  -- Blue Linen Robe
  [2402] = {learn=75, item=2584, min=1, max=1, skillupCnt=1, source={}, colors={75,100,117,135}},  -- Woolen Cape
  [2964] = {learn=75, item=2997, min=1, max=1, skillupCnt=1, source={}, colors={75,90,97,105}},  -- Bolt of Woolen Cloth
  [12046] = {learn=75, item=10047, min=1, max=1, skillupCnt=1, source={}, colors={75,100,117,135}},  -- Simple Kilt
  [3757] = {learn=80, item=4240, min=1, max=1, skillupCnt=1, source={}, colors={80,105,122,140}},  -- Woolen Bag
  [3845] = {learn=80, item=4312, min=1, max=1, skillupCnt=1, source={}, colors={80,105,122,140}},  -- Soft-soled Linen Boots
  [2399] = {learn=85, item=2582, min=1, max=1, skillupCnt=1, source={}, colors={85,110,127,145}},  -- Green Woolen Vest
  [3843] = {learn=85, item=4310, min=1, max=1, skillupCnt=1, source={}, colors={85,110,127,145}},  -- Heavy Woolen Gloves
  [6521] = {learn=90, item=5542, min=1, max=1, skillupCnt=1, source={}, colors={90,115,132,150}},  -- Pearl-clasped Cloak
  [2401] = {learn=95, item=2583, min=1, max=1, skillupCnt=1, source={}, colors={95,120,137,155}},  -- Woolen Boots
  [3758] = {learn=95, item=4241, min=1, max=1, skillupCnt=1, source={2,21}, colors={95,120,137,155}},  -- Green Woolen Bag
  [3847] = {learn=95, item=4313, min=1, max=1, skillupCnt=1, source={2,21}, colors={95,120,137,155}},  -- Red Woolen Boots
  [2406] = {learn=100, item=2587, min=1, max=1, skillupCnt=1, source={}, colors={100,110,120,130}},  -- Gray Woolen Shirt
  [3844] = {learn=100, item=4311, min=1, max=1, skillupCnt=1, source={2,16,21}, colors={100,125,142,160}},  -- Heavy Woolen Cloak
  [7639] = {learn=100, item=6263, min=1, max=1, skillupCnt=1, source={5}, colors={100,125,142,160}},  -- Blue Overalls
  [2403] = {learn=105, item=2585, min=1, max=1, skillupCnt=1, source={2,16}, colors={105,130,147,165}},  -- Gray Woolen Robe
  [3848] = {learn=110, item=4314, min=1, max=1, skillupCnt=1, source={}, colors={110,135,152,170}},  -- Double-stitched Woolen Shoulders
  [3850] = {learn=110, item=4316, min=1, max=1, skillupCnt=1, source={}, colors={110,135,152,170}},  -- Heavy Woolen Pants
  [3866] = {learn=110, item=4330, min=1, max=1, skillupCnt=1, source={}, colors={110,135,152,170}},  -- Stylish Red Shirt
  [8467] = {learn=110, item=6787, min=1, max=1, skillupCnt=1, source={}, colors={110,135,152,170}},  -- White Woolen Dress
  [6688] = {learn=115, item=5763, min=1, max=1, skillupCnt=1, source={2,5}, colors={115,140,157,175}},  -- Red Woolen Bag
  [7643] = {learn=115, item=6264, min=1, max=1, skillupCnt=1, source={5}, colors={115,140,157,175}},  -- Greater Adept's Robe
  [3849] = {learn=120, item=4315, min=1, max=1, skillupCnt=1, source={2}, colors={120,145,162,180}},  -- Reinforced Woolen Shoulders
  [7892] = {learn=120, item=6384, min=1, max=1, skillupCnt=1, source={2,16}, colors={120,145,162,180}},  -- Stylish Blue Shirt
  [7893] = {learn=120, item=6385, min=1, max=1, skillupCnt=1, source={2,16}, colors={120,145,162,180}},  -- Stylish Green Shirt
  [12047] = {learn=120, item=10048, min=1, max=1, skillupCnt=1, source={2}, colors={120,145,162,180}},  -- Colorful Kilt
  [3839] = {learn=125, item=4305, min=1, max=1, skillupCnt=1, source={}, colors={125,135,140,145}},  -- Bolt of Silk Cloth
  [3851] = {learn=125, item=4317, min=1, max=1, skillupCnt=1, source={2}, colors={125,150,167,185}},  -- Phoenix Pants
  [3855] = {learn=125, item=4320, min=1, max=1, skillupCnt=1, source={}, colors={125,150,167,185}},  -- Spidersilk Boots
  [3868] = {learn=125, item=4331, min=1, max=1, skillupCnt=1, source={2}, colors={125,150,167,185}},  -- Phoenix Gloves
  [3852] = {learn=130, item=4318, min=1, max=1, skillupCnt=1, source={}, colors={130,150,165,180}},  -- Gloves of Meditation
  [3869] = {learn=135, item=4332, min=1, max=1, skillupCnt=1, source={5}, colors={135,145,150,155}},  -- Bright Yellow Shirt
  [6690] = {learn=135, item=5766, min=1, max=1, skillupCnt=1, source={}, colors={135,155,170,185}},  -- Lesser Wizard's Robe
  [3856] = {learn=140, item=4321, min=1, max=1, skillupCnt=1, source={2}, colors={140,160,175,190}},  -- Spider Silk Slippers
  [8758] = {learn=140, item=7046, min=1, max=1, skillupCnt=1, source={}, colors={140,160,175,190}},  -- Azure Silk Pants
  [3854] = {learn=145, item=4319, min=1, max=1, skillupCnt=1, source={5}, colors={145,165,180,195}},  -- Azure Silk Gloves
  [8760] = {learn=145, item=7048, min=1, max=1, skillupCnt=1, source={}, colors={145,155,160,165}},  -- Azure Silk Hood
  [8780] = {learn=145, item=7047, min=1, max=1, skillupCnt=1, source={2,16}, colors={145,165,180,195}},  -- Hands of Darkness
  [3813] = {learn=150, item=4245, min=1, max=1, skillupCnt=1, source={}, colors={150,170,185,200}},  -- Small Silk Pack
  [3859] = {learn=150, item=4324, min=1, max=1, skillupCnt=1, source={}, colors={150,170,185,200}},  -- Azure Silk Vest
  [6692] = {learn=150, item=5770, min=1, max=1, skillupCnt=1, source={2}, colors={150,170,185,200}},  -- Robes of Arcana
  [8782] = {learn=150, item=7049, min=1, max=1, skillupCnt=1, source={2}, colors={150,170,185,200}},  -- Truefaith Gloves
  [3870] = {learn=155, item=4333, min=1, max=1, skillupCnt=1, source={5}, colors={155,165,170,175}},  -- Dark Silk Shirt
  [8483] = {learn=160, item=6795, min=1, max=1, skillupCnt=1, source={}, colors={160,170,175,180}},  -- White Swashbuckler's Shirt
  [8762] = {learn=160, item=7050, min=1, max=1, skillupCnt=1, source={}, colors={160,170,175,180}},  -- Silk Headband
  [3857] = {learn=165, item=4322, min=1, max=1, skillupCnt=1, source={5}, colors={165,185,200,215}},  -- Enchanter's Cowl
  [8784] = {learn=165, item=7065, min=1, max=1, skillupCnt=1, source={2}, colors={165,185,200,215}},  -- Green Silk Armor
  [3858] = {learn=170, item=4323, min=1, max=1, skillupCnt=1, source={2}, colors={170,190,205,220}},  -- Shadow Hood
  [3871] = {learn=170, item=4334, min=1, max=1, skillupCnt=1, source={}, colors={170,180,185,190}},  -- Formal White Shirt
  [8764] = {learn=170, item=7051, min=1, max=1, skillupCnt=1, source={}, colors={170,190,205,220}},  -- Earthen Vest
  [3860] = {learn=175, item=4325, min=1, max=1, skillupCnt=1, source={2,16}, colors={175,195,210,225}},  -- Boots of the Enchanter
  [3865] = {learn=175, item=4339, min=1, max=1, skillupCnt=1, source={}, colors={175,180,182,185}},  -- Bolt of Mageweave
  [6693] = {learn=175, item=5764, min=1, max=1, skillupCnt=1, source={2}, colors={175,195,210,225}},  -- Green Silk Pack
  [8489] = {learn=175, item=6796, min=1, max=1, skillupCnt=1, source={}, colors={175,185,190,195}},  -- Red Swashbuckler's Shirt
  [8766] = {learn=175, item=7052, min=1, max=1, skillupCnt=1, source={}, colors={175,195,210,225}},  -- Azure Silk Belt
  [8772] = {learn=175, item=7055, min=1, max=1, skillupCnt=1, source={}, colors={175,195,210,225}},  -- Crimson Silk Belt
  [8786] = {learn=175, item=7053, min=1, max=1, skillupCnt=1, source={5}, colors={175,195,210,225}},  -- Azure Silk Cloak
  [3863] = {learn=180, item=4328, min=1, max=1, skillupCnt=1, source={2}, colors={180,200,215,230}},  -- Spider Belt
  [8774] = {learn=180, item=7057, min=1, max=1, skillupCnt=1, source={}, colors={180,200,215,230}},  -- Green Silken Shoulders
  [8789] = {learn=180, item=7056, min=1, max=1, skillupCnt=1, source={5}, colors={180,200,215,230}},  -- Crimson Silk Cloak
  [3861] = {learn=185, item=4326, min=1, max=1, skillupCnt=1, source={}, colors={185,205,220,235}},  -- Long Silken Cloak
  [3872] = {learn=185, item=4335, min=1, max=1, skillupCnt=1, source={2}, colors={185,195,200,205}},  -- Rich Purple Silk Shirt
  [6695] = {learn=185, item=5765, min=1, max=1, skillupCnt=1, source={2}, colors={185,205,220,235}},  -- Black Silk Pack
  [8791] = {learn=185, item=7058, min=1, max=1, skillupCnt=1, source={}, colors={185,205,215,225}},  -- Crimson Silk Vest
  [8770] = {learn=190, item=7054, min=1, max=1, skillupCnt=1, source={}, colors={190,210,225,240}},  -- Robe of Power
  [8793] = {learn=190, item=7059, min=1, max=1, skillupCnt=1, source={2}, colors={190,210,225,240}},  -- Crimson Silk Shoulders
  [8795] = {learn=190, item=7060, min=1, max=1, skillupCnt=1, source={2,16}, colors={190,210,225,240}},  -- Azure Shoulders
  [21945] = {learn=190, item=17723, min=1, max=1, skillupCnt=1, source={2}, colors={190,200,205,210}},  -- Green Holiday Shirt
  [8797] = {learn=195, item=7061, min=1, max=1, skillupCnt=1, source={2}, colors={195,215,230,245}},  -- Earthen Silk Belt
  [8799] = {learn=195, item=7062, min=1, max=1, skillupCnt=1, source={}, colors={195,215,225,235}},  -- Crimson Silk Pantaloons
  [3862] = {learn=200, item=4327, min=1, max=1, skillupCnt=1, source={5}, colors={200,220,235,250}},  -- Icy Cloak
  [3864] = {learn=200, item=4329, min=1, max=1, skillupCnt=1, source={2}, colors={200,220,235,250}},  -- Star Belt
  [3873] = {learn=200, item=4336, min=1, max=1, skillupCnt=1, source={5}, colors={200,210,215,220}},  -- Black Swashbuckler's Shirt
  [8802] = {learn=205, item=7063, min=1, max=1, skillupCnt=1, source={5}, colors={205,220,235,250}},  -- Crimson Silk Robe
  [12048] = {learn=205, item=9998, min=1, max=1, skillupCnt=1, source={}, colors={205,220,235,250}},  -- Black Mageweave Vest
  [12049] = {learn=205, item=9999, min=1, max=1, skillupCnt=1, source={}, colors={205,220,235,250}},  -- Black Mageweave Leggings
  [8804] = {learn=210, item=7064, min=1, max=1, skillupCnt=1, source={}, colors={210,225,240,255}},  -- Crimson Silk Gloves
  [12050] = {learn=210, item=10001, min=1, max=1, skillupCnt=1, source={}, colors={210,225,240,255}},  -- Black Mageweave Robe
  [12052] = {learn=210, item=10002, min=1, max=1, skillupCnt=1, source={}, colors={210,225,240,255}},  -- Shadoweave Pants
  [12053] = {learn=215, item=10003, min=1, max=1, skillupCnt=1, source={}, colors={215,230,245,260}},  -- Black Mageweave Gloves
  [12055] = {learn=215, item=10004, min=1, max=1, skillupCnt=1, source={}, colors={215,230,245,260}},  -- Shadoweave Robe
  [12056] = {learn=215, item=10007, min=1, max=1, skillupCnt=1, source={2}, colors={215,230,245,260}},  -- Red Mageweave Vest
  [12059] = {learn=215, item=10008, min=1, max=1, skillupCnt=1, source={2}, colors={215,220,225,230}},  -- White Bandit Mask
  [12060] = {learn=215, item=10009, min=1, max=1, skillupCnt=1, source={2}, colors={215,230,245,260}},  -- Red Mageweave Pants
  [12061] = {learn=215, item=10056, min=1, max=1, skillupCnt=1, source={}, colors={215,220,225,230}},  -- Orange Mageweave Shirt
  [12064] = {learn=220, item=10052, min=1, max=1, skillupCnt=1, source={5}, colors={220,225,230,235}},  -- Orange Martial Shirt
  [12065] = {learn=225, item=10050, min=1, max=1, skillupCnt=1, source={}, colors={225,240,255,270}},  -- Mageweave Bag
  [12066] = {learn=225, item=10018, min=1, max=1, skillupCnt=1, source={2}, colors={225,240,255,270}},  -- Red Mageweave Gloves
  [12067] = {learn=225, item=10019, min=1, max=1, skillupCnt=1, source={}, colors={225,240,255,270}},  -- Dreamweave Gloves
  [12069] = {learn=225, item=10042, min=1, max=1, skillupCnt=1, source={}, colors={225,240,255,270}},  -- Cindercloth Robe
  [12070] = {learn=225, item=10021, min=1, max=1, skillupCnt=1, source={}, colors={225,240,255,270}},  -- Dreamweave Vest
  [12071] = {learn=225, item=10023, min=1, max=1, skillupCnt=1, source={}, colors={225,240,255,270}},  -- Shadoweave Gloves
  [27658] = {learn=225, item=22246, min=1, max=1, skillupCnt=1, source={5}, colors={225,240,255,270}},  -- Enchanted Mageweave Pouch
  [12072] = {learn=230, item=10024, min=1, max=1, skillupCnt=1, source={}, colors={230,245,260,275}},  -- Black Mageweave Headband
  [12073] = {learn=230, item=10026, min=1, max=1, skillupCnt=1, source={}, colors={230,245,260,275}},  -- Black Mageweave Boots
  [12074] = {learn=230, item=10027, min=1, max=1, skillupCnt=1, source={}, colors={230,245,260,275}},  -- Black Mageweave Shoulders
  [12075] = {learn=230, item=10054, min=1, max=1, skillupCnt=1, source={5}, colors={230,235,240,245}},  -- Lavender Mageweave Shirt
  [12076] = {learn=235, item=10028, min=1, max=1, skillupCnt=1, source={}, colors={235,250,265,280}},  -- Shadoweave Shoulders
  [12077] = {learn=235, item=10053, min=1, max=1, skillupCnt=1, source={}, colors={235,240,245,250}},  -- Simple Black Dress
  [12078] = {learn=235, item=10029, min=1, max=1, skillupCnt=1, source={2}, colors={235,250,265,280}},  -- Red Mageweave Shoulders
  [12079] = {learn=235, item=10051, min=1, max=1, skillupCnt=1, source={}, colors={235,250,265,280}},  -- Red Mageweave Bag
  [12080] = {learn=235, item=10055, min=1, max=1, skillupCnt=1, source={5}, colors={235,240,245,250}},  -- Pink Mageweave Shirt
  [12081] = {learn=240, item=10030, min=1, max=1, skillupCnt=1, source={5}, colors={240,255,270,285}},  -- Admiral's Hat
  [12082] = {learn=240, item=10031, min=1, max=1, skillupCnt=1, source={}, colors={240,255,270,285}},  -- Shadoweave Boots
  [12084] = {learn=240, item=10033, min=1, max=1, skillupCnt=1, source={2}, colors={240,255,270,285}},  -- Red Mageweave Headband
  [12085] = {learn=240, item=10034, min=1, max=1, skillupCnt=1, source={5}, colors={240,245,250,255}},  -- Tuxedo Shirt
  [12086] = {learn=245, item=10025, min=1, max=1, skillupCnt=1, source={4}, colors={245,260,275,290}},  -- Shadoweave Mask
  [12088] = {learn=245, item=10044, min=1, max=1, skillupCnt=1, source={}, colors={245,260,275,290}},  -- Cindercloth Boots
  [12089] = {learn=245, item=10035, min=1, max=1, skillupCnt=1, source={5}, colors={245,250,255,260}},  -- Tuxedo Pants
  [50647] = {learn=245, item=38278, min=1, max=1, skillupCnt=1, source={5}, colors={245,250,255,260}},  -- Haliscan Pantaloons
  [12091] = {learn=250, item=10040, min=1, max=1, skillupCnt=1, source={5}, colors={250,255,260,265}},  -- White Wedding Dress
  [12092] = {learn=250, item=10041, min=1, max=1, skillupCnt=1, source={}, colors={250,265,280,295}},  -- Dreamweave Circlet
  [12093] = {learn=250, item=10036, min=1, max=1, skillupCnt=1, source={5}, colors={250,265,280,295}},  -- Tuxedo Jacket
  [18401] = {learn=250, item=14048, min=1, max=1, skillupCnt=1, source={}, colors={250,255,257,260}},  -- Bolt of Runecloth
  [18560] = {learn=250, item=14342, min=1, max=1, skillupCnt=1, source={5}, colors={250,290,305,320}},  -- Mooncloth
  [26403] = {learn=250, item=21154, min=1, max=1, skillupCnt=1, source={4}, colors={250,265,280,295}},  -- Festival Dress
  [26407] = {learn=250, item=21542, min=1, max=1, skillupCnt=1, source={4}, colors={250,265,280,295}},  -- Festive Red Pant Suit
  [44950] = {learn=250, item=34087, min=1, max=1, skillupCnt=1, source={5}, colors={250,250,250,250}},  -- Green Winter Clothes
  [44958] = {learn=250, item=34085, min=1, max=1, skillupCnt=1, source={5}, colors={250,250,250,250}},  -- Red Winter Clothes
  [49677] = {learn=250, item=6836, min=1, max=1, skillupCnt=1, source={5}, colors={250,255,270,285}},  -- Dress Shoes
  [50644] = {learn=250, item=38277, min=1, max=1, skillupCnt=1, source={5}, colors={250,265,280,295}},  -- Haliscan Jacket
  [18402] = {learn=255, item=13856, min=1, max=1, skillupCnt=1, source={}, colors={255,270,285,300}},  -- Runecloth Belt
  [18403] = {learn=255, item=13869, min=1, max=1, skillupCnt=1, source={2,16}, colors={255,270,285,300}},  -- Frostweave Tunic
  [18404] = {learn=255, item=13868, min=1, max=1, skillupCnt=1, source={2}, colors={255,270,285,300}},  -- Frostweave Robe
  [18405] = {learn=260, item=14046, min=1, max=1, skillupCnt=1, source={5}, colors={260,275,290,305}},  -- Runecloth Bag
  [18406] = {learn=260, item=13858, min=1, max=1, skillupCnt=1, source={5}, colors={260,275,290,305}},  -- Runecloth Robe
  [18407] = {learn=260, item=13857, min=1, max=1, skillupCnt=1, source={2}, colors={260,275,290,305}},  -- Runecloth Tunic
  [18408] = {learn=260, item=14042, min=1, max=1, skillupCnt=1, source={2}, colors={260,275,290,305}},  -- Cindercloth Vest
  [26085] = {learn=260, item=21340, min=1, max=1, skillupCnt=1, source={5}, colors={260,275,290,305}},  -- Soul Pouch
  [18409] = {learn=265, item=13860, min=1, max=1, skillupCnt=1, source={5}, colors={265,280,295,310}},  -- Runecloth Cloak
  [18410] = {learn=265, item=14143, min=1, max=1, skillupCnt=1, source={2}, colors={265,280,295,310}},  -- Ghostweave Belt
  [18411] = {learn=265, item=13870, min=1, max=1, skillupCnt=1, source={2,16}, colors={265,280,295,310}},  -- Frostweave Gloves
  [18412] = {learn=270, item=14043, min=1, max=1, skillupCnt=1, source={2}, colors={270,285,300,315}},  -- Cindercloth Gloves
  [18413] = {learn=270, item=14142, min=1, max=1, skillupCnt=1, source={2}, colors={270,285,300,315}},  -- Ghostweave Gloves
  [18414] = {learn=270, item=14100, min=1, max=1, skillupCnt=1, source={2,16}, colors={270,285,300,315}},  -- Brightcloth Robe
  [18415] = {learn=270, item=14101, min=1, max=1, skillupCnt=1, source={2}, colors={270,285,300,315}},  -- Brightcloth Gloves
  [18416] = {learn=275, item=14141, min=1, max=1, skillupCnt=1, source={2}, colors={275,290,305,320}},  -- Ghostweave Vest
  [18417] = {learn=275, item=13863, min=1, max=1, skillupCnt=1, source={5}, colors={275,290,305,320}},  -- Runecloth Gloves
  [18418] = {learn=275, item=14044, min=1, max=1, skillupCnt=1, source={2}, colors={275,290,305,320}},  -- Cindercloth Cloak
  [18419] = {learn=275, item=14107, min=1, max=1, skillupCnt=1, source={5}, colors={275,290,305,320}},  -- Felcloth Pants
  [18420] = {learn=275, item=14103, min=1, max=1, skillupCnt=1, source={2}, colors={275,290,305,320}},  -- Brightcloth Cloak
  [18421] = {learn=275, item=14132, min=1, max=1, skillupCnt=1, source={2}, colors={275,290,305,320}},  -- Wizardweave Leggings
  [18422] = {learn=275, item=14134, min=1, max=1, skillupCnt=1, source={2}, colors={275,290,305,320}},  -- Cloak of Fire
  [27659] = {learn=275, item=22248, min=1, max=1, skillupCnt=1, source={5}, colors={275,290,305,320}},  -- Enchanted Runecloth Bag
  [27724] = {learn=275, item=22251, min=1, max=1, skillupCnt=1, source={5}, colors={275,290,305,320}},  -- Cenarion Herb Bag
  [18423] = {learn=280, item=13864, min=1, max=1, skillupCnt=1, source={5}, colors={280,295,310,325}},  -- Runecloth Boots
  [18424] = {learn=280, item=13871, min=1, max=1, skillupCnt=1, source={2}, colors={280,295,310,325}},  -- Frostweave Pants
  [18434] = {learn=280, item=14045, min=1, max=1, skillupCnt=1, source={2}, colors={280,295,310,325}},  -- Cindercloth Pants
  [18436] = {learn=285, item=14136, min=1, max=1, skillupCnt=1, source={2}, colors={285,300,315,330}},  -- Robe of Winter Night
  [18437] = {learn=285, item=14108, min=1, max=1, skillupCnt=1, source={2,16}, colors={285,300,315,330}},  -- Felcloth Boots
  [18438] = {learn=285, item=13865, min=1, max=1, skillupCnt=1, source={2}, colors={285,300,315,330}},  -- Runecloth Pants
  [22813] = {learn=285, item=18258, min=1, max=1, skillupCnt=1, source={}, colors={0,285,290,295}},  -- Gordok Ogre Suit
  [26086] = {learn=285, item=21341, min=1, max=1, skillupCnt=1, source={}, colors={285,300,315,330}},  -- Felcloth Bag
  [18439] = {learn=290, item=14104, min=1, max=1, skillupCnt=1, source={2}, colors={290,305,320,335}},  -- Brightcloth Pants
  [18440] = {learn=290, item=14137, min=1, max=1, skillupCnt=1, source={2}, colors={290,305,320,335}},  -- Mooncloth Leggings
  [18441] = {learn=290, item=14144, min=1, max=1, skillupCnt=1, source={2}, colors={290,305,320,335}},  -- Ghostweave Pants
  [18442] = {learn=290, item=14111, min=1, max=1, skillupCnt=1, source={2}, colors={290,305,320,335}},  -- Felcloth Hood
  [19435] = {learn=290, item=15802, min=1, max=1, skillupCnt=1, source={4}, colors={290,295,310,325}},  -- Mooncloth Boots
  [23662] = {learn=290, item=19047, min=1, max=1, skillupCnt=1, source={5}, colors={290,305,320,335}},  -- Wisdom of the Timbermaw
  [23664] = {learn=290, item=19056, min=1, max=1, skillupCnt=1, source={5}, colors={290,305,320,335}},  -- Argent Boots
  [18444] = {learn=295, item=13866, min=1, max=1, skillupCnt=1, source={2}, colors={295,310,325,340}},  -- Runecloth Headband
  [18445] = {learn=300, item=14155, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Mooncloth Bag
  [18446] = {learn=300, item=14128, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Wizardweave Robe
  [18447] = {learn=300, item=14138, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Mooncloth Vest
  [18448] = {learn=300, item=14139, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Mooncloth Shoulders
  [18449] = {learn=300, item=13867, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Runecloth Shoulders
  [18450] = {learn=300, item=14130, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Wizardweave Turban
  [18451] = {learn=300, item=14106, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Felcloth Robe
  [18452] = {learn=300, item=14140, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Mooncloth Circlet
  [18453] = {learn=300, item=14112, min=1, max=1, skillupCnt=1, source={2,16}, colors={300,315,330,345}},  -- Felcloth Shoulders
  [18454] = {learn=300, item=14146, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Gloves of Spell Mastery
  [18455] = {learn=300, item=14156, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Bottomless Bag
  [18456] = {learn=300, item=14154, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Truefaith Vestments
  [18457] = {learn=300, item=14152, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Robe of the Archmage
  [18458] = {learn=300, item=14153, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Robe of the Void
  [20848] = {learn=300, item=16980, min=1, max=1, skillupCnt=1, source={5}, colors={300,315,330,345}},  -- Flarecore Mantle
  [20849] = {learn=300, item=16979, min=1, max=1, skillupCnt=1, source={5}, colors={300,315,330,345}},  -- Flarecore Gloves
  [22759] = {learn=300, item=18263, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,335,350}},  -- Flarecore Wraps
  [22866] = {learn=300, item=18405, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Belt of the Archmage
  [22867] = {learn=300, item=18407, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Felcloth Gloves
  [22868] = {learn=300, item=18408, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Inferno Gloves
  [22869] = {learn=300, item=18409, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Mooncloth Gloves
  [22870] = {learn=300, item=18413, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Cloak of Warding
  [22902] = {learn=300, item=18486, min=1, max=1, skillupCnt=1, source={5}, colors={300,315,330,345}},  -- Mooncloth Robe
  [23663] = {learn=300, item=19050, min=1, max=1, skillupCnt=1, source={5}, colors={300,315,330,345}},  -- Mantle of the Timbermaw
  [23665] = {learn=300, item=19059, min=1, max=1, skillupCnt=1, source={5}, colors={300,315,330,345}},  -- Argent Shoulders
  [23666] = {learn=300, item=19156, min=1, max=1, skillupCnt=1, source={5}, colors={300,315,330,345}},  -- Flarecore Robe
  [23667] = {learn=300, item=19165, min=1, max=1, skillupCnt=1, source={5}, colors={300,315,330,345}},  -- Flarecore Leggings
  [24091] = {learn=300, item=19682, min=1, max=1, skillupCnt=1, source={5}, colors={300,315,330,345}},  -- Bloodvine Vest
  [24092] = {learn=300, item=19683, min=1, max=1, skillupCnt=1, source={5}, colors={300,315,330,345}},  -- Bloodvine Leggings
  [24093] = {learn=300, item=19684, min=1, max=1, skillupCnt=1, source={5}, colors={300,315,330,345}},  -- Bloodvine Boots
  [24901] = {learn=300, item=20538, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Runed Stygian Leggings
  [24902] = {learn=300, item=20539, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Runed Stygian Belt
  [24903] = {learn=300, item=20537, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Runed Stygian Boots
  [26087] = {learn=300, item=21342, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Core Felcloth Bag
  [26745] = {learn=300, item=21840, min=1, max=1, skillupCnt=1, source={}, colors={300,305,315,325}},  -- Bolt of Netherweave
  [27660] = {learn=300, item=22249, min=1, max=1, skillupCnt=1, source={2}, colors={300,315,330,345}},  -- Big Bag of Enchantment
  [27725] = {learn=300, item=22252, min=1, max=1, skillupCnt=1, source={5}, colors={300,315,330,345}},  -- Satchel of Cenarius
  [28205] = {learn=300, item=22654, min=1, max=1, skillupCnt=1, source={}, colors={300,315,330,345}},  -- Glacial Gloves
  [28207] = {learn=300, item=22652, min=1, max=1, skillupCnt=1, source={}, colors={300,315,330,345}},  -- Glacial Vest
  [28208] = {learn=300, item=22658, min=1, max=1, skillupCnt=1, source={}, colors={300,315,330,345}},  -- Glacial Cloak
  [28209] = {learn=300, item=22655, min=1, max=1, skillupCnt=1, source={}, colors={300,315,330,345}},  -- Glacial Wrists
  [28210] = {learn=300, item=22660, min=1, max=1, skillupCnt=1, source={5}, colors={300,315,330,345}},  -- Gaea's Embrace
  [28480] = {learn=300, item=22756, min=1, max=1, skillupCnt=1, source={5}, colors={300,315,330,345}},  -- Sylvan Vest
  [28481] = {learn=300, item=22757, min=1, max=1, skillupCnt=1, source={5}, colors={300,315,330,345}},  -- Sylvan Crown
  [28482] = {learn=300, item=22758, min=1, max=1, skillupCnt=1, source={5}, colors={300,315,330,345}},  -- Sylvan Shoulders
  [31460] = {learn=300, item=24268, min=2, max=2, skillupCnt=1, source={}, colors={300,300,310,320}},  -- Netherweave Net
  [26764] = {learn=310, item=21849, min=1, max=1, skillupCnt=1, source={}, colors={310,320,325,330}},  -- Netherweave Bracers
  [26765] = {learn=310, item=21850, min=1, max=1, skillupCnt=1, source={}, colors={310,320,325,330}},  -- Netherweave Belt
  [26746] = {learn=315, item=21841, min=1, max=1, skillupCnt=1, source={}, colors={315,320,330,340}},  -- Netherweave Bag
  [26770] = {learn=320, item=21851, min=1, max=1, skillupCnt=1, source={}, colors={320,330,335,340}},  -- Netherweave Gloves
  [26747] = {learn=325, item=21842, min=1, max=1, skillupCnt=1, source={5}, colors={325,330,335,340}},  -- Bolt of Imbued Netherweave
  [26771] = {learn=325, item=21852, min=1, max=1, skillupCnt=1, source={}, colors={325,335,340,345}},  -- Netherweave Pants
  [26772] = {learn=335, item=21853, min=1, max=1, skillupCnt=1, source={}, colors={335,345,350,355}},  -- Netherweave Boots
  [31430] = {learn=335, item=24273, min=1, max=1, skillupCnt=1, source={5}, colors={335,345,350,355}},  -- Mystic Spellthread
  [31431] = {learn=335, item=24275, min=1, max=1, skillupCnt=1, source={5}, colors={335,345,350,355}},  -- Silver Spellthread
  [26749] = {learn=340, item=21843, min=1, max=1, skillupCnt=1, source={5}, colors={340,340,345,350}},  -- Imbued Netherweave Bag
  [26773] = {learn=340, item=21854, min=1, max=1, skillupCnt=1, source={5}, colors={340,350,355,360}},  -- Netherweave Robe
  [26775] = {learn=340, item=21859, min=1, max=1, skillupCnt=1, source={5}, colors={340,350,355,360}},  -- Imbued Netherweave Pants
  [31459] = {learn=340, item=24270, min=1, max=1, skillupCnt=1, source={5}, colors={340,350,355,360}},  -- Bag of Jewels
  [26750] = {learn=345, item=21844, min=1, max=1, skillupCnt=1, source={5}, colors={345,345,350,355}},  -- Bolt of Soulcloth
  [26774] = {learn=345, item=21855, min=1, max=1, skillupCnt=1, source={5}, colors={345,355,360,365}},  -- Netherweave Tunic
  [26751] = {learn=350, item=21845, min=1, max=1, skillupCnt=1, source={5}, colors={350,350,355,360}},  -- Primal Mooncloth
  [26776] = {learn=350, item=21860, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,365,370}},  -- Imbued Netherweave Boots
  [26782] = {learn=350, item=21866, min=1, max=1, skillupCnt=1, source={2}, colors={350,360,365,370}},  -- Arcanoweave Bracers
  [31373] = {learn=350, item=24271, min=1, max=1, skillupCnt=1, source={5}, colors={350,350,355,360}},  -- Spellcloth
  [31434] = {learn=350, item=24249, min=1, max=1, skillupCnt=1, source={2}, colors={350,360,365,370}},  -- Unyielding Bracers
  [31435] = {learn=350, item=24250, min=1, max=1, skillupCnt=1, source={2}, colors={350,360,365,370}},  -- Bracers of Havok
  [31437] = {learn=350, item=24251, min=1, max=1, skillupCnt=1, source={2}, colors={350,360,365,370}},  -- Blackstrike Bracers
  [31438] = {learn=350, item=24252, min=1, max=1, skillupCnt=1, source={2}, colors={350,360,365,370}},  -- Cloak of the Black Void
  [31440] = {learn=350, item=24253, min=1, max=1, skillupCnt=1, source={2}, colors={350,360,365,370}},  -- Cloak of Eternity
  [31441] = {learn=350, item=24254, min=1, max=1, skillupCnt=1, source={2}, colors={350,360,365,370}},  -- White Remedy Cape
  [36686] = {learn=350, item=24272, min=1, max=1, skillupCnt=1, source={5}, colors={350,350,355,360}},  -- Shadowcloth
  [37873] = {learn=350, item=30831, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,365,370}},  -- Cloak of Arcane Evasion
  [37882] = {learn=350, item=30837, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,365,370}},  -- Flameheart Bracers
  [26752] = {learn=355, item=21846, min=1, max=1, skillupCnt=1, source={5}, colors={355,365,370,375}},  -- Spellfire Belt
  [26756] = {learn=355, item=21869, min=1, max=1, skillupCnt=1, source={5}, colors={355,365,370,375}},  -- Frozen Shadoweave Shoulders
  [26760] = {learn=355, item=21873, min=1, max=1, skillupCnt=1, source={5}, colors={355,365,370,375}},  -- Primal Mooncloth Belt
  [26779] = {learn=355, item=21863, min=1, max=1, skillupCnt=1, source={5}, colors={355,365,370,375}},  -- Soulcloth Gloves
  [26777] = {learn=360, item=21861, min=1, max=1, skillupCnt=1, source={5}, colors={360,370,375,380}},  -- Imbued Netherweave Robe
  [26778] = {learn=360, item=21862, min=1, max=1, skillupCnt=1, source={5}, colors={360,370,375,380}},  -- Imbued Netherweave Tunic
  [26783] = {learn=360, item=21867, min=1, max=1, skillupCnt=1, source={2}, colors={360,370,375,380}},  -- Arcanoweave Boots
  [37883] = {learn=360, item=30838, min=1, max=1, skillupCnt=1, source={5}, colors={360,370,375,380}},  -- Flameheart Gloves
  [26753] = {learn=365, item=21847, min=1, max=1, skillupCnt=1, source={5}, colors={365,375,380,385}},  -- Spellfire Gloves
  [26757] = {learn=365, item=21870, min=1, max=1, skillupCnt=1, source={5}, colors={365,375,380,385}},  -- Frozen Shadoweave Boots
  [26761] = {learn=365, item=21874, min=1, max=1, skillupCnt=1, source={5}, colors={365,375,380,385}},  -- Primal Mooncloth Shoulders
  [26780] = {learn=365, item=21864, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,380,385}},  -- Soulcloth Shoulders
  [31442] = {learn=365, item=24255, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,380,385}},  -- Unyielding Girdle
  [31443] = {learn=365, item=24256, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,380,385}},  -- Girdle of Ruination
  [31444] = {learn=365, item=24257, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,380,385}},  -- Black Belt of Knowledge
  [31448] = {learn=365, item=24258, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,380,385}},  -- Resolute Cape
  [31449] = {learn=365, item=24259, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,380,385}},  -- Vengeance Wrap
  [31450] = {learn=365, item=24260, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,380,385}},  -- Manaweave Cloak
  [46128] = {learn=365, item=34366, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Sunfire Handwraps
  [46129] = {learn=365, item=34367, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Hands of Eternal Light
  [46130] = {learn=365, item=34364, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Sunfire Robe
  [46131] = {learn=365, item=34365, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Robe of Eternal Light
  [26784] = {learn=370, item=21868, min=1, max=1, skillupCnt=1, source={2}, colors={370,380,385,390}},  -- Arcanoweave Robe
  [37884] = {learn=370, item=30839, min=1, max=1, skillupCnt=1, source={5}, colors={370,380,385,390}},  -- Flameheart Vest
  [26754] = {learn=375, item=21848, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,390,395}},  -- Spellfire Robe
  [26755] = {learn=375, item=21858, min=1, max=1, skillupCnt=1, source={2,5}, colors={375,385,390,395}},  -- Spellfire Bag
  [26758] = {learn=375, item=21871, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,390,395}},  -- Frozen Shadoweave Robe
  [26759] = {learn=375, item=21872, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,390,395}},  -- Ebon Shadowbag
  [26762] = {learn=375, item=21875, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,390,395}},  -- Primal Mooncloth Robe
  [26763] = {learn=375, item=21876, min=1, max=1, skillupCnt=1, source={2,5}, colors={375,385,390,395}},  -- Primal Mooncloth Bag
  [26781] = {learn=375, item=21865, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,390,395}},  -- Soulcloth Vest
  [31432] = {learn=375, item=24274, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,390,395}},  -- Runic Spellthread
  [31433] = {learn=375, item=24276, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,390,395}},  -- Golden Spellthread
  [31451] = {learn=375, item=24261, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,390,395}},  -- Whitemend Pants
  [31452] = {learn=375, item=24262, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,390,395}},  -- Spellstrike Pants
  [31453] = {learn=375, item=24263, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,390,395}},  -- Battlecast Pants
  [31454] = {learn=375, item=24264, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,390,395}},  -- Whitemend Hood
  [31455] = {learn=375, item=24266, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,390,395}},  -- Spellstrike Hood
  [31456] = {learn=375, item=24267, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,390,395}},  -- Battlecast Hood
  [36315] = {learn=375, item=30038, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,390,395}},  -- Belt of Blasting
  [36316] = {learn=375, item=30036, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,390,395}},  -- Belt of the Long Road
  [36317] = {learn=375, item=30037, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,390,395}},  -- Boots of Blasting
  [36318] = {learn=375, item=30035, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,390,395}},  -- Boots of the Long Road
  [40020] = {learn=375, item=32391, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,390,395}},  -- Soulguard Slippers
  [40021] = {learn=375, item=32392, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,390,395}},  -- Soulguard Bracers
  [40023] = {learn=375, item=32389, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,390,395}},  -- Soulguard Leggings
  [40024] = {learn=375, item=32390, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,390,395}},  -- Soulguard Girdle
  [40060] = {learn=375, item=32420, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,390,395}},  -- Night's End
  [41205] = {learn=375, item=32586, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,390,395}},  -- Bracers of Nimble Thought
  [41206] = {learn=375, item=32587, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,390,395}},  -- Mantle of Nimble Thought
  [41207] = {learn=375, item=32584, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,390,395}},  -- Swiftheal Wraps
  [41208] = {learn=375, item=32585, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,390,395}},  -- Swiftheal Mantle
  [50194] = {learn=375, item=38225, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,390,395}},  -- Mycah's Botanical Bag
  -- skillLine 202
  [3918] = {learn=1, item=4357, min=1, max=1, skillupCnt=1, source={}, colors={1,20,30,40}},  -- Rough Blasting Powder
  [3919] = {learn=1, item=4358, min=2, max=2, skillupCnt=1, source={}, colors={1,30,45,60}},  -- Rough Dynamite
  [3920] = {learn=30, item=8067, min=200, max=200, skillupCnt=1, source={}, colors={0,30,45,60}},  -- Crafted Light Shot
  [3922] = {learn=30, item=4359, min=1, max=1, skillupCnt=1, source={}, colors={30,45,52,60}},  -- Handful of Copper Bolts
  [3923] = {learn=30, item=4360, min=2, max=2, skillupCnt=1, source={}, colors={30,60,75,90}},  -- Rough Copper Bomb
  [3924] = {learn=50, item=4361, min=1, max=1, skillupCnt=1, source={}, colors={50,80,95,110}},  -- Copper Tube
  [3925] = {learn=50, item=4362, min=1, max=1, skillupCnt=1, source={}, colors={50,80,95,110}},  -- Rough Boomstick
  [7430] = {learn=50, item=6219, min=1, max=1, skillupCnt=1, source={}, colors={50,70,80,90}},  -- Arclight Spanner
  [3977] = {learn=60, item=4405, min=1, max=1, skillupCnt=1, source={}, colors={60,90,105,120}},  -- Crude Scope
  [3926] = {learn=65, item=4363, min=1, max=1, skillupCnt=1, source={}, colors={65,95,110,125}},  -- Copper Modulator
  [3928] = {learn=75, item=4401, min=1, max=1, skillupCnt=1, source={2,16,21}, colors={75,105,120,135}},  -- Mechanical Squirrel
  [3929] = {learn=75, item=4364, min=1, max=1, skillupCnt=1, source={}, colors={75,85,90,95}},  -- Coarse Blasting Powder
  [3930] = {learn=75, item=8068, min=200, max=200, skillupCnt=1, source={}, colors={75,85,90,95}},  -- Crafted Heavy Shot
  [3931] = {learn=75, item=4365, min=1, max=3, skillupCnt=1, source={}, colors={75,90,97,105}},  -- Coarse Dynamite (1-3)
  [3932] = {learn=85, item=4366, min=1, max=1, skillupCnt=1, source={}, colors={85,115,130,145}},  -- Target Dummy
  [3973] = {learn=90, item=4404, min=5, max=5, skillupCnt=1, source={}, colors={90,110,125,140}},  -- Silver Contact
  [3933] = {learn=100, item=4367, min=1, max=1, skillupCnt=1, source={2,16,21}, colors={100,130,145,160}},  -- Small Seaforium Charge
  [3934] = {learn=100, item=4368, min=1, max=1, skillupCnt=1, source={}, colors={100,130,145,160}},  -- Flying Tiger Goggles
  [8334] = {learn=100, item=6712, min=1, max=1, skillupCnt=1, source={}, colors={100,115,122,130}},  -- Practice Lock
  [8339] = {learn=100, item=6714, min=1, max=3, skillupCnt=1, source={2,21}, colors={100,115,122,130}},  -- EZ-Thro Dynamite (1-3)
  [3936] = {learn=105, item=4369, min=1, max=1, skillupCnt=1, source={}, colors={105,130,142,155}},  -- Deadly Blunderbuss
  [3937] = {learn=105, item=4370, min=2, max=4, skillupCnt=1, source={}, colors={105,105,130,155}},  -- Large Copper Bomb (2-4)
  [3938] = {learn=105, item=4371, min=1, max=1, skillupCnt=1, source={}, colors={105,105,130,155}},  -- Bronze Tube
  [3978] = {learn=110, item=4406, min=1, max=1, skillupCnt=1, source={}, colors={110,135,147,160}},  -- Standard Scope
  [3939] = {learn=120, item=4372, min=1, max=1, skillupCnt=1, source={5}, colors={120,145,157,170}},  -- Lovingly Crafted Boomstick
  [3940] = {learn=120, item=4373, min=1, max=1, skillupCnt=1, source={2,16}, colors={120,145,157,170}},  -- Shadow Goggles
  [3941] = {learn=120, item=4374, min=1, max=3, skillupCnt=1, source={}, colors={120,120,145,170}},  -- Small Bronze Bomb (1-3)
  [3942] = {learn=125, item=4375, min=1, max=1, skillupCnt=1, source={}, colors={125,125,150,175}},  -- Whirring Bronze Gizmo
  [3944] = {learn=125, item=4376, min=1, max=1, skillupCnt=1, source={2}, colors={125,125,150,175}},  -- Flame Deflector
  [3945] = {learn=125, item=4377, min=1, max=1, skillupCnt=1, source={}, colors={125,125,135,145}},  -- Heavy Blasting Powder
  [3946] = {learn=125, item=4378, min=1, max=5, skillupCnt=1, source={}, colors={125,125,135,145}},  -- Heavy Dynamite (1-5)
  [3947] = {learn=125, item=8069, min=200, max=200, skillupCnt=1, source={}, colors={125,125,135,145}},  -- Crafted Solid Shot
  [9269] = {learn=125, item=7506, min=1, max=1, skillupCnt=1, source={2,5}, colors={125,150,162,175}},  -- Gnomish Universal Remote
  [26416] = {learn=125, item=21558, min=3, max=3, skillupCnt=1, source={2}, colors={125,125,137,150}},  -- Small Blue Rocket
  [26417] = {learn=125, item=21559, min=3, max=3, skillupCnt=1, source={2}, colors={125,125,137,150}},  -- Small Green Rocket
  [26418] = {learn=125, item=21557, min=3, max=3, skillupCnt=1, source={2}, colors={125,125,137,150}},  -- Small Red Rocket
  [3949] = {learn=130, item=4379, min=1, max=1, skillupCnt=1, source={}, colors={130,155,167,180}},  -- Silver-plated Shotgun
  [6458] = {learn=135, item=5507, min=1, max=1, skillupCnt=1, source={}, colors={135,160,172,185}},  -- Ornate Spyglass
  [3950] = {learn=140, item=4380, min=2, max=4, skillupCnt=1, source={}, colors={140,140,165,190}},  -- Big Bronze Bomb (2-4)
  [3952] = {learn=140, item=4381, min=1, max=1, skillupCnt=1, source={5}, colors={140,165,177,190}},  -- Minor Recombobulator
  [3953] = {learn=145, item=4382, min=1, max=1, skillupCnt=1, source={}, colors={145,145,170,195}},  -- Bronze Framework
  [3954] = {learn=145, item=4383, min=1, max=1, skillupCnt=1, source={2}, colors={145,170,182,195}},  -- Moonsight Rifle
  [3955] = {learn=150, item=4384, min=1, max=1, skillupCnt=1, source={}, colors={150,175,187,200}},  -- Explosive Sheep
  [3956] = {learn=150, item=4385, min=1, max=1, skillupCnt=1, source={}, colors={150,175,187,200}},  -- Green Tinted Goggles
  [9271] = {learn=150, item=6533, min=3, max=3, skillupCnt=1, source={}, colors={150,150,160,170}},  -- Aquadynamic Fish Attractor
  [12584] = {learn=150, item=10558, min=3, max=3, skillupCnt=1, source={}, colors={150,150,170,190}},  -- Gold Power Core
  [23066] = {learn=150, item=9318, min=3, max=3, skillupCnt=1, source={5}, colors={150,150,162,175}},  -- Red Firework
  [23067] = {learn=150, item=9312, min=3, max=3, skillupCnt=1, source={5}, colors={150,150,162,175}},  -- Blue Firework
  [23068] = {learn=150, item=9313, min=3, max=3, skillupCnt=1, source={5}, colors={150,150,162,175}},  -- Green Firework
  [3957] = {learn=155, item=4386, min=1, max=1, skillupCnt=1, source={5}, colors={155,175,185,195}},  -- Ice Deflector
  [3958] = {learn=160, item=4387, min=1, max=1, skillupCnt=1, source={}, colors={160,160,170,180}},  -- Iron Strut
  [3959] = {learn=160, item=4388, min=1, max=1, skillupCnt=1, source={2}, colors={160,180,190,200}},  -- Discombobulator Ray
  [3960] = {learn=165, item=4403, min=1, max=1, skillupCnt=1, source={2}, colors={165,185,195,205}},  -- Portable Bronze Mortar
  [9273] = {learn=165, item=7148, min=1, max=1, skillupCnt=1, source={2,5}, colors={165,165,180,200}},  -- Goblin Jumper Cables
  [3961] = {learn=170, item=4389, min=1, max=1, skillupCnt=1, source={}, colors={170,170,190,210}},  -- Gyrochronatom
  [3962] = {learn=175, item=4390, min=2, max=4, skillupCnt=1, source={}, colors={175,175,195,215}},  -- Iron Grenade (2-4)
  [3963] = {learn=175, item=4391, min=1, max=1, skillupCnt=1, source={}, colors={175,175,195,215}},  -- Compact Harvest Reaper Kit
  [12585] = {learn=175, item=10505, min=1, max=1, skillupCnt=1, source={}, colors={175,175,185,195}},  -- Solid Blasting Powder
  [12586] = {learn=175, item=10507, min=2, max=2, skillupCnt=1, source={}, colors={175,175,185,195}},  -- Solid Dynamite
  [12587] = {learn=175, item=10499, min=1, max=1, skillupCnt=1, source={2}, colors={175,195,205,215}},  -- Bright-Eye Goggles
  [12590] = {learn=175, item=10498, min=1, max=1, skillupCnt=1, source={}, colors={175,175,195,215}},  -- Gyromatic Micro-Adjustor
  [26420] = {learn=175, item=21589, min=3, max=3, skillupCnt=1, source={2}, colors={175,175,187,200}},  -- Large Blue Rocket
  [26421] = {learn=175, item=21590, min=3, max=3, skillupCnt=1, source={2}, colors={175,175,187,200}},  -- Large Green Rocket
  [26422] = {learn=175, item=21592, min=3, max=3, skillupCnt=1, source={2}, colors={175,175,187,200}},  -- Large Red Rocket
  [3979] = {learn=180, item=4407, min=1, max=1, skillupCnt=1, source={5}, colors={180,200,210,220}},  -- Accurate Scope
  [3965] = {learn=185, item=4392, min=1, max=1, skillupCnt=1, source={}, colors={185,185,205,225}},  -- Advanced Target Dummy
  [3966] = {learn=185, item=4393, min=1, max=1, skillupCnt=1, source={2}, colors={185,205,215,225}},  -- Craftsman's Monocle
  [8243] = {learn=185, item=4852, min=1, max=1, skillupCnt=1, source={2,4}, colors={185,185,205,225}},  -- Flash Bomb
  [3967] = {learn=190, item=4394, min=2, max=2, skillupCnt=1, source={}, colors={190,190,210,230}},  -- Big Iron Bomb
  [21940] = {learn=190, item=17716, min=1, max=1, skillupCnt=1, source={2}, colors={190,190,210,230}},  -- Snowmaster 9000
  [3968] = {learn=195, item=4395, min=1, max=1, skillupCnt=1, source={2}, colors={195,215,225,235}},  -- Goblin Land Mine
  [12589] = {learn=195, item=10559, min=1, max=1, skillupCnt=1, source={}, colors={195,195,215,235}},  -- Mithril Tube
  [3969] = {learn=200, item=4396, min=1, max=1, skillupCnt=1, source={5}, colors={200,220,230,240}},  -- Mechanical Dragonling
  [3971] = {learn=200, item=4397, min=1, max=1, skillupCnt=1, source={2,5}, colors={200,220,230,240}},  -- Gnomish Cloaking Device
  [3972] = {learn=200, item=4398, min=1, max=1, skillupCnt=1, source={2}, colors={200,200,220,240}},  -- Large Seaforium Charge
  [12591] = {learn=200, item=10560, min=1, max=1, skillupCnt=1, source={}, colors={200,200,220,240}},  -- Unstable Trigger
  [15255] = {learn=200, item=11590, min=1, max=1, skillupCnt=1, source={}, colors={200,200,220,240}},  -- Mechanical Repair Kit
  [23069] = {learn=200, item=18588, min=1, max=1, skillupCnt=1, source={5}, colors={200,200,210,220}},  -- EZ-Thro Dynamite II
  [12594] = {learn=205, item=10500, min=1, max=1, skillupCnt=1, source={}, colors={205,225,235,245}},  -- Fire Goggles
  [12595] = {learn=205, item=10508, min=1, max=1, skillupCnt=1, source={}, colors={205,225,235,245}},  -- Mithril Blunderbuss
  [12715] = {learn=205, item=10644, min=1, max=1, skillupCnt=1, source={}, colors={205,205,205,205}},  -- Goblin Rocket Fuel Recipe
  [12717] = {learn=205, item=10542, min=1, max=1, skillupCnt=1, source={}, colors={205,225,235,245}},  -- Goblin Mining Helmet
  [12718] = {learn=205, item=10543, min=1, max=1, skillupCnt=1, source={}, colors={205,225,235,245}},  -- Goblin Construction Helmet
  [12760] = {learn=205, item=10646, min=1, max=1, skillupCnt=1, source={}, colors={205,205,225,245}},  -- Goblin Sapper Charge
  [12895] = {learn=205, item=10713, min=1, max=1, skillupCnt=1, source={}, colors={205,205,205,205}},  -- Inlaid Mithril Cylinder Plans
  [12899] = {learn=205, item=10716, min=1, max=1, skillupCnt=1, source={}, colors={205,225,235,245}},  -- Gnomish Shrink Ray
  [13240] = {learn=205, item=10577, min=1, max=1, skillupCnt=1, source={}, colors={0,0,0,205}},  -- The Mortar: Reloaded
  [15628] = {learn=205, item=11825, min=1, max=1, skillupCnt=1, source={2}, colors={205,205,205,205}},  -- Pet Bombling
  [15633] = {learn=205, item=11826, min=1, max=1, skillupCnt=1, source={2}, colors={205,205,205,205}},  -- Lil' Smoky
  [12596] = {learn=210, item=10512, min=200, max=200, skillupCnt=1, source={}, colors={210,210,230,250}},  -- Hi-Impact Mithril Slugs
  [12597] = {learn=210, item=10546, min=1, max=1, skillupCnt=1, source={5}, colors={210,230,240,250}},  -- Deadly Scope
  [12897] = {learn=210, item=10545, min=1, max=1, skillupCnt=1, source={}, colors={210,230,240,250}},  -- Gnomish Goggles
  [12902] = {learn=210, item=10720, min=1, max=1, skillupCnt=1, source={}, colors={210,230,240,250}},  -- Gnomish Net-o-Matic Projector
  [12599] = {learn=215, item=10561, min=1, max=1, skillupCnt=1, source={}, colors={215,215,235,255}},  -- Mithril Casing
  [12603] = {learn=215, item=10514, min=3, max=3, skillupCnt=1, source={}, colors={215,215,235,255}},  -- Mithril Frag Bomb
  [12903] = {learn=215, item=10721, min=1, max=1, skillupCnt=1, source={}, colors={215,235,245,255}},  -- Gnomish Harm Prevention Belt
  [12607] = {learn=220, item=10501, min=1, max=1, skillupCnt=1, source={2}, colors={220,240,250,260}},  -- Catseye Ultra Goggles
  [12614] = {learn=220, item=10510, min=1, max=1, skillupCnt=1, source={2}, colors={220,240,250,260}},  -- Mithril Heavy-bore Rifle
  [8895] = {learn=225, item=7189, min=1, max=1, skillupCnt=1, source={2}, colors={225,245,255,265}},  -- Goblin Rocket Boots
  [12615] = {learn=225, item=10502, min=1, max=1, skillupCnt=1, source={2}, colors={225,245,255,265}},  -- Spellpower Goggles Xtreme
  [12616] = {learn=225, item=10518, min=1, max=1, skillupCnt=1, source={2}, colors={225,245,255,265}},  -- Parachute Cloak
  [12716] = {learn=225, item=10577, min=1, max=1, skillupCnt=1, source={}, colors={0,225,235,245}},  -- Goblin Mortar
  [12905] = {learn=225, item=10724, min=1, max=1, skillupCnt=1, source={}, colors={225,245,255,265}},  -- Gnomish Rocket Boots
  [26423] = {learn=225, item=21571, min=3, max=3, skillupCnt=1, source={2}, colors={225,225,237,250}},  -- Blue Rocket Cluster
  [26424] = {learn=225, item=21574, min=3, max=3, skillupCnt=1, source={2}, colors={225,225,237,250}},  -- Green Rocket Cluster
  [26425] = {learn=225, item=21576, min=3, max=3, skillupCnt=1, source={2}, colors={225,225,237,250}},  -- Red Rocket Cluster
  [26442] = {learn=225, item=21569, min=1, max=1, skillupCnt=1, source={4}, colors={225,245,255,265}},  -- Firework Launcher
  [12617] = {learn=230, item=10506, min=1, max=1, skillupCnt=1, source={5}, colors={230,250,260,270}},  -- Deepdive Helmet
  [12618] = {learn=230, item=10503, min=1, max=1, skillupCnt=1, source={}, colors={230,250,260,270}},  -- Rose Colored Goggles
  [12755] = {learn=230, item=10587, min=1, max=1, skillupCnt=1, source={}, colors={230,230,250,270}},  -- Goblin Bomb Dispenser
  [12906] = {learn=230, item=10725, min=1, max=1, skillupCnt=1, source={}, colors={230,250,260,270}},  -- Gnomish Battle Chicken
  [12619] = {learn=235, item=10562, min=4, max=4, skillupCnt=1, source={}, colors={235,235,255,275}},  -- Hi-Explosive Bomb
  [12754] = {learn=235, item=10586, min=2, max=2, skillupCnt=1, source={}, colors={235,235,255,275}},  -- The Big One
  [12907] = {learn=235, item=10726, min=1, max=1, skillupCnt=1, source={}, colors={235,255,265,275}},  -- Gnomish Mind Control Cap
  [12620] = {learn=240, item=10548, min=1, max=1, skillupCnt=1, source={2}, colors={240,260,270,280}},  -- Sniper Scope
  [12759] = {learn=240, item=10645, min=1, max=1, skillupCnt=1, source={}, colors={240,260,270,280}},  -- Gnomish Death Ray
  [12908] = {learn=240, item=10727, min=1, max=1, skillupCnt=1, source={}, colors={240,260,270,280}},  -- Goblin Dragon Gun
  [12621] = {learn=245, item=10513, min=200, max=200, skillupCnt=1, source={}, colors={245,245,265,285}},  -- Mithril Gyro-Shot
  [12622] = {learn=245, item=10504, min=1, max=1, skillupCnt=1, source={}, colors={245,265,275,285}},  -- Green Lens
  [12758] = {learn=245, item=10588, min=1, max=1, skillupCnt=1, source={}, colors={245,265,275,285}},  -- Goblin Rocket Helmet
  [12624] = {learn=250, item=10576, min=1, max=1, skillupCnt=1, source={5}, colors={250,270,280,290}},  -- Mithril Mechanical Dragonling
  [19567] = {learn=250, item=15846, min=1, max=1, skillupCnt=1, source={}, colors={250,270,280,290}},  -- Salt Shaker
  [19788] = {learn=250, item=15992, min=1, max=1, skillupCnt=1, source={}, colors={250,250,255,260}},  -- Dense Blasting Powder
  [23070] = {learn=250, item=18641, min=2, max=2, skillupCnt=1, source={}, colors={250,250,260,270}},  -- Dense Dynamite
  [23507] = {learn=250, item=19026, min=4, max=4, skillupCnt=1, source={5}, colors={250,250,260,270}},  -- Snake Burst Firework
  [26011] = {learn=250, item=21277, min=1, max=1, skillupCnt=1, source={}, colors={250,320,330,340}},  -- Tranquil Mechanical Yeti
  [19790] = {learn=260, item=15993, min=3, max=3, skillupCnt=1, source={5}, colors={260,280,290,300}},  -- Thorium Grenade
  [19791] = {learn=260, item=15994, min=1, max=1, skillupCnt=1, source={5}, colors={260,280,290,300}},  -- Thorium Widget
  [19792] = {learn=260, item=15995, min=1, max=1, skillupCnt=1, source={2}, colors={260,280,290,300}},  -- Thorium Rifle
  [23071] = {learn=260, item=18631, min=1, max=1, skillupCnt=1, source={5}, colors={260,270,275,280}},  -- Truesilver Transformer
  [23077] = {learn=260, item=18634, min=1, max=1, skillupCnt=1, source={5}, colors={260,280,290,300}},  -- Gyrofreeze Ice Reflector
  [23129] = {learn=260, item=18660, min=1, max=1, skillupCnt=1, source={2}, colors={260,260,265,270}},  -- World Enlarger
  [19793] = {learn=265, item=15996, min=1, max=1, skillupCnt=1, source={2}, colors={265,285,295,305}},  -- Lifelike Mechanical Toad
  [23078] = {learn=265, item=18587, min=1, max=1, skillupCnt=1, source={2}, colors={265,285,295,305}},  -- Goblin Jumper Cables XL
  [23096] = {learn=265, item=18645, min=1, max=1, skillupCnt=1, source={2}, colors={265,275,280,285}},  -- Alarm-O-Bot
  [19794] = {learn=270, item=15999, min=1, max=1, skillupCnt=1, source={2}, colors={270,290,300,310}},  -- Spellpower Goggles Xtreme Plus
  [19795] = {learn=275, item=16000, min=1, max=1, skillupCnt=1, source={5}, colors={275,295,305,315}},  -- Thorium Tube
  [19796] = {learn=275, item=16004, min=1, max=1, skillupCnt=1, source={2}, colors={275,295,305,315}},  -- Dark Iron Rifle
  [19814] = {learn=275, item=16023, min=1, max=1, skillupCnt=1, source={5}, colors={275,295,305,315}},  -- Masterwork Target Dummy
  [23079] = {learn=275, item=18637, min=1, max=1, skillupCnt=1, source={2}, colors={275,285,290,295}},  -- Major Recombobulator
  [23080] = {learn=275, item=18594, min=1, max=1, skillupCnt=1, source={5}, colors={275,275,285,295}},  -- Powerful Seaforium Charge
  [26426] = {learn=275, item=21714, min=3, max=3, skillupCnt=1, source={2}, colors={275,275,280,285}},  -- Large Blue Rocket Cluster
  [26427] = {learn=275, item=21716, min=3, max=3, skillupCnt=1, source={2}, colors={275,275,280,285}},  -- Large Green Rocket Cluster
  [26428] = {learn=275, item=21718, min=3, max=3, skillupCnt=1, source={2}, colors={275,275,280,285}},  -- Large Red Rocket Cluster
  [26443] = {learn=275, item=21570, min=1, max=1, skillupCnt=1, source={4}, colors={275,295,305,315}},  -- Firework Cluster Launcher
  [28327] = {learn=275, item=22728, min=1, max=1, skillupCnt=1, source={4,5}, colors={275,275,280,285}},  -- Steam Tonk Controller
  [39895] = {learn=275, item=7191, min=1, max=1, skillupCnt=1, source={5}, colors={275,275,280,285}},  -- Fused Wiring
  [19799] = {learn=285, item=16005, min=3, max=3, skillupCnt=1, source={2}, colors={285,305,315,325}},  -- Dark Iron Bomb
  [19800] = {learn=285, item=15997, min=200, max=200, skillupCnt=1, source={2}, colors={285,295,300,305}},  -- Thorium Shells
  [19815] = {learn=285, item=16006, min=1, max=1, skillupCnt=1, source={5}, colors={285,305,315,325}},  -- Delicate Arcanite Converter
  [23486] = {learn=285, item=18984, min=1, max=1, skillupCnt=1, source={}, colors={0,285,295,305}},  -- Dimensional Ripper - Everlook
  [23489] = {learn=285, item=18986, min=1, max=1, skillupCnt=1, source={}, colors={0,285,295,305}},  -- Ultrasafe Transporter - Gadgetzan
  [19819] = {learn=290, item=16009, min=1, max=1, skillupCnt=1, source={2}, colors={290,310,320,330}},  -- Voice Amplification Modulator
  [19825] = {learn=290, item=16008, min=1, max=1, skillupCnt=1, source={2}, colors={290,310,320,330}},  -- Master Engineer's Goggles
  [23081] = {learn=290, item=18638, min=1, max=1, skillupCnt=1, source={2}, colors={290,310,320,330}},  -- Hyper-Radiant Flame Reflector
  [19830] = {learn=300, item=16022, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Arcanite Dragonling
  [19831] = {learn=300, item=16040, min=3, max=3, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Arcane Bomb
  [19833] = {learn=300, item=16007, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Flawless Arcanite Rifle
  [22704] = {learn=300, item=18232, min=1, max=1, skillupCnt=1, source={}, colors={300,320,330,340}},  -- Field Repair Bot 74A
  [22793] = {learn=300, item=18283, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Biznicks 247x128 Accurascope
  [22795] = {learn=300, item=18282, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Core Marksman Rifle
  [22797] = {learn=300, item=18168, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Force Reactive Disk
  [23082] = {learn=300, item=18639, min=1, max=1, skillupCnt=1, source={2}, colors={300,320,330,340}},  -- Ultra-Flash Shadow Reflector
  [24356] = {learn=300, item=19999, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Bloodvine Goggles
  [24357] = {learn=300, item=19998, min=1, max=1, skillupCnt=1, source={5}, colors={300,320,330,340}},  -- Bloodvine Lens
  [30303] = {learn=300, item=23781, min=4, max=4, skillupCnt=1, source={}, colors={300,300,310,320}},  -- Elemental Blasting Powder
  [30304] = {learn=300, item=23782, min=1, max=1, skillupCnt=1, source={}, colors={300,300,310,320}},  -- Fel Iron Casing
  [30305] = {learn=300, item=23783, min=1, max=1, skillupCnt=1, source={}, colors={300,300,305,310}},  -- Handful of Fel Iron Bolts
  [30310] = {learn=300, item=23736, min=4, max=4, skillupCnt=1, source={}, colors={300,320,330,340}},  -- Fel Iron Bomb
  [30548] = {learn=305, item=23821, min=1, max=1, skillupCnt=1, source={4}, colors={305,305,315,325}},  -- Zapthrottle Mote Extractor
  [30346] = {learn=310, item=23772, min=200, max=200, skillupCnt=1, source={}, colors={310,310,320,330}},  -- Fel Iron Shells
  [30312] = {learn=320, item=23742, min=1, max=1, skillupCnt=1, source={}, colors={320,330,340,350}},  -- Fel Iron Musket
  [30306] = {learn=325, item=23784, min=1, max=1, skillupCnt=1, source={}, colors={325,325,330,335}},  -- Adamantite Frame
  [30311] = {learn=325, item=23737, min=3, max=3, skillupCnt=1, source={}, colors={325,335,345,355}},  -- Adamantite Grenade
  [30337] = {learn=325, item=23767, min=1, max=1, skillupCnt=1, source={2}, colors={325,335,345,355}},  -- Crashin' Thrashin' Robot
  [30348] = {learn=325, item=23774, min=1, max=1, skillupCnt=1, source={5}, colors={325,325,335,345}},  -- Fel Iron Toolbox
  [30558] = {learn=325, item=23826, min=3, max=3, skillupCnt=1, source={}, colors={325,325,335,345}},  -- The Bigger One
  [30568] = {learn=325, item=23841, min=3, max=3, skillupCnt=1, source={}, colors={325,335,345,355}},  -- Gnomish Flame Turret
  [30551] = {learn=330, item=33092, min=20, max=20, skillupCnt=1, source={2}, colors={330,330,340,350}},  -- Healing Potion Injector
  [30329] = {learn=335, item=23764, min=1, max=1, skillupCnt=1, source={5}, colors={335,345,355,365}},  -- Adamantite Scope
  [30341] = {learn=335, item=23768, min=3, max=3, skillupCnt=1, source={5}, colors={335,335,345,355}},  -- White Smoke Flare
  [30344] = {learn=335, item=23771, min=3, max=3, skillupCnt=1, source={5}, colors={335,335,345,355}},  -- Green Smoke Flare
  [30347] = {learn=335, item=34504, min=1, max=1, skillupCnt=1, source={5}, colors={335,335,345,355}},  -- Adamantite Shell Machine
  [32814] = {learn=335, item=25886, min=3, max=3, skillupCnt=1, source={2}, colors={335,335,345,355}},  -- Purple Smoke Flare
  [39971] = {learn=335, item=32423, min=10, max=10, skillupCnt=1, source={}, colors={335,335,340,345}},  -- Icy Blasting Primers
  [39973] = {learn=335, item=32413, min=5, max=5, skillupCnt=1, source={}, colors={335,345,355,365}},  -- Frost Grenades
  [43676] = {learn=335, item=20475, min=1, max=1, skillupCnt=1, source={2}, colors={335,335,345,355}},  -- Adamantite Arrow Maker
  [30307] = {learn=340, item=23785, min=1, max=1, skillupCnt=1, source={}, colors={340,350,360,370}},  -- Hardened Adamantite Tube
  [30308] = {learn=340, item=23786, min=1, max=1, skillupCnt=1, source={}, colors={340,350,360,370}},  -- Khorium Power Core
  [30309] = {learn=340, item=23787, min=1, max=1, skillupCnt=1, source={}, colors={340,350,360,370}},  -- Felsteel Stabilizer
  [30316] = {learn=340, item=23758, min=1, max=1, skillupCnt=1, source={5}, colors={340,350,360,370}},  -- Cogspinner Goggles
  [30317] = {learn=340, item=23761, min=1, max=1, skillupCnt=1, source={2}, colors={340,350,360,370}},  -- Power Amplification Goggles
  [30560] = {learn=340, item=23827, min=2, max=2, skillupCnt=1, source={}, colors={340,340,350,360}},  -- Super Sapper Charge
  [30569] = {learn=340, item=23835, min=1, max=1, skillupCnt=1, source={}, colors={340,360,370,380}},  -- Gnomish Poultryizer
  [30552] = {learn=345, item=33093, min=20, max=20, skillupCnt=1, source={2}, colors={345,345,355,365}},  -- Mana Potion Injector
  [30313] = {learn=350, item=23746, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Adamantite Rifle
  [30318] = {learn=350, item=23762, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,370,380}},  -- Ultra-Spectropic Detection Goggles
  [30349] = {learn=350, item=23775, min=1, max=1, skillupCnt=1, source={}, colors={350,360,370,380}},  -- Khorium Toolbox
  [30547] = {learn=350, item=23819, min=2, max=2, skillupCnt=1, source={5}, colors={350,350,355,360}},  -- Elemental Seaforium Charge
  [30563] = {learn=350, item=23836, min=1, max=1, skillupCnt=1, source={}, colors={350,360,370,380}},  -- Goblin Rocket Launcher
  [30570] = {learn=350, item=23825, min=1, max=1, skillupCnt=1, source={}, colors={350,360,370,380}},  -- Nigh-Invulnerability Belt
  [36954] = {learn=350, item=30542, min=1, max=1, skillupCnt=1, source={}, colors={0,350,360,370}},  -- Dimensional Ripper - Area 52
  [36955] = {learn=350, item=30544, min=1, max=1, skillupCnt=1, source={}, colors={0,350,360,370}},  -- Ultrasafe Transporter - Toshley's Station
  [40274] = {learn=350, item=32461, min=1, max=1, skillupCnt=1, source={}, colors={350,370,380,390}},  -- Furious Gizmatic Goggles
  [41311] = {learn=350, item=32472, min=1, max=1, skillupCnt=1, source={}, colors={350,370,380,390}},  -- Justicebringer 2000 Specs
  [41312] = {learn=350, item=32473, min=1, max=1, skillupCnt=1, source={}, colors={350,370,380,390}},  -- Tankatronic Goggles
  [41314] = {learn=350, item=32474, min=1, max=1, skillupCnt=1, source={}, colors={350,370,380,390}},  -- Surestrike Goggles v2.0
  [41315] = {learn=350, item=32476, min=1, max=1, skillupCnt=1, source={}, colors={350,370,380,390}},  -- Gadgetstorm Goggles
  [41316] = {learn=350, item=32475, min=1, max=1, skillupCnt=1, source={}, colors={350,370,380,390}},  -- Living Replicator Specs
  [41317] = {learn=350, item=32478, min=1, max=1, skillupCnt=1, source={}, colors={350,370,380,390}},  -- Deathblow X11 Goggles
  [41318] = {learn=350, item=32479, min=1, max=1, skillupCnt=1, source={}, colors={350,370,380,390}},  -- Wonderheal XT40 Shades
  [41319] = {learn=350, item=32480, min=1, max=1, skillupCnt=1, source={}, colors={350,370,380,390}},  -- Magnified Moon Specs
  [41320] = {learn=350, item=32494, min=1, max=1, skillupCnt=1, source={}, colors={350,370,380,390}},  -- Destruction Holo-gogs
  [41321] = {learn=350, item=32495, min=1, max=1, skillupCnt=1, source={}, colors={350,370,380,390}},  -- Powerheal 4000 Lens
  [44155] = {learn=350, item=34060, min=1, max=1, skillupCnt=1, source={}, colors={350,375,380,385}},  -- Flying Machine
  [30556] = {learn=355, item=23824, min=1, max=1, skillupCnt=1, source={2}, colors={355,365,375,385}},  -- Rocket Boots Xtreme
  [46697] = {learn=355, item=35581, min=1, max=1, skillupCnt=1, source={2}, colors={355,365,375,385}},  -- Rocket Boots Xtreme Lite
  [30314] = {learn=360, item=23747, min=1, max=1, skillupCnt=1, source={2}, colors={360,370,380,390}},  -- Felsteel Boomstick
  [30325] = {learn=360, item=23763, min=1, max=1, skillupCnt=1, source={2}, colors={360,370,380,390}},  -- Hyper-Vision Goggles
  [30332] = {learn=360, item=23765, min=1, max=1, skillupCnt=1, source={2}, colors={360,370,380,390}},  -- Khorium Scope
  [44391] = {learn=360, item=34113, min=5, max=5, skillupCnt=1, source={2}, colors={360,370,380,390}},  -- Field Repair Bot 110G
  [30315] = {learn=375, item=23748, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Ornate Khorium Rifle
  [30334] = {learn=375, item=23766, min=1, max=1, skillupCnt=1, source={2}, colors={375,385,395,405}},  -- Stabilized Eternium Scope
  [30565] = {learn=375, item=23838, min=1, max=1, skillupCnt=1, source={}, colors={375,375,385,395}},  -- Foreman's Enchanted Helmet
  [30566] = {learn=375, item=23839, min=1, max=1, skillupCnt=1, source={}, colors={375,375,385,395}},  -- Foreman's Reinforced Helmet
  [30574] = {learn=375, item=23828, min=1, max=1, skillupCnt=1, source={}, colors={375,375,385,395}},  -- Gnomish Power Goggles
  [30575] = {learn=375, item=23829, min=1, max=1, skillupCnt=1, source={}, colors={375,375,385,395}},  -- Gnomish Battle Goggles
  [41307] = {learn=375, item=32756, min=1, max=1, skillupCnt=1, source={}, colors={375,375,392,410}},  -- Gyro-balanced Khorium Destroyer
  [44157] = {learn=375, item=34061, min=1, max=1, skillupCnt=1, source={}, colors={375,385,390,395}},  -- Turbo-Charged Flying Machine
  [46106] = {learn=375, item=35183, min=1, max=1, skillupCnt=1, source={2}, colors={375,390,410,430}},  -- Wonderheal XT68 Shades
  [46107] = {learn=375, item=35185, min=1, max=1, skillupCnt=1, source={2}, colors={375,390,410,430}},  -- Justicebringer 3000 Specs
  [46108] = {learn=375, item=35181, min=1, max=1, skillupCnt=1, source={2}, colors={375,390,410,430}},  -- Powerheal 9000 Lens
  [46109] = {learn=375, item=35182, min=1, max=1, skillupCnt=1, source={2}, colors={375,390,410,430}},  -- Hyper-Magnified Moon Specs
  [46110] = {learn=375, item=35184, min=1, max=1, skillupCnt=1, source={2}, colors={375,390,410,430}},  -- Primal-Attuned Goggles
  [46111] = {learn=375, item=34847, min=1, max=1, skillupCnt=1, source={2}, colors={375,390,410,430}},  -- Annihilator Holo-Gogs
  [46112] = {learn=375, item=34355, min=1, max=1, skillupCnt=1, source={2}, colors={375,390,410,430}},  -- Lightning Etched Specs
  [46113] = {learn=375, item=34356, min=1, max=1, skillupCnt=1, source={2}, colors={375,390,410,430}},  -- Surestrike Goggles v3.0
  [46114] = {learn=375, item=34354, min=1, max=1, skillupCnt=1, source={2}, colors={375,390,410,430}},  -- Mayhem Projection Goggles
  [46115] = {learn=375, item=34357, min=1, max=1, skillupCnt=1, source={2}, colors={375,390,410,430}},  -- Hard Khorium Goggles
  [46116] = {learn=375, item=34353, min=1, max=1, skillupCnt=1, source={2}, colors={375,390,410,430}},  -- Quad Deathblow X44 Goggles
  -- skillLine 333
  [7421] = {learn=1, item=6218, min=1, max=1, skillupCnt=1, source={}, colors={1,5,7,10}},  -- Runed Copper Rod
  [14293] = {learn=10, item=11287, min=1, max=1, skillupCnt=1, source={}, colors={10,75,95,115}},  -- Lesser Magic Wand
  [7420] = {learn=15, item=0, min=0, max=0, skillupCnt=1, source={}, colors={15,70,90,110}},  -- Enchant Chest - Minor Health
  [7443] = {learn=20, item=0, min=0, max=0, skillupCnt=1, source={2,5,16,21}, colors={20,80,100,120}},  -- Enchant Chest - Minor Mana
  [7426] = {learn=40, item=0, min=0, max=0, skillupCnt=1, source={}, colors={40,90,110,130}},  -- Enchant Chest - Minor Absorption
  [7454] = {learn=45, item=0, min=0, max=0, skillupCnt=1, source={}, colors={45,95,115,135}},  -- Enchant Cloak - Minor Resistance
  [25124] = {learn=45, item=20744, min=0, max=0, skillupCnt=1, source={5}, colors={45,55,65,75}},  -- Minor Wizard Oil
  [7457] = {learn=50, item=0, min=0, max=0, skillupCnt=1, source={}, colors={50,100,120,140}},  -- Enchant Bracer - Minor Stamina
  [7748] = {learn=60, item=0, min=0, max=0, skillupCnt=1, source={}, colors={60,105,125,145}},  -- Enchant Chest - Lesser Health
  [7766] = {learn=60, item=0, min=0, max=0, skillupCnt=1, source={2,16,21}, colors={60,105,125,145}},  -- Enchant Bracer - Minor Spirit
  [7418] = {learn=70, item=0, min=0, max=0, skillupCnt=1, source={}, colors={0,70,90,110}},  -- Enchant Bracer - Minor Health
  [7771] = {learn=70, item=0, min=0, max=0, skillupCnt=1, source={}, colors={70,110,130,150}},  -- Enchant Cloak - Minor Protection
  [14807] = {learn=70, item=11288, min=1, max=1, skillupCnt=1, source={}, colors={70,110,130,150}},  -- Greater Magic Wand
  [7428] = {learn=80, item=0, min=0, max=0, skillupCnt=1, source={}, colors={0,80,100,120}},  -- Enchant Bracer - Minor Deflection
  [7776] = {learn=80, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={80,115,135,155}},  -- Enchant Chest - Lesser Mana
  [7779] = {learn=80, item=0, min=0, max=0, skillupCnt=1, source={}, colors={80,115,135,155}},  -- Enchant Bracer - Minor Agility
  [7782] = {learn=80, item=0, min=0, max=0, skillupCnt=1, source={2,21}, colors={80,115,135,155}},  -- Enchant Bracer - Minor Strength
  [7786] = {learn=90, item=0, min=0, max=0, skillupCnt=1, source={2,16,21}, colors={90,120,140,160}},  -- Enchant Weapon - Minor Beastslayer
  [7788] = {learn=90, item=0, min=0, max=0, skillupCnt=1, source={}, colors={90,120,140,160}},  -- Enchant Weapon - Minor Striking
  [7745] = {learn=100, item=0, min=0, max=0, skillupCnt=1, source={}, colors={100,130,150,170}},  -- Enchant 2H Weapon - Minor Impact
  [7793] = {learn=100, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={100,130,150,170}},  -- Enchant 2H Weapon - Lesser Intellect
  [7795] = {learn=100, item=6339, min=1, max=1, skillupCnt=1, source={}, colors={100,130,150,170}},  -- Runed Silver Rod
  [13378] = {learn=105, item=0, min=0, max=0, skillupCnt=1, source={}, colors={105,130,150,170}},  -- Enchant Shield - Minor Stamina
  [13380] = {learn=110, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={110,135,155,175}},  -- Enchant 2H Weapon - Lesser Spirit
  [13419] = {learn=110, item=0, min=0, max=0, skillupCnt=1, source={2,5}, colors={110,135,155,175}},  -- Enchant Cloak - Minor Agility
  [13421] = {learn=115, item=0, min=0, max=0, skillupCnt=1, source={}, colors={115,140,160,180}},  -- Enchant Cloak - Lesser Protection
  [13464] = {learn=115, item=0, min=0, max=0, skillupCnt=1, source={2,16}, colors={115,140,160,180}},  -- Enchant Shield - Lesser Protection
  [7857] = {learn=120, item=0, min=0, max=0, skillupCnt=1, source={}, colors={120,145,165,185}},  -- Enchant Chest - Health
  [7859] = {learn=120, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={120,145,165,185}},  -- Enchant Bracer - Lesser Spirit
  [7861] = {learn=125, item=0, min=0, max=0, skillupCnt=1, source={}, colors={125,150,170,190}},  -- Enchant Cloak - Lesser Fire Resistance
  [7863] = {learn=125, item=0, min=0, max=0, skillupCnt=1, source={}, colors={125,150,170,190}},  -- Enchant Boots - Minor Stamina
  [7867] = {learn=125, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={125,150,170,190}},  -- Enchant Boots - Minor Agility
  [13485] = {learn=130, item=0, min=0, max=0, skillupCnt=1, source={}, colors={130,155,175,195}},  -- Enchant Shield - Lesser Spirit
  [13501] = {learn=130, item=0, min=0, max=0, skillupCnt=1, source={}, colors={130,155,175,195}},  -- Enchant Bracer - Lesser Stamina
  [13522] = {learn=135, item=0, min=0, max=0, skillupCnt=1, source={2,16}, colors={135,160,180,200}},  -- Enchant Cloak - Lesser Shadow Resistance
  [13503] = {learn=140, item=0, min=0, max=0, skillupCnt=1, source={}, colors={140,165,185,205}},  -- Enchant Weapon - Lesser Striking
  [13536] = {learn=140, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={140,165,185,205}},  -- Enchant Bracer - Lesser Strength
  [13538] = {learn=140, item=0, min=0, max=0, skillupCnt=1, source={}, colors={140,165,185,205}},  -- Enchant Chest - Lesser Absorption
  [13529] = {learn=145, item=0, min=0, max=0, skillupCnt=1, source={}, colors={145,170,190,210}},  -- Enchant 2H Weapon - Lesser Impact
  [13607] = {learn=145, item=0, min=0, max=0, skillupCnt=1, source={}, colors={145,170,190,210}},  -- Enchant Chest - Mana
  [13612] = {learn=145, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={145,170,190,210}},  -- Enchant Gloves - Mining
  [13617] = {learn=145, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={145,170,190,210}},  -- Enchant Gloves - Herbalism
  [13620] = {learn=145, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={145,170,190,210}},  -- Enchant Gloves - Fishing
  [13622] = {learn=150, item=0, min=0, max=0, skillupCnt=1, source={}, colors={150,175,195,215}},  -- Enchant Bracer - Lesser Intellect
  [13626] = {learn=150, item=0, min=0, max=0, skillupCnt=1, source={}, colors={150,175,195,215}},  -- Enchant Chest - Minor Stats
  [13628] = {learn=150, item=11130, min=1, max=1, skillupCnt=1, source={}, colors={150,175,195,215}},  -- Runed Golden Rod
  [25125] = {learn=150, item=20745, min=0, max=0, skillupCnt=1, source={5}, colors={150,160,170,180}},  -- Minor Mana Oil
  [13631] = {learn=155, item=0, min=0, max=0, skillupCnt=1, source={}, colors={155,175,195,215}},  -- Enchant Shield - Lesser Stamina
  [13635] = {learn=155, item=0, min=0, max=0, skillupCnt=1, source={}, colors={155,175,195,215}},  -- Enchant Cloak - Defense
  [14809] = {learn=155, item=11289, min=1, max=1, skillupCnt=1, source={}, colors={155,175,195,215}},  -- Lesser Mystic Wand
  [13637] = {learn=160, item=0, min=0, max=0, skillupCnt=1, source={}, colors={160,180,200,220}},  -- Enchant Boots - Lesser Agility
  [13640] = {learn=160, item=0, min=0, max=0, skillupCnt=1, source={}, colors={160,180,200,220}},  -- Enchant Chest - Greater Health
  [13642] = {learn=165, item=0, min=0, max=0, skillupCnt=1, source={}, colors={165,185,205,225}},  -- Enchant Bracer - Spirit
  [13644] = {learn=170, item=0, min=0, max=0, skillupCnt=1, source={}, colors={170,190,210,230}},  -- Enchant Boots - Lesser Stamina
  [13646] = {learn=170, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={170,190,210,230}},  -- Enchant Bracer - Lesser Deflection
  [13648] = {learn=170, item=0, min=0, max=0, skillupCnt=1, source={}, colors={170,190,210,230}},  -- Enchant Bracer - Stamina
  [13653] = {learn=175, item=0, min=0, max=0, skillupCnt=1, source={2,16}, colors={175,195,215,235}},  -- Enchant Weapon - Lesser Beastslayer
  [13655] = {learn=175, item=0, min=0, max=0, skillupCnt=1, source={2,16}, colors={175,195,215,235}},  -- Enchant Weapon - Lesser Elemental Slayer
  [13657] = {learn=175, item=0, min=0, max=0, skillupCnt=1, source={}, colors={175,195,215,235}},  -- Enchant Cloak - Fire Resistance
  [14810] = {learn=175, item=11290, min=1, max=1, skillupCnt=1, source={}, colors={175,195,215,235}},  -- Greater Mystic Wand
  [13659] = {learn=180, item=0, min=0, max=0, skillupCnt=1, source={}, colors={180,200,220,240}},  -- Enchant Shield - Spirit
  [13661] = {learn=180, item=0, min=0, max=0, skillupCnt=1, source={}, colors={180,200,220,240}},  -- Enchant Bracer - Strength
  [13663] = {learn=185, item=0, min=0, max=0, skillupCnt=1, source={}, colors={185,205,225,245}},  -- Enchant Chest - Greater Mana
  [13687] = {learn=190, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={190,210,230,250}},  -- Enchant Boots - Lesser Spirit
  [21931] = {learn=190, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={190,210,230,250}},  -- Enchant Weapon - Winter's Might
  [13689] = {learn=195, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={195,215,235,255}},  -- Enchant Shield - Lesser Block
  [13693] = {learn=195, item=0, min=0, max=0, skillupCnt=1, source={}, colors={195,215,235,255}},  -- Enchant Weapon - Striking
  [13695] = {learn=200, item=0, min=0, max=0, skillupCnt=1, source={}, colors={200,220,240,260}},  -- Enchant 2H Weapon - Impact
  [13698] = {learn=200, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={200,220,240,260}},  -- Enchant Gloves - Skinning
  [13700] = {learn=200, item=0, min=0, max=0, skillupCnt=1, source={}, colors={200,220,240,260}},  -- Enchant Chest - Lesser Stats
  [13702] = {learn=200, item=11145, min=1, max=1, skillupCnt=1, source={}, colors={200,220,240,260}},  -- Runed Truesilver Rod
  [25126] = {learn=200, item=20746, min=0, max=0, skillupCnt=1, source={5}, colors={200,210,220,230}},  -- Lesser Wizard Oil
  [13746] = {learn=205, item=0, min=0, max=0, skillupCnt=1, source={}, colors={205,225,245,265}},  -- Enchant Cloak - Greater Defense
  [13794] = {learn=205, item=0, min=0, max=0, skillupCnt=1, source={}, colors={205,225,245,265}},  -- Enchant Cloak - Resistance
  [13815] = {learn=210, item=0, min=0, max=0, skillupCnt=1, source={}, colors={210,230,250,270}},  -- Enchant Gloves - Agility
  [13817] = {learn=210, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={210,230,250,270}},  -- Enchant Shield - Stamina
  [13822] = {learn=210, item=0, min=0, max=0, skillupCnt=1, source={}, colors={210,230,250,270}},  -- Enchant Bracer - Intellect
  [13836] = {learn=215, item=0, min=0, max=0, skillupCnt=1, source={}, colors={215,235,255,275}},  -- Enchant Boots - Stamina
  [13841] = {learn=215, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={215,235,255,275}},  -- Enchant Gloves - Advanced Mining
  [13846] = {learn=220, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={220,240,260,280}},  -- Enchant Bracer - Greater Spirit
  [13858] = {learn=220, item=0, min=0, max=0, skillupCnt=1, source={}, colors={220,240,260,280}},  -- Enchant Chest - Superior Health
  [13868] = {learn=225, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={225,245,265,285}},  -- Enchant Gloves - Advanced Herbalism
  [13882] = {learn=225, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={225,245,265,285}},  -- Enchant Cloak - Lesser Agility
  [13887] = {learn=225, item=0, min=0, max=0, skillupCnt=1, source={}, colors={225,245,265,285}},  -- Enchant Gloves - Strength
  [13890] = {learn=225, item=0, min=0, max=0, skillupCnt=1, source={}, colors={225,245,265,285}},  -- Enchant Boots - Minor Speed
  [13905] = {learn=230, item=0, min=0, max=0, skillupCnt=1, source={}, colors={230,250,270,290}},  -- Enchant Shield - Greater Spirit
  [13915] = {learn=230, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={230,250,270,290}},  -- Enchant Weapon - Demonslaying
  [13917] = {learn=230, item=0, min=0, max=0, skillupCnt=1, source={}, colors={230,250,270,290}},  -- Enchant Chest - Superior Mana
  [13931] = {learn=235, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={235,255,275,295}},  -- Enchant Bracer - Deflection
  [13933] = {learn=235, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={235,255,275,295}},  -- Enchant Shield - Frost Resistance
  [13935] = {learn=235, item=0, min=0, max=0, skillupCnt=1, source={}, colors={235,255,275,295}},  -- Enchant Boots - Agility
  [13937] = {learn=240, item=0, min=0, max=0, skillupCnt=1, source={}, colors={240,260,280,300}},  -- Enchant 2H Weapon - Greater Impact
  [13939] = {learn=240, item=0, min=0, max=0, skillupCnt=1, source={}, colors={240,260,280,300}},  -- Enchant Bracer - Greater Strength
  [13941] = {learn=245, item=0, min=0, max=0, skillupCnt=1, source={}, colors={245,265,285,305}},  -- Enchant Chest - Stats
  [13943] = {learn=245, item=0, min=0, max=0, skillupCnt=1, source={}, colors={245,265,285,305}},  -- Enchant Weapon - Greater Striking
  [13945] = {learn=245, item=0, min=0, max=0, skillupCnt=1, source={2,16}, colors={245,265,285,305}},  -- Enchant Bracer - Greater Stamina
  [13947] = {learn=250, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={250,270,290,310}},  -- Enchant Gloves - Riding Skill
  [13948] = {learn=250, item=0, min=0, max=0, skillupCnt=1, source={}, colors={250,270,290,310}},  -- Enchant Gloves - Minor Haste
  [17180] = {learn=250, item=12655, min=1, max=1, skillupCnt=1, source={}, colors={250,250,255,260}},  -- Enchanted Thorium
  [17181] = {learn=250, item=12810, min=1, max=1, skillupCnt=1, source={}, colors={250,250,255,260}},  -- Enchanted Leather
  [25127] = {learn=250, item=20747, min=0, max=0, skillupCnt=1, source={5}, colors={250,260,270,280}},  -- Lesser Mana Oil
  [20008] = {learn=255, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={255,275,295,315}},  -- Enchant Bracer - Greater Intellect
  [20020] = {learn=260, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={260,280,300,320}},  -- Enchant Boots - Greater Stamina
  [13898] = {learn=265, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={265,285,305,325}},  -- Enchant Weapon - Fiery Weapon
  [15596] = {learn=265, item=11811, min=1, max=1, skillupCnt=1, source={2}, colors={265,285,305,325}},  -- Smoking Heart of the Mountain
  [20014] = {learn=265, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={265,285,305,325}},  -- Enchant Cloak - Greater Resistance
  [20017] = {learn=265, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={265,285,305,325}},  -- Enchant Shield - Greater Stamina
  [20009] = {learn=270, item=0, min=0, max=0, skillupCnt=1, source={2,16}, colors={270,290,310,330}},  -- Enchant Bracer - Superior Spirit
  [20012] = {learn=270, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={270,290,310,330}},  -- Enchant Gloves - Greater Agility
  [20024] = {learn=275, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={275,295,315,335}},  -- Enchant Boots - Spirit
  [20026] = {learn=275, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={275,295,315,335}},  -- Enchant Chest - Major Health
  [25128] = {learn=275, item=20750, min=0, max=0, skillupCnt=1, source={5}, colors={275,285,295,305}},  -- Wizard Oil
  [20016] = {learn=280, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={280,300,320,340}},  -- Enchant Shield - Superior Spirit
  [20015] = {learn=285, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={285,300,317,335}},  -- Enchant Cloak - Superior Defense
  [20029] = {learn=285, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={285,300,317,335}},  -- Enchant Weapon - Icy Chill
  [20028] = {learn=290, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={290,305,322,340}},  -- Enchant Chest - Major Mana
  [20051] = {learn=290, item=16207, min=1, max=1, skillupCnt=1, source={5}, colors={290,305,322,340}},  -- Runed Arcanite Rod
  [23799] = {learn=290, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={290,305,322,340}},  -- Enchant Weapon - Strength
  [23800] = {learn=290, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={290,305,322,340}},  -- Enchant Weapon - Agility
  [23801] = {learn=290, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={290,305,322,340}},  -- Enchant Bracer - Mana Regeneration
  [27837] = {learn=290, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={290,305,322,340}},  -- Enchant 2H Weapon - Agility
  [20010] = {learn=295, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={295,310,325,340}},  -- Enchant Bracer - Superior Strength
  [20013] = {learn=295, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={295,310,325,340}},  -- Enchant Gloves - Greater Strength
  [20023] = {learn=295, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={295,310,325,340}},  -- Enchant Boots - Greater Agility
  [20030] = {learn=295, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={295,310,325,340}},  -- Enchant 2H Weapon - Superior Impact
  [20033] = {learn=295, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={295,310,325,340}},  -- Enchant Weapon - Unholy Weapon
  [20011] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={300,310,325,340}},  -- Enchant Bracer - Superior Stamina
  [20025] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={300,310,325,340}},  -- Enchant Chest - Greater Stats
  [20031] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={300,310,325,340}},  -- Enchant Weapon - Superior Striking
  [20032] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={300,310,325,340}},  -- Enchant Weapon - Lifestealing
  [20034] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={300,310,325,340}},  -- Enchant Weapon - Crusader
  [20035] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={300,310,325,340}},  -- Enchant 2H Weapon - Major Spirit
  [20036] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={300,310,325,340}},  -- Enchant 2H Weapon - Major Intellect
  [22749] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={300,310,325,340}},  -- Enchant Weapon - Spell Power
  [22750] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={300,310,325,340}},  -- Enchant Weapon - Healing Power
  [23802] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={300,310,325,340}},  -- Enchant Bracer - Healing Power
  [23803] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={300,310,325,340}},  -- Enchant Weapon - Mighty Spirit
  [23804] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={300,310,325,340}},  -- Enchant Weapon - Mighty Intellect
  [25072] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={2,5}, colors={300,310,325,340}},  -- Enchant Gloves - Threat
  [25073] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={300,310,325,340}},  -- Enchant Gloves - Shadow Power
  [25074] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={300,310,325,340}},  -- Enchant Gloves - Frost Power
  [25078] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={300,310,325,340}},  -- Enchant Gloves - Fire Power
  [25079] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={300,310,325,340}},  -- Enchant Gloves - Healing Power
  [25080] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={2,5}, colors={300,310,325,340}},  -- Enchant Gloves - Superior Agility
  [25081] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={300,310,325,340}},  -- Enchant Cloak - Greater Fire Resistance
  [25082] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={300,310,325,340}},  -- Enchant Cloak - Greater Nature Resistance
  [25083] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={2,5}, colors={300,310,325,340}},  -- Enchant Cloak - Stealth
  [25084] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={2,5}, colors={300,310,325,340}},  -- Enchant Cloak - Subtlety
  [25086] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={2,5}, colors={300,310,325,340}},  -- Enchant Cloak - Dodge
  [25129] = {learn=300, item=20749, min=0, max=0, skillupCnt=1, source={5}, colors={300,310,320,330}},  -- Brilliant Wizard Oil
  [25130] = {learn=300, item=20748, min=0, max=0, skillupCnt=1, source={5}, colors={300,310,320,330}},  -- Brilliant Mana Oil
  [32664] = {learn=300, item=22461, min=1, max=1, skillupCnt=1, source={}, colors={300,310,325,340}},  -- Runed Fel Iron Rod
  [33991] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={}, colors={300,310,325,340}},  -- Enchant Chest - Restore Mana Prime
  [34002] = {learn=300, item=0, min=0, max=0, skillupCnt=1, source={}, colors={300,310,325,340}},  -- Enchant Bracer - Assault
  [42613] = {learn=300, item=22448, min=1, max=1, skillupCnt=1, source={}, colors={0,300,300,305}},  -- Nexus Transformation
  [27899] = {learn=305, item=0, min=0, max=0, skillupCnt=1, source={}, colors={305,315,330,345}},  -- Enchant Bracer - Brawn
  [27948] = {learn=305, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={305,315,330,345}},  -- Enchant Boots - Vitality
  [33993] = {learn=305, item=0, min=0, max=0, skillupCnt=1, source={}, colors={305,315,330,345}},  -- Enchant Gloves - Blasting
  [34001] = {learn=305, item=0, min=0, max=0, skillupCnt=1, source={}, colors={305,315,330,345}},  -- Enchant Bracer - Major Intellect
  [27944] = {learn=310, item=0, min=0, max=0, skillupCnt=1, source={}, colors={310,320,335,350}},  -- Enchant Shield - Tough Shield
  [27961] = {learn=310, item=0, min=0, max=0, skillupCnt=1, source={}, colors={310,320,335,350}},  -- Enchant Cloak - Major Armor
  [28016] = {learn=310, item=22521, min=0, max=0, skillupCnt=1, source={5}, colors={310,310,320,330}},  -- Superior Mana Oil
  [33996] = {learn=310, item=0, min=0, max=0, skillupCnt=1, source={}, colors={310,320,335,350}},  -- Enchant Gloves - Assault
  [34004] = {learn=310, item=0, min=0, max=0, skillupCnt=1, source={}, colors={310,320,335,350}},  -- Enchant Cloak - Greater Agility
  [27905] = {learn=315, item=0, min=0, max=0, skillupCnt=1, source={}, colors={315,325,340,355}},  -- Enchant Bracer - Stats
  [27957] = {learn=315, item=0, min=0, max=0, skillupCnt=1, source={}, colors={315,325,340,355}},  -- Enchant Chest - Exceptional Health
  [27906] = {learn=320, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={320,330,345,360}},  -- Enchant Bracer - Major Defense
  [27950] = {learn=320, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={320,330,345,360}},  -- Enchant Boots - Fortitude
  [33990] = {learn=320, item=0, min=0, max=0, skillupCnt=1, source={}, colors={320,330,345,360}},  -- Enchant Chest - Major Spirit
  [27911] = {learn=325, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={325,335,350,365}},  -- Enchant Bracer - Superior Healing
  [27945] = {learn=325, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={325,335,350,365}},  -- Enchant Shield - Intellect
  [27958] = {learn=325, item=0, min=0, max=0, skillupCnt=1, source={}, colors={325,335,350,365}},  -- Enchant Chest - Exceptional Mana
  [28027] = {learn=325, item=22460, min=1, max=1, skillupCnt=1, source={}, colors={325,325,330,335}},  -- Prismatic Sphere
  [34003] = {learn=325, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={325,335,350,365}},  -- Enchant Cloak - Spell Penetration
  [34009] = {learn=325, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={325,335,350,365}},  -- Enchant Shield - Major Stamina
  [27962] = {learn=330, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={330,340,355,370}},  -- Enchant Cloak - Major Resistance
  [44383] = {learn=330, item=0, min=0, max=0, skillupCnt=1, source={}, colors={330,340,355,370}},  -- Enchant Shield - Resilience
  [27913] = {learn=335, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={335,345,360,375}},  -- Enchant Bracer - Restore Mana Prime
  [28022] = {learn=335, item=22449, min=1, max=1, skillupCnt=1, source={5}, colors={0,0,0,335}},  -- Large Prismatic Shard
  [42615] = {learn=335, item=22448, min=3, max=3, skillupCnt=1, source={}, colors={0,0,335,335}},  -- Small Prismatic Shard
  [27946] = {learn=340, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={340,350,365,380}},  -- Enchant Shield - Shield Block
  [27951] = {learn=340, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={340,350,365,380}},  -- Enchant Boots - Dexterity
  [27967] = {learn=340, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={340,350,365,380}},  -- Enchant Weapon - Major Striking
  [27968] = {learn=340, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={340,350,365,380}},  -- Enchant Weapon - Major Intellect
  [28019] = {learn=340, item=22522, min=0, max=0, skillupCnt=1, source={5}, colors={340,340,350,360}},  -- Superior Wizard Oil
  [33995] = {learn=340, item=0, min=0, max=0, skillupCnt=1, source={}, colors={340,350,365,380}},  -- Enchant Gloves - Major Strength
  [27960] = {learn=345, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={345,355,370,385}},  -- Enchant Chest - Exceptional Stats
  [33992] = {learn=345, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={345,355,370,385}},  -- Enchant Chest - Major Resilience
  [27914] = {learn=350, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={350,360,375,390}},  -- Enchant Bracer - Fortitude
  [27971] = {learn=350, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={350,360,375,390}},  -- Enchant 2H Weapon - Savagery
  [27972] = {learn=350, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={350,360,375,390}},  -- Enchant Weapon - Potency
  [27975] = {learn=350, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={350,360,375,390}},  -- Enchant Weapon - Major Spellpower
  [28028] = {learn=350, item=22459, min=1, max=1, skillupCnt=1, source={}, colors={350,360,375,390}},  -- Void Sphere
  [32665] = {learn=350, item=22462, min=1, max=1, skillupCnt=1, source={5}, colors={350,360,375,390}},  -- Runed Adamantite Rod
  [33999] = {learn=350, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={350,360,375,390}},  -- Enchant Gloves - Major Healing
  [34005] = {learn=350, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={350,360,375,390}},  -- Enchant Cloak - Greater Arcane Resistance
  [34006] = {learn=350, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={350,360,375,390}},  -- Enchant Cloak - Greater Shadow Resistance
  [34010] = {learn=350, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={350,360,375,390}},  -- Enchant Weapon - Major Healing
  [42620] = {learn=350, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={350,360,367,375}},  -- Enchant Weapon - Greater Agility
  [46578] = {learn=350, item=0, min=0, max=0, skillupCnt=1, source={}, colors={350,350,357,365}},  -- Enchant Weapon - Deathfrost
  [27917] = {learn=360, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={360,370,385,400}},  -- Enchant Bracer - Spellpower
  [27920] = {learn=360, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={360,370,385,400}},  -- Enchant Ring - Striking
  [27924] = {learn=360, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={360,370,385,400}},  -- Enchant Ring - Spellpower
  [27947] = {learn=360, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={360,370,385,400}},  -- Enchant Shield - Resistance
  [27977] = {learn=360, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={360,370,385,400}},  -- Enchant 2H Weapon - Major Agility
  [28003] = {learn=360, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={360,370,385,400}},  -- Enchant Weapon - Spellsurge
  [28004] = {learn=360, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={360,370,385,400}},  -- Enchant Weapon - Battlemaster
  [33994] = {learn=360, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={360,370,385,400}},  -- Enchant Gloves - Spell Strike
  [33997] = {learn=360, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={360,370,385,400}},  -- Enchant Gloves - Major Spellpower
  [34007] = {learn=360, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={360,370,385,400}},  -- Enchant Boots - Cat's Swiftness
  [34008] = {learn=360, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={360,370,385,400}},  -- Enchant Boots - Boar's Speed
  [46594] = {learn=360, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={360,370,385,400}},  -- Enchant Chest - Defense
  [27926] = {learn=370, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={370,380,395,410}},  -- Enchant Ring - Healing Power
  [27954] = {learn=370, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={370,380,395,410}},  -- Enchant Boots - Surefooted
  [27927] = {learn=375, item=0, min=0, max=0, skillupCnt=1, source={5}, colors={375,385,400,415}},  -- Enchant Ring - Stats
  [27981] = {learn=375, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={375,385,400,415}},  -- Enchant Weapon - Sunfire
  [27982] = {learn=375, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={375,385,400,415}},  -- Enchant Weapon - Soulfrost
  [27984] = {learn=375, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={375,385,400,415}},  -- Enchant Weapon - Mongoose
  [32667] = {learn=375, item=22463, min=1, max=1, skillupCnt=1, source={5}, colors={0,375,385,400}},  -- Runed Eternium Rod
  [42974] = {learn=375, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={375,385,400,415}},  -- Enchant Weapon - Executioner
  [45765] = {learn=375, item=22449, min=2, max=2, skillupCnt=1, source={5}, colors={0,0,0,375}},  -- Void Shatter
  [47051] = {learn=375, item=0, min=0, max=0, skillupCnt=1, source={2}, colors={375,380,395,410}},  -- Enchant Cloak - Steelweave
  -- skillLine 755
  [26926] = {learn=5, item=21932, min=1, max=1, skillupCnt=1, source={}, colors={5,35,50,65}},  -- Heavy Copper Ring
  [25255] = {learn=20, item=20816, min=1, max=1, skillupCnt=1, source={}, colors={0,20,35,50}},  -- Delicate Copper Wire
  [32178] = {learn=20, item=25438, min=1, max=1, skillupCnt=1, source={}, colors={20,50,65,80}},  -- Malachite Pendant
  [32179] = {learn=20, item=25439, min=1, max=1, skillupCnt=1, source={}, colors={20,50,65,80}},  -- Tigerseye Band
  [25283] = {learn=30, item=20821, min=1, max=1, skillupCnt=1, source={}, colors={30,60,75,90}},  -- Inlaid Malachite Ring
  [25493] = {learn=30, item=20906, min=1, max=1, skillupCnt=1, source={}, colors={0,30,45,60}},  -- Braided Copper Ring
  [26925] = {learn=30, item=21931, min=1, max=1, skillupCnt=1, source={}, colors={0,30,45,60}},  -- Woven Copper Ring
  [26928] = {learn=30, item=21934, min=1, max=1, skillupCnt=1, source={}, colors={30,60,75,90}},  -- Ornate Tigerseye Necklace
  [32259] = {learn=30, item=25498, min=1, max=1, skillupCnt=1, source={}, colors={0,30,40,50}},  -- Rough Stone Statue
  [25278] = {learn=50, item=20817, min=1, max=1, skillupCnt=1, source={}, colors={50,70,80,90}},  -- Bronze Setting
  [25280] = {learn=50, item=20818, min=1, max=1, skillupCnt=1, source={}, colors={50,80,95,110}},  -- Elegant Silver Ring
  [25490] = {learn=50, item=20907, min=1, max=1, skillupCnt=1, source={}, colors={50,80,95,110}},  -- Solid Bronze Ring
  [26927] = {learn=50, item=21933, min=1, max=1, skillupCnt=1, source={}, colors={50,80,95,110}},  -- Thick Bronze Necklace
  [32801] = {learn=50, item=25880, min=1, max=1, skillupCnt=1, source={}, colors={50,70,80,90}},  -- Coarse Stone Statue
  [25284] = {learn=60, item=20820, min=1, max=1, skillupCnt=1, source={}, colors={60,90,105,120}},  -- Simple Pearl Ring
  [37818] = {learn=65, item=30804, min=1, max=1, skillupCnt=1, source={}, colors={65,95,110,125}},  -- Bronze Band of Force
  [25287] = {learn=70, item=20823, min=1, max=1, skillupCnt=1, source={}, colors={70,100,115,130}},  -- Gloom Band
  [36523] = {learn=75, item=30419, min=1, max=1, skillupCnt=1, source={}, colors={75,105,120,135}},  -- Brilliant Necklace
  [25317] = {learn=80, item=20827, min=1, max=1, skillupCnt=1, source={}, colors={80,110,125,140}},  -- Ring of Silver Might
  [38175] = {learn=80, item=31154, min=1, max=1, skillupCnt=1, source={}, colors={80,110,125,140}},  -- Bronze Torc
  [25305] = {learn=90, item=20826, min=1, max=1, skillupCnt=1, source={}, colors={90,120,135,150}},  -- Heavy Silver Ring
  [25318] = {learn=100, item=20828, min=1, max=1, skillupCnt=1, source={}, colors={100,130,145,160}},  -- Ring of Twilight Shadows
  [36524] = {learn=105, item=30420, min=1, max=1, skillupCnt=1, source={}, colors={105,135,150,165}},  -- Heavy Jade Ring
  [25339] = {learn=110, item=20830, min=1, max=1, skillupCnt=1, source={5}, colors={110,140,155,170}},  -- Amulet of the Moon
  [25498] = {learn=110, item=20909, min=1, max=1, skillupCnt=1, source={}, colors={110,140,155,170}},  -- Barbaric Iron Collar
  [32807] = {learn=110, item=25881, min=1, max=1, skillupCnt=1, source={}, colors={110,120,130,140}},  -- Heavy Stone Statue
  [25321] = {learn=120, item=20832, min=1, max=1, skillupCnt=1, source={}, colors={120,150,165,180}},  -- Moonsoul Crown
  [25610] = {learn=120, item=20950, min=1, max=1, skillupCnt=1, source={5}, colors={120,150,165,180}},  -- Pendant of the Agate Shield
  [25323] = {learn=125, item=20833, min=1, max=1, skillupCnt=1, source={5}, colors={125,155,170,185}},  -- Wicked Moonstone Ring
  [25612] = {learn=125, item=20954, min=1, max=1, skillupCnt=1, source={5}, colors={125,155,170,185}},  -- Heavy Iron Knuckles
  [25613] = {learn=135, item=20955, min=1, max=1, skillupCnt=1, source={}, colors={135,165,180,195}},  -- Golden Dragon Ring
  [25320] = {learn=150, item=20831, min=1, max=1, skillupCnt=1, source={5}, colors={150,180,195,210}},  -- Heavy Golden Necklace of Battle
  [25615] = {learn=150, item=20963, min=1, max=1, skillupCnt=1, source={}, colors={150,170,180,190}},  -- Mithril Filigree
  [25617] = {learn=150, item=20958, min=1, max=1, skillupCnt=1, source={5}, colors={150,180,195,210}},  -- Blazing Citrine Ring
  [25618] = {learn=160, item=20966, min=1, max=1, skillupCnt=1, source={2}, colors={160,190,205,220}},  -- Jade Pendant of Blasting
  [25619] = {learn=170, item=20959, min=1, max=1, skillupCnt=1, source={5}, colors={170,200,215,230}},  -- The Jade Eye
  [25620] = {learn=170, item=20960, min=1, max=1, skillupCnt=1, source={}, colors={170,200,215,230}},  -- Engraved Truesilver Ring
  [32808] = {learn=175, item=25882, min=1, max=1, skillupCnt=1, source={}, colors={175,175,185,195}},  -- Solid Stone Statue
  [25621] = {learn=180, item=20961, min=1, max=1, skillupCnt=1, source={}, colors={180,210,225,240}},  -- Citrine Ring of Rapid Healing
  [34955] = {learn=180, item=29157, min=1, max=1, skillupCnt=1, source={}, colors={180,190,200,210}},  -- Golden Ring of Power
  [25622] = {learn=190, item=20967, min=1, max=1, skillupCnt=1, source={2,16}, colors={190,220,235,250}},  -- Citrine Pendant of Golden Healing
  [26872] = {learn=200, item=21748, min=1, max=1, skillupCnt=1, source={}, colors={200,225,240,255}},  -- Figurine - Jade Owl
  [26873] = {learn=200, item=21756, min=1, max=1, skillupCnt=1, source={2}, colors={200,225,240,255}},  -- Figurine - Golden Hare
  [34959] = {learn=200, item=29158, min=1, max=1, skillupCnt=1, source={}, colors={200,210,220,230}},  -- Truesilver Commander's Ring
  [26874] = {learn=210, item=20964, min=1, max=1, skillupCnt=1, source={}, colors={210,235,250,265}},  -- Aquamarine Signet
  [26875] = {learn=215, item=21758, min=1, max=1, skillupCnt=1, source={5}, colors={215,240,255,270}},  -- Figurine - Black Pearl Panther
  [26876] = {learn=220, item=21755, min=1, max=1, skillupCnt=1, source={}, colors={220,245,260,275}},  -- Aquamarine Pendant of the Warrior
  [26878] = {learn=225, item=20969, min=1, max=1, skillupCnt=1, source={5}, colors={225,250,265,280}},  -- Ruby Crown of Restoration
  [26880] = {learn=225, item=21752, min=1, max=1, skillupCnt=1, source={}, colors={225,235,245,255}},  -- Thorium Setting
  [26881] = {learn=225, item=21760, min=1, max=1, skillupCnt=1, source={5}, colors={225,250,265,280}},  -- Figurine - Truesilver Crab
  [32809] = {learn=225, item=25883, min=1, max=1, skillupCnt=1, source={}, colors={225,225,235,245}},  -- Dense Stone Statue
  [36525] = {learn=230, item=30421, min=1, max=1, skillupCnt=1, source={}, colors={230,255,270,285}},  -- Red Ring of Destruction
  [26882] = {learn=235, item=21763, min=1, max=1, skillupCnt=1, source={2}, colors={235,260,275,290}},  -- Figurine - Truesilver Boar
  [26883] = {learn=235, item=21764, min=1, max=1, skillupCnt=1, source={}, colors={235,260,275,290}},  -- Ruby Pendant of Fire
  [26885] = {learn=240, item=21765, min=1, max=1, skillupCnt=1, source={}, colors={240,265,280,295}},  -- Truesilver Healing Ring
  [26887] = {learn=245, item=21754, min=1, max=1, skillupCnt=1, source={2}, colors={245,270,285,300}},  -- The Aquamarine Ward
  [26896] = {learn=250, item=21753, min=1, max=1, skillupCnt=1, source={2}, colors={250,275,290,305}},  -- Gem Studded Band
  [26897] = {learn=250, item=21766, min=1, max=1, skillupCnt=1, source={5}, colors={250,275,290,305}},  -- Opal Necklace of Impact
  [26900] = {learn=260, item=21769, min=1, max=1, skillupCnt=1, source={2}, colors={260,280,290,300}},  -- Figurine - Ruby Serpent
  [26902] = {learn=260, item=21767, min=1, max=1, skillupCnt=1, source={}, colors={260,280,290,300}},  -- Simple Opal Ring
  [36526] = {learn=265, item=30422, min=1, max=1, skillupCnt=1, source={}, colors={265,285,295,305}},  -- Diamond Focus Ring
  [26903] = {learn=275, item=21768, min=1, max=1, skillupCnt=1, source={}, colors={275,285,295,305}},  -- Sapphire Signet
  [26906] = {learn=275, item=21774, min=1, max=1, skillupCnt=1, source={5}, colors={275,285,295,305}},  -- Emerald Crown of Destruction
  [26907] = {learn=280, item=21775, min=1, max=1, skillupCnt=1, source={}, colors={280,290,300,310}},  -- Onslaught Ring
  [26908] = {learn=280, item=21790, min=1, max=1, skillupCnt=1, source={}, colors={280,290,300,310}},  -- Sapphire Pendant of Winter Night
  [34960] = {learn=280, item=29159, min=1, max=1, skillupCnt=1, source={}, colors={280,290,300,310}},  -- Glowing Thorium Band
  [26909] = {learn=285, item=21777, min=1, max=1, skillupCnt=1, source={2}, colors={285,295,305,315}},  -- Figurine - Emerald Owl
  [26910] = {learn=285, item=21778, min=1, max=1, skillupCnt=1, source={5}, colors={285,295,305,315}},  -- Ring of Bitter Shadows
  [26911] = {learn=290, item=21791, min=1, max=1, skillupCnt=1, source={}, colors={290,300,310,320}},  -- Living Emerald Pendant
  [34961] = {learn=290, item=29160, min=1, max=1, skillupCnt=1, source={}, colors={290,300,310,320}},  -- Emerald Lion Ring
  [26912] = {learn=300, item=21784, min=1, max=1, skillupCnt=1, source={2}, colors={300,310,320,330}},  -- Figurine - Black Diamond Crab
  [26914] = {learn=300, item=21789, min=1, max=1, skillupCnt=1, source={2}, colors={300,310,320,330}},  -- Figurine - Dark Iron Scorpid
  [28903] = {learn=300, item=23094, min=1, max=1, skillupCnt=1, source={5}, colors={300,300,320,340}},  -- Teardrop Blood Garnet
  [28910] = {learn=300, item=23098, min=1, max=1, skillupCnt=1, source={5}, colors={300,300,320,340}},  -- Inscribed Flame Spessarite
  [28916] = {learn=300, item=23103, min=1, max=1, skillupCnt=1, source={5}, colors={300,300,320,340}},  -- Radiant Deep Peridot
  [28925] = {learn=300, item=23108, min=1, max=1, skillupCnt=1, source={5}, colors={300,300,320,340}},  -- Glowing Shadow Draenite
  [28938] = {learn=300, item=23113, min=1, max=1, skillupCnt=1, source={5}, colors={300,300,320,340}},  -- Brilliant Golden Draenite
  [28950] = {learn=300, item=23118, min=1, max=1, skillupCnt=1, source={5}, colors={300,300,320,340}},  -- Solid Azure Moonstone
  [26915] = {learn=305, item=21792, min=1, max=1, skillupCnt=1, source={5}, colors={305,315,325,335}},  -- Necklace of the Diamond Tower
  [28905] = {learn=305, item=23095, min=1, max=1, skillupCnt=1, source={5}, colors={305,305,325,345}},  -- Bold Blood Garnet
  [28912] = {learn=305, item=23099, min=1, max=1, skillupCnt=1, source={5}, colors={305,305,325,345}},  -- Luminous Flame Spessarite
  [28917] = {learn=305, item=23104, min=1, max=1, skillupCnt=1, source={5}, colors={305,305,325,345}},  -- Jagged Deep Peridot
  [28927] = {learn=305, item=23109, min=1, max=1, skillupCnt=1, source={5}, colors={305,305,325,345}},  -- Royal Shadow Draenite
  [28944] = {learn=305, item=23114, min=1, max=1, skillupCnt=1, source={5}, colors={305,305,325,345}},  -- Gleaming Golden Draenite
  [28953] = {learn=305, item=23119, min=1, max=1, skillupCnt=1, source={5}, colors={305,305,325,345}},  -- Sparkling Azure Moonstone
  [34590] = {learn=305, item=28595, min=1, max=1, skillupCnt=1, source={5}, colors={305,305,325,345}},  -- Bright Blood Garnet
  [26916] = {learn=310, item=21779, min=1, max=1, skillupCnt=1, source={}, colors={310,320,330,340}},  -- Band of Natural Fire
  [31048] = {learn=310, item=24074, min=1, max=1, skillupCnt=1, source={}, colors={310,320,330,340}},  -- Fel Iron Blood Ring
  [31049] = {learn=310, item=24075, min=1, max=1, skillupCnt=1, source={}, colors={310,320,335,350}},  -- Golden Draenite Ring
  [26918] = {learn=315, item=21793, min=1, max=1, skillupCnt=1, source={}, colors={315,325,335,345}},  -- Arcanite Sword Pendant
  [28906] = {learn=315, item=23096, min=1, max=1, skillupCnt=1, source={5}, colors={315,315,335,355}},  -- Runed Blood Garnet
  [28914] = {learn=315, item=23100, min=1, max=1, skillupCnt=1, source={5}, colors={315,315,335,355}},  -- Glinting Flame Spessarite
  [28918] = {learn=315, item=23105, min=1, max=1, skillupCnt=1, source={5}, colors={315,315,335,355}},  -- Enduring Deep Peridot
  [28933] = {learn=315, item=23110, min=1, max=1, skillupCnt=1, source={5}, colors={315,315,335,355}},  -- Shifting Shadow Draenite
  [28947] = {learn=315, item=23115, min=1, max=1, skillupCnt=1, source={5}, colors={315,315,335,355}},  -- Thick Golden Draenite
  [28955] = {learn=315, item=23120, min=1, max=1, skillupCnt=1, source={2}, colors={315,315,335,355}},  -- Stormy Azure Moonstone
  [31050] = {learn=320, item=24076, min=1, max=1, skillupCnt=1, source={}, colors={320,330,340,350}},  -- Azure Moonstone Ring
  [26920] = {learn=325, item=21780, min=1, max=1, skillupCnt=1, source={}, colors={325,335,345,355}},  -- Blood Crown
  [28907] = {learn=325, item=23097, min=1, max=1, skillupCnt=1, source={5}, colors={325,325,340,355}},  -- Delicate Blood Garnet
  [28915] = {learn=325, item=23101, min=1, max=1, skillupCnt=1, source={5}, colors={325,325,340,355}},  -- Potent Flame Spessarite
  [28924] = {learn=325, item=23106, min=1, max=1, skillupCnt=1, source={5}, colors={325,325,340,355}},  -- Dazzling Deep Peridot
  [28936] = {learn=325, item=23111, min=1, max=1, skillupCnt=1, source={5}, colors={325,325,340,355}},  -- Sovereign Shadow Draenite
  [28948] = {learn=325, item=23116, min=1, max=1, skillupCnt=1, source={5}, colors={325,325,340,355}},  -- Rigid Golden Draenite
  [28957] = {learn=325, item=23121, min=1, max=1, skillupCnt=1, source={5}, colors={325,325,340,355}},  -- Lustrous Azure Moonstone
  [34069] = {learn=325, item=28290, min=1, max=1, skillupCnt=1, source={5}, colors={325,325,340,355}},  -- Smooth Golden Draenite
  [38068] = {learn=325, item=31079, min=1, max=1, skillupCnt=1, source={}, colors={325,325,335,345}},  -- Mercurial Adamantite
  [39451] = {learn=325, item=31860, min=1, max=1, skillupCnt=1, source={2}, colors={325,325,340,355}},  -- Great Golden Draenite
  [39455] = {learn=325, item=31862, min=1, max=1, skillupCnt=1, source={2}, colors={325,325,340,355}},  -- Balanced Shadow Draenite
  [39458] = {learn=325, item=31864, min=1, max=1, skillupCnt=1, source={2}, colors={325,325,340,355}},  -- Infused Shadow Draenite
  [39466] = {learn=325, item=31866, min=1, max=1, skillupCnt=1, source={2}, colors={325,325,340,355}},  -- Veiled Flame Spessarite
  [39467] = {learn=325, item=31869, min=1, max=1, skillupCnt=1, source={2}, colors={325,325,340,355}},  -- Wicked Flame Spessarite
  [41414] = {learn=325, item=32772, min=1, max=1, skillupCnt=1, source={}, colors={325,335,345,355}},  -- Brilliant Pearl Band
  [41420] = {learn=325, item=32833, min=1, max=1, skillupCnt=1, source={}, colors={325,325,332,340}},  -- Purified Jaggal Pearl
  [41415] = {learn=330, item=32774, min=1, max=1, skillupCnt=1, source={}, colors={330,340,350,360}},  -- The Black Pearl
  [31051] = {learn=335, item=24077, min=1, max=1, skillupCnt=1, source={}, colors={335,345,355,365}},  -- Thick Adamantite Necklace
  [31052] = {learn=335, item=24078, min=1, max=1, skillupCnt=1, source={}, colors={335,345,355,365}},  -- Heavy Adamantite Ring
  [40514] = {learn=340, item=32508, min=1, max=1, skillupCnt=1, source={}, colors={340,340,355,370}},  -- Necklace of the Deep
  [31058] = {learn=345, item=24087, min=1, max=1, skillupCnt=1, source={2}, colors={345,355,365,375}},  -- Heavy Felsteel Ring
  [31053] = {learn=350, item=24079, min=1, max=1, skillupCnt=1, source={2}, colors={350,360,370,380}},  -- Khorium Band of Shadows
  [31084] = {learn=350, item=24027, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Bold Living Ruby
  [31085] = {learn=350, item=24028, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Delicate Living Ruby
  [31087] = {learn=350, item=24029, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Teardrop Living Ruby
  [31088] = {learn=350, item=24030, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Runed Living Ruby
  [31089] = {learn=350, item=24031, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Bright Living Ruby
  [31090] = {learn=350, item=24032, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Subtle Living Ruby
  [31091] = {learn=350, item=24036, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Flashing Living Ruby
  [31092] = {learn=350, item=24033, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Solid Star of Elune
  [31094] = {learn=350, item=24037, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Lustrous Star of Elune
  [31095] = {learn=350, item=24039, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Stormy Star of Elune
  [31096] = {learn=350, item=24047, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Brilliant Dawnstone
  [31097] = {learn=350, item=24048, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Smooth Dawnstone
  [31098] = {learn=350, item=24051, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Rigid Dawnstone
  [31099] = {learn=350, item=24050, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Gleaming Dawnstone
  [31100] = {learn=350, item=24052, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Thick Dawnstone
  [31101] = {learn=350, item=24053, min=1, max=1, skillupCnt=1, source={5}, colors={350,350,365,380}},  -- Mystic Dawnstone
  [31102] = {learn=350, item=24054, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Sovereign Nightseye
  [31103] = {learn=350, item=24055, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Shifting Nightseye
  [31104] = {learn=350, item=24056, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Glowing Nightseye
  [31105] = {learn=350, item=24057, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Royal Nightseye
  [31106] = {learn=350, item=24058, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Inscribed Noble Topaz
  [31107] = {learn=350, item=24059, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Potent Noble Topaz
  [31108] = {learn=350, item=24060, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Luminous Noble Topaz
  [31109] = {learn=350, item=24061, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Glinting Noble Topaz
  [31110] = {learn=350, item=24062, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Enduring Talasite
  [31111] = {learn=350, item=24066, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Radiant Talasite
  [31112] = {learn=350, item=24065, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Dazzling Talasite
  [31113] = {learn=350, item=24067, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Jagged Talasite
  [31149] = {learn=350, item=24035, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Sparkling Star of Elune
  [39452] = {learn=350, item=31861, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Great Dawnstone
  [39462] = {learn=350, item=31865, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Infused Nightseye
  [39463] = {learn=350, item=31863, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Balanced Nightseye
  [39470] = {learn=350, item=31867, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Veiled Noble Topaz
  [39471] = {learn=350, item=31868, min=1, max=1, skillupCnt=1, source={2}, colors={350,350,365,380}},  -- Wicked Noble Topaz
  [41429] = {learn=350, item=32836, min=1, max=1, skillupCnt=1, source={}, colors={350,350,365,380}},  -- Purified Shadow Pearl
  [43493] = {learn=350, item=33782, min=1, max=1, skillupCnt=1, source={5}, colors={350,350,365,380}},  -- Steady Talasite
  [46403] = {learn=350, item=35315, min=1, max=1, skillupCnt=1, source={5}, colors={350,350,365,380}},  -- Quick Dawnstone
  [46404] = {learn=350, item=35316, min=1, max=1, skillupCnt=1, source={5}, colors={350,350,365,380}},  -- Reckless Noble Topaz
  [46405] = {learn=350, item=35318, min=1, max=1, skillupCnt=1, source={5}, colors={350,350,365,380}},  -- Forceful Talasite
  [46803] = {learn=350, item=35707, min=1, max=1, skillupCnt=1, source={5}, colors={350,350,365,380}},  -- Regal Nightseye
  [47280] = {learn=350, item=35945, min=1, max=1, skillupCnt=1, source={}, colors={350,350,365,380}},  -- Brilliant Glass
  [31054] = {learn=355, item=24080, min=1, max=1, skillupCnt=1, source={2}, colors={355,365,375,385}},  -- Khorium Band of Frost
  [31055] = {learn=355, item=24082, min=1, max=1, skillupCnt=1, source={2}, colors={355,365,375,385}},  -- Khorium Inferno Band
  [31060] = {learn=355, item=24088, min=1, max=1, skillupCnt=1, source={2}, colors={355,365,375,385}},  -- Delicate Eternium Ring
  [31067] = {learn=355, item=24106, min=1, max=1, skillupCnt=1, source={2}, colors={355,365,375,385}},  -- Thick Felsteel Necklace
  [31068] = {learn=355, item=24110, min=1, max=1, skillupCnt=1, source={2}, colors={355,365,375,385}},  -- Living Ruby Pendant
  [31056] = {learn=360, item=24085, min=1, max=1, skillupCnt=1, source={2}, colors={360,370,380,390}},  -- Khorium Band of Leaves
  [31062] = {learn=360, item=24092, min=1, max=1, skillupCnt=1, source={5}, colors={360,370,380,390}},  -- Pendant of Frozen Flame
  [31063] = {learn=360, item=24093, min=1, max=1, skillupCnt=1, source={5}, colors={360,370,380,390}},  -- Pendant of Thawing
  [31064] = {learn=360, item=24095, min=1, max=1, skillupCnt=1, source={5}, colors={360,370,380,390}},  -- Pendant of Withering
  [31065] = {learn=360, item=24097, min=1, max=1, skillupCnt=1, source={5}, colors={360,370,380,390}},  -- Pendant of Shadow's End
  [31066] = {learn=360, item=24098, min=1, max=1, skillupCnt=1, source={5}, colors={360,370,380,390}},  -- Pendant of the Null Rune
  [31070] = {learn=360, item=24114, min=1, max=1, skillupCnt=1, source={2}, colors={360,370,380,390}},  -- Braided Eternium Chain
  [31071] = {learn=360, item=24116, min=1, max=1, skillupCnt=1, source={2}, colors={360,370,380,390}},  -- Eye of the Night
  [37855] = {learn=360, item=30825, min=1, max=1, skillupCnt=1, source={5}, colors={360,370,380,390}},  -- Ring of Arcane Shielding
  [42558] = {learn=360, item=33133, min=1, max=1, skillupCnt=1, source={5}, colors={360,365,370,375}},  -- Don Julio's Heart
  [42588] = {learn=360, item=33134, min=1, max=1, skillupCnt=1, source={5}, colors={360,365,370,375}},  -- Kailee's Rose
  [42589] = {learn=360, item=33131, min=1, max=1, skillupCnt=1, source={5}, colors={360,365,370,375}},  -- Crimson Sun
  [42590] = {learn=360, item=33135, min=1, max=1, skillupCnt=1, source={5}, colors={360,365,370,375}},  -- Falling Star
  [42591] = {learn=360, item=33143, min=1, max=1, skillupCnt=1, source={5}, colors={360,365,370,375}},  -- Stone of Blades
  [42592] = {learn=360, item=33140, min=1, max=1, skillupCnt=1, source={5}, colors={360,365,370,375}},  -- Blood of Amber
  [42593] = {learn=360, item=33144, min=1, max=1, skillupCnt=1, source={5}, colors={360,365,370,375}},  -- Facet of Eternity
  [31057] = {learn=365, item=24086, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Arcane Khorium Band
  [31061] = {learn=365, item=24089, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Blazing Eternium Band
  [31072] = {learn=365, item=24117, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Embrace of the Dawn
  [31076] = {learn=365, item=24121, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Chain of the Twilight Owl
  [32866] = {learn=365, item=25896, min=1, max=1, skillupCnt=1, source={5}, colors={365,375,385,395}},  -- Powerful Earthstorm Diamond
  [32867] = {learn=365, item=25897, min=1, max=1, skillupCnt=1, source={5}, colors={365,375,385,395}},  -- Bracing Earthstorm Diamond
  [32868] = {learn=365, item=25898, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Tenacious Earthstorm Diamond
  [32869] = {learn=365, item=25899, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Brutal Earthstorm Diamond
  [32870] = {learn=365, item=25901, min=1, max=1, skillupCnt=1, source={5}, colors={365,375,385,395}},  -- Insightful Earthstorm Diamond
  [32871] = {learn=365, item=25890, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Destructive Skyfire Diamond
  [32872] = {learn=365, item=25893, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Mystical Skyfire Diamond
  [32873] = {learn=365, item=25894, min=1, max=1, skillupCnt=1, source={5}, colors={365,375,385,395}},  -- Swift Skyfire Diamond
  [32874] = {learn=365, item=25895, min=1, max=1, skillupCnt=1, source={5}, colors={365,375,385,395}},  -- Enigmatic Skyfire Diamond
  [39961] = {learn=365, item=32409, min=1, max=1, skillupCnt=1, source={5}, colors={365,375,385,395}},  -- Relentless Earthstorm Diamond
  [39963] = {learn=365, item=32410, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Thundering Skyfire Diamond
  [41418] = {learn=365, item=32776, min=1, max=1, skillupCnt=1, source={}, colors={365,375,385,395}},  -- Crown of the Sea Witch
  [44794] = {learn=365, item=34220, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,385,395}},  -- Chaotic Skyfire Diamond
  [46122] = {learn=365, item=34362, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Loop of Forged Power
  [46123] = {learn=365, item=34363, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Ring of Flowing Life
  [46124] = {learn=365, item=34361, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Hard Khorium Band
  [46125] = {learn=365, item=34359, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Pendant of Sunfire
  [46126] = {learn=365, item=34360, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Amulet of Flowing Life
  [46127] = {learn=365, item=34358, min=1, max=1, skillupCnt=1, source={2}, colors={365,375,392,410}},  -- Hard Khorium Choker
  [31077] = {learn=370, item=24122, min=1, max=1, skillupCnt=1, source={2}, colors={370,380,390,400}},  -- Coronet of the Verdant Flame
  [31078] = {learn=370, item=24123, min=1, max=1, skillupCnt=1, source={2}, colors={370,380,390,400}},  -- Circlet of Arcane Might
  [31079] = {learn=370, item=24124, min=1, max=1, skillupCnt=1, source={5}, colors={370,380,390,400}},  -- Figurine - Felsteel Boar
  [31080] = {learn=370, item=24125, min=1, max=1, skillupCnt=1, source={5}, colors={370,380,390,400}},  -- Figurine - Dawnstone Crab
  [31081] = {learn=370, item=24126, min=1, max=1, skillupCnt=1, source={5}, colors={370,380,390,400}},  -- Figurine - Living Ruby Serpent
  [31082] = {learn=370, item=24127, min=1, max=1, skillupCnt=1, source={5}, colors={370,380,390,400}},  -- Figurine - Talasite Owl
  [31083] = {learn=370, item=24128, min=1, max=1, skillupCnt=1, source={5}, colors={370,380,390,400}},  -- Figurine - Nightseye Panther
  [46597] = {learn=370, item=35501, min=1, max=1, skillupCnt=1, source={5}, colors={370,380,390,400}},  -- Eternal Earthstorm Diamond
  [46601] = {learn=370, item=35503, min=1, max=1, skillupCnt=1, source={5}, colors={370,380,390,400}},  -- Ember Skyfire Diamond
  [38503] = {learn=375, item=31398, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- The Frozen Eye
  [38504] = {learn=375, item=31399, min=1, max=1, skillupCnt=1, source={5}, colors={375,385,395,405}},  -- The Natural Ward
  [39705] = {learn=375, item=32193, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Bold Crimson Spinel
  [39706] = {learn=375, item=32194, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Delicate Crimson Spinel
  [39710] = {learn=375, item=32195, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Teardrop Crimson Spinel
  [39711] = {learn=375, item=32196, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Runed Crimson Spinel
  [39712] = {learn=375, item=32197, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Bright Crimson Spinel
  [39713] = {learn=375, item=32198, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Subtle Crimson Spinel
  [39714] = {learn=375, item=32199, min=1, max=1, skillupCnt=1, source={2,5}, colors={375,375,387,400}},  -- Flashing Crimson Spinel
  [39715] = {learn=375, item=32200, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Solid Empyrean Sapphire
  [39716] = {learn=375, item=32201, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Sparkling Empyrean Sapphire
  [39717] = {learn=375, item=32202, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Lustrous Empyrean Sapphire
  [39718] = {learn=375, item=32203, min=1, max=1, skillupCnt=1, source={2,5}, colors={375,375,387,400}},  -- Stormy Empyrean Sapphire
  [39719] = {learn=375, item=32204, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Brilliant Lionseye
  [39720] = {learn=375, item=32205, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Smooth Lionseye
  [39721] = {learn=375, item=32206, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Rigid Lionseye
  [39722] = {learn=375, item=32207, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Gleaming Lionseye
  [39723] = {learn=375, item=32208, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Thick Lionseye
  [39724] = {learn=375, item=32209, min=1, max=1, skillupCnt=1, source={2,5}, colors={375,375,387,400}},  -- Mystic Lionseye
  [39725] = {learn=375, item=32210, min=1, max=1, skillupCnt=1, source={2,5}, colors={375,375,387,400}},  -- Great Lionseye
  [39727] = {learn=375, item=32211, min=1, max=1, skillupCnt=1, source={2,5}, colors={375,375,387,400}},  -- Sovereign Shadowsong Amethyst
  [39728] = {learn=375, item=32212, min=1, max=1, skillupCnt=1, source={2,5}, colors={375,375,387,400}},  -- Shifting Shadowsong Amethyst
  [39729] = {learn=375, item=32213, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Balanced Shadowsong Amethyst
  [39730] = {learn=375, item=32214, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Infused Shadowsong Amethyst
  [39731] = {learn=375, item=32215, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Glowing Shadowsong Amethyst
  [39732] = {learn=375, item=32216, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Royal Shadowsong Amethyst
  [39733] = {learn=375, item=32217, min=1, max=1, skillupCnt=1, source={2,5}, colors={375,375,387,400}},  -- Inscribed Pyrestone
  [39734] = {learn=375, item=32218, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Potent Pyrestone
  [39735] = {learn=375, item=32219, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Luminous Pyrestone
  [39736] = {learn=375, item=32220, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Glinting Pyrestone
  [39737] = {learn=375, item=32221, min=1, max=1, skillupCnt=1, source={2,5}, colors={375,375,387,400}},  -- Veiled Pyrestone
  [39738] = {learn=375, item=32222, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Wicked Pyrestone
  [39739] = {learn=375, item=32223, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Enduring Seaspray Emerald
  [39740] = {learn=375, item=32224, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Radiant Seaspray Emerald
  [39741] = {learn=375, item=32225, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Dazzling Seaspray Emerald
  [39742] = {learn=375, item=32226, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Jagged Seaspray Emerald
  [46775] = {learn=375, item=35693, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Figurine - Empyrean Tortoise
  [46776] = {learn=375, item=35694, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Figurine - Khorium Boar
  [46777] = {learn=375, item=35700, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Figurine - Crimson Serpent
  [46778] = {learn=375, item=35702, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Figurine - Shadowsong Panther
  [46779] = {learn=375, item=35703, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Figurine - Seaspray Albatross
  [47053] = {learn=375, item=35759, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Forceful Seaspray Emerald
  [47054] = {learn=375, item=35758, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Steady Seaspray Emerald
  [47055] = {learn=375, item=35760, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Reckless Pyrestone
  [47056] = {learn=375, item=35761, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Quick Lionseye
  [48789] = {learn=375, item=37503, min=1, max=1, skillupCnt=1, source={5}, colors={375,375,387,400}},  -- Purified Shadowsong Amethyst
}
