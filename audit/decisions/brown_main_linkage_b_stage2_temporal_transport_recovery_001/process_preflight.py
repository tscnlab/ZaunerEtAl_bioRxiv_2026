"""Read-only process inventory before the single Brown continuation."""
import datetime,json,pathlib,re,subprocess
root=pathlib.Path(__file__).resolve().parent
output=root/'process_preflight.json'
assert not output.exists()
run=subprocess.run(['/bin/ps','-axo','pid=,ppid=,etime=,command='],capture_output=True,text=True,check=True)
rows=run.stdout.splitlines()
needles=('main_linkage_b_amendment','run_bounded_job_v','brown_adherence/stage2','brown_adherence/13_','brown_adherence/14_')
engine=re.compile(r'(?:^|[ /])(R|Rscript|quarto|pandoc)(?:[ /]|$)|run_bounded_job_v')
matches=[line for line in rows if any(x in line for x in needles) and engine.search(line)
         and 'process_preflight.py' not in line and 'verify_and_seal.R' not in line]
record={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'command':run.args,'exit_code':run.returncode,
        'no_competing_brown_process':not matches,'matching_count':len(matches),'matching_processes':matches,
        'r_metadata_context':[x for x in rows if engine.search(x)]}
output.write_text(json.dumps(record,indent=2)+'\n')
print(json.dumps({k:record[k] for k in ('utc','matching_count','no_competing_brown_process')}))
assert not matches

