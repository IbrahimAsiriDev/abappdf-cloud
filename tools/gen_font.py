"""Build zcl_abappdf_font from the OFL Noto Naskh Arabic subset."""
import pathlib
import tempfile
import urllib.request
import base64

from fontTools.ttLib import TTFont
from fontTools.subset import Subsetter, Options

ROOT = pathlib.Path(__file__).resolve().parents[1]
SRC = ROOT / "src" / "zcl_abappdf_font.clas.abap"
RAW = pathlib.Path(tempfile.gettempdir()) / "NotoNaskhArabic-Regular.ttf"
SUB = pathlib.Path(tempfile.gettempdir()) / "abappdf-arabic.ttf"
URL = (
    "https://github.com/notofonts/notofonts.github.io/raw/main/"
    "fonts/NotoNaskhArabic/full/ttf/NotoNaskhArabic-Regular.ttf"
)

RIGHT = {
    0x0622: (0xFE81, 0xFE82),
    0x0623: (0xFE83, 0xFE84),
    0x0624: (0xFE85, 0xFE86),
    0x0625: (0xFE87, 0xFE88),
    0x0627: (0xFE8D, 0xFE8E),
    0x0629: (0xFE93, 0xFE94),
    0x062F: (0xFEA9, 0xFEAA),
    0x0630: (0xFEAB, 0xFEAC),
    0x0631: (0xFEAD, 0xFEAE),
    0x0632: (0xFEAF, 0xFEB0),
    0x0648: (0xFEED, 0xFEEE),
    0x0649: (0xFEEF, 0xFEF0),
    0x0671: (0xFB50, 0xFB51),
}
DUAL = {
    0x0626: (0xFE89, 0xFE8A, 0xFE8B, 0xFE8C),
    0x0628: (0xFE8F, 0xFE90, 0xFE91, 0xFE92),
    0x062A: (0xFE95, 0xFE96, 0xFE97, 0xFE98),
    0x062B: (0xFE99, 0xFE9A, 0xFE9B, 0xFE9C),
    0x062C: (0xFE9D, 0xFE9E, 0xFE9F, 0xFEA0),
    0x062D: (0xFEA1, 0xFEA2, 0xFEA3, 0xFEA4),
    0x062E: (0xFEA5, 0xFEA6, 0xFEA7, 0xFEA8),
    0x0633: (0xFEB1, 0xFEB2, 0xFEB3, 0xFEB4),
    0x0634: (0xFEB5, 0xFEB6, 0xFEB7, 0xFEB8),
    0x0635: (0xFEB9, 0xFEBA, 0xFEBB, 0xFEBC),
    0x0636: (0xFEBD, 0xFEBE, 0xFEBF, 0xFEC0),
    0x0637: (0xFEC1, 0xFEC2, 0xFEC3, 0xFEC4),
    0x0638: (0xFEC5, 0xFEC6, 0xFEC7, 0xFEC8),
    0x0639: (0xFEC9, 0xFECA, 0xFECB, 0xFECC),
    0x063A: (0xFECD, 0xFECE, 0xFECF, 0xFED0),
    0x0640: (0x0640, 0x0640, 0x0640, 0x0640),
    0x0641: (0xFED1, 0xFED2, 0xFED3, 0xFED4),
    0x0642: (0xFED5, 0xFED6, 0xFED7, 0xFED8),
    0x0643: (0xFED9, 0xFEDA, 0xFEDB, 0xFEDC),
    0x0644: (0xFEDD, 0xFEDE, 0xFEDF, 0xFEE0),
    0x0645: (0xFEE1, 0xFEE2, 0xFEE3, 0xFEE4),
    0x0646: (0xFEE5, 0xFEE6, 0xFEE7, 0xFEE8),
    0x0647: (0xFEE9, 0xFEEA, 0xFEEB, 0xFEEC),
    0x064A: (0xFEF1, 0xFEF2, 0xFEF3, 0xFEF4),
}
LAM_ALEF = {
    0x0622: (0xFEF5, 0xFEF6),
    0x0623: (0xFEF7, 0xFEF8),
    0x0625: (0xFEF9, 0xFEFA),
    0x0627: (0xFEFB, 0xFEFC),
}


def u16(data, off):
    return int.from_bytes(data[off:off + 2], "big")


def i16(data, off):
    value = u16(data, off)
    return value - 65536 if value >= 32768 else value


def u32(data, off):
    return int.from_bytes(data[off:off + 4], "big")


def parse_cmap(data):
    count = u16(data, 4)
    cmap_off = None
    for index in range(count):
        at = 12 + index * 16
        if data[at:at + 4] == b"cmap":
            cmap_off = u32(data, at + 8)
    encodings = u16(data, cmap_off + 2)
    sub = None
    for index in range(encodings):
        plat = u16(data, cmap_off + 4 + index * 8)
        enc = u16(data, cmap_off + 6 + index * 8)
        rel = u32(data, cmap_off + 8 + index * 8)
        if plat == 3 and enc == 1:
            sub = cmap_off + rel
    segments = u16(data, sub + 6) // 2
    end_at = sub + 14
    start_at = end_at + segments * 2 + 2
    delta_at = start_at + segments * 2
    roff_at = delta_at + segments * 2
    mapping = {}
    for index in range(segments):
        end = u16(data, end_at + index * 2)
        start = u16(data, start_at + index * 2)
        delta = i16(data, delta_at + index * 2)
        roff = u16(data, roff_at + index * 2)
        for cp in range(start, end + 1):
            if cp == 0xFFFF:
                continue
            if roff == 0:
                gid = (cp + delta) & 0xFFFF
            else:
                pos = (roff_at + index * 2) + roff + 2 * (cp - start)
                gid = u16(data, pos)
                if gid:
                    gid = (gid + delta) & 0xFFFF
            if gid:
                mapping[cp] = gid
    return mapping


