/**
 * @project AncestorTree
 * @file src/lib/pdf-export.ts
 * @description PDF export for family tree — SVG serialisation approach (no foreignObject issues)
 * @version 2.0.0
 * @updated 2026-03-12
 */

import { jsPDF } from 'jspdf';

export interface PdfExportOptions {
  filename?: string;
  orientation?: 'landscape' | 'portrait';
  pageSize?: 'a4' | 'a3' | 'a2';
}

const PAGE_SIZES = {
  a4: { width: 297, height: 210 },
  a3: { width: 420, height: 297 },
  a2: { width: 594, height: 420 },
} as const;

/** Warn user when the tree is very large */
export function getExportWarning(nodeCount: number): string | null {
  if (nodeCount > 100) {
    return 'Cây quá lớn (>100 người). Vui lòng lọc theo nhánh trước khi xuất để đảm bảo chất lượng.';
  }
  if (nodeCount > 50) {
    return 'Cây khá lớn (>50 người). Chất lượng PDF có thể bị giảm.';
  }
  return null;
}

/**
 * Export the visible family-tree SVG to PDF.
 *
 * Strategy:
 *  1. Clone the container's <svg>, reset pan/zoom transform, set full-tree viewBox.
 *  2. Serialise to a Blob URL and draw via HTMLImageElement onto an off-screen canvas.
 *  3. Convert canvas to PNG and embed in jsPDF.
 *
 * This avoids html2canvas's known inability to render SVG <foreignObject> content.
 */
export async function exportTreeToPdf(
  containerElement: HTMLElement,
  treeWidth: number,
  treeHeight: number,
  offsetX: number,
  options: PdfExportOptions = {},
): Promise<void> {
  const {
    filename,
    orientation = 'landscape',
    pageSize = 'a3',
  } = options;

  const date = new Date().toISOString().slice(0, 10);
  const name = filename || `gia-pha-${date}.pdf`;

  // ── 1. Find the SVG inside the container ─────────────────────────────────
  const svgEl = containerElement.querySelector('svg') as SVGSVGElement | null;
  if (!svgEl) throw new Error('Không tìm thấy phần tử SVG để xuất.');

  // ── 2. Clone and prepare a "full-tree" SVG ───────────────────────────────
  const padding = 60;
  const fullW = Math.max(treeWidth + padding * 2, 400);
  const fullH = Math.max(treeHeight + padding * 2, 300);

  const clone = svgEl.cloneNode(true) as SVGSVGElement;
  clone.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
  clone.setAttribute('width', String(fullW));
  clone.setAttribute('height', String(fullH));
  clone.setAttribute('viewBox', `0 0 ${fullW} ${fullH}`);

  // Reset the outer <g> transform (removes current pan/zoom)
  const outerG = clone.querySelector('g') as SVGGElement | null;
  if (outerG) {
    outerG.setAttribute('transform', 'translate(0,0) scale(1)');
    // The inner <g> carries the offsetX; update it to include padding
    const innerG = outerG.querySelector('g') as SVGGElement | null;
    if (innerG) {
      innerG.setAttribute('transform', `translate(${offsetX + padding},${padding})`);
    }
  }

  // Remove minimap overlay (data-html2canvas-ignore is reused as a marker)
  clone.querySelectorAll('[data-html2canvas-ignore]').forEach((el) => el.remove());

  // Inject white background rect at the front
  const bg = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
  bg.setAttribute('x', '0');
  bg.setAttribute('y', '0');
  bg.setAttribute('width', String(fullW));
  bg.setAttribute('height', String(fullH));
  bg.setAttribute('fill', '#ffffff');
  clone.insertBefore(bg, clone.firstChild);

  // ── 3. Serialise SVG → Blob URL ──────────────────────────────────────────
  const svgStr = new XMLSerializer().serializeToString(clone);
  const blob = new Blob([svgStr], { type: 'image/svg+xml;charset=utf-8' });
  const blobUrl = URL.createObjectURL(blob);

  // ── 4. Draw SVG onto an off-screen canvas ────────────────────────────────
  const DPR = 2; // 2× for crisp output
  const canvas = document.createElement('canvas');
  canvas.width = fullW * DPR;
  canvas.height = fullH * DPR;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('Canvas 2D context unavailable');

  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  const img = new Image();
  img.src = blobUrl;

  try {
    await new Promise<void>((resolve, reject) => {
      img.onload = () => {
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
        resolve();
      };
      img.onerror = () => reject(new Error('Không thể render SVG thành ảnh.'));
      setTimeout(() => reject(new Error('Xuất PDF bị hết giờ (>15s).')), 15_000);
    });
  } finally {
    URL.revokeObjectURL(blobUrl);
  }

  // ── 5. Build PDF ──────────────────────────────────────────────────────────
  const imgData = canvas.toDataURL('image/png');
  const dims = PAGE_SIZES[pageSize];
  const pdf = new jsPDF({ orientation, unit: 'mm', format: pageSize.toUpperCase() });

  const pageW = orientation === 'landscape' ? dims.width : dims.height;
  const pageH = orientation === 'landscape' ? dims.height : dims.width;

  const margin = 10;
  const footerH = 8;
  const contentW = pageW - margin * 2;
  const contentH = pageH - margin * 2 - footerH;

  const imgRatio = canvas.width / canvas.height;
  const pageRatio = contentW / contentH;

  let drawW: number, drawH: number;
  if (imgRatio > pageRatio) {
    drawW = contentW;
    drawH = contentW / imgRatio;
  } else {
    drawH = contentH;
    drawW = contentH * imgRatio;
  }

  const dx = margin + (contentW - drawW) / 2;
  const dy = margin + (contentH - drawH) / 2;

  pdf.addImage(imgData, 'PNG', dx, dy, drawW, drawH);

  // Footer
  pdf.setFontSize(7);
  pdf.setTextColor(160, 160, 160);
  pdf.text(
    `Gia Phả Điện Tử — AncestorTree — Xuất ngày ${date}`,
    pageW / 2,
    pageH - 4,
    { align: 'center' },
  );

  pdf.save(name);
}
