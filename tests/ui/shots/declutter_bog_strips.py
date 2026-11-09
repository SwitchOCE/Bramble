#!/usr/bin/env python3
"""Assemble and verify the same real Bog fight's selected before/after moments."""
import argparse
import json
from pathlib import Path
from PIL import Image
from declutter_strips import write_sheet


def assemble(frames_dir, output_dir, fixture_path, revision):
    fixture = json.loads(fixture_path.read_text())
    output_dir.mkdir(parents=True, exist_ok=True)
    summary = []
    for source in sorted(frames_dir.glob('*/manifest.json')):
        manifest = json.loads(source.read_text())
        assert manifest['timing_passes_equal']
        assert manifest['events'] == fixture['combat']['events']
        assert set(manifest['selected_attack_event_indices']) == set(fixture['selected_attack_event_indices'])
        destination = output_dir / source.parent.name
        destination.mkdir(parents=True, exist_ok=True)
        for interval in manifest['attacks']:
            ticks = interval['sample_ticks']
            assert len(ticks) == 8 and len(set(ticks)) == 8
            gaps = [b-a for a, b in zip(ticks, ticks[1:])]
            assert max(gaps)-min(gaps) <= 1
            assert all(f['ancillary_text_nodes'] <= 10 for f in interval['frames'])
            interval['strip'] = write_sheet(source.parent, destination, manifest['pixels'], interval, manifest['fixed_step'])
            with Image.open(destination / interval['strip']) as image:
                assert image.size == (6752, 1640)
            interval['named_moments'] = [kind for kind, moment in fixture['moments'].items() if moment['attack_event_index'] == interval['event_index']]
        manifest.update(production_revision=revision, fixture_provenance=fixture['provenance'], named_moments=fixture['moments'])
        (destination / 'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
        summary.append(dict(run=source.parent.name, production_revision=revision, sheets=len(manifest['attacks']), frames=len(manifest['attacks'])*8, speed=manifest['speed'], reduce_motion=manifest['reduce_motion'], events_sha256=manifest['source_events_sha256'], raw_labels=[min(f['raw_text_nodes'] for i in manifest['attacks'] for f in i['frames']), max(f['raw_text_nodes'] for i in manifest['attacks'] for f in i['frames'])], ancillary_labels=[min(f['ancillary_text_nodes'] for i in manifest['attacks'] for f in i['frames']), max(f['ancillary_text_nodes'] for i in manifest['attacks'] for f in i['frames'])]))
    assert len(summary) == 3
    (output_dir / 'runs.json').write_text(json.dumps(summary, indent=2)+'\n')
    print(f'{output_dir}: {sum(x["sheets"] for x in summary)} sheets / {sum(x["frames"] for x in summary)} frames; equal source events; eight even native samples; budget <=10')


def compare(packet):
    before = json.loads((packet/'before/runs.json').read_text())
    after = json.loads((packet/'after/runs.json').read_text())
    assert len(before) == len(after) == 3
    pairs=[]
    for a,b in zip(before,after):
        assert a['run'] == b['run']
        assert a['events_sha256'] == b['events_sha256']
        pairs.append(dict(run=a['run'], same_event_stream=True, before=a, after=b))
    report=dict(method='Native 1688x780 viewport frames, fixed1/120s discovery + complete replay. Exactly eight evenly spaced frames per actual attack-to-next-attack interval, assembled without scaling into6752x1640 sheets. Before d400831e in isolated git archive. After uses exactly the same serialized full35-event real Combat.run stream. No fresh cold reader or scorer run.', pairs=pairs)
    (packet/'capture-report.json').write_text(json.dumps(report,indent=2)+'\n')
    print('Before/after event-stream equality verified for all three modes')


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('frames',type=Path)
    parser.add_argument('output',type=Path)
    parser.add_argument('fixture',type=Path)
    parser.add_argument('--revision',required=True)
    parser.add_argument('--compare',action='store_true')
    args=parser.parse_args()
    assemble(args.frames,args.output,args.fixture,args.revision)
    if args.compare:
        compare(args.output.parent)
