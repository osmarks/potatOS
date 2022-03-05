import commonmark, os, shutil, json, datetime

css = """
body {
    max-width: 40em;
    text-align: justify;
    font-family: 'Fira Sans', sans-serif;
}

ul {
    list-style-type: square;
    padding: 0;
    padding-left: 1em;
}

code {
    background: black;
    color: white;
    padding: 2px;
}

h1, h2, h3, h4, h5, h6 {
    border-bottom: 1px solid gray;
    margin: 0;
    margin-bottom: 0.5em;
    font-weight: 500;
}

h1 a, h2 a, h3 a, h4 a, h5 a, h6 a {
    color: inherit;
    text-decoration: none;
}

ul p, ol p {
    margin: 0;
}

img {
    width: 100%;
}
"""

def privacy_policy():
    import cmarkgfm
    import re
    from cmarkgfm.cmark import Options as cmarkgfmOptions

    md = open("privacy/index.md").read()
    out = []

    tlcounter = 0
    counter = 0
    after_prelude = False

    for line in md.split("\n"):
        if line == "## Welcome to potatOS!":
            after_prelude = True
        if not after_prelude:
            out.append(line)
            continue
        if re.match(r"^##", line):
            tlcounter += 1
            counter = 0
        if re.match(r"""^[^#]+""", line) and not re.match(r"^[*\[]", line):
            out.append("")
            counter += 1
            out.append(f"""<h3 id="s{tlcounter}-{counter}"><a href="#s{tlcounter}-{counter}">{tlcounter}.{counter}</a></h3>\n""")
        out.append(line)

    out = "\n".join(out)

    local_css = css + """
.spoiler {
    opacity: 0;
    transition: opacity 0.5s;
}

.spoiler:hover {
    opacity: 1;
}
"""
    script = open("privacy/script.js", "r").read()
    mdtext = cmarkgfm.markdown_to_html_with_extensions(out, cmarkgfmOptions.CMARK_OPT_FOOTNOTES | cmarkgfmOptions.CMARK_OPT_UNSAFE)
    return f"""<!DOCTYPE html><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>PotatOS Privacy Policy</title><style>{local_css}</style>\n{mdtext}<div id=contentend></div><script>{script}</script>"""

with open("README.md") as f:
    html = commonmark.commonmark("\n".join(f.read().splitlines()[1:]))

gif_replacer = f"""
const im = document.getElementById("im")
const vids = {json.dumps(os.listdir("images"))}.filter(x => !x.endsWith(".gif"))
if (Math.random() < 0.02) {{
    const v = document.createElement("video")
    v.src = vids[Math.floor(Math.random() * vids.length)]
    v.muted = true
    v.loop = true
    v.autoplay = true
    im.replaceWith(v)
}}
"""

with open("manifest", "r") as f:
    data = f.readlines()
    main = json.loads(data[0])
    meta = json.loads(data[1])

potatos_meta = f"""<div>
Current build: <code>{meta["hash"][:8]}</code> ({main["description"]}), version {main["build"]}, built {datetime.datetime.fromtimestamp(main["timestamp"], tz=datetime.timezone.utc).strftime("%Y-%m-%d %H:%M:%S (UTC)")}.
</div>"""

html = f"""
<!DOCTYPE html>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>PotatOS</title>
<style>{css}</style>
<h1>Welcome to PotatOS!</h1>
<img src="/potatos.gif" id="im">
{potatos_meta}
{html}
<script>{gif_replacer}</script>
"""

os.makedirs("website/privacy", exist_ok=True)
for im in os.listdir("images"):
    shutil.copy(os.path.join("images", im), os.path.join("website", im))
with open("website/index.html", "w") as f:
    f.write(html)
with open("website/privacy/index.html", "w") as f:
    f.write(privacy_policy())