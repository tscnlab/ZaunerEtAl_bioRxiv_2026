"""Exercise the real rollback rejection path only on the exact isolated fixture."""
from common import *
from transaction import read_plan,rollback,durable_copy,fsync_dir
assert IS_FIXTURE and TX==OUT/'fixtures/full'
p,events=read_plan();r=p['entries'][0];target=target_path(r['target'])
assert exact(target,r['post_sha256'],r['bytes'])
test_bytes=b'Order016 isolated fixture: deliberately unexpected concurrent bytes.\n'
target.write_bytes(test_bytes)
snapshot=inv(ACTIVE_SITE);journal=(TX/'transaction_journal.jsonl').read_bytes()
rejected=False
try:rollback()
except RuntimeError as exc:
    assert 'Unexpected concurrent target' in str(exc);rejected=True
assert rejected and inv(ACTIVE_SITE)==snapshot and (TX/'transaction_journal.jsonl').read_bytes()==journal
assert target.read_bytes()==test_bytes
safe(E/'guard_injected_bytes.txt').write_bytes(test_bytes)
tmp=TX/'live_site/.fixture-guard-restore.tmp';assert not tmp.exists()
durable_copy(ROOT/r['staged'],tmp);assert exact(tmp,r['post_sha256'],r['bytes'])
assert target.read_bytes()==test_bytes;os.replace(tmp,target);fsync_dir(target.parent)
assert exact(target,r['post_sha256'],r['bytes'])
dump(E/'fixture_guard.json',dict(utc=utc(),fixture_only=True,unexpected_target_rejected=True,all_other_files_and_journal_untouched=True,restored_only_known_injected_fixture_bytes=True,production_writes=0))
