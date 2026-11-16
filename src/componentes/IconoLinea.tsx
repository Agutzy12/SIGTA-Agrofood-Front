import type { CSSProperties } from 'react';

/** Ícono de una línea de producto (los de Agrifood). El archivo es sólo la forma: el color lo pone el CSS (.ico-linea). */
const ARCHIVO: Record<string, string> = {
  DESHIDRATADOS: 'deshidratados', PRE_ELABORADOS: 'pre-elaborados', FRUTOS_SECOS: 'frutos-secos', PRE_MEZCLAS: 'pre-mezclas', PASTAS_SECAS: 'pastas-secas',
};

export function IconoLinea({ codigo }: { codigo: string }) {
  const archivo = ARCHIVO[codigo];
  if (!archivo) return null;
  return <span className="ico-linea" aria-hidden="true" style={{ '--forma': `url('/img/lineas/${archivo}.png')` } as CSSProperties} />;
}
