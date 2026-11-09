#!/usr/bin/env python3
"""Matched label/pocket measurements and an auditable semantic free-surface mask."""
import argparse
import hashlib
import json
import math
import shutil
from pathlib import Path
from PIL import Image, ImageDraw


def merge_baseline(packet, temporary):
    """Preserve original PNG bytes; add missing scenes and metadata from d400 replay."""
    report = []
    for manifest in sorted((temporary / 'before').glob('manifest-*.json')):
        value = json.loads(manifest.read_text())
        for capture in value['captures']:
            source = temporary / 'before' / capture['file']
            target = packet / 'before' / capture['file']
            identical = True
            if target.exists() and capture["scenario"] not in {"lobby", "scout"}:
                with Image.open(source) as a, Image.open(target) as b:
                    identical = a.size == b.size and a.convert('RGBA').tobytes() == b.convert('RGBA').tobytes()
                capture['existing_before_png_preserved'] = True
            else:
                shutil.copy2(source, target)
                capture['existing_before_png_preserved'] = False
            capture['mask_reference_pixels_equal'] = identical
            report.append(dict(file=capture['file'], existing_before_png_preserved=capture['existing_before_png_preserved'], mask_reference_pixels_equal=identical, sha256=hashlib.sha256(target.read_bytes()).hexdigest()))
        (packet / 'before' / manifest.name).write_text(json.dumps(value, indent=2)+'\n')
    (packet / 'before' / 'preserved-baseline.json').write_text(json.dumps(report, indent=2)+'\n')
    print('Baseline PNGs preserved; missing scenes copied; reference pixel equality:', all(x['mask_reference_pixels_equal'] for x in report))


def mask_capture(directory, capture, pixels):
    assert 'calm_mask_regions' in capture, capture['file']
    width, height = pixels
    mask = Image.new('L', (width, height), 255)
    draw = ImageDraw.Draw(mask)
    for item in capture['calm_mask_regions']:
        x, y, w, h = item['rect']
        x0, y0 = max(0, math.floor(x)), max(0, math.floor(y))
        x1, y1 = min(width, math.ceil(x+w)), min(height, math.ceil(y+h))
        if x1 > x0 and y1 > y0:
            draw.rectangle((x0,y0,x1-1,y1-1), fill=0)
    free = mask.histogram()[255]
    filename = Path(capture['file']).stem+'-calm-mask.png'
    mask.save(directory/filename)
    capture['calm_space_mask'] = filename
    capture['calm_space_share'] = free / (width*height)
    capture['calm_space_pixels'] = free
    return capture


def measure(packet):
    pairs=[]
    for size in ['1688x780','1920x1080']:
        phases={}
        for phase in ['before','after']:
            path=packet/phase/('manifest-'+size+'.json')
            manifest=json.loads(path.read_text())
            for capture in manifest['captures']:
                mask_capture(packet/phase,capture,manifest['pixels'])
            path.write_text(json.dumps(manifest,indent=2)+'\n')
            phases[phase]={c['scenario']:c for c in manifest['captures']}
        assert phases['before'].keys() == phases['after'].keys()
        for scenario,a in phases['before'].items():
            b=phases['after'][scenario]
            assert a['state_sha256']==b['state_sha256'], (size,scenario)
            pair=dict(scenario=scenario,pixels=[int(x) for x in size.split('x')],same_serialized_state=True,state_sha256=a['state_sha256'],source=a['source'],before=dict(image='before/'+a['file'],labels=a['visible_text_count'],pocket_canvas=a['pocket_canvas'],calm_space_share=a['calm_space_share'],mask='before/'+a['calm_space_mask']),after=dict(image='after/'+b['file'],labels=b['visible_text_count'],pocket_canvas=b['pocket_canvas'],calm_space_share=b['calm_space_share'],mask='after/'+b['calm_space_mask']))
            pairs.append(pair)
            print(size,scenario,'labels',a['visible_text_count'],'->',b['visible_text_count'],'pocket',a['pocket_canvas'],'->',b['pocket_canvas'],'free-surface',round(a['calm_space_share']*100,1),'->',round(b['calm_space_share']*100,1))
    report=dict(calm_space_method='Semantic free-surface proxy, measured in native viewport pixels. Occupied mask is the union of visible nonempty text-control rectangles, card face rectangles, action-button rectangles, art frames, stat/cost badges and gold plaque. Remaining pixels are counted as calm; plain tray/playmat/shop surfaces and empty pockets count as calm. Masks are white=calm, black=occupied. Bounds use floor/ceil then clip to viewport. Mask region paths/rectangles are saved with each capture for audit.',calm_space_limitations='This measures free surface, not perceptual complexity: floor marks, tray carving and background grain are not separately subtracted; text rectangles include padding. It is an explicit, identical before/after proxy, not a claim that the perceptual 35-40% target passed. Reader-open rows are reported separately and are not resting-budget scenarios.',pairs=pairs)
    (packet/'pairs.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('packet',type=Path)
    p.add_argument('--merge-baseline',type=Path)
    p.add_argument('--measure',action='store_true')
    a=p.parse_args()
    if a.merge_baseline: merge_baseline(a.packet,a.merge_baseline)
    if a.measure: measure(a.packet)
