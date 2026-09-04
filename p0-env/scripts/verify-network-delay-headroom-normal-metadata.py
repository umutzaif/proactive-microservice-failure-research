#!/usr/bin/env python3
"""Fail-closed verifier for D-067 no-toxic-proxy normal metadata."""
from __future__ import annotations
import argparse,hashlib,json,subprocess
from datetime import datetime
from pathlib import Path
def load(p):return json.loads(Path(p).read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def sec(a,b):return (datetime.fromisoformat(b.replace('Z','+00:00'))-datetime.fromisoformat(a.replace('Z','+00:00'))).total_seconds()
def verify(repo:Path,path:Path):
 m=load(path);checks=[]
 def c(n,p,o):checks.append({'name':n,'passed':bool(p),'observed':o})
 allowed={'ob-netdelay-500m-normal-15u-001':'ob-second-15u-1r-v1','ob-netdelay-500m-normal-15u-002':'ob-second-15u-1r-v1','ob-netdelay-500m-normal-10u-001':'ob-default-10u-1r-v1','ob-netdelay-500m-normal-10u-002':'ob-default-10u-1r-v1','ob-netdelay-500m-normal-15u-003':'ob-second-15u-1r-v1','ob-netdelay-500m-normal-10u-003':'ob-default-10u-1r-v1','ob-netdelay-500m-normal-15u-004':'ob-second-15u-1r-v1','ob-netdelay-500m-normal-15u-005':'ob-second-15u-1r-v1','ob-netdelay-500m-normal-15u-006':'ob-second-15u-1r-v1','ob-netdelay-500m-normal-10u-004':'ob-default-10u-1r-v1'}
 c('identity',m.get('run_id') in allowed and m.get('workload_profile_id')==allowed.get(m.get('run_id')) and m.get('random_seed')==1 and m.get('experiment_id')=='P2-NETWORK-DELAY-HEADROOM-001' and m.get('run_kind')=='network_delay_normal_baseline',m.get('run_id'))
 c('no_fault',m.get('fault_class')=='normal' and m.get('scientific_fault_started') is False and m.get('normal_topology')=='no_toxic_proxy_overlay',m.get('normal_topology'))
 c('resources',m.get('resources')=={'server_cpu_limit':'500m','server_cpu_request':'100m','proxy_cpu_limit':'100m'},m.get('resources'))
 resolved={}
 for n,pk,hk in [('workload','workload_profile_path','workload_profile_sha256'),('slo','slo_path','slo_sha256'),('clean_pre','proxy_clean_pre_evidence_path','proxy_clean_pre_evidence_sha256'),('clean_post','proxy_clean_post_evidence_path','proxy_clean_post_evidence_sha256'),('manifestation','manifestation_evidence_path','manifestation_evidence_sha256'),('analysis','headroom_input_path','headroom_input_sha256')]:
  raw=m.get(pk,'');p=(repo/raw).resolve()
  try:p.relative_to(repo.resolve());inside=True
  except ValueError:inside=False
  ok=bool(raw) and inside and p.is_file() and sha(p)==m.get(hk);c(n+'_path_hash',ok,raw)
  if ok:resolved[n]=p
 if 'clean_pre' in resolved and 'clean_post' in resolved:
  evidence=[load(resolved['clean_pre']),load(resolved['clean_post'])];c('proxy_clean',all(e.get('after',{}).get('toxics')==[] and e.get('scientific_fault_started') is False and e.get('run_id')==m.get('run_id') for e in evidence),[e.get('after',{}).get('toxics') for e in evidence])
 if 'manifestation' in resolved:c('null_manifestation',load(resolved['manifestation']).get('failure_manifestation') is None,m.get('failure_manifestation'))
 if 'analysis' in resolved:c('headroom_input',load(resolved['analysis']).get('valid_headroom_input') is True,load(resolved['analysis']).get('run_level_upper_tail_ms'))
 p=m.get('phases',{})
 try:c('durations',sec(p['warmup_start_utc'],p['warmup_end_utc'])>=300 and sec(p['normal_baseline_start_utc'],p['normal_baseline_end_utc'])>=300,p)
 except Exception as e:c('durations',False,str(e))
 host=m.get('host_health',{});runtime=m.get('runtime_evidence',{});c('validity',m.get('valid_run') is True and all(host.get(x)==0 for x in ['whea_event_17_delta','kernel_power_41_delta','bugcheck_delta']) and runtime.get('tracked_deployment_count')==15 and runtime.get('pod_lifecycle_stable') is True and runtime.get('proxy_clean_pre_verified') is True and runtime.get('proxy_clean_post_verified') is True and runtime.get('rollback_verified') is True,{'host':host,'runtime':runtime})
 network=m.get('host_network',{});network_ok=network.get('transport') in {'ethernet','wifi'} and network.get('stable') is True and bool(network.get('adapter_name')) and bool(network.get('interface_description')) and bool(network.get('driver_version')) and network.get('privacy_contract')=='ssid_bssid_mac_ip_gateway_omitted' and not any(k in network for k in ['ssid','bssid','mac_address','ip_address','gateway'])
 if network.get('transport')=='wifi':
  raw=network.get('qualification_evidence_path','');qp=(repo/raw).resolve()
  try:qp.relative_to(repo.resolve());inside=True
  except ValueError:inside=False
  network_ok=network_ok and bool(raw) and inside and qp.is_file() and sha(qp)==network.get('qualification_evidence_sha256')
 c('host_network',network_ok,network)
 c('revision',m.get('code_revision')==subprocess.check_output(['git','-C',str(repo),'rev-parse','HEAD'],text=True).strip(),m.get('code_revision'))
 return {'verification_passed':all(x['passed'] for x in checks),'checks':checks}
def main():
 p=argparse.ArgumentParser();p.add_argument('--repo-root',type=Path,default=Path.cwd());p.add_argument('--metadata',type=Path,required=True);a=p.parse_args();r=verify(a.repo_root.resolve(),a.metadata.resolve());print(json.dumps({'verification_passed':r['verification_passed'],'checks':len(r['checks']),'failures':[x for x in r['checks'] if not x['passed']]},sort_keys=True));return 0 if r['verification_passed'] else 1
if __name__=='__main__':raise SystemExit(main())