def subset():
    if not RAW.exists():
        urllib.request.urlretrieve(URL, RAW)
    font = TTFont(RAW)
    unicodes = set()
    for start, end in (
        (0x20, 0x7E), (0xA0, 0xFF), (0x600, 0x6FF), (0x750, 0x77F),
        (0x8A0, 0x8FF), (0xFB50, 0xFDFF), (0xFE70, 0xFEFF),
    ):
        unicodes.update(range(start, end + 1))
    unicodes.update((0x200C, 0x200D, 0x200E, 0x200F))
    options = Options()
    options.layout_features = []
    options.drop_tables = ["GSUB", "GPOS", "GDEF", "morx", "kerx", "JSTF", "DSIG", "MATH"]
    options.hinting = False
    options.desubroutinize = True
    options.name_IDs = [0, 1, 2, 3, 4, 5, 6]
    options.notdef_outline = True
    options.recommended_glyphs = True
    tool = Subsetter(options=options)
    tool.populate(unicodes=unicodes)
    tool.subset(font)
    font.save(SUB)
    return font


def case_lines(mapping):
    lines = []
    for cp, forms in sorted(RIGHT.items()):
        isol, fina = forms
        if isol not in mapping:
            isol = cp
        if fina not in mapping:
            fina = isol
        lines.append(
            "      WHEN {0}. ev_isol = {1}. ev_fina = {2}. ev_kind = 'R'.".format(cp, isol, fina)
        )
    for cp, forms in sorted(DUAL.items()):
        isol, fina, init, medi = forms
        if isol not in mapping:
            isol = cp
        if fina not in mapping:
            fina = isol
        if init not in mapping:
            init = isol
        if medi not in mapping:
            medi = init
        lines.append(
            "      WHEN {0}. ev_isol = {1}. ev_fina = {2}. ev_init = {3}. ev_medi = {4}. ev_kind = 'D'.".format(
                cp, isol, fina, init, medi
            )
        )
    return "\n".join(lines)


def lam_lines(mapping):
    lines = []
    for cp, forms in sorted(LAM_ALEF.items()):
        isol, fina = forms
        if isol not in mapping or fina not in mapping:
            raise SystemExit("missing lam-alef {0:04X}".format(cp))
        lines.append("      WHEN {0}. lv_isol = {1}. lv_fina = {2}.".format(cp, isol, fina))
    return "\n".join(lines)


