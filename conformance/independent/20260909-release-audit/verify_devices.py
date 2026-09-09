"""Validate retained device evidence without promoting the open release gates."""
import hashlib
import json
from pathlib import Path
import re

root = Path(__file__).resolve().parents[4]
record = root / 'mcl-sdk/hardware/dfr1154-autonomous-node/runs/20260909-central-lifecycle'
for line in (record / 'SHA256SUMS.txt').read_text().splitlines():
    digest, name = line.split('  ', 1)
    assert hashlib.sha256((record / name).read_bytes()).hexdigest() == digest, name

results = {}
for name, role in [('final-lifecycle-03', 'central'), ('final-lifecycle-05', 'peripheral')]:
    board = (record / 'logs' / (name + '-board.log')).read_text()
    phone = (record / 'logs' / (name + '-android.log')).read_text()
    session = re.search(r'CONTACT_ESTABLISHED transport=3 profile=1 ses=([0-9A-F]{8})', board)[1]
    own = int(re.search(r'VALUE own_source_ref=(\d+) provenance=LOCAL', board)[1])
    peer = re.search(r'source_ref=([0-9A-F]{8}) provenance=LOCAL', phone)[1]
    assert f'policy: peer_ref={peer} transport=3 -> admit' in board
    assert 'MACHINE policy admit status=0' in phone
    assert f'MACHINE event=3 transport=3 profile=1 peer_ref={own:08X} session_ref={session} status=0' in phone
    result = next(line for line in board.splitlines() if line.startswith('MCLAUTO RESULT '))
    for required in ['zero_prior=true', 'machine=MIGRATED', 'log_dropped=0', 'ble_lost=0']:
        assert required in result, (name, required)
    assert 'MACHINE candidate ready status=3' not in phone
    if role == 'central':
        assert 'acceptor: peer token ' in board and 'BLE result connect=1 ready=1' in board
        assert 'BLE ATT write uuid=' in phone
    else:
        assert 'offerer: advertising own token ' in board
        # This exact regression exercised arrival before readiness service.
        assert phone.index('BLE frame in, 34 bytes') < phone.index('MACHINE candidate ready status=0')
        assert phone.index('MACHINE candidate ready status=0') < phone.index('MACHINE event=2 ')
    results[name] = {'role': role, 'session': session, 'both_endpoints_migrated': True}

retry = (record / 'logs/final-retry-audio.log').read_text()
settled = re.findall(r'BLE settled_retry heap=(\d+) largest=(\d+) dma=(\d+)/(\d+)', retry)
assert len(settled) == 2 and settled[0] == settled[1]
assert 'RETRY_RESOURCE_PASS attempts=2 clients=1 dropped=0' in retry
assert retry.count('MCLAUTO CONTACT 10 bytes at sample') == 2
stop = (record / 'logs/final-stop.log').read_text()
assert 'HOST STOP issued during worker attempt' in stop
assert 'BLE cancel_rc=0' in stop and 'RESULT state=STOPPED' in stop
readback = (record / 'logs/final-readback-sha256.log').read_text()
digest = '0DF1D23A7F710840EB1DD5A85D122C4D1A9DA2E89A15D24E57A540C296E5702C'
assert f'EXPECTED={digest}' in readback and f'READBACK={digest}' in readback
for name in ['contention-01', 'contention-02']:
    board = (record / 'logs' / (name + '-board.log')).read_text()
    assert 'CONTACT_ESTABLISHED' not in board
    assert 'machine=EXHAUSTED' in board
print(json.dumps({'device_regressions': results, 'retry_resources': settled[0],
                  'readback_match': True, 'stop_cancelled': True,
                  'three_machine_qualified': False, 'release_approved': False}, indent=2))
