import csv
import errno
import hashlib
import http.server
import json
import os
from pathlib import Path
import signal
import socket
import sys
from datetime import datetime, timezone
from urllib.parse import unquote, urlsplit
from lxml import html

PROJECT = Path('/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026')
OUT = Path(__file__).parent
LIVE = PROJECT / '_build/nathealth'
CAND = PROJECT / 'audit/report_harmonization/final_site_a4_delta_2026_09_14/candidate_build'
SERVE_ROOT = CAND if sys.argv[1] == 'serve_candidate' else LIVE
LIFECYCLE = 'candidate_lifecycle.json' if sys.argv[1] == 'serve_candidate' else 'lifecycle.json'

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def save(name, data):
    (OUT / name).write_text(json.dumps(data, indent=2) + '\n')

def inv(root):
    paths = list(root.rglob('*'))
    assert not any(p.is_symlink() for p in paths), 'Symlink found'
    return {str(p.relative_to(root)): {'bytes': p.stat().st_size, 'sha256': sha(p)}
            for p in paths if p.is_file()}

def protected():
    paths = ['index.qmd', 'supplementary_information.qmd', '_quarto.yml',
             '_quarto-nathealth.yml', 'styles.css', 'styles-nathealth.css',
             '_includes/nathealth-mobile-toc.html', 'renv.lock',
             'audit/report_harmonization/phase4_corpus_manifest.csv']
    return {p: {'bytes': (PROJECT / p).stat().st_size, 'sha256': sha(PROJECT / p)} for p in paths}

def preflight():
    expected = {}
    with (PROJECT / 'audit/report_harmonization/final_site_promotion_2026_09_14/evidence/post_live_inventory.csv').open() as f:
        for r in csv.DictReader(f):
            expected[r['path']] = {'bytes': int(r['bytes']), 'sha256': r['sha256']}
    live, cand = inv(LIVE), inv(CAND)
    assert live == expected and len(live) == len(cand) == 914
    assert live.keys() == cand.keys()
    delta = [p for p in sorted(live) if live[p] != cand[p]]
    assert len(delta) == 6
    trees = {name: html.fromstring((root / 'index.html').read_bytes()) for name, root in [('live', LIVE), ('candidate', CAND)]}
    code = {name: [s.text or '' for s in tree.xpath('//script') if 'var localhostRegex' in (s.text or '')] for name, tree in trees.items()}
    assert len(code['live']) == 1 and code['live'] == code['candidate']
    raw_links = {name: [{'text': a.text_content(), 'href': a.get('href'), 'target': a.get('target'), 'class': a.get('class')} for a in tree.xpath('//a[contains(@href,"fig-s15") or contains(@href,"fig-s16") or contains(@href,"fig-s17") or contains(@href,"fig-s18")]')][:30] for name, tree in trees.items()}
    snippet = code['live'][0]
    lo, hi = snippet.index('var localhostRegex'), snippet.index('function tippyHover')
    (OUT / 'identical_link_handler.txt').write_text(snippet[lo:hi])
    save('preflight.json', {'time': datetime.now(timezone.utc).isoformat(), 'live': live, 'candidate': cand, 'protected': protected(), 'delta': delta, 'zero_symlinks': True, 'raw_links': raw_links, 'identical_link_handler_sha256': hashlib.sha256(snippet.encode()).hexdigest()})
    print(json.dumps({'preflight': 'PASS', 'live': len(live), 'candidate': len(cand), 'six_file_delta': delta, 'raw_links': raw_links}), flush=True)

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(SERVE_ROOT), **kwargs)
    def list_directory(self, path):
        self.send_error(403, 'Directory listing disabled')
    def translate_path(self, path):
        requested = unquote(urlsplit(path).path)
        result = (SERVE_ROOT / requested.lstrip('/')).resolve()
        if not result.is_relative_to(SERVE_ROOT.resolve()) or any(p.is_symlink() for p in [result, *result.parents] if p.is_relative_to(SERVE_ROOT.resolve())):
            return str(OUT / 'nonexistent-denied')
        return str(result)
    def log_message(self, fmt, *args):
        with (OUT / 'http_requests.log').open('a') as f:
            f.write(self.log_date_time_string() + ' ' + (fmt % args) + '\n')

def serve():
    pre = json.loads((OUT / 'preflight.json').read_text())
    assert inv(LIVE) == pre['live'] and inv(CAND) == pre['candidate'] and protected() == pre['protected']
    server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    state = {'pid': os.getpid(), 'address': '127.0.0.1', 'port': server.server_port, 'root': str(SERVE_ROOT), 'started': datetime.now(timezone.utc).isoformat(), 'read_only_get_head': True, 'status': 'listening'}
    save(LIFECYCLE, state)
    print(json.dumps(state), flush=True)
    def stop(signum, frame):
        raise KeyboardInterrupt
    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
        state.update(status='stopped', stopped=datetime.now(timezone.utc).isoformat())
        save(LIFECYCLE, state)

def postflight():
    pre = json.loads((OUT / 'preflight.json').read_text())
    assert inv(LIVE) == pre['live'] and inv(CAND) == pre['candidate'] and protected() == pre['protected']
    listeners = []
    for f in ['lifecycle.json', 'candidate_lifecycle.json']:
        if not (OUT / f).exists():
            continue
        state = json.loads((OUT / f).read_text())
        s = socket.socket()
        s.settimeout(2)
        result = s.connect_ex(('127.0.0.1', state['port']))
        s.close()
        assert result == errno.ECONNREFUSED and state['status'] == 'stopped', (result, state['status'])
        listeners.append({'port':state['port'], 'pid':state['pid'], 'connect_ex':result})
    summary = {'status': 'PASS', 'live_exact': 914, 'candidate_exact': 914, 'protected_exact': len(pre['protected']), 'no_listener': True, 'listeners': listeners, 'finished': datetime.now(timezone.utc).isoformat()}
    save('postflight.json', summary)
    print(json.dumps(summary))

{'preflight': preflight, 'serve': serve, 'serve_candidate': serve, 'postflight': postflight}[sys.argv[1]]()
