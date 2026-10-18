import os, sys, glob
from docx2pdf import convert
import fitz

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
docx = os.path.join(ROOT, "report", "report.docx")
pdf = os.path.join(ROOT, "report", "report.pdf")

convert(docx, pdf)
print("pdf written:", pdf, os.path.getsize(pdf), "bytes")

outdir = os.path.join(ROOT, "report", "preview")
os.makedirs(outdir, exist_ok=True)
for f in glob.glob(os.path.join(outdir, "*.png")):
    os.remove(f)

doc = fitz.open(pdf)
print("pages:", doc.page_count)
for i, page in enumerate(doc):
    pix = page.get_pixmap(dpi=100)
    pix.save(os.path.join(outdir, f"page{i:02d}.png"))
print("previews in", outdir)
