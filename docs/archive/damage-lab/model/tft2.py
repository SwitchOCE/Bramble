exec(open('tft.py').read().split('# TFT live')[0])
tftmap={1:2,3:5,5:8,7:10,9:12,11:17}
report("TFT numbers as-is, 100 HP, 2 rounds per stage", 100, step(tftmap))
report("TFT numbers, 70 HP", 70, step(tftmap))
report("Base 2,4,6,8,10,13,16,20,25 every 1.5 rounds, 60 HP", 60, step({1:2,3:4,5:6,6:8,8:10,10:13,11:16,12:20,13:25}))
