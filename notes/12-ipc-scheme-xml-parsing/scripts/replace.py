from pathlib import Path


p = Path(r'EN_ipc_scheme_20260101.xml')
q = p.with_name(p.stem+'_notext'+p.suffix)

OLD = b'<textBody><title><titlePart>'
NEW = b''

q.write_bytes(p.read_bytes().replace(OLD, NEW))
