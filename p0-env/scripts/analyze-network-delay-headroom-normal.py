#!/usr/bin/env python3
"""Derive the D-067 run-level upper-tail summary from frozen-SLO windows."""
from __future__ import annotations
import argparse, json
from pathlib import Path

def main() -> int:
    parser=argparse.ArgumentParser();parser.add_argument('--manifestation-evidence',type=Path,required=True);parser.add_argument('--run-id',required=True);parser.add_argument('--workload-profile-id',required=True);parser.add_argument('--output',type=Path,required=True);args=parser.parse_args()
    evidence=json.loads(args.manifestation_evidence.read_text(encoding='utf-8-sig'))
    if evidence.get('run_id') != args.run_id: raise ValueError('run_id_mismatch')
    if evidence.get('slo_id') != 'p2-network-delay-001-slo-v1': raise ValueError('slo_id_mismatch')
    windows=evidence.get('windows',[])
    values=[float(item['product_p95_latency_ms']) for item in windows if item.get('product_p95_latency_ms') is not None]
    result={'schema_version':1,'analysis_kind':'network-delay-500m-normal-headroom-input','run_id':args.run_id,'workload_profile_id':args.workload_profile_id,'normal_topology':'no_toxic_proxy_overlay','window_seconds':5,'expected_window_count':60,'complete_window_count':len(windows),'nonempty_product_window_count':len(values),'minimum_nonempty_product_window_count':48,'run_level_upper_tail_definition':'maximum nonempty product-detail 5-second window-p95 latency during baseline','run_level_upper_tail_ms':max(values) if values else None,'failure_manifestation':evidence.get('failure_manifestation'),'coverage_verified':len(windows)==60 and len(values)>=48,'valid_headroom_input':len(windows)==60 and len(values)>=48 and evidence.get('failure_manifestation') is None}
    args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text(json.dumps(result,indent=2,sort_keys=True)+'\n',encoding='utf-8')
    print(json.dumps({'run_id':args.run_id,'upper_tail_ms':result['run_level_upper_tail_ms'],'valid_headroom_input':result['valid_headroom_input']},sort_keys=True))
    return 0 if result['valid_headroom_input'] else 1
if __name__=='__main__': raise SystemExit(main())
