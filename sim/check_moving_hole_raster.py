"""Verify/plot the actual Figure 5/9 moving-hole feedback regression."""
import csv
import sys
from collections import defaultdict
from pathlib import Path
from PIL import Image, ImageDraw

source=Path(sys.argv[1])
output=Path(sys.argv[2])
frames=defaultdict(list)
with source.open() as f:
    for r in csv.DictReader(f):
        row={k:int(v) for k,v in r.items()}
        frames[row['frame']].append(row)
complete=[f for n,f in sorted(frames.items()) if n>=2 and len(f)==313]
assert len(complete)>=990, len(complete)
for name,expected_min in [('raw',95),('sampled',83)]:
    starts=[]
    for f in complete:
        active=[r['line'] for r in f if r[name]]
        assert len(active)==16 and active==list(range(active[0],active[0]+16)),(name,active)
        assert 80<=active[0] and active[-1]<=243,(name,active)
        starts.append(active[0])
    steps=[b-a for a,b in zip(starts,starts[1:])]
    assert all(abs(d)==1 for d in steps),(name,set(steps))
    top=sum(a==-1 and b==1 for a,b in zip(steps,steps[1:]))
    bottom=sum(a==1 and b==-1 for a,b in zip(steps,steps[1:]))
    assert top>=3 and bottom>=3,(top,bottom)
    assert min(starts)==expected_min and max(starts)==224,(name,min(starts),max(starts))
    print(f'{name}: {len(complete)} complete fields, 16-line width, start {min(starts)}..{max(starts)}, top turns={top}, bottom turns={bottom}, no wrap')

count=max(frames)+1
chart=Image.new('RGB',(count+70,691),'#171717');draw=ImageDraw.Draw(chart)
draw.text((12,8),'Actual Figure 5/9 feedback: red=raw boundary; green=sampled boundary; 6/8 presets',fill='white')
for n,rows in frames.items():
    for r in rows:
        y=35+2*r['line']
        if r['raw']:draw.line((60+n,y,60+n,y+1),fill='#ee5555')
        if r['sampled']:draw.line((60+n,y,60+n,y+1),fill='#00ff00')
for line in (0,80,128,240,312):
    y=35+line*2;draw.text((24,y),str(line),fill='white')
    if line in (80,240):draw.line((60,y,count+60,y),fill='#777777')
for n in range(0,count,100):draw.text((60+n,670),str(n),fill='white')
draw.text((6,670),'Frame',fill='white')
chart.save(output/'moving_hole_raster.png')
images=[]
for n in range(2,count-1,4):
    im=Image.new('RGB',(420,360),'#171717');d=ImageDraw.Draw(im)
    d.text((10,8),f'Measured raster diagnostic - frame {n}',fill='white')
    d.text((10,23),'Red: raw wall decode   Green: sampled wall decode',fill='white')
    for line in (80,240):d.line((80,line+40,340,line+40),fill='#777777')
    for r in frames[n]:
        y=r['line']+40
        if r['raw']:d.line((130,y,155,y),fill='#ee5555')
        if r['sampled']:d.line((265,y,290,y),fill='#00ff00')
    images.append(im.quantize(colors=8, dither=Image.NONE))
images[0].save(output/'moving_hole_raster.gif',save_all=True,append_images=images[1:],duration=80,loop=0)
