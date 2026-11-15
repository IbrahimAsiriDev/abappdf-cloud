"""Embed the demo forms into ZCL_ABAPPDF_DEMO.

forms/ZPDF_TRAVEL.xml goes to TEMPLATE, forms/ZPDF_TRAVEL_AR.xml to TEMPLATE_AR.

Run after changing the demo form in the designer and exporting it to forms/.
"""
import json
import pathlib
import re
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parent.parent
FORMS = (("template", ROOT / "forms" / "ZPDF_TRAVEL.xml"),
         ("template_ar", ROOT / "forms" / "ZPDF_TRAVEL_AR.xml"))
CLASS = ROOT / "src" / "zcl_abappdf_demo.clas.abap"
CHUNK = 180


def lines_for(field, text):
    """ABAP string literals cannot hold line breaks or exceed 255 characters,
    so each line of the text is split into chunks and joined with newline."""
    out = []
    text = text.replace("\r\n", "\n")
    for n, line in enumerate(text.split("\n")):
        if n:
            out.append(f"    rs_template-{field} = rs_template-{field} && cl_abap_char_utilities=>newline.")
        for i in range(0, len(line), CHUNK):
            part = line[i:i + CHUNK].replace("`", "``")
            out.append(f"    rs_template-{field} = rs_template-{field} && `{part}`.")
    return out


def method(name, path):
    form = ET.parse(path).getroot().find("form")
    page = form.find("page").attrib
    sample = (form.findtext("sample") or "{}").strip()
    sample = json.dumps(json.loads(sample), ensure_ascii=False, separators=(",", ":"))
    body = [
        f"  METHOD {name}.",
        f"    rs_template-form_id = `{form.attrib['id']}`.",
        f"    rs_template-page_size = `{page.get('size', 'A4')}`.",
        f"    rs_template-orientation = `{page.get('orientation', 'P')}`.",
        f"    rs_template-margin_top = {int(page.get('top', 10))}.",
        f"    rs_template-margin_right = {int(page.get('right', 10))}.",
        f"    rs_template-margin_bottom = {int(page.get('bottom', 10))}.",
        f"    rs_template-margin_left = {int(page.get('left', 10))}.",
    ]
    for field, tag in (("html", "body"), ("css", "style"), ("header", "header"), ("footer", "footer")):
        body += lines_for(field, form.findtext(tag) or "")
    body += lines_for("sample", sample)
    body.append("  ENDMETHOD.")
    return body


def main():
    src = CLASS.read_text(encoding="utf-8")
    for name, path in FORMS:
        body = method(name, path)
        src, n = re.subn(r"  METHOD %s\.\n.*?  ENDMETHOD\." % name, lambda _: "\n".join(body), src, flags=re.S)
        if n != 1:
            raise SystemExit(f"METHOD {name} not found")
        print(f"{CLASS.name}: {name} has {len(body)} lines")
    CLASS.write_text(src, encoding="utf-8")


main()
