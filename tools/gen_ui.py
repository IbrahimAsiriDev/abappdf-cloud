import base64
import pathlib

root = pathlib.Path(__file__).resolve().parents[1]
html = (root / "web" / "designer.html").read_bytes()
b64 = base64.b64encode(html).decode("ascii")
if "'" in b64 or "\n" in b64:
    raise SystemExit("base64 contains a quote or newline")

chunk = 120
per = chunk * 180
parts = [b64[i:i + per] for i in range(0, len(b64), per)]

lines = []
lines.append("CLASS zcl_abappdf_ui DEFINITION")
lines.append("  PUBLIC")
lines.append("  FINAL")
lines.append("  CREATE PUBLIC.")
lines.append("")
lines.append("  PUBLIC SECTION.")
lines.append("    \"Generated from abap-cloud/web/designer.html.")
lines.append("    \"Regenerate this class when that page changes.")
lines.append("    CLASS-METHODS html")
lines.append("      RETURNING")
lines.append("        VALUE(rv_html) TYPE string.")
lines.append("")
lines.append("  PRIVATE SECTION.")
for i in range(1, len(parts) + 1):
    lines.append("    CLASS-METHODS part_{0:02d}".format(i))
    lines.append("      RETURNING")
    lines.append("        VALUE(rv_b64) TYPE string.")
lines.append("ENDCLASS.")
lines.append("")
lines.append("CLASS zcl_abappdf_ui IMPLEMENTATION.")
lines.append("")
lines.append("  METHOD html.")
lines.append("    DATA lv_b64 TYPE string.")
lines.append("    DATA lv_x TYPE xstring.")
# One statement of every part exceeds ABAP's 255-character line limit.
calls = ["part_{0:02d}( )".format(i) for i in range(1, len(parts) + 1)]
chunk_calls = []
width = 0
first = True
for call in calls:
    extra = len(call) + (0 if not chunk_calls else 4)
    if chunk_calls and width + extra > 180:
        op = "lv_b64 = " if first else "lv_b64 = lv_b64 && "
        lines.append("    {0}{1}.".format(op, " && ".join(chunk_calls)))
        first = False
        chunk_calls = [call]
        width = len(call)
    else:
        chunk_calls.append(call)
        width += extra
if chunk_calls:
    op = "lv_b64 = " if first else "lv_b64 = lv_b64 && "
    lines.append("    {0}{1}.".format(op, " && ".join(chunk_calls)))
lines.append("    lv_x = cl_web_http_utility=>decode_x_base64( lv_b64 ).")
lines.append("    rv_html = cl_abap_conv_codepage=>create_in( )->convert( lv_x ).")
lines.append("  ENDMETHOD.")
lines.append("")
for i, part in enumerate(parts, 1):
    lines.append("  METHOD part_{0:02d}.".format(i))
    pieces = [part[j:j + chunk] for j in range(0, len(part), chunk)]
    lines.append("    rv_b64 = '{0}'.".format(pieces[0]))
    for piece in pieces[1:]:
        lines.append("    rv_b64 = rv_b64 && '{0}'.".format(piece))
    lines.append("  ENDMETHOD.")
    lines.append("")
lines.append("ENDCLASS.")

out = root / "src" / "zcl_abappdf_ui.clas.abap"
out.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
print("parts", len(parts), "b64", len(b64), "lines", len(lines), "bytes", out.stat().st_size)
