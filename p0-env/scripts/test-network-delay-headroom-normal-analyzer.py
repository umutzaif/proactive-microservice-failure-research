#!/usr/bin/env python3
import json, subprocess, tempfile
from pathlib import Path
PY=Path(__file__).with_name('analyze-network-delay-headroom-normal.py')
def run(root:Path,windows:list[dict],manifestation=None)->int:
    evidence=root/'manifestation.json';output=root/'analysis.json';evidence.write_text(json.dumps({'run_id':'ob-netdelay-500m-normal-10u-001','slo_id':'p2-network-delay-001-slo-v1','failure_manifestation':manifestation,'windows':windows}),encoding='utf-8')
    return subprocess.run([str(Path(__import__('sys').executable)),str(PY),'--manifestation-evidence',str(evidence),'--run-id','ob-netdelay-500m-normal-10u-001','--workload-profile-id','ob-default-10u-1r-v1','--output',str(output)],capture_output=True,text=True).returncode
def main()->int:
    with tempfile.TemporaryDirectory() as d:
        root=Path(d);full=[{'product_p95_latency_ms':float(i+1)} for i in range(60)]
        assert run(root,full)==0
        analysis=json.loads((root/'analysis.json').read_text());assert analysis['run_level_upper_tail_ms']==60.0 and analysis['valid_headroom_input'] is True
        assert run(root,full[:47])!=0
        assert run(root,full,'2026-08-21T00:00:15Z')!=0
    print('network_delay_headroom_normal_analyzer_positive=passed');print('network_delay_headroom_normal_coverage_negative=passed');print('network_delay_headroom_normal_manifestation_negative=passed');return 0
if __name__=='__main__':raise SystemExit(main())
