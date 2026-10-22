"""Check the eight-second trace produced by moving_hole_video_diagnostic.patch."""
import csv, json, sys
from pathlib import Path
rows=[]
with Path(sys.argv[1]).open() as f:
    for r in csv.DictReader(f):
        if all(r.get(k) not in (None,'') for k in ('time_10ns','line','hole','attract')):
            rows.append({k:int(v) for k,v in r.items()})
frames=[]; current=[]
for r in rows:
    if current and r['line']<current[-1]['line']:
        frames.append(current);current=[]
    current.append(r)
complete=[f for f in frames if len(f)==313 and all(r['attract']==0 for r in f)]
# First paid frame can contain START's asynchronous clear / initial fill.
settled=complete[2:]
positions=[]
for f in settled:
    active=[r['line'] for r in f if r['hole']]
    assert len(active)==16, (f[0]['time_10ns'],len(active))
    assert active==list(range(active[0],active[0]+16)), active
    assert active[0]>=80 and active[-1]<=243, active
    positions.append(active[0])
deltas=[b-a for a,b in zip(positions,positions[1:])]
assert all(abs(d)==1 for d in deltas),set(deltas)
turns=[{'frame_in_checked_run':i+1,'line':positions[i+1], 'boundary':'top' if a<0 else 'bottom'}
       for i,(a,b) in enumerate(zip(deltas,deltas[1:])) if a!=b]
intervals={b['time_10ns']-a['time_10ns'] for a,b in zip(rows,rows[1:])}
assert intervals=={6370}, intervals
result={'complete_paid_frames_checked':len(settled),'frame_lines':313,'line_ns':63700,
        'first_hole_line_min':min(positions),'first_hole_line_max':max(positions),
        'width':16,'turns':turns,'sim_time_ms':rows[-1]['time_10ns']/1e5}
assert len(settled)>=380, 'Capture is too short'
assert sum(t['boundary']=='top' for t in turns)>=1, 'No upper reversal'
assert sum(t['boundary']=='bottom' for t in turns)>=2, 'Fewer than two lower reversals'
print(json.dumps(result,indent=2))
