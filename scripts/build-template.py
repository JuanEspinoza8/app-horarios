"""
Genera public/plantilla.docx a partir de privado/HSX-base.docx (la planilla
original del cliente), inyectando los marcadores de docxtemplater:

  Encabezado: {nombre} {legajo} {mes} {convenio} {horario}
  Detalle   : una sola fila {#filas} {fecha} {entrada} {salida} {al50} {al100}
              {franco} {via25} {via50} {motivo} {/filas}  (se repite por día)
  Totales   : {tot50} {tot100}

Es un paso de build (una sola vez / cuando cambie la planilla base). El runtime
de la PWA solo consume el .docx resultante. Uso: python scripts/build-template.py
"""
import copy
import os
import zipfile
import xml.etree.ElementTree as ET

W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
Wq = "{" + W + "}"
XML_SPACE = "{http://www.w3.org/XML/1998/namespace}space"

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.join(HERE, "..", "privado", "HSX-base.docx")
OUT = os.path.join(HERE, "..", "public", "plantilla.docx")


def register_all_namespaces(xml_bytes: bytes):
    """Registra cada prefijo->uri del documento para que ET conserve los prefijos
    (evita ns0:, y mantiene válido mc:Ignorable)."""
    for _, (prefix, uri) in ET.iterparse(_bytes_io(xml_bytes), events=["start-ns"]):
        ET.register_namespace(prefix, uri)


def _bytes_io(b):
    import io

    return io.BytesIO(b)


def set_cell_text(tc: ET.Element, text: str):
    """Reemplaza el contenido de la celda por un único run con `text`,
    conservando el formato (rPr) de la celda."""
    paras = tc.findall(Wq + "p")
    target = next((p for p in paras if p.find(Wq + "r") is not None), paras[0])

    rpr = None
    run = target.find(Wq + "r")
    if run is not None:
        rpr = run.find(Wq + "rPr")
    if rpr is None:
        ppr = target.find(Wq + "pPr")
        if ppr is not None:
            rpr = ppr.find(Wq + "rPr")

    for r in target.findall(Wq + "r"):
        target.remove(r)

    new_run = ET.SubElement(target, Wq + "r")
    if rpr is not None:
        new_run.append(copy.deepcopy(rpr))
    t = ET.SubElement(new_run, Wq + "t")
    t.set(XML_SPACE, "preserve")
    t.text = text


def main():
    with zipfile.ZipFile(BASE) as z:
        names = z.namelist()
        contents = {n: z.read(n) for n in names}

    doc_xml = contents["word/document.xml"]
    register_all_namespaces(doc_xml)
    root = ET.fromstring(doc_xml)

    tbls = list(root.iter(Wq + "tbl"))
    assert len(tbls) == 2, f"esperaba 2 tablas, hay {len(tbls)}"
    header_tbl, detail_tbl = tbls[0], tbls[1]

    # --- Encabezado (fila 0 de valores) ---
    hrow = header_tbl.findall(Wq + "tr")[0]
    hcells = hrow.findall(Wq + "tc")
    set_cell_text(hcells[0], "{nombre}")
    set_cell_text(hcells[2], "{legajo}")
    set_cell_text(hcells[4], "{mes}")
    set_cell_text(hcells[6], "{convenio}")
    set_cell_text(hcells[8], "{horario}")

    # --- Detalle ---
    drows = detail_tbl.findall(Wq + "tr")
    assert len(drows) == 21, f"esperaba 21 filas de detalle, hay {len(drows)}"
    header_a, header_b = drows[0], drows[1]
    template_row = drows[2]
    totals_row = drows[-1]
    data_rows_to_delete = drows[3:-1]  # 17 filas vacías sobrantes

    # Marcadores en la fila plantilla (9 celdas)
    tcells = template_row.findall(Wq + "tc")
    set_cell_text(tcells[0], "{#filas}{fecha}")
    set_cell_text(tcells[1], "{entrada}")
    set_cell_text(tcells[2], "{salida}")
    set_cell_text(tcells[3], "{al50}")
    set_cell_text(tcells[4], "{al100}")
    set_cell_text(tcells[5], "{franco}")
    set_cell_text(tcells[6], "{via25}")
    set_cell_text(tcells[7], "{via50}")
    set_cell_text(tcells[8], "{motivo}{/filas}")

    # Totales: celda 1 -> {tot50}, celda 2 -> {tot100}
    totcells = totals_row.findall(Wq + "tc")
    set_cell_text(totcells[1], "{tot50}")
    set_cell_text(totcells[2], "{tot100}")

    # Borrar las 17 filas de datos sobrantes
    for r in data_rows_to_delete:
        detail_tbl.remove(r)

    # Serializar conservando la declaración XML original
    body = ET.tostring(root, encoding="unicode")
    new_doc = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\r\n' + body
    contents["word/document.xml"] = new_doc.encode("utf-8")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as z:
        for n in names:
            z.writestr(n, contents[n])

    print("OK ->", os.path.relpath(OUT, os.path.join(HERE, "..")))


if __name__ == "__main__":
    main()