def main():
    font = subset()
    data = SUB.read_bytes()
    expect = {cp: font.getGlyphID(name) for cp, name in font.getBestCmap().items()}
    got = parse_cmap(data)
    if got != expect:
        missing = [cp for cp in expect if got.get(cp) != expect[cp]]
        raise SystemExit("cmap mismatch {0}".format(len(missing)))
    sample = "العملة والمصاريف الاستباقية"
    print("font", len(data), "cmap", len(got), "sample ok")
    b64 = base64.b64encode(data).decode("ascii")
    chunk = 120
    per = chunk * 180
    parts = [b64[i:i + per] for i in range(0, len(b64), per)]
    lines = []
    lines.append("CLASS zcl_abappdf_font DEFINITION")
    lines.append("  PUBLIC")
    lines.append("  FINAL")
    lines.append("  CREATE PUBLIC.")
    lines.append("")
    lines.append("  PUBLIC SECTION.")
    lines.append("    \"Noto Naskh Arabic is used under the SIL Open Font License.")
    lines.append("    \"Regenerate with abap-cloud/tools/gen_font.py.")
    lines.append("    CLASS-METHODS contains")
    lines.append("      IMPORTING iv_text TYPE string")
    lines.append("      RETURNING VALUE(rv_yes) TYPE abap_bool.")
    lines.append("    CLASS-METHODS glyphs")
    lines.append("      IMPORTING iv_text TYPE string")
    lines.append("      RETURNING VALUE(rv_hex) TYPE string.")
    lines.append("    CLASS-METHODS advance")
    lines.append("      IMPORTING iv_text TYPE string")
    lines.append("                iv_size TYPE decfloat34")
    lines.append("      RETURNING VALUE(rv_pt) TYPE decfloat34.")
    lines.append("    CLASS-METHODS objects")
    lines.append("      IMPORTING iv_first TYPE i")
    lines.append("      RETURNING VALUE(rt_obj) TYPE string_table.")
    lines.append("    CONSTANTS object_count TYPE i VALUE 5.")
    lines.append("")
    lines.append("  PRIVATE SECTION.")
    lines.append("    TYPES:")
    lines.append("      BEGIN OF ty_cmap,")
    lines.append("        cp  TYPE i,")
    lines.append("        gid TYPE i,")
    lines.append("      END OF ty_cmap,")
    lines.append("      BEGIN OF ty_item,")
    lines.append("        gid TYPE i,")
    lines.append("        ltr TYPE abap_bool,")
    lines.append("      END OF ty_item.")
    lines.append("    CLASS-DATA gv_ready TYPE abap_bool.")
    lines.append("    CLASS-DATA gv_font TYPE xstring.")
    lines.append("    CLASS-DATA gv_hex TYPE string.")
    lines.append("    CLASS-DATA gv_widths TYPE string.")
    lines.append("    CLASS-DATA gv_unicode TYPE string.")
    lines.append("    CLASS-DATA gv_upem TYPE i.")
    lines.append("    CLASS-DATA gv_ascent TYPE i.")
    lines.append("    CLASS-DATA gv_descent TYPE i.")
    lines.append("    CLASS-DATA gv_xmin TYPE i.")
    lines.append("    CLASS-DATA gv_ymin TYPE i.")
    lines.append("    CLASS-DATA gv_xmax TYPE i.")
    lines.append("    CLASS-DATA gv_ymax TYPE i.")
    lines.append("    CLASS-DATA gt_cmap TYPE HASHED TABLE OF ty_cmap WITH UNIQUE KEY cp.")
    lines.append("    CLASS-DATA gt_adv TYPE STANDARD TABLE OF i WITH EMPTY KEY.")
    for index in range(1, len(parts) + 1):
        lines.append("    CLASS-METHODS part_{0:02d}".format(index))
        lines.append("      RETURNING VALUE(rv_b64) TYPE string.")
    lines.append("    CLASS-METHODS ensure.")
    lines.append("    CLASS-METHODS byte_at")
    lines.append("      IMPORTING iv_x TYPE xstring")
    lines.append("                iv_off TYPE i")
    lines.append("      RETURNING VALUE(rv_n) TYPE i.")
    lines.append("    CLASS-METHODS u16")
    lines.append("      IMPORTING iv_off TYPE i")
    lines.append("      RETURNING VALUE(rv_n) TYPE i.")
    lines.append("    CLASS-METHODS i16")
    lines.append("      IMPORTING iv_off TYPE i")
    lines.append("      RETURNING VALUE(rv_n) TYPE i.")
    lines.append("    CLASS-METHODS u32")
    lines.append("      IMPORTING iv_off TYPE i")
    lines.append("      RETURNING VALUE(rv_n) TYPE i.")
    lines.append("    CLASS-METHODS find_table")
    lines.append("      IMPORTING iv_name TYPE string")
    lines.append("      RETURNING VALUE(rv_off) TYPE i.")
    lines.append("    CLASS-METHODS codepoint")
    lines.append("      IMPORTING iv_ch TYPE string")
    lines.append("      RETURNING VALUE(rv_cp) TYPE i.")
    lines.append("    CLASS-METHODS gid_of")
    lines.append("      IMPORTING iv_cp TYPE i")
    lines.append("      RETURNING VALUE(rv_gid) TYPE i.")
    lines.append("    CLASS-METHODS hex4")
    lines.append("      IMPORTING iv_n TYPE i")
    lines.append("      RETURNING VALUE(rv_hex) TYPE string.")
    lines.append("    CLASS-METHODS presentation")
    lines.append("      IMPORTING iv_cp TYPE i")
    lines.append("      EXPORTING ev_isol TYPE i")
    lines.append("                ev_fina TYPE i")
    lines.append("                ev_init TYPE i")
    lines.append("                ev_medi TYPE i")
    lines.append("                ev_kind TYPE c.")
    lines.append("    CLASS-METHODS lam_alef")
    lines.append("      IMPORTING iv_alef TYPE i")
    lines.append("                iv_final TYPE abap_bool")
    lines.append("      RETURNING VALUE(rv_cp) TYPE i.")
    lines.append("    CLASS-METHODS transparent")
    lines.append("      IMPORTING iv_cp TYPE i")
    lines.append("      RETURNING VALUE(rv_yes) TYPE abap_bool.")
    lines.append("    CLASS-METHODS load.")
    lines.append("    CLASS-METHODS shape")
    lines.append("      IMPORTING iv_text TYPE string")
    lines.append("      EXPORTING ev_hex TYPE string")
    lines.append("                ev_units TYPE i.")
    lines.append("ENDCLASS.")
    lines.append("")
    lines.append("CLASS zcl_abappdf_font IMPLEMENTATION.")
    lines.append("")
    lines.append(BODY.replace("%%CASES%%", case_lines(got)).replace("%%LAM%%", lam_lines(got)))
    lines.append("")
    calls = ["part_{0:02d}( )".format(i) for i in range(1, len(parts) + 1)]
    lines.append("  METHOD ensure.")
    lines.append("    DATA lv_b64 TYPE string.")
    lines.append("    IF gv_ready = abap_true.")
    lines.append("      RETURN.")
    lines.append("    ENDIF.")
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
    lines.append("    gv_font = cl_web_http_utility=>decode_x_base64( lv_b64 ).")
    lines.append("    load( ).")
    lines.append("    gv_ready = abap_true.")
    lines.append("  ENDMETHOD.")
    lines.append("")
    for index, part in enumerate(parts, 1):
        lines.append("  METHOD part_{0:02d}.".format(index))
        pieces = [part[j:j + chunk] for j in range(0, len(part), chunk)]
        lines.append("    rv_b64 = '{0}'.".format(pieces[0]))
        for piece in pieces[1:]:
            lines.append("    rv_b64 = rv_b64 && '{0}'.".format(piece))
        lines.append("  ENDMETHOD.")
        lines.append("")
    lines.append("ENDCLASS.")
    lines.append("")
    SRC.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print("wrote", SRC, "lines", len(lines), "bytes", SRC.stat().st_size)


