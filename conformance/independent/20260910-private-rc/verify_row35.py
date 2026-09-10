"""Verify the original Row 35 invariant against immutable physical receipts."""
from pathlib import Path
import hashlib,json,subprocess,sys
root=Path(__file__).resolve().parents[4]
record=root/'mcl-sdk/hardware/dfr1154-autonomous-node/runs/20260909-contention-closure'
for line in (record/'SHA256SUMS.txt').read_text(encoding='utf-8').splitlines():
    digest,name=line.split('  ',1)
    assert hashlib.sha256((record/name).read_bytes()).hexdigest()==digest,name
result=subprocess.run([sys.executable,str(record/'verify_closure.py'),str(record/'logs')],capture_output=True,text=True,check=True)
cell=json.loads(result.stdout)['cells']['closure-trace-cell1']
assert all(cell['tx_frames'].values()) and all(cell['rx_frames'].values())
assert set(cell['windows_heard_by'])=={'board','android'}
assert cell['matching_pair_migrated'] and cell['no_three_edge_accept_cycle']
assert cell['accept_proposals']==2 and cell['session']=='E0585224'
print(json.dumps({'row35_original_invariant_passed':True,'session':cell,'three_cell_stress_matrix_passed':False,'stable_release_approved':False,'basis':'Original V1_SCOPE 5.10; owner review restores this invariant and treats later stress cells as non-gating.'},indent=2))
