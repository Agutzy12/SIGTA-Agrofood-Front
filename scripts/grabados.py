"""
Genera las ilustraciones de línea tipo grabado de SIGTA (public/img/grabados/*.svg).
Son dibujos propios, hechos con trazos y rayados: una escena por área.
Uso:  python3 scripts/grabados.py
Se usan como máscara en el CSS, así el color lo pone el tema (claro u oscuro).
"""
import math, random
from pathlib import Path

W, H = 1200, 300
SUELO = 232

class Dibujo:
    def __init__(self, semilla):
        self.r = random.Random(semilla); self.piezas = [([], '')]; self.t = self.piezas[0][0]
    def pieza(self, silueta=''):
        """Empieza un objeto nuevo. Su silueta tapa todo lo que se dibujó antes (lo que queda detrás)."""
        self.piezas.append(([], silueta)); self.t = self.piezas[-1][0]
    @staticmethod
    def pol(pts): return '<path d="M' + 'L'.join(f'{x:.1f} {y:.1f}' for x, y in pts) + 'Z"/>'
    def j(self, v, a=0.8): return v + self.r.uniform(-a, a)          # pulso de la mano
    def linea(self, x1, y1, x2, y2, g=1.1, a=0.8):
        # una recta dibujada a mano: levemente curva
        mx, my = (x1 + x2) / 2 + self.r.uniform(-a, a), (y1 + y2) / 2 + self.r.uniform(-a, a)
        self.t.append(f'<path d="M{self.j(x1,a/2):.1f} {self.j(y1,a/2):.1f}Q{mx:.1f} {my:.1f} {self.j(x2,a/2):.1f} {self.j(y2,a/2):.1f}" stroke-width="{g}"/>')
    def poli(self, pts, g=1.2, cerrar=True):
        n = len(pts)
        for i in range(n if cerrar else n - 1):
            (x1, y1), (x2, y2) = pts[i], pts[(i + 1) % n]; self.linea(x1, y1, x2, y2, g)
    def curva(self, pts, g=1.1):
        d = f'M{pts[0][0]:.1f} {pts[0][1]:.1f}'
        for i in range(1, len(pts) - 1):
            (x, y), (nx, ny) = pts[i], pts[i + 1]; d += f'Q{x:.1f} {y:.1f} {(x+nx)/2:.1f} {(y+ny)/2:.1f}'
        d += f'T{pts[-1][0]:.1f} {pts[-1][1]:.1f}'
        self.t.append(f'<path d="{d}" stroke-width="{g}"/>')
    def rayado(self, x1, y1, x2, y2, paso=5, ang=60, g=0.7, corte=0.0):
        # rayado inclinado dentro de un rectángulo (sombra)
        dx = (y2 - y1) / math.tan(math.radians(ang))
        x = x1 - dx
        while x < x2:
            ax, ay, bx, by = x, y2, x + dx, y1
            if ax < x1: ay = y2 - (x1 - ax) * math.tan(math.radians(ang)); ax = x1
            if bx > x2: by = y1 + (bx - x2) * math.tan(math.radians(ang)); bx = x2
            if self.r.random() >= corte: self.linea(ax, ay, bx, by, g, 0.5)
            x += paso + self.r.uniform(-0.8, 0.8)
    def tablas(self, x1, y1, x2, y2, paso=7, g=0.7):
        x = x1 + paso
        while x < x2 - 2: self.linea(x, y1 + self.r.uniform(0, 2), x, y2, g, 0.4); x += paso + self.r.uniform(-1, 1)
    def aros(self, x1, y1, x2, y2, paso=9, g=0.7, comba=3):
        y = y1 + paso
        while y < y2 - 2: self.curva([(x1, y), ((x1 + x2) / 2, y + comba), (x2, y)], g); y += paso + self.r.uniform(-1, 1)

    # ---- piezas ----
    def suelo(self, x1=0, x2=W, y=SUELO):
        self.pieza()
        pts = [(x, y + self.r.uniform(-1.2, 1.2)) for x in range(x1, x2 + 1, 60)]; self.curva(pts, 1.3)
    def surcos(self, x1, x2, fuga_x, y1=SUELO + 4, y2=H, n=16, g=0.8):
        for i in range(n + 1):
            xb = x1 + (x2 - x1) * i / n
            xt = fuga_x + (xb - fuga_x) * 0.42
            self.curva([(xt, y1), ((xt + xb) / 2 + self.r.uniform(-2, 2), (y1 + y2) / 2), (xb + (xb - fuga_x) * 0.25, y2)], g)
    def pasto(self, x1, x2, y=SUELO, n=40):
        for _ in range(n):
            x = self.r.uniform(x1, x2); h = self.r.uniform(4, 10)
            self.linea(x, y + self.r.uniform(0, 3), x + self.r.uniform(-3, 3), y - h, 0.7, 0.3)
    def lomas(self, y=150, amp=14, x1=0, x2=W, g=0.9):
        f = self.r.uniform(0, 6)
        self.curva([(x, y + math.sin(x / 130 + f) * amp + math.sin(x / 47 + f) * amp * .3) for x in range(x1, x2 + 1, 40)], g)
    def nube(self, x, y, ancho=120):
        for i in range(4):
            a = ancho * self.r.uniform(.35, 1); dx = self.r.uniform(-20, 20)
            self.linea(x + dx, y + i * 6, x + dx + a, y + i * 6, 0.7, 0.6)
    def arbol(self, x, base=SUELO, alto=70, ancho=44):
        self.pieza(f'<ellipse cx="{x}" cy="{base - alto * .68:.1f}" rx="{ancho / 2 + 4:.1f}" ry="{alto * .34 + 5:.1f}"/>' + self.pol([(x - 2, base), (x - 2, base - alto * .5), (x + 3, base - alto * .5), (x + 3, base)]))
        self.linea(x - 2, base, x - 1, base - alto * .45, 1.2); self.linea(x + 3, base, x + 2, base - alto * .45, 1.2)
        self.linea(x, base - alto * .4, x - ancho * .2, base - alto * .62, 0.9); self.linea(x + 1, base - alto * .4, x + ancho * .22, base - alto * .6, 0.9)
        cx, cy = x, base - alto * .68
        for _ in range(int(ancho * 1.5)):                                   # copa: muchos arquitos
            ang = self.r.uniform(0, math.tau); d = math.sqrt(self.r.random())
            px, py = cx + math.cos(ang) * d * ancho / 2, cy + math.sin(ang) * d * alto * .34
            s = self.r.uniform(3, 6.5)
            self.t.append(f'<path d="M{px-s:.1f} {py:.1f}q{s:.1f} {-s*1.3:.1f} {2*s:.1f} 0" stroke-width="{0.7 if px < cx else 0.95}"/>')
    def galpon(self, x, ancho=150, alto=64, fondo=90, base=SUELO, porton=True, silo_chapa=False):
        # frente a dos aguas + lateral en perspectiva
        y0 = base - alto; cumbre = y0 - ancho * .32; k = 0.22   # k: cuánto sube el lateral
        frente = [(x, base), (x, y0), (x + ancho / 2, cumbre), (x + ancho, y0), (x + ancho, base)]
        lx = x + ancho + fondo; ly0 = y0 - fondo * k * .35; lb = base - fondo * k * .12
        self.pieza(self.pol([(x, base), (x, y0), (x + ancho / 2, cumbre), (x + ancho / 2 + fondo, cumbre - fondo * k * .35), (lx, ly0), (lx, lb), (x + ancho, base)]))
        self.poli(frente, 1.4)
        self.linea(x + ancho, y0, lx, ly0, 1.3); self.linea(lx, ly0, lx, lb, 1.3); self.linea(x + ancho, base, lx, lb, 1.3)
        cx2, cy2 = x + ancho / 2 + fondo, cumbre - fondo * k * .35
        self.linea(x + ancho / 2, cumbre, cx2, cy2, 1.3); self.linea(cx2, cy2, lx, ly0, 1.3)
        for i in range(1, 14):                                              # chapas del techo
            f = i / 14
            ax, ay = x + ancho / 2 + fondo * f, cumbre + (cy2 - cumbre) * f
            bx, by = x + ancho + fondo * f, y0 + (ly0 - y0) * f
            self.linea(ax, ay, bx, by, 0.7, 0.5)
        self.tablas(x, y0 + 4, x + ancho, base, 9)
        for i in range(1, 9):                                               # tablas del lateral, en sombra
            f = i / 9; px = x + ancho + fondo * f
            self.linea(px, y0 + (ly0 - y0) * f, px, base + (lb - base) * f, 0.9, 0.4)
        self.rayado(x + ancho + 2, y0 + 4, lx - 2, base - 2, 6, 55, 0.6, 0.15)
        if porton:
            px1, px2, py = x + ancho * .3, x + ancho * .7, base - alto * .72
            self.poli([(px1, base), (px1, py), (px2, py), (px2, base)], 1.2, cerrar=False)
            self.linea(px1, py, px2, base, 0.8); self.linea(px2, py, px1, base, 0.8); self.linea((px1 + px2) / 2, py, (px1 + px2) / 2, base, 1)
        vx, vy = x + ancho / 2, y0 - ancho * .1                             # ventana del altillo
        self.poli([(vx - 8, vy + 9), (vx - 8, vy - 7), (vx + 8, vy - 7), (vx + 8, vy + 9)], 1); self.linea(vx, vy - 7, vx, vy + 9, 0.7); self.linea(vx - 8, vy + 1, vx + 8, vy + 1, 0.7)
        return lx
    def silo(self, x, ancho=46, alto=120, base=SUELO, techo=20):
        y0 = base - alto
        self.pieza(self.pol([(x, base + 3), (x, y0), (x + ancho / 2, y0 - techo), (x + ancho, y0), (x + ancho, base + 3)]))
        self.linea(x, base, x, y0, 1.4); self.linea(x + ancho, base, x + ancho, y0, 1.4)
        self.curva([(x, y0), (x + ancho / 2, y0 + 5), (x + ancho, y0)], 1.2); self.curva([(x, base), (x + ancho / 2, base + 5), (x + ancho, base)], 1.2)
        self.linea(x, y0, x + ancho / 2, y0 - techo, 1.3); self.linea(x + ancho, y0, x + ancho / 2, y0 - techo, 1.3)
        for f in (.25, .5, .75): self.linea(x + ancho * f, y0 + 3, x + ancho / 2, y0 - techo, 0.6, 0.3)
        self.linea(x + ancho / 2, y0 - techo, x + ancho / 2, y0 - techo - 6, 1.2)
        self.aros(x, y0, x + ancho, base, 11, 0.7, 4)
        self.rayado(x + ancho * .62, y0 + 6, x + ancho - 1, base - 2, 4.5, 68, 0.6, 0.1)      # lado en sombra
        ex = x + ancho * .18                                                                 # escalera
        self.linea(ex, base, ex, y0 + 8, 0.7, 0.3); self.linea(ex + 5, base, ex + 5, y0 + 8, 0.7, 0.3)
        y = base - 6
        while y > y0 + 10: self.linea(ex, y, ex + 5, y, 0.6, 0.2); y -= 6
    def torre(self, x, ancho=26, alto=190, base=SUELO):
        # noria / elevador de la planta: torre reticulada con casilla arriba
        y0 = base - alto
        self.pieza(self.pol([(x, base), (x, y0), (x - 11, y0), (x - 11, y0 - 22), (x + ancho / 2, y0 - 34), (x + ancho + 11, y0 - 22), (x + ancho + 11, y0), (x + ancho, y0), (x + ancho, base)]))
        self.linea(x, base, x, y0, 1.3); self.linea(x + ancho, base, x + ancho, y0, 1.3)
        y = base
        while y > y0 + 4:
            ny = max(y - ancho, y0)
            self.linea(x, y, x + ancho, ny, 0.7, 0.4); self.linea(x + ancho, y, x, ny, 0.7, 0.4); self.linea(x, ny, x + ancho, ny, 0.8, 0.4); y = ny
        self.poli([(x - 8, y0), (x - 8, y0 - 22), (x + ancho + 8, y0 - 22), (x + ancho + 8, y0)], 1.3)
        self.linea(x - 11, y0 - 22, x + ancho / 2, y0 - 34, 1.2); self.linea(x + ancho + 11, y0 - 22, x + ancho / 2, y0 - 34, 1.2)
        self.tablas(x - 8, y0 - 21, x + ancho + 8, y0, 6, 0.6)
        return y0 - 10
    def cano(self, x1, y1, x2, y2):
        self.pieza(self.pol([(x1, y1), (x2, y2), (x2, y2 + 5), (x1, y1 + 5)]))
        self.linea(x1, y1, x2, y2, 1.1); self.linea(x1, y1 + 5, x2, y2 + 5, 1.1)
        n = int(math.hypot(x2 - x1, y2 - y1) / 16)
        for i in range(1, n): f = i / n; self.linea(x1 + (x2 - x1) * f, y1 + (y2 - y1) * f, x1 + (x2 - x1) * f, y1 + (y2 - y1) * f + 5, 0.6, 0.2)
    def molino(self, x, alto=130, base=SUELO):
        # molino de viento de campo: torre reticulada + rueda de aspas + cola
        y0 = base - alto; a = 20
        self.pieza(f'<circle cx="{x}" cy="{y0 - 4}" r="31"/>' + self.pol([(x + 6, y0 - 4), (x + 52, y0 - 13), (x + 64, y0 - 4), (x + 52, y0 + 5)]))
        self.linea(x - a, base, x - 3, y0, 1.2); self.linea(x + a, base, x + 3, y0, 1.2)
        for i in range(5):
            f1, f2 = i / 5, (i + 1) / 5
            xa1, xb1 = x - a + (a - 3) * f1, x + a - (a - 3) * f1; xa2, xb2 = x - a + (a - 3) * f2, x + a - (a - 3) * f2
            ya, yb = base - alto * f1, base - alto * f2
            self.linea(xa1, ya, xb2, yb, 0.7, 0.4); self.linea(xb1, ya, xa2, yb, 0.7, 0.4); self.linea(xa2, yb, xb2, yb, 0.8, 0.3)
        R = 30; cy = y0 - 4
        self.t.append(f'<circle cx="{x}" cy="{cy}" r="{R}" stroke-width="1.1"/><circle cx="{x}" cy="{cy}" r="{R*.42:.1f}" stroke-width="0.8"/><circle cx="{x}" cy="{cy}" r="3" stroke-width="1.2"/>')
        for i in range(18):
            an = math.tau * i / 18
            self.linea(x + math.cos(an) * 4, cy + math.sin(an) * 4, x + math.cos(an) * R, cy + math.sin(an) * R, 0.7, 0.3)
            an2 = an + .2; self.linea(x + math.cos(an) * R * .45, cy + math.sin(an) * R * .45, x + math.cos(an2) * R, cy + math.sin(an2) * R, 0.6, 0.3)
        self.poli([(x + 6, cy), (x + R + 22, cy - 9), (x + R + 34, cy), (x + R + 22, cy + 9)], 1)
    def alambrado(self, x1, x2, base=SUELO + 2, alto=20, paso=34):
        self.pieza()
        x = x1
        while x <= x2: self.linea(x, base + 3, x + self.r.uniform(-1, 1), base - alto, 1.2); x += paso
        for f in (.25, .55, .85): self.curva([(x, base - alto * f + (2 if (i % 2) else 0)) for i, x in enumerate(range(x1, x2 + 1, paso // 2))], 0.6)
    def espiga(self, x, base, alto=64, incl=0):
        tx, ty = x + incl, base - alto
        self.curva([(x, base), (x + incl * .3, base - alto * .5), (tx, ty)], 0.9)
        for i in range(7):
            f = i / 7; px, py = tx - incl * .25 * f, ty + 22 * f
            self.t.append(f'<path d="M{px:.1f} {py:.1f}q-6 -4 -5 -11M{px:.1f} {py:.1f}q6 -4 5 -11" stroke-width="0.8"/>')
        self.linea(tx, ty, tx + incl * .1, ty - 12, 0.6, 0.3)
    def trigal(self, x1, x2, base=H + 6, n=26, alto=70):
        self.pieza()
        for i in range(n):
            x = x1 + (x2 - x1) * i / (n - 1) + self.r.uniform(-8, 8)
            self.espiga(x, base, alto + self.r.uniform(-16, 16), self.r.uniform(-12, 12))
    def camion(self, x, base=SUELO, largo=150, alto=58):
        y0 = base - alto - 10
        self.pieza(self.pol([(x, base), (x, y0), (x + largo, y0), (x + largo, base - 50), (x + largo + 30, base - 50), (x + largo + 48, base - 30), (x + largo + 52, base)]))
        self.poli([(x, base - 12), (x, y0), (x + largo, y0), (x + largo, base - 12)], 1.4)             # caja
        self.tablas(x, y0 + 2, x + largo, base - 12, 12, 0.6); self.linea(x, y0 + alto * .5, x + largo, y0 + alto * .5, 0.6)
        cx = x + largo + 4
        self.poli([(cx, base - 12), (cx, base - 50), (cx + 26, base - 50), (cx + 44, base - 30), (cx + 48, base - 12)], 1.4)   # cabina
        self.poli([(cx + 6, base - 32), (cx + 6, base - 45), (cx + 23, base - 45), (cx + 35, base - 32)], 0.9)
        self.linea(x - 4, base - 12, cx + 48, base - 12, 1.2)
        for rx in (x + 24, x + 46, x + largo - 18, cx + 30):
            self.t.append(f'<circle cx="{rx}" cy="{base - 9}" r="10" stroke-width="1.4"/><circle cx="{rx}" cy="{base - 9}" r="4" stroke-width="0.9"/>')
        self.rayado(x + 2, base - 11, x + largo - 30, base - 2, 4, 50, 0.5)
    def pallet(self, x, base=SUELO, filas=3, cols=3, lado=17):
        self.pieza(self.pol([(x - 3, base), (x - 3, base - 4), (x, base - 4), (x, base - 4 - filas * lado * .82), (x + cols * lado, base - 4 - filas * lado * .82), (x + cols * lado, base - 4), (x + cols * lado + 3, base - 4), (x + cols * lado + 3, base)]))
        self.linea(x - 3, base - 4, x + cols * lado + 3, base - 4, 1.3); self.linea(x - 3, base, x + cols * lado + 3, base, 1.1)
        for c in (0, cols * lado / 2 - 2, cols * lado - 4): self.poli([(x + c, base), (x + c, base - 4), (x + c + 4, base - 4), (x + c + 4, base)], 0.8)
        for f in range(filas):
            for c in range(cols if f < filas - 1 or self.r.random() > .4 else cols - 1):
                bx, by = x + c * lado, base - 4 - (f + 1) * lado * .82
                self.poli([(bx, by + lado * .82), (bx, by), (bx + lado, by), (bx + lado, by + lado * .82)], 1)
                self.linea(bx + lado * .3, by, bx + lado * .3, by + lado * .82, 0.5, 0.2); self.linea(bx + lado * .7, by, bx + lado * .7, by + lado * .82, 0.5, 0.2)
    def pajaros(self, x, y, n=4):
        for _ in range(n):
            px, py, s = x + self.r.uniform(-40, 40), y + self.r.uniform(-14, 14), self.r.uniform(3, 6)
            self.t.append(f'<path d="M{px-s:.1f} {py:.1f}q{s/2:.1f} {-s:.1f} {s:.1f} 0q{s/2:.1f} {-s:.1f} {s:.1f} 0" stroke-width="0.8"/>')
    def svg(self):
        # Cada pieza se recorta con las siluetas de las piezas que tiene adelante: así nada se ve "a través" de un galpón.
        defs, cuerpo = [], []
        for i, (trazos, _) in enumerate(self.piezas):
            delante = ''.join(sil for _, sil in self.piezas[i + 1:])
            if delante:
                defs.append(f'<mask id="m{i}" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}"><rect width="{W}" height="{H}" fill="#fff"/><g fill="#000" stroke="#000" stroke-width="2">{delante}</g></mask>')
                cuerpo.append(f'<g mask="url(#m{i})">{"".join(trazos)}</g>')
            else: cuerpo.append(''.join(trazos))
        return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" fill="none" stroke="#000" stroke-linecap="round" stroke-linejoin="round">'
                f'<defs>{"".join(defs)}</defs>{"".join(cuerpo)}</svg>\n')

def granja():
    d = Dibujo(7)
    d.lomas(168, 12); d.lomas(186, 8, g=0.7); d.nube(140, 46, 150); d.nube(760, 34, 120); d.pajaros(520, 70)
    d.arbol(70, alto=96, ancho=62); d.arbol(128, alto=70, ancho=44)
    d.galpon(300, 150, 66, 110); d.silo(556, 44, 128)
    d.galpon(640, 96, 44, 70, porton=False); d.arbol(880, alto=86, ancho=56); d.arbol(934, alto=62, ancho=40)
    d.molino(1040, 118); d.alambrado(150, 290); d.alambrado(960, 1190)
    d.suelo(); d.pasto(0, W, n=70); d.surcos(-200, 1400, 600, n=30)
    return d
def planta():
    d = Dibujo(21)
    d.lomas(176, 8, g=0.7); d.nube(90, 40, 140); d.nube(980, 52, 130)
    for i, x in enumerate((330, 388, 446, 504)): d.silo(x, 50, 136 - (i % 2) * 6, techo=22)
    cy = d.torre(580, 26, 196)
    for x in (355, 413, 471, 529): d.cano(593, cy + 6, x, SUELO - 150)
    d.galpon(660, 170, 60, 150); d.silo(1000, 40, 92)
    d.arbol(120, alto=84, ancho=54); d.arbol(182, alto=60, ancho=38); d.arbol(1090, alto=90, ancho=58)
    d.alambrado(0, 300, paso=40); d.suelo(); d.pasto(0, W, n=60); d.surcos(-300, 1500, 620, n=26)
    return d
def campo():
    d = Dibujo(33)
    d.lomas(150, 16); d.lomas(172, 10, g=0.7); d.lomas(196, 6, g=0.6); d.nube(420, 38, 170); d.nube(900, 60, 110); d.pajaros(250, 60, 5)
    d.molino(210, 126); d.arbol(330, alto=74, ancho=48)
    d.silo(712, 36, 96); d.galpon(760, 110, 50, 80); d.arbol(1000, alto=92, ancho=60); d.arbol(1060, alto=64, ancho=42)
    d.suelo(); d.pasto(0, W, n=50); d.trigal(-10, W + 10, n=58, alto=62)
    return d
def deposito():
    d = Dibujo(45)
    d.lomas(182, 7, g=0.7); d.nube(180, 44, 130); d.nube(840, 36, 150)
    d.galpon(240, 220, 78, 190); d.pallet(96, filas=3); d.pallet(160, filas=2)
    d.camion(700); d.pallet(930, filas=3, cols=2); d.pallet(980, filas=2, cols=3)
    d.arbol(40, alto=88, ancho=54); d.arbol(1110, alto=96, ancho=62); d.silo(1150, 36, 100)
    d.suelo(); d.pasto(0, 240, n=20); d.pasto(1040, W, n=16)
    for y in (SUELO + 16, SUELO + 34, SUELO + 56): d.linea(-20, y, W + 20, y + 2, 0.7, 1.5)      # playón
    for x in range(40, W, 110): d.linea(x, SUELO + 45, x + 46, SUELO + 45, 1)
    return d

if __name__ == '__main__':
    destino = Path(__file__).resolve().parent.parent / 'public/img/grabados'; destino.mkdir(parents=True, exist_ok=True)
    for nombre, f in (('granja', granja), ('planta', planta), ('campo', campo), ('deposito', deposito)):
        (destino / f'{nombre}.svg').write_text(f().svg()); print(nombre, f'{(destino / f"{nombre}.svg").stat().st_size / 1024:.0f} KB')