BODY = r'''
  METHOD contains.
    DATA lv_i TYPE i.
    DATA lv_cp TYPE i.
    DO strlen( iv_text ) TIMES.
      lv_i = sy-index - 1.
      lv_cp = codepoint( substring( val = iv_text off = lv_i len = 1 ) ).
      IF ( lv_cp >= 1536 AND lv_cp <= 1791 ) OR ( lv_cp >= 64336 AND lv_cp <= 65023 )
          OR ( lv_cp >= 65136 AND lv_cp <= 65279 ).
        rv_yes = abap_true.
        RETURN.
      ENDIF.
    ENDDO.
  ENDMETHOD.


  METHOD glyphs.
    DATA lv_units TYPE i.
    shape( EXPORTING iv_text = iv_text IMPORTING ev_hex = rv_hex ev_units = lv_units ).
  ENDMETHOD.


  METHOD advance.
    DATA lv_hex TYPE string.
    DATA lv_units TYPE i.
    shape( EXPORTING iv_text = iv_text IMPORTING ev_hex = lv_hex ev_units = lv_units ).
    IF gv_upem > 0.
      rv_pt = CONV decfloat34( lv_units ) * iv_size / gv_upem.
    ENDIF.
  ENDMETHOD.


  METHOD objects.
    DATA lv_cid TYPE i.
    DATA lv_fd TYPE i.
    DATA lv_file TYPE i.
    DATA lv_tu TYPE i.
    DATA lv_len TYPE i.
    DATA lv_raw TYPE i.
    DATA lv_stream TYPE string.
    DATA lv_obj TYPE string.
    DATA lv_nl TYPE string.
    ensure( ).
    lv_nl = cl_abap_char_utilities=>newline.
    lv_cid = iv_first + 1.
    lv_fd = iv_first + 2.
    lv_file = iv_first + 3.
    lv_tu = iv_first + 4.
    lv_stream = gv_hex && '>'.
    lv_len = strlen( lv_stream ).
    lv_raw = xstrlen( gv_font ).
    lv_obj = |{ iv_first } 0 obj{ lv_nl }| &&
      |<< /Type /Font /Subtype /Type0| &&
      | /BaseFont /NotoNaskhArabic-Regular| &&
      | /Encoding /Identity-H| &&
      | /DescendantFonts [{ lv_cid } 0 R]| &&
      | /ToUnicode { lv_tu } 0 R >>{ lv_nl }endobj{ lv_nl }|.
    APPEND lv_obj TO rt_obj.
    lv_obj = |{ lv_cid } 0 obj{ lv_nl }| &&
      |<< /Type /Font /Subtype /CIDFontType2| &&
      | /BaseFont /NotoNaskhArabic-Regular| &&
      | /CIDSystemInfo << /Registry (Adobe)| &&
      | /Ordering (Identity) /Supplement 0 >>| &&
      | /FontDescriptor { lv_fd } 0 R| &&
      | /CIDToGIDMap /Identity /DW 500| &&
      | /W [{ gv_widths }] >>{ lv_nl }endobj{ lv_nl }|.
    APPEND lv_obj TO rt_obj.
    lv_obj = |{ lv_fd } 0 obj{ lv_nl }| &&
      |<< /Type /FontDescriptor| &&
      | /FontName /NotoNaskhArabic-Regular /Flags 4| &&
      | /FontBBox [{ gv_xmin } { gv_ymin } { gv_xmax } { gv_ymax }]| &&
      | /ItalicAngle 0 /Ascent { gv_ascent }| &&
      | /Descent { gv_descent } /CapHeight { gv_ascent }| &&
      | /StemV 80 /FontFile2 { lv_file } 0 R >>{ lv_nl }endobj{ lv_nl }|.
    APPEND lv_obj TO rt_obj.
    lv_obj = |{ lv_file } 0 obj{ lv_nl }| &&
      |<< /Length { lv_len } /Length1 { lv_raw }| &&
      | /Filter /ASCIIHexDecode >>{ lv_nl }| &&
      |stream{ lv_nl }{ lv_stream }{ lv_nl }| &&
      |endstream{ lv_nl }endobj{ lv_nl }|.
    APPEND lv_obj TO rt_obj.
    lv_obj = |{ lv_tu } 0 obj{ lv_nl }| &&
      |<< /Length { strlen( gv_unicode ) } >>{ lv_nl }| &&
      |stream{ lv_nl }{ gv_unicode }{ lv_nl }| &&
      |endstream{ lv_nl }endobj{ lv_nl }|.
    APPEND lv_obj TO rt_obj.
  ENDMETHOD.


  METHOD byte_at.
    DATA lv_bit TYPE c LENGTH 1.
    DATA lv_pos TYPE i.
    lv_pos = iv_off * 8 + 1.
    DO 8 TIMES.
      GET BIT lv_pos OF iv_x INTO lv_bit.
      IF lv_bit = '1'.
        rv_n = rv_n * 2 + 1.
      ELSE.
        rv_n = rv_n * 2.
      ENDIF.
      lv_pos = lv_pos + 1.
    ENDDO.
  ENDMETHOD.


  METHOD u16.
    rv_n = byte_at( iv_x = gv_font iv_off = iv_off ) * 256
      + byte_at( iv_x = gv_font iv_off = iv_off + 1 ).
  ENDMETHOD.


  METHOD i16.
    rv_n = u16( iv_off ).
    IF rv_n >= 32768.
      rv_n = rv_n - 65536.
    ENDIF.
  ENDMETHOD.


  METHOD u32.
    rv_n = byte_at( iv_x = gv_font iv_off = iv_off ) * 16777216
      + byte_at( iv_x = gv_font iv_off = iv_off + 1 ) * 65536
      + byte_at( iv_x = gv_font iv_off = iv_off + 2 ) * 256
      + byte_at( iv_x = gv_font iv_off = iv_off + 3 ).
  ENDMETHOD.


  METHOD find_table.
    DATA lv_n TYPE i.
    DATA lv_at TYPE i.
    DATA lv_tag TYPE string.
    DATA lv_k TYPE i.
    lv_n = u16( 4 ).
    lv_at = 12.
    DO lv_n TIMES.
      CLEAR lv_tag.
      DO 4 TIMES.
        lv_k = byte_at( iv_x = gv_font iv_off = lv_at + sy-index - 1 ).
        IF lv_k >= 97 AND lv_k <= 122.
          lv_tag = lv_tag && substring( val = 'abcdefghijklmnopqrstuvwxyz' off = lv_k - 97 len = 1 ).
        ENDIF.
      ENDDO.
      IF lv_tag = iv_name.
        rv_off = u32( lv_at + 8 ).
        RETURN.
      ENDIF.
      lv_at = lv_at + 16.
    ENDDO.
  ENDMETHOD.


  METHOD codepoint.
    DATA lv_x TYPE xstring.
    DATA lv_b0 TYPE i.
    DATA lv_b1 TYPE i.
    DATA lv_b2 TYPE i.
    DATA lv_n TYPE i.
    IF iv_ch IS INITIAL.
      RETURN.
    ENDIF.
    lv_x = cl_abap_conv_codepage=>create_out( codepage = 'UTF-8' )->convert( iv_ch ).
    lv_n = xstrlen( lv_x ).
    IF lv_n < 1.
      RETURN.
    ENDIF.
    lv_b0 = byte_at( iv_x = lv_x iv_off = 0 ).
    IF lv_n = 1.
      rv_cp = lv_b0.
      RETURN.
    ENDIF.
    lv_b1 = byte_at( iv_x = lv_x iv_off = 1 ).
    IF lv_n = 2 AND lv_b0 >= 192 AND lv_b0 <= 223.
      rv_cp = ( lv_b0 - 192 ) * 64 + ( lv_b1 - 128 ).
      RETURN.
    ENDIF.
    IF lv_n = 2 AND lv_b0 < 128 AND lv_b1 < 128.
      IF lv_b0 <= lv_b1.
        rv_cp = lv_b0 * 256 + lv_b1.
      ELSE.
        rv_cp = lv_b1 * 256 + lv_b0.
      ENDIF.
      RETURN.
    ENDIF.
    IF lv_n >= 3 AND lv_b0 >= 224 AND lv_b0 <= 239.
      lv_b2 = byte_at( iv_x = lv_x iv_off = 2 ).
      rv_cp = ( lv_b0 - 224 ) * 4096 + ( lv_b1 - 128 ) * 64 + ( lv_b2 - 128 ).
      RETURN.
    ENDIF.
    IF lv_n >= 4 AND lv_b0 = 254 AND lv_b1 = 255.
      rv_cp = byte_at( iv_x = lv_x iv_off = 2 ) * 256
        + byte_at( iv_x = lv_x iv_off = 3 ).
      RETURN.
    ENDIF.
    IF lv_n >= 4 AND lv_b0 = 255 AND lv_b1 = 254.
      rv_cp = byte_at( iv_x = lv_x iv_off = 3 ) * 256
        + byte_at( iv_x = lv_x iv_off = 2 ).
    ENDIF.
  ENDMETHOD.


  METHOD gid_of.
    DATA ls_map TYPE ty_cmap.
    READ TABLE gt_cmap WITH TABLE KEY cp = iv_cp INTO ls_map.
    IF sy-subrc = 0.
      rv_gid = ls_map-gid.
    ENDIF.
  ENDMETHOD.


  METHOD hex4.
    DATA lv_n TYPE i.
    DATA lv_div TYPE i VALUE 4096.
    DATA lv_d TYPE i.
    DATA lv_digits TYPE string VALUE '0123456789ABCDEF'.
    lv_n = iv_n.
    IF lv_n < 0.
      lv_n = 0.
    ENDIF.
    DO 4 TIMES.
      lv_d = lv_n DIV lv_div.
      lv_n = lv_n MOD lv_div.
      lv_div = lv_div DIV 16.
      rv_hex = rv_hex && substring( val = lv_digits off = lv_d len = 1 ).
    ENDDO.
  ENDMETHOD.


  METHOD presentation.
    ev_isol = iv_cp.
    ev_fina = iv_cp.
    ev_init = iv_cp.
    ev_medi = iv_cp.
    ev_kind = 'U'.
    CASE iv_cp.
%%CASES%%
    ENDCASE.
  ENDMETHOD.


  METHOD lam_alef.
    DATA lv_isol TYPE i.
    DATA lv_fina TYPE i.
    CASE iv_alef.
%%LAM%%
      WHEN OTHERS.
        RETURN.
    ENDCASE.
    IF iv_final = abap_true.
      rv_cp = lv_fina.
    ELSE.
      rv_cp = lv_isol.
    ENDIF.
  ENDMETHOD.


  METHOD transparent.
    IF ( iv_cp >= 1611 AND iv_cp <= 1631 ) OR iv_cp = 1648
        OR ( iv_cp >= 1750 AND iv_cp <= 1773 ).
      rv_yes = abap_true.
    ENDIF.
  ENDMETHOD.


  METHOD shape.
    TYPES ty_cps TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    DATA lt_cp TYPE ty_cps.
    DATA lt_item TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.
    DATA ls_item TYPE ty_item.
    DATA lv_i TYPE i.
    DATA lv_n TYPE i.
    DATA lv_cp TYPE i.
    DATA lv_next TYPE i.
    DATA lv_prev TYPE i.
    DATA lv_at TYPE i.
    DATA lv_isol TYPE i.
    DATA lv_fina TYPE i.
    DATA lv_init TYPE i.
    DATA lv_medi TYPE i.
    DATA lv_kind TYPE c.
    DATA lv_nk TYPE c.
    DATA lv_pk TYPE c.
    DATA lv_join_r TYPE abap_bool.
    DATA lv_join_l TYPE abap_bool.
    DATA lv_form TYPE i.
    DATA lv_rtl TYPE abap_bool.
    DATA lv_from TYPE i.
    DATA lv_to TYPE i.
    DATA lv_adv TYPE i.
    DATA lt_hex TYPE string_table.
    ensure( ).
    DO strlen( iv_text ) TIMES.
      lv_at = sy-index - 1.
      APPEND codepoint( substring( val = iv_text off = lv_at len = 1 ) ) TO lt_cp.
    ENDDO.
    lv_n = lines( lt_cp ).
    lv_i = 1.
    WHILE lv_i <= lv_n.
      READ TABLE lt_cp INDEX lv_i INTO lv_cp.
      IF transparent( lv_cp ) = abap_true.
        CLEAR ls_item.
        ls_item-gid = gid_of( lv_cp ).
        APPEND ls_item TO lt_item.
        lv_i = lv_i + 1.
        CONTINUE.
      ENDIF.
      IF lv_cp = 1604 AND lv_i < lv_n.
        READ TABLE lt_cp INDEX lv_i + 1 INTO lv_next.
        lv_form = lam_alef( iv_alef = lv_next iv_final = abap_false ).
        IF lv_form > 0.
          lv_join_r = abap_false.
          lv_at = lv_i - 1.
          WHILE lv_at >= 1.
            READ TABLE lt_cp INDEX lv_at INTO lv_prev.
            IF transparent( lv_prev ) = abap_false.
              presentation( EXPORTING iv_cp = lv_prev IMPORTING ev_kind = lv_pk ).
              IF lv_pk = 'D'.
                lv_join_r = abap_true.
              ENDIF.
              EXIT.
            ENDIF.
            lv_at = lv_at - 1.
          ENDWHILE.
          CLEAR ls_item.
          ls_item-gid = gid_of( lam_alef( iv_alef = lv_next iv_final = lv_join_r ) ).
          APPEND ls_item TO lt_item.
          lv_rtl = abap_true.
          lv_i = lv_i + 2.
          CONTINUE.
        ENDIF.
      ENDIF.
      presentation(
        EXPORTING iv_cp = lv_cp
        IMPORTING ev_isol = lv_isol ev_fina = lv_fina ev_init = lv_init ev_medi = lv_medi ev_kind = lv_kind ).
      IF lv_kind = 'D' OR lv_kind = 'R'.
        lv_rtl = abap_true.
        lv_join_r = abap_false.
        lv_join_l = abap_false.
        lv_at = lv_i - 1.
        WHILE lv_at >= 1.
          READ TABLE lt_cp INDEX lv_at INTO lv_prev.
          IF transparent( lv_prev ) = abap_false.
            presentation( EXPORTING iv_cp = lv_prev IMPORTING ev_kind = lv_pk ).
            IF lv_pk = 'D'.
              lv_join_r = abap_true.
            ENDIF.
            EXIT.
          ENDIF.
          lv_at = lv_at - 1.
        ENDWHILE.
        IF lv_kind = 'D'.
          lv_at = lv_i + 1.
          WHILE lv_at <= lv_n.
            READ TABLE lt_cp INDEX lv_at INTO lv_next.
            IF transparent( lv_next ) = abap_false.
              presentation( EXPORTING iv_cp = lv_next IMPORTING ev_kind = lv_nk ).
              IF lv_nk = 'D' OR lv_nk = 'R'.
                lv_join_l = abap_true.
              ENDIF.
              EXIT.
            ENDIF.
            lv_at = lv_at + 1.
          ENDWHILE.
        ENDIF.
        IF lv_join_r = abap_true AND lv_join_l = abap_true.
          lv_form = lv_medi.
        ELSEIF lv_join_r = abap_true.
          lv_form = lv_fina.
        ELSEIF lv_join_l = abap_true.
          lv_form = lv_init.
        ELSE.
          lv_form = lv_isol.
        ENDIF.
        CLEAR ls_item.
        ls_item-gid = gid_of( lv_form ).
        APPEND ls_item TO lt_item.
      ELSE.
        CLEAR ls_item.
        ls_item-gid = gid_of( lv_cp ).
        IF lv_cp <> 32 AND transparent( lv_cp ) = abap_false
            AND NOT ( ( lv_cp >= 1536 AND lv_cp <= 1791 ) OR ( lv_cp >= 64336 AND lv_cp <= 65023 ) ).
          ls_item-ltr = abap_true.
        ENDIF.
        APPEND ls_item TO lt_item.
      ENDIF.
      lv_i = lv_i + 1.
    ENDWHILE.
    IF lv_rtl = abap_true.
      DATA(lt_rev) = lt_item.
      CLEAR lt_item.
      lv_n = lines( lt_rev ).
      DO lv_n TIMES.
        READ TABLE lt_rev INDEX lv_n - sy-index + 1 INTO ls_item.
        APPEND ls_item TO lt_item.
      ENDDO.
      lv_i = 1.
      WHILE lv_i <= lines( lt_item ).
        READ TABLE lt_item INDEX lv_i INTO ls_item.
        IF ls_item-ltr = abap_false.
          lv_i = lv_i + 1.
          CONTINUE.
        ENDIF.
        lv_from = lv_i.
        lv_to = lv_i.
        WHILE lv_to <= lines( lt_item ).
          READ TABLE lt_item INDEX lv_to INTO ls_item.
          IF ls_item-ltr = abap_false.
            EXIT.
          ENDIF.
          lv_to = lv_to + 1.
        ENDWHILE.
        lv_to = lv_to - 1.
        WHILE lv_from < lv_to.
          READ TABLE lt_item INDEX lv_from INTO ls_item.
          READ TABLE lt_item INDEX lv_to INTO DATA(ls_swap).
          MODIFY lt_item FROM ls_swap INDEX lv_from.
          MODIFY lt_item FROM ls_item INDEX lv_to.
          lv_from = lv_from + 1.
          lv_to = lv_to - 1.
        ENDWHILE.
        lv_i = lv_i + 1.
        WHILE lv_i <= lines( lt_item ).
          READ TABLE lt_item INDEX lv_i INTO ls_item.
          IF ls_item-ltr = abap_false.
            EXIT.
          ENDIF.
          lv_i = lv_i + 1.
        ENDWHILE.
      ENDWHILE.
    ENDIF.
    LOOP AT lt_item INTO ls_item.
      APPEND hex4( ls_item-gid ) TO lt_hex.
      READ TABLE gt_adv INDEX ls_item-gid + 1 INTO lv_adv.
      IF sy-subrc = 0.
        ev_units = ev_units + lv_adv.
      ENDIF.
    ENDLOOP.
    CONCATENATE LINES OF lt_hex INTO ev_hex.
  ENDMETHOD.


  METHOD load.
    DATA lv_cmap TYPE i.
    DATA lv_nenc TYPE i.
    DATA lv_i TYPE i.
    DATA lv_plat TYPE i.
    DATA lv_enc TYPE i.
    DATA lv_sub TYPE i.
    DATA lv_seg TYPE i.
    DATA lv_end_at TYPE i.
    DATA lv_start_at TYPE i.
    DATA lv_delta_at TYPE i.
    DATA lv_roff_at TYPE i.
    DATA lv_end TYPE i.
    DATA lv_start TYPE i.
    DATA lv_delta TYPE i.
    DATA lv_roff TYPE i.
    DATA lv_cp TYPE i.
    DATA lv_gid TYPE i.
    DATA lv_pos TYPE i.
    DATA lv_hhea TYPE i.
    DATA lv_hmtx TYPE i.
    DATA lv_head TYPE i.
    DATA lv_metrics TYPE i.
    DATA lv_glyphs TYPE i.
    DATA lv_adv TYPE i.
    DATA ls_map TYPE ty_cmap.
    TYPES:
      BEGIN OF ty_rev,
        gid TYPE i,
        cp  TYPE i,
      END OF ty_rev.
    DATA lt_rev TYPE SORTED TABLE OF ty_rev WITH UNIQUE KEY gid.
    DATA ls_rev TYPE ty_rev.
    DATA lt_hex TYPE string_table.
    DATA lv_take TYPE i.
    DATA lv_chunk TYPE xstring.
    DATA lv_b TYPE i.
    DATA lv_hi TYPE i.
    DATA lv_lo TYPE i.
    DATA lv_piece TYPE string.
    DATA lv_digits TYPE string VALUE '0123456789ABCDEF'.
    DATA lt_bf TYPE string_table.
    DATA lv_count TYPE i.
    DATA lv_block TYPE string.
    lv_cmap = find_table( 'cmap' ).
    lv_nenc = u16( lv_cmap + 2 ).
    DO lv_nenc TIMES.
      lv_i = sy-index - 1.
      lv_plat = u16( lv_cmap + 4 + lv_i * 8 ).
      lv_enc = u16( lv_cmap + 6 + lv_i * 8 ).
      IF lv_plat = 3 AND lv_enc = 1.
        lv_sub = lv_cmap + u32( lv_cmap + 8 + lv_i * 8 ).
      ENDIF.
    ENDDO.
    lv_seg = u16( lv_sub + 6 ) DIV 2.
    lv_end_at = lv_sub + 14.
    lv_start_at = lv_end_at + lv_seg * 2 + 2.
    lv_delta_at = lv_start_at + lv_seg * 2.
    lv_roff_at = lv_delta_at + lv_seg * 2.
    DO lv_seg TIMES.
      lv_i = sy-index - 1.
      lv_end = u16( lv_end_at + lv_i * 2 ).
      lv_start = u16( lv_start_at + lv_i * 2 ).
      lv_delta = i16( lv_delta_at + lv_i * 2 ).
      lv_roff = u16( lv_roff_at + lv_i * 2 ).
      lv_cp = lv_start.
      WHILE lv_cp <= lv_end AND lv_cp < 65535.
        IF lv_roff = 0.
          lv_gid = lv_cp + lv_delta.
        ELSE.
          lv_pos = lv_roff_at + lv_i * 2 + lv_roff + 2 * ( lv_cp - lv_start ).
          lv_gid = u16( lv_pos ).
          IF lv_gid <> 0.
            lv_gid = lv_gid + lv_delta.
          ENDIF.
        ENDIF.
        WHILE lv_gid < 0.
          lv_gid = lv_gid + 65536.
        ENDWHILE.
        WHILE lv_gid > 65535.
          lv_gid = lv_gid - 65536.
        ENDWHILE.
        IF lv_gid <> 0.
          ls_map-cp = lv_cp.
          ls_map-gid = lv_gid.
          INSERT ls_map INTO TABLE gt_cmap.
        ENDIF.
        lv_cp = lv_cp + 1.
      ENDWHILE.
    ENDDO.
    lv_head = find_table( 'head' ).
    gv_upem = u16( lv_head + 18 ).
    gv_xmin = i16( lv_head + 36 ).
    gv_ymin = i16( lv_head + 38 ).
    gv_xmax = i16( lv_head + 40 ).
    gv_ymax = i16( lv_head + 42 ).
    lv_hhea = find_table( 'hhea' ).
    gv_ascent = i16( lv_hhea + 4 ).
    gv_descent = i16( lv_hhea + 6 ).
    lv_metrics = u16( lv_hhea + 34 ).
    lv_glyphs = u16( find_table( 'maxp' ) + 4 ).
    lv_hmtx = find_table( 'hmtx' ).
    DO lv_glyphs TIMES.
      lv_i = sy-index - 1.
      IF lv_i < lv_metrics.
        lv_adv = u16( lv_hmtx + lv_i * 4 ).
      ENDIF.
      APPEND lv_adv TO gt_adv.
    ENDDO.
    gv_widths = |0 [|.
    LOOP AT gt_adv INTO lv_adv.
      gv_widths = gv_widths && | { lv_adv }|.
    ENDLOOP.
    gv_widths = gv_widths && | ]|.
    LOOP AT gt_cmap INTO ls_map.
      READ TABLE lt_rev WITH TABLE KEY gid = ls_map-gid INTO ls_rev.
      IF sy-subrc <> 0.
        ls_rev-gid = ls_map-gid.
        ls_rev-cp = ls_map-cp.
        INSERT ls_rev INTO TABLE lt_rev.
      ELSEIF ls_rev-cp >= 64336 AND ls_map-cp < 64336.
        ls_rev-cp = ls_map-cp.
        MODIFY TABLE lt_rev FROM ls_rev.
      ENDIF.
    ENDLOOP.
    LOOP AT lt_rev INTO ls_rev.
      IF lv_count = 100.
        lv_block = lv_block && |{ lv_count } beginbfchar{ cl_abap_char_utilities=>newline }|.
        LOOP AT lt_bf INTO DATA(lv_bf).
          lv_block = lv_block && lv_bf && cl_abap_char_utilities=>newline.
        ENDLOOP.
        lv_block = lv_block && |endbfchar{ cl_abap_char_utilities=>newline }|.
        CLEAR lt_bf.
        CLEAR lv_count.
      ENDIF.
      APPEND |<{ hex4( ls_rev-gid ) }> <{ hex4( ls_rev-cp ) }>| TO lt_bf.
      lv_count = lv_count + 1.
    ENDLOOP.
    IF lv_count > 0.
      lv_block = lv_block && |{ lv_count } beginbfchar{ cl_abap_char_utilities=>newline }|.
      LOOP AT lt_bf INTO lv_bf.
        lv_block = lv_block && lv_bf && cl_abap_char_utilities=>newline.
      ENDLOOP.
      lv_block = lv_block && |endbfchar{ cl_abap_char_utilities=>newline }|.
    ENDIF.
    gv_unicode = |/CIDInit /ProcSet findresource begin{ cl_abap_char_utilities=>newline }| &&
      |12 dict begin{ cl_abap_char_utilities=>newline }begincmap{ cl_abap_char_utilities=>newline }| &&
      |/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def{ cl_abap_char_utilities=>newline }| &&
      |/CMapName /Adobe-Identity-UCS def{ cl_abap_char_utilities=>newline }/CMapType 2 def{ cl_abap_char_utilities=>newline }| &&
      |1 begincodespacerange{ cl_abap_char_utilities=>newline }<0000> <FFFF>{ cl_abap_char_utilities=>newline }endcodespacerange{ cl_abap_char_utilities=>newline }| &&
      lv_block &&
      |endcmap{ cl_abap_char_utilities=>newline }CMapName currentdict /CMap defineresource pop{ cl_abap_char_utilities=>newline }end{ cl_abap_char_utilities=>newline }end|.
    lv_pos = 0.
    CLEAR lv_piece.
    WHILE lv_pos < xstrlen( gv_font ).
      lv_b = byte_at( iv_x = gv_font iv_off = lv_pos ).
      lv_hi = lv_b DIV 16.
      lv_lo = lv_b MOD 16.
      lv_piece = lv_piece && substring( val = lv_digits off = lv_hi len = 1 ) && substring( val = lv_digits off = lv_lo len = 1 ).
      IF strlen( lv_piece ) >= 64.
        APPEND lv_piece TO lt_hex.
        CLEAR lv_piece.
      ENDIF.
      lv_pos = lv_pos + 1.
    ENDWHILE.
    IF lv_piece IS NOT INITIAL.
      APPEND lv_piece TO lt_hex.
    ENDIF.
    CONCATENATE LINES OF lt_hex INTO gv_hex.
  ENDMETHOD.
'''


if __name__ == "__main__":
    main()
