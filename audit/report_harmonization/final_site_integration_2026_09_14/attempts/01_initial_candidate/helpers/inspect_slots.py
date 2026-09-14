"""Read-only implementation boundary inventory; never print embedded payloads."""
from common import *
for p in [LIVE/'index.html',LIVE/'supplementary_information.html',ACCEPTED]:
    raw=p.read_text();tree=doc(p)
    print('\nFILE',label(p))
    print('main-open',raw[span(raw,'main')[0]:raw.index('>',span(raw,'main')[0])+1])
    print('HEAD metadata',[(n.tag,dict(n.attrib),n.text or '') for n in tree.xpath('//head/title|//head/meta')])
    print('STYLES',[(i,len(m[0]),m[0][:130]) for i,m in enumerate(re.finditer(r'<style\b[^>]*>[\s\S]*?</style>',raw))])
    main=one(tree.xpath('//main'))
    print('MAIN children',[(n.tag,n.get('id'),(n.text_content()[:90] if n.tag!='script' else 'SCRIPT')) for n in main if isinstance(n.tag,str)])
    toc=tree.xpath('//*[@id="TOC"]')
    if toc:print('TOC',etree.tostring(toc[0],encoding='unicode')[:14000])
    print('HEADER',segment(raw,'header','title-block-header')[:1600] if 'id="title-block-header"' in raw else 'none')
    if p==ACCEPTED:
        print('CUSTOM_STYLE',[m[0] for m in re.finditer(r'<style\b[^>]*>[\s\S]*?</style>',raw) if 'manuscript-figure' in m[0]][:1])
