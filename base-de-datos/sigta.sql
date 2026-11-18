-- SIGTA · Sistema Integral de Gestión y Trazabilidad Alimentaria
-- Base completa: tablas, claves, reglas (triggers) y datos. Generada con: npm run db:exportar
-- Para importarla, ver base-de-datos/LEEME.md

--
-- PostgreSQL database dump
--


-- Dumped from database version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: Dictamen; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."Dictamen" AS ENUM (
    'APROBAR_LIBERAR',
    'RECHAZAR_BLOQUEAR'
);


--
-- Name: EstadoLote; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."EstadoLote" AS ENUM (
    'CUARENTENA',
    'APROBADO_LIBERADO',
    'RECHAZADO_BLOQUEADO'
);


--
-- Name: EstadoOP; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."EstadoOP" AS ENUM (
    'CREADA',
    'PLANIFICADA',
    'EN_PRODUCCION',
    'EN_CONTROL_CALIDAD',
    'FINALIZADA',
    'RECHAZADA_SCRAP',
    'CANCELADA'
);


--
-- Name: EstadoPartida; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."EstadoPartida" AS ENUM (
    'LIBERADO',
    'CUARENTENA',
    'RECHAZADO'
);


--
-- Name: Rol; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."Rol" AS ENUM (
    'PRODUCCION',
    'CALIDAD',
    'DEPOSITO',
    'DIRECCION'
);


--
-- Name: TipoInsumo; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."TipoInsumo" AS ENUM (
    'MP',
    'ME'
);


--
-- Name: sigta_auditoria_solo_agregar(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sigta_auditoria_solo_agregar() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE EXCEPTION 'El registro de auditoría no se puede modificar ni borrar' USING ERRCODE = 'SG409';
END;
$$;


--
-- Name: sigta_bloqueo_logico(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sigta_bloqueo_logico() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  estado_lote text;
BEGIN
  SELECT "estado"::text INTO estado_lote FROM "lote_produccion" WHERE "id" = NEW."lote_id";
  IF estado_lote IS DISTINCT FROM 'APROBADO_LIBERADO' THEN
    RAISE EXCEPTION 'Bloqueo lógico: el lote no está aprobado y liberado (estado %)', COALESCE(estado_lote, 'inexistente')
      USING ERRCODE = 'SG423';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: sigta_estado_lote_final(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sigta_estado_lote_final() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF OLD."estado" <> 'CUARENTENA' AND NEW."estado" <> OLD."estado" THEN
    RAISE EXCEPTION 'El dictamen del lote % ya está firmado y no se puede cambiar', OLD."codigo" USING ERRCODE = 'SG409';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: sigta_protocolo_inalterable(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sigta_protocolo_inalterable() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'El protocolo de calidad firmado no puede eliminarse' USING ERRCODE = 'SG409';
  END IF;
  RAISE EXCEPTION 'El protocolo de calidad firmado es inalterable' USING ERRCODE = 'SG409';
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _prisma_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._prisma_migrations (
    id character varying(36) NOT NULL,
    checksum character varying(64) NOT NULL,
    finished_at timestamp with time zone,
    migration_name character varying(255) NOT NULL,
    logs text,
    rolled_back_at timestamp with time zone,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    applied_steps_count integer DEFAULT 0 NOT NULL
);


--
-- Name: auditoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditoria (
    id integer NOT NULL,
    fecha timestamp(3) with time zone NOT NULL,
    usuario text NOT NULL,
    rol text NOT NULL,
    accion text NOT NULL,
    entidad text,
    detalle text,
    resultado text,
    op_id integer,
    lote_id integer
);


--
-- Name: auditoria_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auditoria_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auditoria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auditoria_id_seq OWNED BY public.auditoria.id;


--
-- Name: categoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categoria (
    id integer NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL,
    familia text NOT NULL,
    url_web text
);


--
-- Name: consumo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.consumo (
    id integer NOT NULL,
    op_id integer NOT NULL,
    insumo_id integer NOT NULL,
    partida_id integer NOT NULL,
    cantidad double precision NOT NULL,
    CONSTRAINT consumo_cantidad_positiva CHECK ((cantidad > (0)::double precision))
);


--
-- Name: consumo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.consumo_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: consumo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.consumo_id_seq OWNED BY public.consumo.id;


--
-- Name: control_calidad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.control_calidad (
    id integer NOT NULL,
    lote_id integer NOT NULL,
    protocolo text NOT NULL,
    formulario text NOT NULL,
    humedad double precision NOT NULL,
    ph double precision NOT NULL,
    aroma text NOT NULL,
    color text NOT NULL,
    sabor text NOT NULL,
    ufc integer NOT NULL,
    dictamen public."Dictamen" NOT NULL,
    observaciones text,
    analista text NOT NULL,
    fecha timestamp(3) with time zone NOT NULL
);


--
-- Name: control_calidad_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.control_calidad_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: control_calidad_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.control_calidad_id_seq OWNED BY public.control_calidad.id;


--
-- Name: despacho; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.despacho (
    id integer NOT NULL,
    lote_id integer NOT NULL,
    cliente text NOT NULL,
    cantidad_kg double precision NOT NULL,
    fecha timestamp(3) with time zone NOT NULL,
    usuario text NOT NULL,
    CONSTRAINT despacho_cantidad_positiva CHECK ((cantidad_kg > (0)::double precision))
);


--
-- Name: despacho_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.despacho_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: despacho_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.despacho_id_seq OWNED BY public.despacho.id;


--
-- Name: insumo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.insumo (
    id integer NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL,
    tipo public."TipoInsumo" NOT NULL,
    unidad text NOT NULL,
    critico boolean DEFAULT true NOT NULL,
    stock_minimo double precision DEFAULT 0 NOT NULL
);


--
-- Name: linea; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.linea (
    id integer NOT NULL,
    nombre text NOT NULL,
    proceso text DEFAULT ''::text NOT NULL
);


--
-- Name: lote_produccion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lote_produccion (
    id integer NOT NULL,
    codigo text NOT NULL,
    op_id integer NOT NULL,
    producto_id integer NOT NULL,
    cantidad_kg double precision NOT NULL,
    bultos integer NOT NULL,
    vencimiento date NOT NULL,
    estado public."EstadoLote" NOT NULL,
    creado_en timestamp(3) with time zone NOT NULL,
    borrador jsonb,
    CONSTRAINT lote_cantidad_positiva CHECK (((cantidad_kg > (0)::double precision) AND (bultos >= 0)))
);


--
-- Name: lote_produccion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lote_produccion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lote_produccion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lote_produccion_id_seq OWNED BY public.lote_produccion.id;


--
-- Name: op_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.op_item (
    op_id integer NOT NULL,
    insumo_id integer NOT NULL,
    cantidad_teorica double precision NOT NULL
);


--
-- Name: orden_produccion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orden_produccion (
    id integer NOT NULL,
    secuencia integer NOT NULL,
    numero text NOT NULL,
    producto_id integer NOT NULL,
    receta_id integer NOT NULL,
    linea_id integer,
    cantidad_kg double precision NOT NULL,
    fecha_proyectada date NOT NULL,
    hora_prevista text,
    estado public."EstadoOP" NOT NULL,
    pausada boolean DEFAULT false NOT NULL,
    motivo_pausa text,
    observaciones text,
    creado_por text NOT NULL,
    creado_en timestamp(3) with time zone NOT NULL,
    inicio_real timestamp(3) with time zone,
    operador text,
    fin_elaboracion timestamp(3) with time zone,
    cierre timestamp(3) with time zone,
    cantidad_real_kg double precision,
    bultos integer,
    merma_kg double precision,
    merma_pct double precision,
    lote_codigo_previsto text,
    vencimiento_previsto date,
    avance jsonb,
    CONSTRAINT op_cantidad_positiva CHECK ((cantidad_kg > (0)::double precision))
);


--
-- Name: orden_produccion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orden_produccion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orden_produccion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.orden_produccion_id_seq OWNED BY public.orden_produccion.id;


--
-- Name: pallet; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pallet (
    id integer NOT NULL,
    codigo text NOT NULL,
    lote_id integer NOT NULL,
    bultos integer NOT NULL,
    kg double precision NOT NULL
);


--
-- Name: pallet_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pallet_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pallet_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pallet_id_seq OWNED BY public.pallet.id;


--
-- Name: partida_insumo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.partida_insumo (
    id integer NOT NULL,
    insumo_id integer NOT NULL,
    nro_lote text NOT NULL,
    proveedor text,
    cantidad double precision NOT NULL,
    vencimiento date,
    documento_origen text,
    estado public."EstadoPartida" DEFAULT 'LIBERADO'::public."EstadoPartida" NOT NULL,
    ingreso timestamp(3) with time zone NOT NULL,
    CONSTRAINT partida_saldo_no_negativo CHECK ((cantidad >= (0)::double precision))
);


--
-- Name: partida_insumo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.partida_insumo_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: partida_insumo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.partida_insumo_id_seq OWNED BY public.partida_insumo.id;


--
-- Name: producto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.producto (
    id integer NOT NULL,
    codigo text NOT NULL,
    gtin text NOT NULL,
    nombre text NOT NULL,
    linea_id integer,
    presentacion_kg double precision NOT NULL,
    vida_util_meses integer NOT NULL,
    humedad_max double precision NOT NULL,
    ph_min double precision NOT NULL,
    ph_max double precision NOT NULL,
    ufc_max integer NOT NULL,
    color_esperado text NOT NULL,
    alergenos text,
    almacenamiento text,
    categoria_id integer,
    embalaje text,
    ingredientes text,
    presentacion text DEFAULT ''::text NOT NULL,
    raciones integer,
    unidades_por_caja integer,
    unidades_por_pallet integer DEFAULT 25 NOT NULL,
    url_web text,
    CONSTRAINT producto_presentacion_positiva CHECK (((presentacion_kg > (0)::double precision) AND (unidades_por_pallet > 0)))
);


--
-- Name: receta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.receta (
    id integer NOT NULL,
    codigo text NOT NULL,
    producto_id integer NOT NULL,
    version integer NOT NULL,
    vigente_desde date NOT NULL,
    base_kg double precision NOT NULL,
    activa boolean DEFAULT true NOT NULL
);


--
-- Name: receta_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.receta_item (
    receta_id integer NOT NULL,
    insumo_id integer NOT NULL,
    cantidad_base double precision NOT NULL
);


--
-- Name: stock_pt; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stock_pt (
    id integer NOT NULL,
    lote_id integer NOT NULL,
    comprobante text NOT NULL,
    deposito text NOT NULL,
    sector text NOT NULL,
    rack text NOT NULL,
    nivel text NOT NULL,
    camara text,
    bultos integer NOT NULL,
    pallets integer NOT NULL,
    kg_recibidos double precision NOT NULL,
    cantidad_kg double precision NOT NULL,
    bultos_danados integer DEFAULT 0 NOT NULL,
    merma_kg double precision DEFAULT 0 NOT NULL,
    justificacion text,
    recibido_por text NOT NULL,
    fecha timestamp(3) with time zone NOT NULL,
    CONSTRAINT stock_pt_saldo_no_negativo CHECK ((cantidad_kg >= (0)::double precision))
);


--
-- Name: stock_pt_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stock_pt_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_pt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stock_pt_id_seq OWNED BY public.stock_pt.id;


--
-- Name: usuario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuario (
    id integer NOT NULL,
    email text NOT NULL,
    nombre text NOT NULL,
    cargo text NOT NULL,
    iniciales text NOT NULL,
    rol public."Rol" NOT NULL,
    password_hash text NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    creado_en timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: usuario_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usuario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usuario_id_seq OWNED BY public.usuario.id;


--
-- Name: auditoria id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria ALTER COLUMN id SET DEFAULT nextval('public.auditoria_id_seq'::regclass);


--
-- Name: consumo id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consumo ALTER COLUMN id SET DEFAULT nextval('public.consumo_id_seq'::regclass);


--
-- Name: control_calidad id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.control_calidad ALTER COLUMN id SET DEFAULT nextval('public.control_calidad_id_seq'::regclass);


--
-- Name: despacho id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.despacho ALTER COLUMN id SET DEFAULT nextval('public.despacho_id_seq'::regclass);


--
-- Name: lote_produccion id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lote_produccion ALTER COLUMN id SET DEFAULT nextval('public.lote_produccion_id_seq'::regclass);


--
-- Name: orden_produccion id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orden_produccion ALTER COLUMN id SET DEFAULT nextval('public.orden_produccion_id_seq'::regclass);


--
-- Name: pallet id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pallet ALTER COLUMN id SET DEFAULT nextval('public.pallet_id_seq'::regclass);


--
-- Name: partida_insumo id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partida_insumo ALTER COLUMN id SET DEFAULT nextval('public.partida_insumo_id_seq'::regclass);


--
-- Name: stock_pt id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_pt ALTER COLUMN id SET DEFAULT nextval('public.stock_pt_id_seq'::regclass);


--
-- Name: usuario id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario ALTER COLUMN id SET DEFAULT nextval('public.usuario_id_seq'::regclass);


--
-- Data for Name: _prisma_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES
	('dd81cbb5-705b-4356-a79b-e26a27c80265', '76f92c060eeb38069e342364c911f51f3340678eeeda8bc3a51ce12e9e2e24d3', '2026-11-18 00:38:07.168758+00', '20261112230003_modelo_inicial', NULL, NULL, '2026-11-18 00:38:07.114092+00', 1),
	('d9e6ddae-186b-40d1-84c4-53d4787fc58e', '0950a5d468137b01756906c316c08f69878b1356f317f88d1dd48e2a74a4b455', '2026-11-18 00:38:07.174417+00', '20261112230100_reglas_de_negocio', NULL, NULL, '2026-11-18 00:38:07.16946+00', 1),
	('18a48bf1-fdf0-4443-928c-2896096a6ea8', '7d365b6f9d07fc62d6172433ecb0da3b8c0a7d2ac954494554d555682928e4d5', '2026-11-18 00:38:07.180105+00', '20261112234521_catalogo_agrifood', NULL, NULL, '2026-11-18 00:38:07.17515+00', 1);


--
-- Data for Name: auditoria; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.auditoria (id, fecha, usuario, rol, accion, entidad, detalle, resultado, op_id, lote_id) VALUES
	(1, '2026-11-04 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00111', 'Creación de la orden', 'OP Creada', 1, NULL),
	(2, '2026-11-04 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00111', 'Confirmación de disponibilidad', 'OP Planificada', 1, NULL),
	(3, '2026-11-04 10:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00111', 'Inicio de elaboración y asignación de lote', 'OP En producción', 1, NULL),
	(4, '2026-11-04 11:40:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-COD500-202645-01', 'Fin de elaboración · 1176 kg netos', 'Lote Cuarentena', 1, 1),
	(5, '2026-11-04 12:45:00+00', 'Lucía Benítez', 'CALIDAD', 'LOTE_LIBERADO', 'L-COD500-202645-01', 'Firma de protocolo de calidad', 'Lote liberado · OP en CC', 1, 1),
	(6, '2026-11-04 13:30:00+00', 'Diego Acosta', 'DEPOSITO', 'OP_FINALIZADA', 'OP-2026-00111', 'Recepción de 4 pallets · 1176 kg', 'OP Finalizada', 1, 1),
	(7, '2026-11-05 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00112', 'Creación de la orden', 'OP Creada', 2, NULL),
	(8, '2026-11-05 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00112', 'Confirmación de disponibilidad', 'OP Planificada', 2, NULL),
	(9, '2026-11-05 10:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00112', 'Inicio de elaboración y asignación de lote', 'OP En producción', 2, NULL),
	(10, '2026-11-05 11:40:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-PIZ500-202645-01', 'Fin de elaboración · 588 kg netos', 'Lote Cuarentena', 2, 2),
	(11, '2026-11-05 12:45:00+00', 'Lucía Benítez', 'CALIDAD', 'LOTE_LIBERADO', 'L-PIZ500-202645-01', 'Firma de protocolo de calidad', 'Lote liberado · OP en CC', 2, 2),
	(12, '2026-11-05 13:30:00+00', 'Diego Acosta', 'DEPOSITO', 'OP_FINALIZADA', 'OP-2026-00112', 'Recepción de 2 pallets · 588 kg', 'OP Finalizada', 2, 2),
	(13, '2026-11-06 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00113', 'Creación de la orden', 'OP Creada', 3, NULL),
	(14, '2026-11-06 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00113', 'Confirmación de disponibilidad', 'OP Planificada', 3, NULL),
	(15, '2026-11-06 10:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00113', 'Inicio de elaboración y asignación de lote', 'OP En producción', 3, NULL),
	(16, '2026-11-06 11:40:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-AJOE20-202645-01', 'Fin de elaboración · 200 kg netos', 'Lote Cuarentena', 3, 3),
	(17, '2026-11-06 12:45:00+00', 'Lucía Benítez', 'CALIDAD', 'LOTE_LIBERADO', 'L-AJOE20-202645-01', 'Firma de protocolo de calidad', 'Lote liberado · OP en CC', 3, 3),
	(18, '2026-11-06 13:30:00+00', 'Diego Acosta', 'DEPOSITO', 'OP_FINALIZADA', 'OP-2026-00113', 'Recepción de 1 pallets · 200 kg', 'OP Finalizada', 3, 3),
	(19, '2026-11-09 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00114', 'Creación de la orden', 'OP Creada', 4, NULL),
	(20, '2026-11-09 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00114', 'Confirmación de disponibilidad', 'OP Planificada', 4, NULL),
	(21, '2026-11-09 10:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00114', 'Inicio de elaboración y asignación de lote', 'OP En producción', 4, NULL),
	(22, '2026-11-09 11:40:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-SPA500-202646-01', 'Fin de elaboración · 1176 kg netos', 'Lote Cuarentena', 4, 4),
	(23, '2026-11-09 12:45:00+00', 'Lucía Benítez', 'CALIDAD', 'LOTE_LIBERADO', 'L-SPA500-202646-01', 'Firma de protocolo de calidad', 'Lote liberado · OP en CC', 4, 4),
	(24, '2026-11-09 13:30:00+00', 'Diego Acosta', 'DEPOSITO', 'OP_FINALIZADA', 'OP-2026-00114', 'Recepción de 4 pallets · 1176 kg', 'OP Finalizada', 4, 4),
	(25, '2026-11-09 12:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00115', 'Creación de la orden', 'OP Creada', 5, NULL),
	(26, '2026-11-09 12:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00115', 'Confirmación de disponibilidad', 'OP Planificada', 5, NULL),
	(27, '2026-11-09 13:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00115', 'Inicio de elaboración y asignación de lote', 'OP En producción', 5, NULL),
	(28, '2026-11-09 14:40:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-ARZ8K-202646-01', 'Fin de elaboración · 392 kg netos', 'Lote Cuarentena', 5, 5),
	(29, '2026-11-09 15:45:00+00', 'Lucía Benítez', 'CALIDAD', 'LOTE_LIBERADO', 'L-ARZ8K-202646-01', 'Firma de protocolo de calidad', 'Lote liberado · OP en CC', 5, 5),
	(30, '2026-11-09 16:30:00+00', 'Diego Acosta', 'DEPOSITO', 'OP_FINALIZADA', 'OP-2026-00115', 'Recepción de 1 pallets · 392 kg', 'OP Finalizada', 5, 5),
	(31, '2026-11-10 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00116', 'Creación de la orden', 'OP Creada', 6, NULL),
	(32, '2026-11-10 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00116', 'Confirmación de disponibilidad', 'OP Planificada', 6, NULL),
	(33, '2026-11-10 10:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00116', 'Inicio de elaboración y asignación de lote', 'OP En producción', 6, NULL),
	(34, '2026-11-10 11:40:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-BIZC500-202646-01', 'Fin de elaboración · 490 kg netos', 'Lote Cuarentena', 6, 6),
	(35, '2026-11-10 12:45:00+00', 'Lucía Benítez', 'CALIDAD', 'LOTE_LIBERADO', 'L-BIZC500-202646-01', 'Firma de protocolo de calidad', 'Lote liberado · OP en CC', 6, 6),
	(36, '2026-11-10 13:30:00+00', 'Diego Acosta', 'DEPOSITO', 'OP_FINALIZADA', 'OP-2026-00116', 'Recepción de 2 pallets · 490 kg', 'OP Finalizada', 6, 6),
	(37, '2026-11-10 11:30:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00117', 'Creación de la orden', 'OP Creada', 7, NULL),
	(38, '2026-11-10 11:30:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00117', 'Confirmación de disponibilidad', 'OP Planificada', 7, NULL),
	(39, '2026-11-10 12:30:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00117', 'Inicio de elaboración y asignación de lote', 'OP En producción', 7, NULL),
	(40, '2026-11-10 14:10:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-NUE120-202646-01', 'Fin de elaboración · 235.2 kg netos', 'Lote Cuarentena', 7, 7),
	(41, '2026-11-10 15:15:00+00', 'Lucía Benítez', 'CALIDAD', 'LOTE_LIBERADO', 'L-NUE120-202646-01', 'Firma de protocolo de calidad', 'Lote liberado · OP en CC', 7, 7),
	(42, '2026-11-10 16:00:00+00', 'Diego Acosta', 'DEPOSITO', 'OP_FINALIZADA', 'OP-2026-00117', 'Recepción de 1 pallets · 235.2 kg', 'OP Finalizada', 7, 7),
	(43, '2026-11-10 14:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00118', 'Creación de la orden', 'OP Creada', 8, NULL),
	(44, '2026-11-10 14:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00118', 'Confirmación de disponibilidad', 'OP Planificada', 8, NULL),
	(45, '2026-11-10 15:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00118', 'Inicio de elaboración y asignación de lote', 'OP En producción', 8, NULL),
	(46, '2026-11-10 16:40:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-ESPE10-202646-01', 'Fin de elaboración · 100 kg netos', 'Lote Cuarentena', 8, 8),
	(47, '2026-11-10 17:45:00+00', 'Lucía Benítez', 'CALIDAD', 'LOTE_LIBERADO', 'L-ESPE10-202646-01', 'Firma de protocolo de calidad', 'Lote liberado · OP en CC', 8, 8),
	(48, '2026-11-10 18:30:00+00', 'Diego Acosta', 'DEPOSITO', 'OP_FINALIZADA', 'OP-2026-00118', 'Recepción de 1 pallets · 100 kg', 'OP Finalizada', 8, 8),
	(49, '2026-11-11 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00119', 'Creación de la orden', 'OP Creada', 9, NULL),
	(50, '2026-11-11 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00119', 'Confirmación de disponibilidad', 'OP Planificada', 9, NULL),
	(51, '2026-11-11 10:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00119', 'Inicio de elaboración y asignación de lote', 'OP En producción', 9, NULL),
	(52, '2026-11-11 11:40:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-RIG500-202646-01', 'Fin de elaboración · 980 kg netos', 'Lote Cuarentena', 9, 9),
	(53, '2026-11-11 12:45:00+00', 'Lucía Benítez', 'CALIDAD', 'LOTE_LIBERADO', 'L-RIG500-202646-01', 'Firma de protocolo de calidad', 'Lote liberado · OP en CC', 9, 9),
	(54, '2026-11-11 13:30:00+00', 'Diego Acosta', 'DEPOSITO', 'OP_FINALIZADA', 'OP-2026-00119', 'Recepción de 4 pallets · 980 kg', 'OP Finalizada', 9, 9),
	(55, '2026-11-11 12:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00120', 'Creación de la orden', 'OP Creada', 10, NULL),
	(56, '2026-11-11 12:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00120', 'Confirmación de disponibilidad', 'OP Planificada', 10, NULL),
	(57, '2026-11-11 13:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00120', 'Inicio de elaboración y asignación de lote', 'OP En producción', 10, NULL),
	(58, '2026-11-11 14:40:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-PUR4K-202646-01', 'Fin de elaboración · 441 kg netos', 'Lote Cuarentena', 10, 10),
	(59, '2026-11-11 15:45:00+00', 'Lucía Benítez', 'CALIDAD', 'LOTE_LIBERADO', 'L-PUR4K-202646-01', 'Firma de protocolo de calidad', 'Lote liberado · OP en CC', 10, 10),
	(60, '2026-11-11 16:30:00+00', 'Diego Acosta', 'DEPOSITO', 'OP_FINALIZADA', 'OP-2026-00120', 'Recepción de 2 pallets · 441 kg', 'OP Finalizada', 10, 10),
	(61, '2026-11-11 14:30:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00121', 'Creación de la orden', 'OP Creada', 11, NULL),
	(62, '2026-11-11 14:30:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00121', 'Confirmación de disponibilidad', 'OP Planificada', 11, NULL),
	(63, '2026-11-11 15:30:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00121', 'Inicio de elaboración y asignación de lote', 'OP En producción', 11, NULL),
	(64, '2026-11-11 17:10:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-NOQ500-202646-01', 'Fin de elaboración · 490 kg netos', 'Lote Cuarentena', 11, 11),
	(65, '2026-11-11 18:15:00+00', 'Lucía Benítez', 'CALIDAD', 'LOTE_LIBERADO', 'L-NOQ500-202646-01', 'Firma de protocolo de calidad', 'Lote liberado · OP en CC', 11, 11),
	(66, '2026-11-11 19:00:00+00', 'Diego Acosta', 'DEPOSITO', 'OP_FINALIZADA', 'OP-2026-00121', 'Recepción de 2 pallets · 490 kg', 'OP Finalizada', 11, 11),
	(67, '2026-11-12 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00122', 'Creación de la orden', 'OP Creada', 12, NULL),
	(68, '2026-11-12 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00122', 'Confirmación de disponibilidad', 'OP Planificada', 12, NULL),
	(69, '2026-11-12 10:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00122', 'Inicio de elaboración y asignación de lote', 'OP En producción', 12, NULL),
	(70, '2026-11-12 11:40:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-TIR500-202646-01', 'Fin de elaboración · 980 kg netos', 'Lote Cuarentena', 12, 12),
	(71, '2026-11-12 12:45:00+00', 'Lucía Benítez', 'CALIDAD', 'LOTE_LIBERADO', 'L-TIR500-202646-01', 'Firma de protocolo de calidad', 'Lote liberado · OP en CC', 12, 12),
	(72, '2026-11-12 13:30:00+00', 'Diego Acosta', 'DEPOSITO', 'OP_FINALIZADA', 'OP-2026-00122', 'Recepción de 4 pallets · 980 kg', 'OP Finalizada', 12, 12),
	(73, '2026-11-12 11:30:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00123', 'Creación de la orden', 'OP Creada', 13, NULL),
	(74, '2026-11-12 11:30:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00123', 'Confirmación de disponibilidad', 'OP Planificada', 13, NULL),
	(75, '2026-11-12 12:30:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00123', 'Inicio de elaboración y asignación de lote', 'OP En producción', 13, NULL),
	(76, '2026-11-12 14:10:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-LEN8K-202646-01', 'Fin de elaboración · 392 kg netos', 'Lote Cuarentena', 13, 13),
	(77, '2026-11-12 15:15:00+00', 'Lucía Benítez', 'CALIDAD', 'LOTE_LIBERADO', 'L-LEN8K-202646-01', 'Firma de protocolo de calidad', 'Lote liberado · OP en CC', 13, 13),
	(78, '2026-11-12 16:00:00+00', 'Diego Acosta', 'DEPOSITO', 'OP_FINALIZADA', 'OP-2026-00123', 'Recepción de 1 pallets · 392 kg', 'OP Finalizada', 13, 13),
	(79, '2026-11-12 14:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00124', 'Creación de la orden', 'OP Creada', 14, NULL),
	(80, '2026-11-12 14:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00124', 'Confirmación de disponibilidad', 'OP Planificada', 14, NULL),
	(81, '2026-11-12 15:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00124', 'Inicio de elaboración y asignación de lote', 'OP En producción', 14, NULL),
	(82, '2026-11-12 16:40:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-TOME20-202646-01', 'Fin de elaboración · 200 kg netos', 'Lote Cuarentena', 14, 14),
	(83, '2026-11-12 17:45:00+00', 'Lucía Benítez', 'CALIDAD', 'LOTE_LIBERADO', 'L-TOME20-202646-01', 'Firma de protocolo de calidad', 'Lote liberado · OP en CC', 14, 14),
	(84, '2026-11-12 18:30:00+00', 'Diego Acosta', 'DEPOSITO', 'OP_FINALIZADA', 'OP-2026-00124', 'Recepción de 1 pallets · 200 kg', 'OP Finalizada', 14, 14),
	(85, '2026-11-13 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00125', 'Creación de la orden', 'OP Creada', 15, NULL),
	(86, '2026-11-13 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00125', 'Confirmación de disponibilidad', 'OP Planificada', 15, NULL),
	(87, '2026-11-13 10:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00125', 'Inicio de elaboración y asignación de lote', 'OP En producción', 15, NULL),
	(88, '2026-11-13 11:40:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-COD500-202646-01', 'Fin de elaboración · 1176 kg netos', 'Lote Cuarentena', 15, 15),
	(89, '2026-11-13 12:45:00+00', 'Lucía Benítez', 'CALIDAD', 'LOTE_LIBERADO', 'L-COD500-202646-01', 'Firma de protocolo de calidad', 'Lote liberado · OP en CC', 15, 15),
	(90, '2026-11-13 13:30:00+00', 'Diego Acosta', 'DEPOSITO', 'OP_FINALIZADA', 'OP-2026-00125', 'Recepción de 4 pallets · 1176 kg', 'OP Finalizada', 15, 15),
	(91, '2026-11-14 13:30:00+00', 'Diego Acosta', 'DEPOSITO', 'DESPACHO', 'L-COD500-202646-01', 'Despacho de 300 kg a Distribuidora Mayorista del Litoral S.R.L.', 'Stock descontado', 15, 15),
	(92, '2026-11-13 12:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00126', 'Creación de la orden', 'OP Creada', 16, NULL),
	(93, '2026-11-13 12:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00126', 'Confirmación de disponibilidad', 'OP Planificada', 16, NULL),
	(94, '2026-11-13 13:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00126', 'Inicio de elaboración y asignación de lote', 'OP En producción', 16, NULL),
	(95, '2026-11-13 14:40:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-BUN200-202646-01', 'Fin de elaboración · 156.8 kg netos', 'Lote Cuarentena', 16, 16),
	(96, '2026-11-16 15:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00127', 'Creación de la orden', 'OP Creada', 17, NULL),
	(97, '2026-11-16 15:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00127', 'Confirmación de disponibilidad', 'OP Planificada', 17, NULL),
	(98, '2026-11-16 16:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00127', 'Inicio de elaboración y asignación de lote', 'OP En producción', 17, NULL),
	(99, '2026-11-16 17:40:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-SPA500-202647-01', 'Fin de elaboración · 1176 kg netos', 'Lote Cuarentena', 17, 17),
	(100, '2026-11-16 13:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00128', 'Creación de la orden', 'OP Creada', 18, NULL);
INSERT INTO public.auditoria (id, fecha, usuario, rol, accion, entidad, detalle, resultado, op_id, lote_id) VALUES
	(101, '2026-11-16 13:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00128', 'Confirmación de disponibilidad', 'OP Planificada', 18, NULL),
	(102, '2026-11-16 13:15:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CANCELADA', 'OP-2026-00128', 'Cancelación de la orden · Se cancela por cambio en el pedido del cliente', 'OP Cancelada', 18, NULL),
	(103, '2026-11-16 12:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00129', 'Creación de la orden', 'OP Creada', 19, NULL),
	(104, '2026-11-16 12:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00129', 'Confirmación de disponibilidad', 'OP Planificada', 19, NULL),
	(105, '2026-11-16 13:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00129', 'Inicio de elaboración y asignación de lote', 'OP En producción', 19, NULL),
	(106, '2026-11-16 14:40:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-PIZ500-202647-01', 'Fin de elaboración · 588 kg netos', 'Lote Cuarentena', 19, 18),
	(107, '2026-11-16 15:45:00+00', 'Lucía Benítez', 'CALIDAD', 'LOTE_BLOQUEADO', 'L-PIZ500-202647-01', 'Firma de protocolo de calidad · lote rechazado', 'Lote bloqueado · OP rechazada', 19, 18),
	(108, '2026-11-16 15:45:00+00', 'Lucía Benítez', 'CALIDAD', 'ALERTA_NO_CONFORMIDAD', 'L-PIZ500-202647-01', 'Jefatura de planta: desvío en el lote L-PIZ500-202647-01 (OP-2026-00129). Lote bloqueado y orden a Scrap. Recuento microbiológico fuera de especificación. Se bloquea el lote y se informa a jefatura de planta.', NULL, 19, 18),
	(109, '2026-11-16 10:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00130', 'Creación de la orden', 'OP Creada', 20, NULL),
	(110, '2026-11-16 10:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00130', 'Confirmación de disponibilidad', 'OP Planificada', 20, NULL),
	(111, '2026-11-16 11:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00130', 'Inicio de elaboración y asignación de lote', 'OP En producción', 20, NULL),
	(112, '2026-11-16 12:40:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-ZANC20-202647-01', 'Fin de elaboración · 200 kg netos', 'Lote Cuarentena', 20, 19),
	(113, '2026-11-16 13:45:00+00', 'Lucía Benítez', 'CALIDAD', 'LOTE_LIBERADO', 'L-ZANC20-202647-01', 'Firma de protocolo de calidad', 'Lote liberado · OP en CC', 20, 19),
	(114, '2026-11-17 08:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00131', 'Creación de la orden', 'OP Creada', 21, NULL),
	(115, '2026-11-17 08:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00131', 'Confirmación de disponibilidad', 'OP Planificada', 21, NULL),
	(116, '2026-11-17 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00131', 'Inicio de elaboración y asignación de lote', 'OP En producción', 21, NULL),
	(117, '2026-11-17 10:40:00+00', 'Martín Pérez', 'PRODUCCION', 'LOTE_EN_CUARENTENA', 'L-ARZ240-202647-01', 'Fin de elaboración · 235.2 kg netos', 'Lote Cuarentena', 21, 20),
	(118, '2026-11-17 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00132', 'Creación de la orden', 'OP Creada', 22, NULL),
	(119, '2026-11-17 09:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00132', 'Confirmación de disponibilidad', 'OP Planificada', 22, NULL),
	(120, '2026-11-17 10:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_INICIADA', 'OP-2026-00132', 'Inicio de elaboración y asignación de lote', 'OP En producción', 22, NULL),
	(121, '2026-11-17 10:40:00+00', 'Martín Pérez', 'PRODUCCION', 'LINEA_PAUSADA', 'OP-2026-00132', 'Pausa de línea · Ajuste del dosificador', 'En producción (pausada)', 22, NULL),
	(122, '2026-11-17 10:30:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00133', 'Creación de la orden', 'OP Creada', 23, NULL),
	(123, '2026-11-17 10:30:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00133', 'Confirmación de disponibilidad', 'OP Planificada', 23, NULL),
	(124, '2026-11-17 13:30:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00134', 'Creación de la orden', 'OP Creada', 24, NULL),
	(125, '2026-11-17 13:30:00+00', 'Martín Pérez', 'PRODUCCION', 'ALERTA_COMPRAS', 'OP-2026-00134', 'Compras y Suministros: la OP-2026-00134 necesita abastecimiento. Huevo en polvo: faltan 7 kg', NULL, 24, NULL),
	(126, '2026-11-17 14:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_CREADA', 'OP-2026-00135', 'Creación de la orden', 'OP Creada', 25, NULL),
	(127, '2026-11-17 14:00:00+00', 'Martín Pérez', 'PRODUCCION', 'OP_PLANIFICADA', 'OP-2026-00135', 'Confirmación de disponibilidad', 'OP Planificada', 25, NULL);


--
-- Data for Name: categoria; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.categoria (id, codigo, nombre, familia, url_web) VALUES
	(1, 'DESHIDRATADOS', 'Línea Deshidratados', 'Línea Tierra', 'https://agrifood-argentina.com/linea-deshidratados.php'),
	(2, 'FRUTOS_SECOS', 'Línea Frutos Secos', 'Línea Tierra', 'https://agrifood-argentina.com/linea-frutos-secos.php'),
	(3, 'PRE_ELABORADOS', 'Línea Pre Elaborados', 'Línea Tierra', 'https://agrifood-argentina.com/linea-pre-elaborados.php'),
	(4, 'PRE_MEZCLAS', 'Línea Pre Mezclas', 'Línea Molino', 'https://agrifood-argentina.com/linea-pre-mezclas.php'),
	(5, 'PASTAS_SECAS', 'Línea Pastas Secas', 'Línea Molino', 'https://agrifood-argentina.com/linea-pastas-secas.php');


--
-- Data for Name: consumo; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.consumo (id, op_id, insumo_id, partida_id, cantidad) VALUES
	(1, 1, 2, 4, 840),
	(2, 1, 1, 1, 372),
	(3, 1, 34, 37, 2400),
	(4, 1, 39, 42, 100),
	(5, 1, 42, 45, 4),
	(6, 2, 1, 1, 570),
	(7, 2, 4, 6, 15),
	(8, 2, 8, 10, 15),
	(9, 2, 11, 13, 12),
	(10, 2, 34, 37, 1200),
	(11, 2, 39, 42, 50),
	(12, 2, 42, 45, 2),
	(13, 3, 19, 21, 620),
	(14, 3, 37, 40, 10),
	(15, 3, 41, 44, 10),
	(16, 3, 42, 45, 1),
	(17, 4, 2, 4, 840),
	(18, 4, 1, 1, 372),
	(19, 4, 34, 37, 2400),
	(20, 4, 39, 42, 100),
	(21, 4, 42, 45, 4),
	(22, 5, 13, 15, 280),
	(23, 5, 29, 32, 24),
	(24, 5, 30, 33, 20),
	(25, 5, 31, 34, 16),
	(26, 5, 32, 35, 16),
	(27, 5, 4, 6, 12),
	(28, 5, 15, 17, 12),
	(29, 5, 5, 7, 8),
	(30, 5, 12, 14, 8),
	(31, 5, 16, 18, 8),
	(32, 5, 33, 36, 4),
	(33, 5, 36, 39, 50),
	(34, 5, 41, 44, 50),
	(35, 5, 42, 45, 1),
	(36, 6, 1, 1, 275),
	(37, 6, 3, 5, 175),
	(38, 6, 10, 12, 30),
	(39, 6, 6, 8, 15),
	(40, 6, 9, 11, 10),
	(41, 6, 4, 6, 5),
	(42, 6, 34, 37, 1000),
	(43, 6, 39, 42, 42),
	(44, 6, 42, 45, 2),
	(45, 7, 26, 29, 242.4),
	(46, 7, 38, 41, 2000),
	(47, 7, 40, 43, 24),
	(48, 7, 42, 45, 1),
	(49, 8, 20, 22, 1150),
	(50, 8, 37, 40, 10),
	(51, 8, 41, 44, 10),
	(52, 8, 42, 45, 1),
	(53, 9, 2, 4, 700),
	(54, 9, 1, 1, 310),
	(55, 9, 34, 37, 2000),
	(56, 9, 39, 42, 84),
	(57, 9, 42, 45, 4),
	(58, 10, 29, 32, 270),
	(59, 10, 32, 35, 139.5),
	(60, 10, 7, 9, 40.5),
	(61, 10, 4, 6, 9),
	(62, 10, 36, 39, 100),
	(63, 10, 41, 44, 100),
	(64, 10, 42, 45, 2),
	(65, 11, 29, 32, 250),
	(66, 11, 1, 1, 230),
	(67, 11, 6, 8, 15),
	(68, 11, 4, 6, 10),
	(69, 11, 12, 14, 5),
	(70, 11, 34, 37, 1000),
	(71, 11, 39, 42, 42),
	(72, 11, 42, 45, 2),
	(73, 12, 2, 4, 700),
	(74, 12, 1, 1, 310),
	(75, 12, 34, 37, 2000),
	(76, 12, 39, 42, 84),
	(77, 12, 42, 45, 4),
	(78, 13, 14, 16, 200),
	(79, 13, 13, 15, 80),
	(80, 13, 29, 32, 24),
	(81, 13, 30, 33, 24),
	(82, 13, 31, 34, 20),
	(83, 13, 15, 17, 16),
	(84, 13, 4, 6, 12),
	(85, 13, 32, 35, 12),
	(86, 13, 5, 7, 8),
	(87, 13, 16, 18, 8),
	(88, 13, 12, 14, 4),
	(89, 13, 36, 39, 50),
	(90, 13, 41, 44, 50),
	(91, 13, 42, 45, 1),
	(92, 14, 25, 28, 620),
	(93, 14, 3, 5, 10),
	(94, 14, 17, 19, 10),
	(95, 14, 18, 20, 10),
	(96, 14, 37, 40, 10),
	(97, 14, 41, 44, 10),
	(98, 14, 42, 45, 1),
	(99, 15, 2, 4, 840),
	(100, 15, 1, 1, 372);
INSERT INTO public.consumo (id, op_id, insumo_id, partida_id, cantidad) VALUES
	(101, 15, 34, 37, 2400),
	(102, 15, 39, 42, 100),
	(103, 15, 42, 45, 4),
	(104, 16, 1, 1, 96),
	(105, 16, 33, 36, 24),
	(106, 16, 7, 9, 16),
	(107, 16, 6, 8, 12.8),
	(108, 16, 9, 11, 6.4),
	(109, 16, 15, 17, 4.8),
	(110, 16, 4, 6, 3.2),
	(111, 16, 35, 38, 800),
	(112, 16, 39, 42, 34),
	(113, 16, 42, 45, 1),
	(114, 17, 2, 4, 840),
	(115, 17, 1, 1, 372),
	(116, 17, 34, 37, 2400),
	(117, 17, 39, 42, 100),
	(118, 17, 42, 45, 4),
	(119, 19, 1, 1, 570),
	(120, 19, 4, 6, 15),
	(121, 19, 8, 10, 15),
	(122, 19, 11, 13, 12),
	(123, 19, 34, 37, 1200),
	(124, 19, 39, 42, 50),
	(125, 19, 42, 45, 2),
	(126, 20, 22, 25, 1800),
	(127, 20, 37, 40, 10),
	(128, 20, 41, 44, 10),
	(129, 20, 42, 45, 1),
	(130, 21, 13, 15, 168),
	(131, 21, 29, 32, 14.4),
	(132, 21, 30, 33, 12),
	(133, 21, 31, 34, 9.6),
	(134, 21, 32, 35, 9.6),
	(135, 21, 4, 6, 7.2),
	(136, 21, 15, 17, 7.2),
	(137, 21, 5, 7, 4.8),
	(138, 21, 12, 14, 4.8),
	(139, 21, 16, 18, 4.8),
	(140, 21, 33, 36, 2.4),
	(141, 21, 35, 38, 1001),
	(142, 21, 39, 42, 42),
	(143, 21, 42, 45, 1);


--
-- Data for Name: control_calidad; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.control_calidad (id, lote_id, protocolo, formulario, humedad, ph, aroma, color, sabor, ufc, dictamen, observaciones, analista, fecha) VALUES
	(1, 1, 'CC-2026-00111', 'R.BPM.01V01', 9.8, 6.3, 'Característico', 'Amarillo ámbar uniforme', 'Característico', 320, 'APROBAR_LIBERAR', 'Resultados dentro de la especificación de ejemplo. Sin desvíos observados.', 'Lucía Benítez', '2026-11-04 12:45:00+00'),
	(2, 2, 'CC-2026-00112', 'R.BPM.01V01', 10.5, 6.5, 'Característico', 'Blanco crema', 'Característico', 320, 'APROBAR_LIBERAR', 'Resultados dentro de la especificación de ejemplo. Sin desvíos observados.', 'Lucía Benítez', '2026-11-05 12:45:00+00'),
	(3, 3, 'CC-2026-00113', 'R.BPM.01V01', 5.3, 6, 'Característico', 'Blanco cremoso', 'Característico', 320, 'APROBAR_LIBERAR', 'Resultados dentro de la especificación de ejemplo. Sin desvíos observados.', 'Lucía Benítez', '2026-11-06 12:45:00+00'),
	(4, 4, 'CC-2026-00114', 'R.BPM.01V01', 9.8, 6.3, 'Característico', 'Amarillo ámbar uniforme', 'Característico', 320, 'APROBAR_LIBERAR', 'Resultados dentro de la especificación de ejemplo. Sin desvíos observados.', 'Lucía Benítez', '2026-11-09 12:45:00+00'),
	(5, 5, 'CC-2026-00115', 'R.BPM.01V01', 7.5, 6.3, 'Característico', 'Característico con hortalizas visibles', 'Característico', 320, 'APROBAR_LIBERAR', 'Resultados dentro de la especificación de ejemplo. Sin desvíos observados.', 'Lucía Benítez', '2026-11-09 15:45:00+00'),
	(6, 6, 'CC-2026-00116', 'R.BPM.01V01', 9, 6.5, 'Característico', 'Marrón chocolate', 'Característico', 320, 'APROBAR_LIBERAR', 'Resultados dentro de la especificación de ejemplo. Sin desvíos observados.', 'Lucía Benítez', '2026-11-10 12:45:00+00'),
	(7, 7, 'CC-2026-00117', 'R.BPM.01V01', 4.5, 5.3, 'Característico', 'Mariposa blanca o ámbar', 'Característico', 320, 'APROBAR_LIBERAR', 'Resultados dentro de la especificación de ejemplo. Sin desvíos observados.', 'Lucía Benítez', '2026-11-10 15:15:00+00'),
	(8, 8, 'CC-2026-00118', 'R.BPM.01V01', 5.3, 6, 'Característico', 'Verde intenso', 'Característico', 320, 'APROBAR_LIBERAR', 'Resultados dentro de la especificación de ejemplo. Sin desvíos observados.', 'Lucía Benítez', '2026-11-10 17:45:00+00'),
	(9, 9, 'CC-2026-00119', 'R.BPM.01V01', 9.8, 6.3, 'Característico', 'Amarillo ámbar uniforme', 'Característico', 320, 'APROBAR_LIBERAR', 'Resultados dentro de la especificación de ejemplo. Sin desvíos observados.', 'Lucía Benítez', '2026-11-11 12:45:00+00'),
	(10, 10, 'CC-2026-00120', 'R.BPM.01V01', 7.5, 6.3, 'Característico', 'Amarillo anaranjado', 'Característico', 320, 'APROBAR_LIBERAR', 'Resultados dentro de la especificación de ejemplo. Sin desvíos observados.', 'Lucía Benítez', '2026-11-11 15:45:00+00'),
	(11, 11, 'CC-2026-00121', 'R.BPM.01V01', 10.5, 6.5, 'Característico', 'Blanco crema', 'Característico', 320, 'APROBAR_LIBERAR', 'Resultados dentro de la especificación de ejemplo. Sin desvíos observados.', 'Lucía Benítez', '2026-11-11 18:15:00+00'),
	(12, 12, 'CC-2026-00122', 'R.BPM.01V01', 9.8, 6.3, 'Característico', 'Amarillo ámbar uniforme', 'Característico', 320, 'APROBAR_LIBERAR', 'Resultados dentro de la especificación de ejemplo. Sin desvíos observados.', 'Lucía Benítez', '2026-11-12 12:45:00+00'),
	(13, 13, 'CC-2026-00123', 'R.BPM.01V01', 7.5, 6.3, 'Característico', 'Marrón con hortalizas visibles', 'Característico', 320, 'APROBAR_LIBERAR', 'Resultados dentro de la especificación de ejemplo. Sin desvíos observados.', 'Lucía Benítez', '2026-11-12 15:15:00+00'),
	(14, 14, 'CC-2026-00124', 'R.BPM.01V01', 5.3, 4.4, 'Característico', 'Rojo intenso', 'Característico', 320, 'APROBAR_LIBERAR', 'Resultados dentro de la especificación de ejemplo. Sin desvíos observados.', 'Lucía Benítez', '2026-11-12 17:45:00+00'),
	(15, 15, 'CC-2026-00125', 'R.BPM.01V01', 9.8, 6.3, 'Característico', 'Amarillo ámbar uniforme', 'Característico', 320, 'APROBAR_LIBERAR', 'Resultados dentro de la especificación de ejemplo. Sin desvíos observados.', 'Lucía Benítez', '2026-11-13 12:45:00+00'),
	(16, 18, 'CC-2026-00129', 'R.BPM.01V01', 10.5, 6.5, 'Característico', 'Blanco crema', 'Característico', 45000, 'RECHAZAR_BLOQUEAR', 'Recuento microbiológico fuera de especificación. Se bloquea el lote y se informa a jefatura de planta.', 'Lucía Benítez', '2026-11-16 15:45:00+00'),
	(17, 19, 'CC-2026-00130', 'R.BPM.01V01', 5.3, 6, 'Característico', 'Naranja intenso', 'Característico', 320, 'APROBAR_LIBERAR', 'Resultados dentro de la especificación de ejemplo. Sin desvíos observados.', 'Lucía Benítez', '2026-11-16 13:45:00+00');


--
-- Data for Name: despacho; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.despacho (id, lote_id, cliente, cantidad_kg, fecha, usuario) VALUES
	(1, 15, 'Distribuidora Mayorista del Litoral S.R.L.', 300, '2026-11-14 13:30:00+00', 'Diego Acosta');


--
-- Data for Name: insumo; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.insumo (id, codigo, nombre, tipo, unidad, critico, stock_minimo) VALUES
	(1, 'MP-HAR000', 'Harina de trigo 000', 'MP', 'kg', true, 1000),
	(2, 'MP-SEMOLA', 'Sémola de trigo candeal', 'MP', 'kg', true, 800),
	(3, 'MP-AZUCAR', 'Azúcar', 'MP', 'kg', true, 200),
	(4, 'MP-SAL', 'Sal fina', 'MP', 'kg', true, 50),
	(5, 'MP-ALMIDON', 'Almidón de maíz', 'MP', 'kg', true, 50),
	(6, 'MP-HUEVO', 'Huevo en polvo', 'MP', 'kg', true, 40),
	(7, 'MP-LECHE', 'Leche entera en polvo', 'MP', 'kg', true, 50),
	(8, 'MP-LEVAD', 'Levadura deshidratada', 'MP', 'kg', true, 15),
	(9, 'MP-LEUD', 'Leudante químico (bicarbonato y fosfato)', 'MP', 'kg', true, 15),
	(10, 'MP-CACAO', 'Cacao en polvo', 'MP', 'kg', true, 30),
	(11, 'MP-GLUCO', 'Glucosa en polvo', 'MP', 'kg', true, 15),
	(12, 'MP-COND', 'Condimentos (perejil, orégano, pimienta, nuez moscada)', 'MP', 'kg', true, 10),
	(13, 'MP-ARROZ', 'Arroz parboil', 'MP', 'kg', true, 300),
	(14, 'MP-LENTE', 'Lentejas', 'MP', 'kg', true, 200),
	(15, 'MP-CEBOL', 'Cebolla deshidratada', 'MP', 'kg', true, 30),
	(16, 'MP-MORRON', 'Pimiento morrón rojo deshidratado', 'MP', 'kg', true, 15),
	(17, 'MP-HARARR', 'Harina de arroz', 'MP', 'kg', true, 30),
	(18, 'MP-MALTO', 'Maltodextrina', 'MP', 'kg', true, 30),
	(19, 'MP-AJOF', 'Ajo fresco', 'MP', 'kg', true, 500),
	(20, 'MP-ESPF', 'Espinaca fresca', 'MP', 'kg', true, 800),
	(21, 'MP-PAPAF', 'Papa fresca', 'MP', 'kg', true, 1000),
	(22, 'MP-ZANAF', 'Zanahoria fresca', 'MP', 'kg', true, 800),
	(23, 'MP-ZAPF', 'Zapallo fresco', 'MP', 'kg', true, 800),
	(24, 'MP-ZAPC', 'Zapallo concentrado', 'MP', 'kg', true, 200),
	(25, 'MP-TOMC', 'Tomate concentrado doble', 'MP', 'kg', true, 300),
	(26, 'MP-NUEZ', 'Nueces peladas a granel', 'MP', 'kg', true, 100),
	(27, 'MP-PASA', 'Pasas de uva morochas a granel', 'MP', 'kg', true, 100),
	(28, 'MP-ARAN', 'Arándanos deshidratados a granel', 'MP', 'kg', true, 80),
	(29, 'MP-PAPAD', 'Papa deshidratada (de planta)', 'MP', 'kg', true, 100),
	(30, 'MP-ZANAD', 'Zanahoria deshidratada (de planta)', 'MP', 'kg', true, 30),
	(31, 'MP-TOMD', 'Tomate deshidratado (de planta)', 'MP', 'kg', true, 30),
	(32, 'MP-ZAPD', 'Zapallo deshidratado (de planta)', 'MP', 'kg', true, 30),
	(33, 'MP-ESPD', 'Espinaca deshidratada (de planta)', 'MP', 'kg', true, 20),
	(34, 'ENV-BOPP', 'Bolsa de polipropileno biorientado impresa 500 g', 'ME', 'un.', true, 1000),
	(35, 'ENV-POUCH', 'Bolsa pouch laminada (consumo)', 'ME', 'un.', true, 500),
	(36, 'ENV-INST', 'Bolsa institucional de polietileno', 'ME', 'un.', true, 50),
	(37, 'ENV-KRAFT', 'Bolsa de papel kraft multipliego con interior de polietileno', 'ME', 'un.', true, 50),
	(38, 'ENV-FLOW', 'Film flow pack 120 g', 'ME', 'un.', true, 1000),
	(39, 'CAJ-24', 'Caja de cartón corrugado x24', 'ME', 'un.', true, 100),
	(40, 'CAJ-10K', 'Caja de cartón 10 kg (frutos secos)', 'ME', 'un.', true, 30),
	(41, 'ETQ-LOTE', 'Etiqueta de lote', 'ME', 'un.', true, 200),
	(42, 'FIL-STR', 'Film estirable para pallets', 'ME', 'rollos', false, 20);


--
-- Data for Name: linea; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.linea (id, nombre, proceso) VALUES
	(1, 'Línea de mezclado', 'Dosificado, mezclado y envasado'),
	(2, 'Línea de pastas', 'Amasado, extrusión, secado y envasado'),
	(3, 'Deshidratadora', 'Lavado, cortado, deshidratado y molienda'),
	(4, 'Línea de fraccionamiento', 'Selección y envasado');


--
-- Data for Name: lote_produccion; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.lote_produccion (id, codigo, op_id, producto_id, cantidad_kg, bultos, vencimiento, estado, creado_en, borrador) VALUES
	(1, 'L-COD500-202645-01', 1, 28, 1176, 2352, '2027-11-04', 'APROBADO_LIBERADO', '2026-11-04 11:40:00+00', NULL),
	(2, 'L-PIZ500-202645-01', 2, 27, 588, 1176, '2027-11-05', 'APROBADO_LIBERADO', '2026-11-05 11:40:00+00', NULL),
	(3, 'L-AJOE20-202645-01', 3, 1, 200, 10, '2027-11-06', 'APROBADO_LIBERADO', '2026-11-06 11:40:00+00', NULL),
	(4, 'L-SPA500-202646-01', 4, 29, 1176, 2352, '2027-11-09', 'APROBADO_LIBERADO', '2026-11-09 11:40:00+00', NULL),
	(5, 'L-ARZ8K-202646-01', 5, 17, 392, 49, '2027-11-09', 'APROBADO_LIBERADO', '2026-11-09 14:40:00+00', NULL),
	(6, 'L-BIZC500-202646-01', 6, 24, 490, 980, '2027-11-10', 'APROBADO_LIBERADO', '2026-11-10 11:40:00+00', NULL),
	(7, 'L-NUE120-202646-01', 7, 12, 235.2, 1960, '2027-11-10', 'APROBADO_LIBERADO', '2026-11-10 14:10:00+00', NULL),
	(8, 'L-ESPE10-202646-01', 8, 3, 100, 10, '2027-11-10', 'APROBADO_LIBERADO', '2026-11-10 16:40:00+00', NULL),
	(9, 'L-RIG500-202646-01', 9, 30, 980, 1960, '2027-11-11', 'APROBADO_LIBERADO', '2026-11-11 11:40:00+00', NULL),
	(10, 'L-PUR4K-202646-01', 10, 23, 441, 98, '2027-11-11', 'APROBADO_LIBERADO', '2026-11-11 14:40:00+00', NULL),
	(11, 'L-NOQ500-202646-01', 11, 26, 490, 980, '2027-11-11', 'APROBADO_LIBERADO', '2026-11-11 17:10:00+00', NULL),
	(12, 'L-TIR500-202646-01', 12, 31, 980, 1960, '2027-11-12', 'APROBADO_LIBERADO', '2026-11-12 11:40:00+00', NULL),
	(13, 'L-LEN8K-202646-01', 13, 21, 392, 49, '2027-11-12', 'APROBADO_LIBERADO', '2026-11-12 14:10:00+00', NULL),
	(14, 'L-TOME20-202646-01', 14, 6, 200, 10, '2027-11-12', 'APROBADO_LIBERADO', '2026-11-12 16:40:00+00', NULL),
	(15, 'L-COD500-202646-01', 15, 28, 1176, 2352, '2027-11-13', 'APROBADO_LIBERADO', '2026-11-13 11:40:00+00', NULL),
	(18, 'L-PIZ500-202647-01', 19, 27, 588, 1176, '2027-11-16', 'RECHAZADO_BLOQUEADO', '2026-11-16 14:40:00+00', NULL),
	(19, 'L-ZANC20-202647-01', 20, 7, 200, 10, '2027-11-16', 'APROBADO_LIBERADO', '2026-11-16 12:40:00+00', NULL),
	(20, 'L-ARZ240-202647-01', 21, 16, 235.2, 980, '2027-11-17', 'CUARENTENA', '2026-11-17 10:40:00+00', NULL),
	(16, 'L-BUN200-202646-01', 16, 18, 156.8, 784, '2027-11-13', 'CUARENTENA', '2026-11-13 14:40:00+00', '{"ph": 6.3, "ufc": "", "aroma": "Característico", "color": "", "sabor": "", "humedad": 8.2, "dictamen": "", "guardado_en": "2026-11-17T10:40:00.000Z", "guardado_por": "Lucía Benítez", "observaciones": ""}'),
	(17, 'L-SPA500-202647-01', 17, 29, 1176, 2352, '2027-11-16', 'CUARENTENA', '2026-11-16 17:40:00+00', '{"ph": 6.3, "ufc": "", "aroma": "Característico", "color": "", "sabor": "", "humedad": 8.2, "dictamen": "", "guardado_en": "2026-11-17T10:40:00.000Z", "guardado_por": "Lucía Benítez", "observaciones": ""}');


--
-- Data for Name: op_item; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.op_item (op_id, insumo_id, cantidad_teorica) VALUES
	(1, 2, 840),
	(1, 1, 372),
	(1, 34, 2400),
	(1, 39, 100),
	(1, 42, 4),
	(2, 1, 570),
	(2, 4, 15),
	(2, 8, 15),
	(2, 11, 12),
	(2, 34, 1200),
	(2, 39, 50),
	(2, 42, 2),
	(3, 19, 620),
	(3, 37, 10),
	(3, 41, 10),
	(3, 42, 1),
	(4, 2, 840),
	(4, 1, 372),
	(4, 34, 2400),
	(4, 39, 100),
	(4, 42, 4),
	(5, 13, 280),
	(5, 29, 24),
	(5, 30, 20),
	(5, 31, 16),
	(5, 32, 16),
	(5, 4, 12),
	(5, 15, 12),
	(5, 5, 8),
	(5, 12, 8),
	(5, 16, 8),
	(5, 33, 4),
	(5, 36, 50),
	(5, 41, 50),
	(5, 42, 1),
	(6, 1, 275),
	(6, 3, 175),
	(6, 10, 30),
	(6, 6, 15),
	(6, 9, 10),
	(6, 4, 5),
	(6, 34, 1000),
	(6, 39, 42),
	(6, 42, 2),
	(7, 26, 242.4),
	(7, 38, 2000),
	(7, 40, 24),
	(7, 42, 1),
	(8, 20, 1150),
	(8, 37, 10),
	(8, 41, 10),
	(8, 42, 1),
	(9, 2, 700),
	(9, 1, 310),
	(9, 34, 2000),
	(9, 39, 84),
	(9, 42, 4),
	(10, 29, 270),
	(10, 32, 139.5),
	(10, 7, 40.5),
	(10, 4, 9),
	(10, 36, 100),
	(10, 41, 100),
	(10, 42, 2),
	(11, 29, 250),
	(11, 1, 230),
	(11, 6, 15),
	(11, 4, 10),
	(11, 12, 5),
	(11, 34, 1000),
	(11, 39, 42),
	(11, 42, 2),
	(12, 2, 700),
	(12, 1, 310),
	(12, 34, 2000),
	(12, 39, 84),
	(12, 42, 4),
	(13, 14, 200),
	(13, 13, 80),
	(13, 29, 24),
	(13, 30, 24),
	(13, 31, 20),
	(13, 15, 16),
	(13, 4, 12),
	(13, 32, 12),
	(13, 5, 8),
	(13, 16, 8),
	(13, 12, 4),
	(13, 36, 50),
	(13, 41, 50),
	(13, 42, 1),
	(14, 25, 620),
	(14, 3, 10),
	(14, 17, 10),
	(14, 18, 10),
	(14, 37, 10),
	(14, 41, 10),
	(14, 42, 1),
	(15, 2, 840),
	(15, 1, 372);
INSERT INTO public.op_item (op_id, insumo_id, cantidad_teorica) VALUES
	(15, 34, 2400),
	(15, 39, 100),
	(15, 42, 4),
	(16, 1, 96),
	(16, 33, 24),
	(16, 7, 16),
	(16, 6, 12.8),
	(16, 9, 6.4),
	(16, 15, 4.8),
	(16, 4, 3.2),
	(16, 35, 800),
	(16, 39, 34),
	(16, 42, 1),
	(17, 2, 840),
	(17, 1, 372),
	(17, 34, 2400),
	(17, 39, 100),
	(17, 42, 4),
	(18, 27, 121.2),
	(18, 38, 1000),
	(18, 40, 12),
	(18, 42, 1),
	(19, 1, 570),
	(19, 4, 15),
	(19, 8, 15),
	(19, 11, 12),
	(19, 34, 1200),
	(19, 39, 50),
	(19, 42, 2),
	(20, 22, 1800),
	(20, 37, 10),
	(20, 41, 10),
	(20, 42, 1),
	(21, 13, 168),
	(21, 29, 14.4),
	(21, 30, 12),
	(21, 31, 9.6),
	(21, 32, 9.6),
	(21, 4, 7.2),
	(21, 15, 7.2),
	(21, 5, 4.8),
	(21, 12, 4.8),
	(21, 16, 4.8),
	(21, 33, 2.4),
	(21, 35, 1001),
	(21, 39, 42),
	(21, 42, 1),
	(22, 2, 840),
	(22, 1, 372),
	(22, 34, 2400),
	(22, 39, 100),
	(22, 42, 4),
	(23, 2, 700),
	(23, 1, 310),
	(23, 34, 2000),
	(23, 39, 84),
	(23, 42, 4),
	(24, 1, 240),
	(24, 33, 60),
	(24, 7, 40),
	(24, 6, 32),
	(24, 9, 16),
	(24, 15, 12),
	(24, 4, 8),
	(24, 36, 80),
	(24, 41, 80),
	(24, 42, 1),
	(25, 19, 620),
	(25, 37, 10),
	(25, 41, 10),
	(25, 42, 1);


--
-- Data for Name: orden_produccion; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.orden_produccion (id, secuencia, numero, producto_id, receta_id, linea_id, cantidad_kg, fecha_proyectada, hora_prevista, estado, pausada, motivo_pausa, observaciones, creado_por, creado_en, inicio_real, operador, fin_elaboracion, cierre, cantidad_real_kg, bultos, merma_kg, merma_pct, lote_codigo_previsto, vencimiento_previsto, avance) VALUES
	(1, 111, 'OP-2026-00111', 28, 28, 2, 1200, '2026-11-04', '07:00', 'FINALIZADA', false, NULL, NULL, 'Martín Pérez', '2026-11-04 09:00:00+00', '2026-11-04 10:00:00+00', 'Martín Pérez', '2026-11-04 11:40:00+00', '2026-11-04 13:30:00+00', 1176, 2352, 36, 2.97, 'L-COD500-202645-01', '2027-11-04', NULL),
	(2, 112, 'OP-2026-00112', 27, 27, 1, 600, '2026-11-05', '07:00', 'FINALIZADA', false, NULL, NULL, 'Martín Pérez', '2026-11-05 09:00:00+00', '2026-11-05 10:00:00+00', 'Martín Pérez', '2026-11-05 11:40:00+00', '2026-11-05 13:30:00+00', 588, 1176, 24, 3.92, 'L-PIZ500-202645-01', '2027-11-05', NULL),
	(3, 113, 'OP-2026-00113', 1, 1, 3, 200, '2026-11-06', '07:00', 'FINALIZADA', false, NULL, NULL, 'Martín Pérez', '2026-11-06 09:00:00+00', '2026-11-06 10:00:00+00', 'Martín Pérez', '2026-11-06 11:40:00+00', '2026-11-06 13:30:00+00', 200, 10, 420, 67.74, 'L-AJOE20-202645-01', '2027-11-06', NULL),
	(4, 114, 'OP-2026-00114', 29, 29, 2, 1200, '2026-11-09', '07:00', 'FINALIZADA', false, NULL, NULL, 'Martín Pérez', '2026-11-09 09:00:00+00', '2026-11-09 10:00:00+00', 'Martín Pérez', '2026-11-09 11:40:00+00', '2026-11-09 13:30:00+00', 1176, 2352, 36, 2.97, 'L-SPA500-202646-01', '2027-11-09', NULL),
	(5, 115, 'OP-2026-00115', 17, 17, 1, 400, '2026-11-09', '10:00', 'FINALIZADA', false, NULL, NULL, 'Martín Pérez', '2026-11-09 12:00:00+00', '2026-11-09 13:00:00+00', 'Martín Pérez', '2026-11-09 14:40:00+00', '2026-11-09 16:30:00+00', 392, 49, 16, 3.92, 'L-ARZ8K-202646-01', '2027-11-09', NULL),
	(6, 116, 'OP-2026-00116', 24, 24, 1, 500, '2026-11-10', '07:00', 'FINALIZADA', false, NULL, NULL, 'Martín Pérez', '2026-11-10 09:00:00+00', '2026-11-10 10:00:00+00', 'Martín Pérez', '2026-11-10 11:40:00+00', '2026-11-10 13:30:00+00', 490, 980, 20, 3.92, 'L-BIZC500-202646-01', '2027-11-10', NULL),
	(7, 117, 'OP-2026-00117', 12, 12, 4, 240, '2026-11-10', '09:30', 'FINALIZADA', false, NULL, NULL, 'Martín Pérez', '2026-11-10 11:30:00+00', '2026-11-10 12:30:00+00', 'Martín Pérez', '2026-11-10 14:10:00+00', '2026-11-10 16:00:00+00', 235.2, 1960, 7.2, 2.97, 'L-NUE120-202646-01', '2027-11-10', NULL),
	(8, 118, 'OP-2026-00118', 3, 3, 3, 100, '2026-11-10', '12:00', 'FINALIZADA', false, NULL, NULL, 'Martín Pérez', '2026-11-10 14:00:00+00', '2026-11-10 15:00:00+00', 'Martín Pérez', '2026-11-10 16:40:00+00', '2026-11-10 18:30:00+00', 100, 10, 1050, 91.3, 'L-ESPE10-202646-01', '2027-11-10', NULL),
	(9, 119, 'OP-2026-00119', 30, 30, 2, 1000, '2026-11-11', '07:00', 'FINALIZADA', false, NULL, NULL, 'Martín Pérez', '2026-11-11 09:00:00+00', '2026-11-11 10:00:00+00', 'Martín Pérez', '2026-11-11 11:40:00+00', '2026-11-11 13:30:00+00', 980, 1960, 30, 2.97, 'L-RIG500-202646-01', '2027-11-11', NULL),
	(10, 120, 'OP-2026-00120', 23, 23, 1, 450, '2026-11-11', '10:00', 'FINALIZADA', false, NULL, NULL, 'Martín Pérez', '2026-11-11 12:00:00+00', '2026-11-11 13:00:00+00', 'Martín Pérez', '2026-11-11 14:40:00+00', '2026-11-11 16:30:00+00', 441, 98, 18, 3.92, 'L-PUR4K-202646-01', '2027-11-11', NULL),
	(11, 121, 'OP-2026-00121', 26, 26, 1, 500, '2026-11-11', '12:30', 'FINALIZADA', false, NULL, NULL, 'Martín Pérez', '2026-11-11 14:30:00+00', '2026-11-11 15:30:00+00', 'Martín Pérez', '2026-11-11 17:10:00+00', '2026-11-11 19:00:00+00', 490, 980, 20, 3.92, 'L-NOQ500-202646-01', '2027-11-11', NULL),
	(12, 122, 'OP-2026-00122', 31, 31, 2, 1000, '2026-11-12', '07:00', 'FINALIZADA', false, NULL, NULL, 'Martín Pérez', '2026-11-12 09:00:00+00', '2026-11-12 10:00:00+00', 'Martín Pérez', '2026-11-12 11:40:00+00', '2026-11-12 13:30:00+00', 980, 1960, 30, 2.97, 'L-TIR500-202646-01', '2027-11-12', NULL),
	(13, 123, 'OP-2026-00123', 21, 21, 1, 400, '2026-11-12', '09:30', 'FINALIZADA', false, NULL, NULL, 'Martín Pérez', '2026-11-12 11:30:00+00', '2026-11-12 12:30:00+00', 'Martín Pérez', '2026-11-12 14:10:00+00', '2026-11-12 16:00:00+00', 392, 49, 16, 3.92, 'L-LEN8K-202646-01', '2027-11-12', NULL),
	(14, 124, 'OP-2026-00124', 6, 6, 3, 200, '2026-11-12', '12:00', 'FINALIZADA', false, NULL, NULL, 'Martín Pérez', '2026-11-12 14:00:00+00', '2026-11-12 15:00:00+00', 'Martín Pérez', '2026-11-12 16:40:00+00', '2026-11-12 18:30:00+00', 200, 10, 450, 69.23, 'L-TOME20-202646-01', '2027-11-12', NULL),
	(15, 125, 'OP-2026-00125', 28, 28, 2, 1200, '2026-11-13', '07:00', 'FINALIZADA', false, NULL, NULL, 'Martín Pérez', '2026-11-13 09:00:00+00', '2026-11-13 10:00:00+00', 'Martín Pérez', '2026-11-13 11:40:00+00', '2026-11-13 13:30:00+00', 1176, 2352, 36, 2.97, 'L-COD500-202646-01', '2027-11-13', NULL),
	(16, 126, 'OP-2026-00126', 18, 18, 1, 160, '2026-11-13', '10:00', 'EN_CONTROL_CALIDAD', false, NULL, NULL, 'Martín Pérez', '2026-11-13 12:00:00+00', '2026-11-13 13:00:00+00', 'Martín Pérez', '2026-11-13 14:40:00+00', NULL, 156.8, 784, 6.4, 3.92, 'L-BUN200-202646-01', '2027-11-13', NULL),
	(17, 127, 'OP-2026-00127', 29, 29, 2, 1200, '2026-11-16', '13:00', 'EN_CONTROL_CALIDAD', false, NULL, NULL, 'Martín Pérez', '2026-11-16 15:00:00+00', '2026-11-16 16:00:00+00', 'Martín Pérez', '2026-11-16 17:40:00+00', NULL, 1176, 2352, 36, 2.97, 'L-SPA500-202647-01', '2027-11-16', NULL),
	(18, 128, 'OP-2026-00128', 14, 14, 4, 120, '2026-11-16', '11:00', 'CANCELADA', false, NULL, NULL, 'Martín Pérez', '2026-11-16 13:00:00+00', NULL, NULL, NULL, '2026-11-16 13:15:00+00', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	(19, 129, 'OP-2026-00129', 27, 27, 1, 600, '2026-11-16', '10:00', 'RECHAZADA_SCRAP', false, NULL, NULL, 'Martín Pérez', '2026-11-16 12:00:00+00', '2026-11-16 13:00:00+00', 'Martín Pérez', '2026-11-16 14:40:00+00', '2026-11-16 15:45:00+00', 588, 1176, 24, 3.92, 'L-PIZ500-202647-01', '2027-11-16', NULL),
	(20, 130, 'OP-2026-00130', 7, 7, 3, 200, '2026-11-16', '08:00', 'EN_CONTROL_CALIDAD', false, NULL, NULL, 'Martín Pérez', '2026-11-16 10:00:00+00', '2026-11-16 11:00:00+00', 'Martín Pérez', '2026-11-16 12:40:00+00', NULL, 200, 10, 1600, 88.89, 'L-ZANC20-202647-01', '2027-11-16', NULL),
	(21, 131, 'OP-2026-00131', 16, 16, 1, 240, '2026-11-17', '06:00', 'EN_CONTROL_CALIDAD', false, NULL, NULL, 'Martín Pérez', '2026-11-17 08:00:00+00', '2026-11-17 09:00:00+00', 'Martín Pérez', '2026-11-17 10:40:00+00', NULL, 235.2, 980, 9.6, 3.92, 'L-ARZ240-202647-01', '2027-11-17', NULL),
	(22, 132, 'OP-2026-00132', 28, 28, 2, 1200, '2026-11-17', '07:00', 'EN_PRODUCCION', true, 'Ajuste del dosificador', NULL, 'Martín Pérez', '2026-11-17 09:00:00+00', '2026-11-17 10:00:00+00', 'Martín Pérez', NULL, NULL, NULL, NULL, NULL, NULL, 'L-COD500-202647-01', '2027-11-17', NULL),
	(23, 133, 'OP-2026-00133', 29, 29, 2, 1000, '2026-11-17', '08:30', 'PLANIFICADA', false, NULL, 'Elaboración del turno mañana. Verificar limpieza de línea y cambio de envase antes del inicio.', 'Martín Pérez', '2026-11-17 10:30:00+00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	(24, 134, 'OP-2026-00134', 19, 19, 1, 400, '2026-11-17', '11:30', 'CREADA', false, NULL, 'Falta huevo en polvo: esperando reposición.', 'Martín Pérez', '2026-11-17 13:30:00+00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	(25, 135, 'OP-2026-00135', 2, 2, 3, 200, '2026-11-17', '12:00', 'PLANIFICADA', false, NULL, 'Usar primero la partida de ajo que vence antes.', 'Martín Pérez', '2026-11-17 14:00:00+00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);


--
-- Data for Name: pallet; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.pallet (id, codigo, lote_id, bultos, kg) VALUES
	(1, 'PAL-2026-00001', 1, 600, 300),
	(2, 'PAL-2026-00002', 1, 600, 300),
	(3, 'PAL-2026-00003', 1, 600, 300),
	(4, 'PAL-2026-00004', 1, 552, 276),
	(5, 'PAL-2026-00005', 2, 600, 300),
	(6, 'PAL-2026-00006', 2, 576, 288),
	(7, 'PAL-2026-00007', 3, 10, 200),
	(8, 'PAL-2026-00008', 4, 600, 300),
	(9, 'PAL-2026-00009', 4, 600, 300),
	(10, 'PAL-2026-00010', 4, 600, 300),
	(11, 'PAL-2026-00011', 4, 552, 276),
	(12, 'PAL-2026-00012', 5, 49, 392),
	(13, 'PAL-2026-00013', 6, 600, 300),
	(14, 'PAL-2026-00014', 6, 380, 190),
	(15, 'PAL-2026-00015', 7, 1960, 235.2),
	(16, 'PAL-2026-00016', 8, 10, 100),
	(17, 'PAL-2026-00017', 9, 600, 300),
	(18, 'PAL-2026-00018', 9, 600, 300),
	(19, 'PAL-2026-00019', 9, 600, 300),
	(20, 'PAL-2026-00020', 9, 160, 80),
	(21, 'PAL-2026-00021', 10, 80, 360),
	(22, 'PAL-2026-00022', 10, 18, 81),
	(23, 'PAL-2026-00023', 11, 600, 300),
	(24, 'PAL-2026-00024', 11, 380, 190),
	(25, 'PAL-2026-00025', 12, 600, 300),
	(26, 'PAL-2026-00026', 12, 600, 300),
	(27, 'PAL-2026-00027', 12, 600, 300),
	(28, 'PAL-2026-00028', 12, 160, 80),
	(29, 'PAL-2026-00029', 13, 49, 392),
	(30, 'PAL-2026-00030', 14, 10, 200),
	(31, 'PAL-2026-00031', 15, 600, 300),
	(32, 'PAL-2026-00032', 15, 600, 300),
	(33, 'PAL-2026-00033', 15, 600, 300),
	(34, 'PAL-2026-00034', 15, 552, 276);


--
-- Data for Name: partida_insumo; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.partida_insumo (id, insumo_id, nro_lote, proveedor, cantidad, vencimiento, documento_origen, estado, ingreso) VALUES
	(3, 1, 'MF-261020', 'Molinos Florencia SAU', 2500, '2027-05-26', 'REM 00052-00093222', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(20, 18, 'MAL-261017', 'Almidones del Litoral S.A.', 80, '2027-11-12', 'REM-AL-261017', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(21, 19, 'AJO-Q-1104', 'Quinta Don Pedro (Colonia Caroya)', 1400, '2026-12-07', 'REM-QDP-1104', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(4, 2, 'MF-SC-2610', 'Molinos Florencia SAU', 2400, '2027-06-05', 'REM 00052-00093230', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(36, 33, 'ED-L-2644', 'Planta Agrifood · Deshidratadora', 100, '2027-10-13', 'TRF-INT-2648', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(5, 3, 'AZU-261011', 'Azucarera del Norte S.A.', 600, '2028-02-10', 'REM-AN-261011', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(22, 20, 'ESP-H-1109', 'Hortícola Cinturón Verde Córdoba', 700, '2026-11-20', 'REM-HCV-1109', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(23, 20, 'ESP-H-1111', 'Hortícola Cinturón Verde Córdoba', 1500, '2026-11-22', 'REM-HCV-1111', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(6, 4, 'SAL-261005', 'Salinas del Centro S.R.L.', 300, '2028-10-17', 'REM-SC-261005', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(7, 5, 'ALM-261003', 'Almidones del Litoral S.A.', 200, '2027-08-04', 'REM-AL-261003', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(24, 21, 'PAP-Q-1102', 'Quinta Don Pedro (Colonia Caroya)', 2500, '2026-12-12', 'REM-QDP-1102', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(37, 34, 'BOPP-2610', 'Plásticos Industriales S.A.', 12000, NULL, 'REM-PI-2610', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(25, 22, 'ZAN-H-1108', 'Hortícola Cinturón Verde Córdoba', 1800, '2026-11-29', 'REM-HCV-1108', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(8, 6, 'HUE-261007', 'Ovoproductos Pampeanos S.A.', 25, '2027-03-17', 'REM-OP-261007', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(26, 23, 'ZAP-Q-1105', 'Quinta Don Pedro (Colonia Caroya)', 1600, '2026-12-17', 'REM-QDP-1105', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(9, 7, 'LEC-261004', 'Lácteos Villa María S.A.', 200, '2027-06-05', 'REM-LV-261004', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(10, 8, 'LEV-261009', 'Levaduras Pampeanas S.A.', 60, '2027-03-07', 'REM-LP-261009', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(38, 35, 'POU-2610', 'Plásticos Industriales S.A.', 6000, NULL, 'REM-PI-2611', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(11, 9, 'LEU-261002', 'Insumos Panaderos S.R.L.', 80, '2027-09-13', 'REM-IP-261002', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(27, 24, 'ZAC-261003', 'Concentrados Mendocinos S.A.', 500, '2027-06-05', 'REM-CM-261003', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(39, 36, 'INS-2610', 'Plásticos Industriales S.A.', 400, NULL, 'REM-PI-2612', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(28, 25, 'TOC-261001', 'Concentrados Mendocinos S.A.', 900, '2027-06-25', 'REM-CM-261001', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(40, 37, 'KRA-2610', 'Cartocor S.A.', 300, NULL, 'REM-CA-2610', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(41, 38, 'FLW-2610', 'Plásticos Industriales S.A.', 8000, NULL, 'REM-PI-2613', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(42, 39, 'OC1424-CAJ', 'Cartocor S.A.', 900, NULL, 'OC 1424 · REM-CA-2611', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(43, 40, 'CJ10-2610', 'Cartocor S.A.', 120, NULL, 'REM-CA-2612', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(1, 1, 'MF-261001', 'Molinos Florencia SAU', 600, '2027-04-16', 'REM 00052-00093101', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(29, 26, 'NUE-261018', 'Nogales de Catamarca S.A.', 300, '2027-07-15', 'REM-NC-261018', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(12, 10, 'CAC-261006', 'Cacao del Plata S.A.', 90, '2027-10-13', 'REM-CP-261006', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(44, 41, 'ETQ-2610', 'Etiquetas del Centro S.A.', 2000, NULL, 'REM-EC-2610', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(45, 42, 'FIL-261002', 'Plásticos Industriales S.A.', 12, NULL, 'REM-PI-261002', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(30, 27, 'PAS-261019', 'Viñedos de San Juan S.R.L.', 260, '2027-08-14', 'REM-VS-261019', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(13, 11, 'GLU-261008', 'Insumos Panaderos S.R.L.', 60, '2027-09-13', 'REM-IP-261008', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(31, 28, 'ARA-261020', 'Berries del Litoral S.A.', 200, '2027-09-13', 'REM-BL-261020', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(32, 29, 'PD-L-2644', 'Planta Agrifood · Deshidratadora', 500, '2027-10-13', 'TRF-INT-2644', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(33, 30, 'ZD-L-2644', 'Planta Agrifood · Deshidratadora', 120, '2027-10-13', 'TRF-INT-2645', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(14, 12, 'CON-261010', 'Aromas del Campo S.R.L.', 40, '2027-10-13', 'REM-AC-261010', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(15, 13, 'ARR-261012', 'Arrocera Entrerriana S.A.', 900, '2027-09-13', 'REM-AE-261012', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(34, 31, 'TD-L-2644', 'Planta Agrifood · Deshidratadora', 120, '2027-10-13', 'TRF-INT-2646', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(2, 1, 'MF-261015', 'Molinos Florencia SAU', 3000, '2027-05-01', 'REM 00052-00093180', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(16, 14, 'LEN-261013', 'Legumbres del Norte S.A.', 600, '2027-09-13', 'REM-LN-261013', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(17, 15, 'CEB-261014', 'Deshidratados de Cuyo S.A.', 120, '2027-10-13', 'REM-DC-261014', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(35, 32, 'ZPD-L-2644', 'Planta Agrifood · Deshidratadora', 200, '2027-10-13', 'TRF-INT-2647', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(18, 16, 'MOR-261014', 'Deshidratados de Cuyo S.A.', 50, '2027-10-13', 'REM-DC-261015', 'LIBERADO', '2026-11-18 00:38:08.033+00'),
	(19, 17, 'HAR-261016', 'Arrocera Entrerriana S.A.', 80, '2027-07-15', 'REM-AE-261016', 'LIBERADO', '2026-11-18 00:38:08.033+00');


--
-- Data for Name: producto; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.producto (id, codigo, gtin, nombre, linea_id, presentacion_kg, vida_util_meses, humedad_max, ph_min, ph_max, ufc_max, color_esperado, alergenos, almacenamiento, categoria_id, embalaje, ingredientes, presentacion, raciones, unidades_por_caja, unidades_por_pallet, url_web) VALUES
	(1, 'AJOE20', '7791234500017', 'Ajo Deshidratado en Escamas', 3, 20, 12, 7, 5, 7, 10000, 'Blanco cremoso', NULL, 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 1, 'Primario: bolsa cerrada de polietileno de baja densidad. Secundario: bolsa cerrada de papel kraft color marrón multipliego.', 'Ajo fresco, bulbo Allium sativum L.', '20 kg', NULL, NULL, 40, 'https://agrifood-argentina.com/productos/deshidratados/ajo-deshidratado-en-escamas.php'),
	(2, 'AJOP20', '7791234500024', 'Ajo Deshidratado en Polvo', 3, 20, 12, 7, 5, 7, 10000, 'Blanco cremoso', NULL, 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 1, 'Primario: bolsa cerrada de polietileno de baja densidad. Secundario: bolsa cerrada de papel kraft color marrón multipliego.', 'Ajo fresco, bulbo Allium sativum L.', '20 kg', NULL, NULL, 40, 'https://agrifood-argentina.com/productos/deshidratados/ajo-deshidratado-en-polvo.php'),
	(3, 'ESPE10', '7791234500031', 'Espinaca Deshidratada en Escamas', 3, 10, 12, 7, 5, 7, 10000, 'Verde intenso', NULL, 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 1, 'Primario: bolsa cerrada de polietileno de baja densidad. Secundario: bolsa cerrada de papel kraft color marrón multipliego.', 'Espinaca fresca, hojas de Spinacea oleracea L.', '10 kg', NULL, NULL, 36, 'https://agrifood-argentina.com/productos/deshidratados/espinaca-deshidratada-en-escamas.php'),
	(4, 'ESPP10', '7791234500048', 'Espinaca Deshidratada en Polvo', 3, 10, 12, 7, 5, 7, 10000, 'Verde intenso', NULL, 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 1, 'Primario: bolsa cerrada de polietileno de baja densidad. Secundario: bolsa cerrada de papel kraft color marrón multipliego.', 'Espinaca fresca, hojas de Spinacea oleracea L.', '10 kg', NULL, NULL, 36, 'https://agrifood-argentina.com/productos/deshidratados/espinaca-deshidratada-en-polvo.php'),
	(5, 'PAPC20', '7791234500055', 'Papa Deshidratada en Cubos', 3, 20, 12, 7, 5, 7, 10000, 'Blanco amarillento', NULL, 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 1, 'Primario: bolsa cerrada de polietileno de baja densidad. Secundario: bolsa cerrada de papel kraft color marrón multipliego.', 'Papa fresca, tubérculo Solanum tuberosum.', '20 kg', NULL, NULL, 40, 'https://agrifood-argentina.com/productos/deshidratados/papa-deshidratada-en-cubos.php'),
	(6, 'TOME20', '7791234500062', 'Tomate Deshidratado en Escamas', 3, 20, 12, 7, 4, 4.8, 10000, 'Rojo intenso', NULL, 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 1, 'Primario: bolsa cerrada de polietileno de baja densidad. Secundario: bolsa cerrada plastillera.', 'Tomate concentrado doble, azúcar, harina de arroz, maltodextrina (vehículo), bicarbonato de sodio INS 500 ii (regulador de acidez).', '20 kg', NULL, NULL, 40, 'https://agrifood-argentina.com/productos/deshidratados/tomate-deshidratado-en-escamas.php'),
	(7, 'ZANC20', '7791234500079', 'Zanahoria Deshidratada en Cubo', 3, 20, 12, 7, 5, 7, 10000, 'Naranja intenso', NULL, 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 1, 'Primario: bolsa cerrada de polietileno de baja densidad. Secundario: bolsa cerrada de papel kraft color marrón multipliego.', 'Zanahoria fresca, raíz de Daucus carota.', '20 kg', NULL, NULL, 40, 'https://agrifood-argentina.com/productos/deshidratados/zanahoria-deshidratada-en-cubo.php'),
	(8, 'ZAPC20', '7791234500086', 'Zapallo Deshidratado en Cubos', 3, 20, 12, 7, 5, 7, 10000, 'Naranja', NULL, 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 1, 'Primario: bolsa cerrada de polietileno de baja densidad. Secundario: bolsa cerrada de papel kraft color marrón multipliego.', 'Zapallo fresco, Cucurbita maxima.', '20 kg', NULL, NULL, 40, 'https://agrifood-argentina.com/productos/deshidratados/zapallo-deshidratada-en-cubos.php'),
	(9, 'ZAPE20', '7791234500093', 'Zapallo Deshidratado en Escamas', 3, 20, 12, 7, 5, 7, 10000, 'Naranja', NULL, 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 1, 'Primario: bolsa cerrada de polietileno de baja densidad. Secundario: bolsa cerrada de papel kraft color marrón multipliego.', 'Zapallo concentrado, almidón de maíz, azúcar, harina de arroz, maltodextrina (vehículo), bicarbonato de sodio INS 500 ii (regulador de acidez).', '20 kg', NULL, NULL, 40, 'https://agrifood-argentina.com/productos/deshidratados/zapallo-deshidratada-en-escamas.php'),
	(10, 'ARA120', '7791234500109', 'Arándanos', 4, 0.12, 12, 18, 3.5, 7, 10000, 'Rojo oscuro', NULL, 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 2, 'Flow pack de 120 g. Se despachan en cajas de 10 kg.', 'Arándanos deshidratados.', 'Flow Pack 120 g', NULL, 80, 3200, 'https://agrifood-argentina.com/productos/frutos-secos/arandanos-120gr.php'),
	(11, 'ARA5K', '7791234500116', 'Arándanos', 4, 5, 12, 18, 3.5, 7, 10000, 'Rojo oscuro', NULL, 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 2, 'Bolsa de polietileno de 5 kg. Se despachan en cajas de 10 kg.', 'Arándanos deshidratados.', '5 kg', NULL, NULL, 80, 'https://agrifood-argentina.com/productos/frutos-secos/arandanos-5kg.php'),
	(12, 'NUE120', '7791234500123', 'Nueces Californianas o Francesas', 4, 0.12, 12, 6, 3.5, 7, 10000, 'Mariposa blanca o ámbar', 'Contiene frutos secos (nuez).', 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 2, 'Flow pack de 120 g. Se despachan en cajas de 10 kg.', 'Nueces peladas, variedades mariposa blanca, mariposa ámbar y cobriza.', 'Flow Pack 120 g', NULL, 80, 3200, 'https://agrifood-argentina.com/productos/frutos-secos/nueces-peladas-120gr.php'),
	(13, 'NUE5K', '7791234500130', 'Nueces Californianas o Francesas', 4, 5, 12, 6, 3.5, 7, 10000, 'Mariposa blanca o ámbar', 'Contiene frutos secos (nuez).', 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 2, 'Bolsa de polietileno de 5 kg. Se despachan en cajas de 10 kg.', 'Nueces peladas, variedades mariposa blanca, mariposa ámbar y cobriza.', '5 kg', NULL, NULL, 80, 'https://agrifood-argentina.com/productos/frutos-secos/nueces-peladas-5kg.php'),
	(14, 'PAS120', '7791234500147', 'Pasas de Uvas Morochas', 4, 0.12, 12, 18, 3.5, 7, 10000, 'Morado oscuro', 'Puede contener sulfitos.', 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 2, 'Flow pack de 120 g. Se despachan en cajas de 10 kg.', 'Pasas de uva morochas.', 'Flow Pack 120 g', NULL, 80, 3200, 'https://agrifood-argentina.com/productos/frutos-secos/pasas-de-uvas-morochas-120gr.php'),
	(15, 'PAS5K', '7791234500154', 'Pasas de Uvas Morochas', 4, 5, 12, 18, 3.5, 7, 10000, 'Morado oscuro', 'Puede contener sulfitos.', 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 2, 'Bolsa de polietileno de 5 kg. Se despachan en cajas de 10 kg.', 'Pasas de uva morochas.', '5 kg', NULL, NULL, 80, 'https://agrifood-argentina.com/productos/frutos-secos/pasas-de-uvas-morochas-5kg.php'),
	(16, 'ARZ240', '7791234500161', 'Arroz con Hortalizas', 1, 0.24, 12, 10, 5.5, 7, 10000, 'Característico con hortalizas visibles', NULL, 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 3, 'Bolsa pouch laminada con cierre. Se despacha en cajas de cartón corrugado de 24 unidades.', 'Arroz parboil, papa deshidratada, zanahoria deshidratada, tomate deshidratado, zapallo deshidratado, cebolla deshidratada, sal, pimiento morrón rojo deshidratado, espinaca deshidratada, almidón de maíz, perejil, ajo en polvo, azúcar, pimienta blanca molida, orégano, pimentón y colorante: cúrcuma.', '240 g / 3 raciones', 3, 24, 1200, 'https://agrifood-argentina.com/productos/pre-elaborados/arroz-con-hortalizas-240gr.php'),
	(17, 'ARZ8K', '7791234500178', 'Arroz con Hortalizas', 1, 8, 12, 10, 5.5, 7, 10000, 'Característico con hortalizas visibles', NULL, 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 3, 'Bolsa institucional de polietileno de baja densidad, rotulada con lote y vencimiento.', 'Arroz parboil, papa deshidratada, zanahoria deshidratada, tomate deshidratado, zapallo deshidratado, cebolla deshidratada, sal, pimiento morrón rojo deshidratado, espinaca deshidratada, almidón de maíz, perejil, ajo en polvo, azúcar, pimienta blanca molida, orégano, pimentón y colorante: cúrcuma.', '8 kg / 100 raciones', 100, NULL, 60, 'https://agrifood-argentina.com/productos/pre-elaborados/arroz-con-hortalizas-8kg.php'),
	(18, 'BUN200', '7791234500185', 'Buñuelos de Espinaca', 1, 0.2, 12, 10, 5.5, 7, 10000, 'Verde claro', 'Contiene leche y huevo. Contiene derivados de trigo y soja. Puede contener restos de sulfitos.', 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 3, 'Bolsa pouch laminada con cierre. Se despacha en cajas de cartón corrugado de 24 unidades.', 'Harina de trigo tipo 000 enriquecida según Ley 25.630 (hierro, ácido fólico, tiamina, riboflavina, niacina), espinaca deshidratada, leche entera en polvo, huevo en polvo, sal, cebolla deshidratada, leudante químico: bicarbonato de sodio INS 500 ii.', '200 g / 8 raciones', 8, 24, 1200, 'https://agrifood-argentina.com/productos/pre-elaborados/bunuelos-espinaca-200gr.php'),
	(19, 'BUN5K', '7791234500192', 'Buñuelos de Espinaca', 1, 5, 12, 10, 5.5, 7, 10000, 'Verde claro', 'Contiene leche y huevo. Contiene derivados de trigo y soja. Puede contener restos de sulfitos.', 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 3, 'Bolsa institucional de polietileno de baja densidad, rotulada con lote y vencimiento.', 'Harina de trigo tipo 000 enriquecida según Ley 25.630 (hierro, ácido fólico, tiamina, riboflavina, niacina), espinaca deshidratada, leche entera en polvo, huevo en polvo, sal, cebolla deshidratada, leudante químico: bicarbonato de sodio INS 500 ii.', '5 kg / 200 raciones', 200, NULL, 80, 'https://agrifood-argentina.com/productos/pre-elaborados/bunuelos-espinaca-5kg.php'),
	(20, 'LEN240', '7791234500208', 'Guiso de Lentejas', 1, 0.24, 12, 10, 5.5, 7, 10000, 'Marrón con hortalizas visibles', 'Puede contener trigo, huevo, leche y sulfitos.', 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 3, 'Bolsa pouch laminada con cierre. Se despacha en cajas de cartón corrugado de 24 unidades.', 'Lentejas, arroz parboil, zanahoria deshidratada, papa deshidratada, cebolla deshidratada, tomate deshidratado, sal, almidón de maíz, zapallo deshidratado, pimiento morrón rojo deshidratado y orégano.', '240 g / 3 raciones', 3, 24, 1200, 'https://agrifood-argentina.com/productos/pre-elaborados/guiso-de-lentejas-240gr.php'),
	(21, 'LEN8K', '7791234500215', 'Guiso de Lentejas', 1, 8, 12, 10, 5.5, 7, 10000, 'Marrón con hortalizas visibles', 'Puede contener trigo, huevo, leche y sulfitos.', 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 3, 'Bolsa institucional de polietileno de baja densidad, rotulada con lote y vencimiento.', 'Lentejas, arroz parboil, zanahoria deshidratada, papa deshidratada, cebolla deshidratada, tomate deshidratado, sal, almidón de maíz, zapallo deshidratado, pimiento morrón rojo deshidratado y orégano.', '8 kg / 100 raciones', 100, NULL, 60, 'https://agrifood-argentina.com/productos/pre-elaborados/guiso-de-lentejas-8kg.php'),
	(22, 'PUR180', '7791234500222', 'Puré Mixto de Papa y Zapallo', 1, 0.18, 12, 10, 5.5, 7, 10000, 'Amarillo anaranjado', 'Contiene sulfitos, leche y derivados de soja. Puede contener huevo.', 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 3, 'Bolsa pouch laminada con cierre. Se despacha en cajas de cartón corrugado de 24 unidades.', 'Papa deshidratada (papa fresca, emulsionante: INS 471, estabilizante: INS 450 ii, conservante: INS 223, acidulante: INS 330, antioxidante: INS 321), zapallo deshidratado (zapallo concentrado, almidón de maíz, azúcar, harina de arroz, vehículo: maltodextrina, regulador de acidez: INS 500 ii), leche entera en polvo y sal.', '180 g / 6 raciones', 6, 24, 1200, 'https://agrifood-argentina.com/productos/pre-elaborados/pure-mixto-pure-zapallo-180gr.php'),
	(23, 'PUR4K', '7791234500239', 'Puré Mixto de Papa y Zapallo', 1, 4.5, 12, 10, 5.5, 7, 10000, 'Amarillo anaranjado', 'Contiene sulfitos, leche y derivados de soja. Puede contener huevo.', 'El producto deberá ser almacenado en su envase original al resguardo de la luz y protegido de factores contaminantes. No requiere refrigeración.', 3, 'Bolsa institucional de polietileno de baja densidad, rotulada con lote y vencimiento.', 'Papa deshidratada (papa fresca, emulsionante: INS 471, estabilizante: INS 450 ii, conservante: INS 223, acidulante: INS 330, antioxidante: INS 321), zapallo deshidratado (zapallo concentrado, almidón de maíz, azúcar, harina de arroz, vehículo: maltodextrina, regulador de acidez: INS 500 ii), leche entera en polvo y sal.', '4,5 kg / 150 raciones', 150, NULL, 80, 'https://agrifood-argentina.com/productos/pre-elaborados/pure-mixto-pure-zapallo-4kg.php'),
	(24, 'BIZC500', '7791234500246', 'Bizcochuelo Sabor Chocolate', 1, 0.5, 12, 12, 5.5, 7.5, 10000, 'Marrón chocolate', 'Contiene gluten (trigo) y huevo.', 'El producto deberá ser almacenado en su envase original en un lugar de 25 grados, 60% de humedad y protegido de factores contaminantes.', 4, 'Primario: bolsa cerrada de polietileno de baja densidad. Secundario: bolsa cerrada de polipropileno OPP + CPP.', 'Harina de trigo tipo 000 enriquecida según Ley 25.630 (hierro, ácido fólico, tiamina, riboflavina, niacina), azúcar, cacao en polvo, huevo en polvo, sal, leudantes químicos: INS 500 ii, aromatizante: aroma artificial a chocolate.', '500 g', NULL, 24, 600, 'https://agrifood-argentina.com/productos/pre-mezclas/bizcochuelo-sabor-chocolate-500gr.php'),
	(25, 'BIZV500', '7791234500253', 'Bizcochuelo Sabor Vainilla', 1, 0.5, 12, 12, 5.5, 7.5, 10000, 'Blanco crema', 'Contiene gluten (trigo) y huevo.', 'El producto deberá ser almacenado en su envase original en un lugar de 25 grados, 60% de humedad y protegido de factores contaminantes.', 4, 'Primario: bolsa cerrada de polietileno de baja densidad. Secundario: bolsa cerrada de polipropileno OPP + CPP.', 'Harina de trigo tipo 000 enriquecida según Ley 25.630 (hierro, ácido fólico, tiamina, riboflavina, niacina), azúcar, almidón de maíz, huevo en polvo, sal, leudantes químicos: INS 500 ii, aromatizante: aroma artificial a vainilla.', '500 g', NULL, 24, 600, 'https://agrifood-argentina.com/productos/pre-mezclas/bizcochuelo-sabor-vainilla-500gr.php'),
	(26, 'NOQ500', '7791234500260', 'Ñoquis de Papa Caseros', 1, 0.5, 12, 14, 5.5, 7.5, 10000, 'Blanco crema', 'Contiene gluten (trigo) y huevo. Contiene sulfitos.', 'El producto deberá ser almacenado en su envase original en un lugar de 25 grados, 60% de humedad y protegido de factores contaminantes.', 4, 'Primario: bolsa cerrada de polietileno de baja densidad. Secundario: bolsa cerrada de polipropileno OPP + CPP.', 'Harina de trigo tipo 000 enriquecida según Ley 25.630 (hierro, ácido fólico, tiamina, riboflavina, niacina), papa deshidratada, huevo en polvo, nuez moscada, leudantes químicos (bicarbonato de sodio INS 500 ii, fosfato monocálcico INS 341 i), estabilizante (INS 412).', '500 g', NULL, 24, 600, 'https://agrifood-argentina.com/productos/pre-mezclas/noquis-de-papa-caseros-500gr.php'),
	(27, 'PIZ500', '7791234500277', 'Pizza Casera Premezcla', 1, 0.5, 12, 14, 5.5, 7.5, 10000, 'Blanco crema', 'Contiene gluten (trigo).', 'El producto deberá ser almacenado en su envase original en un lugar de 25 grados, 60% de humedad y protegido de factores contaminantes.', 4, 'Primario: bolsa cerrada de polietileno de baja densidad. Secundario: bolsa cerrada de polipropileno OPP + CPP.', 'Harina de trigo tipo 000 enriquecida según Ley 25.630 (hierro, ácido fólico, tiamina, riboflavina, niacina), levadura deshidratada, glucosa en polvo, emulsionante (estearoil lactilato de sodio INS 481 i), mejoradores (ácido ascórbico INS 300, amilasa INS 1100, L-cisteína INS 920).', '500 g', NULL, 24, 600, 'https://agrifood-argentina.com/productos/pre-mezclas/pizza-casera-premezcla-500gr.php'),
	(28, 'COD500', '7791234500284', 'Coditos', 2, 0.5, 12, 13, 5.5, 7, 10000, 'Amarillo ámbar uniforme', 'Contiene gluten (trigo).', 'El producto deberá ser almacenado en su envase original en un lugar de 25 grados, 60% de humedad y protegido de factores contaminantes.', 5, 'Primario: bolsa cerrada de polietileno de baja densidad. Secundario: bolsa cerrada de polipropileno biorientado 20/20.', 'Sémola de trigo candeal y harina de trigo 000 enriquecida según Ley 25.630, agua.', '500 g', NULL, 24, 600, 'https://agrifood-argentina.com/productos/pastas-secas/coditos-500gr.php'),
	(29, 'SPA500', '7791234500291', 'Spaghetti', 2, 0.5, 12, 13, 5.5, 7, 10000, 'Amarillo ámbar uniforme', 'Contiene gluten (trigo).', 'El producto deberá ser almacenado en su envase original en un lugar de 25 grados, 60% de humedad y protegido de factores contaminantes.', 5, 'Primario: bolsa cerrada de polietileno de baja densidad. Secundario: bolsa cerrada de polipropileno biorientado 20/20.', 'Sémola de trigo candeal y harina de trigo 000 enriquecida según Ley 25.630, agua.', '500 g', NULL, 24, 600, 'https://agrifood-argentina.com/productos/pastas-secas/spaghetti-500gr.php'),
	(30, 'RIG500', '7791234500307', 'Rigatoni', 2, 0.5, 12, 13, 5.5, 7, 10000, 'Amarillo ámbar uniforme', 'Contiene gluten (trigo).', 'El producto deberá ser almacenado en su envase original en un lugar de 25 grados, 60% de humedad y protegido de factores contaminantes.', 5, 'Primario: bolsa cerrada de polietileno de baja densidad. Secundario: bolsa cerrada de polipropileno biorientado 20/20.', 'Sémola de trigo candeal y harina de trigo 000 enriquecida según Ley 25.630, agua.', '500 g', NULL, 24, 600, 'https://agrifood-argentina.com/productos/pastas-secas/rigatoni-500gr.php'),
	(31, 'TIR500', '7791234500314', 'Tirabuzon', 2, 0.5, 12, 13, 5.5, 7, 10000, 'Amarillo ámbar uniforme', 'Contiene gluten (trigo).', 'El producto deberá ser almacenado en su envase original en un lugar de 25 grados, 60% de humedad y protegido de factores contaminantes.', 5, 'Primario: bolsa cerrada de polietileno de baja densidad. Secundario: bolsa cerrada de polipropileno biorientado 20/20.', 'Sémola de trigo candeal y harina de trigo 000 enriquecida según Ley 25.630, agua.', '500 g', NULL, 24, 600, 'https://agrifood-argentina.com/productos/pastas-secas/tirabuzon-500gr.php');


--
-- Data for Name: receta; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.receta (id, codigo, producto_id, version, vigente_desde, base_kg, activa) VALUES
	(1, 'REC-AJOE20', 1, 1, '2026-07-01', 100, true),
	(2, 'REC-AJOP20', 2, 1, '2026-07-01', 100, true),
	(3, 'REC-ESPE10', 3, 1, '2026-07-01', 100, true),
	(4, 'REC-ESPP10', 4, 1, '2026-07-01', 100, true),
	(5, 'REC-PAPC20', 5, 1, '2026-07-01', 100, true),
	(6, 'REC-TOME20', 6, 1, '2026-07-01', 100, true),
	(7, 'REC-ZANC20', 7, 1, '2026-07-01', 100, true),
	(8, 'REC-ZAPC20', 8, 1, '2026-07-01', 100, true),
	(9, 'REC-ZAPE20', 9, 1, '2026-07-01', 100, true),
	(10, 'REC-ARA120', 10, 1, '2026-07-01', 100, true),
	(11, 'REC-ARA5K', 11, 1, '2026-07-01', 100, true),
	(12, 'REC-NUE120', 12, 1, '2026-07-01', 100, true),
	(13, 'REC-NUE5K', 13, 1, '2026-07-01', 100, true),
	(14, 'REC-PAS120', 14, 1, '2026-07-01', 100, true),
	(15, 'REC-PAS5K', 15, 1, '2026-07-01', 100, true),
	(16, 'REC-ARZ240', 16, 1, '2026-07-01', 100, true),
	(17, 'REC-ARZ8K', 17, 1, '2026-07-01', 100, true),
	(18, 'REC-BUN200', 18, 1, '2026-07-01', 100, true),
	(19, 'REC-BUN5K', 19, 1, '2026-07-01', 100, true),
	(20, 'REC-LEN240', 20, 1, '2026-07-01', 100, true),
	(21, 'REC-LEN8K', 21, 1, '2026-07-01', 100, true),
	(22, 'REC-PUR180', 22, 1, '2026-07-01', 100, true),
	(23, 'REC-PUR4K', 23, 1, '2026-07-01', 100, true),
	(24, 'REC-BIZC500', 24, 1, '2026-07-01', 100, true),
	(25, 'REC-BIZV500', 25, 1, '2026-07-01', 100, true),
	(26, 'REC-NOQ500', 26, 1, '2026-07-01', 100, true),
	(27, 'REC-PIZ500', 27, 1, '2026-07-01', 100, true),
	(28, 'REC-COD500', 28, 1, '2026-07-01', 100, true),
	(29, 'REC-SPA500', 29, 1, '2026-07-01', 100, true),
	(30, 'REC-RIG500', 30, 1, '2026-07-01', 100, true),
	(31, 'REC-TIR500', 31, 1, '2026-07-01', 100, true);


--
-- Data for Name: receta_item; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.receta_item (receta_id, insumo_id, cantidad_base) VALUES
	(1, 19, 310),
	(1, 37, 5),
	(1, 41, 5),
	(1, 42, 0.13),
	(2, 19, 310),
	(2, 37, 5),
	(2, 41, 5),
	(2, 42, 0.13),
	(3, 20, 1150),
	(3, 37, 10),
	(3, 41, 10),
	(3, 42, 0.28),
	(4, 20, 1150),
	(4, 37, 10),
	(4, 41, 10),
	(4, 42, 0.28),
	(5, 21, 520),
	(5, 37, 5),
	(5, 41, 5),
	(5, 42, 0.13),
	(6, 25, 310),
	(6, 3, 5),
	(6, 17, 5),
	(6, 18, 5),
	(6, 37, 5),
	(6, 41, 5),
	(6, 42, 0.13),
	(7, 22, 900),
	(7, 37, 5),
	(7, 41, 5),
	(7, 42, 0.13),
	(8, 23, 850),
	(8, 37, 5),
	(8, 41, 5),
	(8, 42, 0.13),
	(9, 24, 190),
	(9, 5, 8),
	(9, 3, 5),
	(9, 17, 5),
	(9, 18, 4),
	(9, 37, 5),
	(9, 41, 5),
	(9, 42, 0.13),
	(10, 28, 101),
	(10, 38, 833.33),
	(10, 40, 10),
	(10, 42, 0.26),
	(11, 28, 101),
	(11, 36, 20),
	(11, 40, 10),
	(11, 41, 20),
	(11, 42, 0.25),
	(12, 26, 101),
	(12, 38, 833.33),
	(12, 40, 10),
	(12, 42, 0.26),
	(13, 26, 101),
	(13, 36, 20),
	(13, 40, 10),
	(13, 41, 20),
	(13, 42, 0.25),
	(14, 27, 101),
	(14, 38, 833.33),
	(14, 40, 10),
	(14, 42, 0.26),
	(15, 27, 101),
	(15, 36, 20),
	(15, 40, 10),
	(15, 41, 20),
	(15, 42, 0.25),
	(16, 13, 70),
	(16, 29, 6),
	(16, 30, 5),
	(16, 31, 4),
	(16, 32, 4),
	(16, 15, 3),
	(16, 4, 3),
	(16, 16, 2),
	(16, 33, 1),
	(16, 5, 2),
	(16, 12, 2),
	(16, 35, 416.67),
	(16, 39, 17.36),
	(16, 42, 0.35),
	(17, 13, 70),
	(17, 29, 6),
	(17, 30, 5),
	(17, 31, 4),
	(17, 32, 4),
	(17, 15, 3),
	(17, 4, 3),
	(17, 16, 2),
	(17, 33, 1),
	(17, 5, 2),
	(17, 12, 2),
	(17, 36, 12.5),
	(17, 41, 12.5),
	(17, 42, 0.21),
	(18, 1, 60),
	(18, 33, 15);
INSERT INTO public.receta_item (receta_id, insumo_id, cantidad_base) VALUES
	(18, 7, 10),
	(18, 6, 8),
	(18, 15, 3),
	(18, 4, 2),
	(18, 9, 4),
	(18, 35, 500),
	(18, 39, 20.83),
	(18, 42, 0.42),
	(19, 1, 60),
	(19, 33, 15),
	(19, 7, 10),
	(19, 6, 8),
	(19, 15, 3),
	(19, 4, 2),
	(19, 9, 4),
	(19, 36, 20),
	(19, 41, 20),
	(19, 42, 0.25),
	(20, 14, 50),
	(20, 13, 20),
	(20, 30, 6),
	(20, 29, 6),
	(20, 15, 4),
	(20, 31, 5),
	(20, 4, 3),
	(20, 5, 2),
	(20, 32, 3),
	(20, 16, 2),
	(20, 12, 1),
	(20, 35, 416.67),
	(20, 39, 17.36),
	(20, 42, 0.35),
	(21, 14, 50),
	(21, 13, 20),
	(21, 30, 6),
	(21, 29, 6),
	(21, 15, 4),
	(21, 31, 5),
	(21, 4, 3),
	(21, 5, 2),
	(21, 32, 3),
	(21, 16, 2),
	(21, 12, 1),
	(21, 36, 12.5),
	(21, 41, 12.5),
	(21, 42, 0.21),
	(22, 29, 60),
	(22, 32, 31),
	(22, 7, 9),
	(22, 4, 2),
	(22, 35, 555.56),
	(22, 39, 23.15),
	(22, 42, 0.46),
	(23, 29, 60),
	(23, 32, 31),
	(23, 7, 9),
	(23, 4, 2),
	(23, 36, 22.22),
	(23, 41, 22.22),
	(23, 42, 0.28),
	(24, 1, 55),
	(24, 3, 35),
	(24, 10, 6),
	(24, 6, 3),
	(24, 9, 2),
	(24, 4, 1),
	(24, 34, 200),
	(24, 39, 8.33),
	(24, 42, 0.33),
	(25, 1, 58),
	(25, 3, 35),
	(25, 5, 3),
	(25, 6, 3),
	(25, 9, 2),
	(25, 4, 1),
	(25, 34, 200),
	(25, 39, 8.33),
	(25, 42, 0.33),
	(26, 1, 46),
	(26, 29, 50),
	(26, 6, 3),
	(26, 4, 2),
	(26, 12, 1),
	(26, 34, 200),
	(26, 39, 8.33),
	(26, 42, 0.33),
	(27, 1, 95),
	(27, 8, 2.5),
	(27, 11, 2),
	(27, 4, 2.5),
	(27, 34, 200),
	(27, 39, 8.33),
	(27, 42, 0.33),
	(28, 2, 70),
	(28, 1, 31),
	(28, 34, 200),
	(28, 39, 8.33),
	(28, 42, 0.33),
	(29, 2, 70),
	(29, 1, 31);
INSERT INTO public.receta_item (receta_id, insumo_id, cantidad_base) VALUES
	(29, 34, 200),
	(29, 39, 8.33),
	(29, 42, 0.33),
	(30, 2, 70),
	(30, 1, 31),
	(30, 34, 200),
	(30, 39, 8.33),
	(30, 42, 0.33),
	(31, 2, 70),
	(31, 1, 31),
	(31, 34, 200),
	(31, 39, 8.33),
	(31, 42, 0.33);


--
-- Data for Name: stock_pt; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.stock_pt (id, lote_id, comprobante, deposito, sector, rack, nivel, camara, bultos, pallets, kg_recibidos, cantidad_kg, bultos_danados, merma_kg, justificacion, recibido_por, fecha) VALUES
	(1, 1, 'REC-2026-00111', 'Producto terminado', 'Secos · Ambiente', 'A02', '02', NULL, 2352, 4, 1176, 1176, 0, 0, NULL, 'Diego Acosta', '2026-11-04 13:30:00+00'),
	(2, 2, 'REC-2026-00112', 'Producto terminado', 'Secos · Ambiente', 'A03', '02', NULL, 1176, 2, 588, 588, 0, 0, NULL, 'Diego Acosta', '2026-11-05 13:30:00+00'),
	(3, 3, 'REC-2026-00113', 'Producto terminado', 'Secos · Ambiente', 'B01', '02', NULL, 10, 1, 200, 200, 0, 0, NULL, 'Diego Acosta', '2026-11-06 13:30:00+00'),
	(4, 4, 'REC-2026-00114', 'Producto terminado', 'Secos · Ambiente', 'A02', '02', NULL, 2352, 4, 1176, 1176, 0, 0, NULL, 'Diego Acosta', '2026-11-09 13:30:00+00'),
	(5, 5, 'REC-2026-00115', 'Producto terminado', 'Secos · Ambiente', 'A04', '02', NULL, 49, 1, 392, 392, 0, 0, NULL, 'Diego Acosta', '2026-11-09 16:30:00+00'),
	(6, 6, 'REC-2026-00116', 'Producto terminado', 'Secos · Ambiente', 'A03', '02', NULL, 980, 2, 490, 490, 0, 0, NULL, 'Diego Acosta', '2026-11-10 13:30:00+00'),
	(7, 7, 'REC-2026-00117', 'Producto terminado', 'Secos · Ambiente', 'B03', '02', NULL, 1960, 1, 235.2, 235.2, 0, 0, NULL, 'Diego Acosta', '2026-11-10 16:00:00+00'),
	(8, 8, 'REC-2026-00118', 'Producto terminado', 'Secos · Ambiente', 'B01', '02', NULL, 10, 1, 100, 100, 0, 0, NULL, 'Diego Acosta', '2026-11-10 18:30:00+00'),
	(9, 9, 'REC-2026-00119', 'Producto terminado', 'Secos · Ambiente', 'A02', '02', NULL, 1960, 4, 980, 980, 0, 0, NULL, 'Diego Acosta', '2026-11-11 13:30:00+00'),
	(10, 10, 'REC-2026-00120', 'Producto terminado', 'Secos · Ambiente', 'A04', '02', NULL, 98, 2, 441, 441, 0, 0, NULL, 'Diego Acosta', '2026-11-11 16:30:00+00'),
	(11, 11, 'REC-2026-00121', 'Producto terminado', 'Secos · Ambiente', 'A03', '02', NULL, 980, 2, 490, 490, 0, 0, NULL, 'Diego Acosta', '2026-11-11 19:00:00+00'),
	(12, 12, 'REC-2026-00122', 'Producto terminado', 'Secos · Ambiente', 'A02', '02', NULL, 1960, 4, 980, 980, 0, 0, NULL, 'Diego Acosta', '2026-11-12 13:30:00+00'),
	(13, 13, 'REC-2026-00123', 'Producto terminado', 'Secos · Ambiente', 'A04', '02', NULL, 49, 1, 392, 392, 0, 0, NULL, 'Diego Acosta', '2026-11-12 16:00:00+00'),
	(14, 14, 'REC-2026-00124', 'Producto terminado', 'Secos · Ambiente', 'B01', '02', NULL, 10, 1, 200, 200, 0, 0, NULL, 'Diego Acosta', '2026-11-12 18:30:00+00'),
	(15, 15, 'REC-2026-00125', 'Producto terminado', 'Secos · Ambiente', 'A02', '02', NULL, 2352, 4, 1176, 876, 0, 0, NULL, 'Diego Acosta', '2026-11-13 13:30:00+00');


--
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.usuario (id, email, nombre, cargo, iniciales, rol, password_hash, activo, creado_en) VALUES
	(1, 'produccion@sigta.demo', 'Martín Pérez', 'Supervisor de producción', 'MP', 'PRODUCCION', '$2b$10$hR8yIyczw9libJQCSq0GN.1N5PBgB6aQMp3ymNMilLQ9v8V7F2luu', true, '2026-11-18 00:38:07.897+00'),
	(2, 'calidad@sigta.demo', 'Lucía Benítez', 'Técnica de calidad', 'LB', 'CALIDAD', '$2b$10$hR8yIyczw9libJQCSq0GN.1N5PBgB6aQMp3ymNMilLQ9v8V7F2luu', true, '2026-11-18 00:38:07.905+00'),
	(3, 'deposito@sigta.demo', 'Diego Acosta', 'Operario de depósito', 'DA', 'DEPOSITO', '$2b$10$hR8yIyczw9libJQCSq0GN.1N5PBgB6aQMp3ymNMilLQ9v8V7F2luu', true, '2026-11-18 00:38:07.907+00'),
	(4, 'gerencia@sigta.demo', 'Valeria Ruiz', 'Gerencia (sólo consulta)', 'VR', 'DIRECCION', '$2b$10$hR8yIyczw9libJQCSq0GN.1N5PBgB6aQMp3ymNMilLQ9v8V7F2luu', true, '2026-11-18 00:38:07.908+00');


--
-- Name: auditoria_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auditoria_id_seq', 127, true);


--
-- Name: consumo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.consumo_id_seq', 143, true);


--
-- Name: control_calidad_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.control_calidad_id_seq', 17, true);


--
-- Name: despacho_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.despacho_id_seq', 1, true);


--
-- Name: lote_produccion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.lote_produccion_id_seq', 20, true);


--
-- Name: orden_produccion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.orden_produccion_id_seq', 25, true);


--
-- Name: pallet_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pallet_id_seq', 34, true);


--
-- Name: partida_insumo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.partida_insumo_id_seq', 45, true);


--
-- Name: stock_pt_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.stock_pt_id_seq', 15, true);


--
-- Name: usuario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.usuario_id_seq', 4, true);


--
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- Name: auditoria auditoria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);


--
-- Name: categoria categoria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id);


--
-- Name: consumo consumo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consumo
    ADD CONSTRAINT consumo_pkey PRIMARY KEY (id);


--
-- Name: control_calidad control_calidad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.control_calidad
    ADD CONSTRAINT control_calidad_pkey PRIMARY KEY (id);


--
-- Name: despacho despacho_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.despacho
    ADD CONSTRAINT despacho_pkey PRIMARY KEY (id);


--
-- Name: insumo insumo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.insumo
    ADD CONSTRAINT insumo_pkey PRIMARY KEY (id);


--
-- Name: linea linea_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.linea
    ADD CONSTRAINT linea_pkey PRIMARY KEY (id);


--
-- Name: lote_produccion lote_produccion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lote_produccion
    ADD CONSTRAINT lote_produccion_pkey PRIMARY KEY (id);


--
-- Name: op_item op_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.op_item
    ADD CONSTRAINT op_item_pkey PRIMARY KEY (op_id, insumo_id);


--
-- Name: orden_produccion orden_produccion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orden_produccion
    ADD CONSTRAINT orden_produccion_pkey PRIMARY KEY (id);


--
-- Name: pallet pallet_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pallet
    ADD CONSTRAINT pallet_pkey PRIMARY KEY (id);


--
-- Name: partida_insumo partida_insumo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partida_insumo
    ADD CONSTRAINT partida_insumo_pkey PRIMARY KEY (id);


--
-- Name: producto producto_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.producto
    ADD CONSTRAINT producto_pkey PRIMARY KEY (id);


--
-- Name: receta_item receta_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receta_item
    ADD CONSTRAINT receta_item_pkey PRIMARY KEY (receta_id, insumo_id);


--
-- Name: receta receta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receta
    ADD CONSTRAINT receta_pkey PRIMARY KEY (id);


--
-- Name: stock_pt stock_pt_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_pt
    ADD CONSTRAINT stock_pt_pkey PRIMARY KEY (id);


--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- Name: auditoria_accion_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditoria_accion_idx ON public.auditoria USING btree (accion);


--
-- Name: auditoria_lote_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditoria_lote_id_idx ON public.auditoria USING btree (lote_id);


--
-- Name: auditoria_op_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditoria_op_id_idx ON public.auditoria USING btree (op_id);


--
-- Name: categoria_codigo_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX categoria_codigo_key ON public.categoria USING btree (codigo);


--
-- Name: consumo_op_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX consumo_op_id_idx ON public.consumo USING btree (op_id);


--
-- Name: consumo_partida_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX consumo_partida_id_idx ON public.consumo USING btree (partida_id);


--
-- Name: control_calidad_lote_id_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX control_calidad_lote_id_key ON public.control_calidad USING btree (lote_id);


--
-- Name: control_calidad_protocolo_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX control_calidad_protocolo_key ON public.control_calidad USING btree (protocolo);


--
-- Name: insumo_codigo_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX insumo_codigo_key ON public.insumo USING btree (codigo);


--
-- Name: lote_produccion_codigo_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX lote_produccion_codigo_key ON public.lote_produccion USING btree (codigo);


--
-- Name: lote_produccion_estado_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lote_produccion_estado_idx ON public.lote_produccion USING btree (estado);


--
-- Name: lote_produccion_op_id_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX lote_produccion_op_id_key ON public.lote_produccion USING btree (op_id);


--
-- Name: orden_produccion_estado_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orden_produccion_estado_idx ON public.orden_produccion USING btree (estado);


--
-- Name: orden_produccion_numero_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX orden_produccion_numero_key ON public.orden_produccion USING btree (numero);


--
-- Name: orden_produccion_secuencia_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX orden_produccion_secuencia_key ON public.orden_produccion USING btree (secuencia);


--
-- Name: pallet_codigo_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX pallet_codigo_key ON public.pallet USING btree (codigo);


--
-- Name: partida_insumo_insumo_id_estado_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX partida_insumo_insumo_id_estado_idx ON public.partida_insumo USING btree (insumo_id, estado);


--
-- Name: partida_insumo_nro_lote_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX partida_insumo_nro_lote_idx ON public.partida_insumo USING btree (nro_lote);


--
-- Name: producto_codigo_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX producto_codigo_key ON public.producto USING btree (codigo);


--
-- Name: producto_gtin_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX producto_gtin_key ON public.producto USING btree (gtin);


--
-- Name: receta_codigo_version_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX receta_codigo_version_key ON public.receta USING btree (codigo, version);


--
-- Name: stock_pt_lote_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX stock_pt_lote_id_idx ON public.stock_pt USING btree (lote_id);


--
-- Name: usuario_email_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX usuario_email_key ON public.usuario USING btree (email);


--
-- Name: auditoria trg_auditoria_solo_agregar; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auditoria_solo_agregar BEFORE DELETE OR UPDATE ON public.auditoria FOR EACH ROW EXECUTE FUNCTION public.sigta_auditoria_solo_agregar();


--
-- Name: control_calidad trg_control_calidad_inalterable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_control_calidad_inalterable BEFORE DELETE OR UPDATE ON public.control_calidad FOR EACH ROW EXECUTE FUNCTION public.sigta_protocolo_inalterable();


--
-- Name: despacho trg_despacho_bloqueo; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_despacho_bloqueo BEFORE INSERT ON public.despacho FOR EACH ROW EXECUTE FUNCTION public.sigta_bloqueo_logico();


--
-- Name: lote_produccion trg_lote_estado_final; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_lote_estado_final BEFORE UPDATE OF estado ON public.lote_produccion FOR EACH ROW EXECUTE FUNCTION public.sigta_estado_lote_final();


--
-- Name: stock_pt trg_stock_pt_bloqueo; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_stock_pt_bloqueo BEFORE INSERT ON public.stock_pt FOR EACH ROW EXECUTE FUNCTION public.sigta_bloqueo_logico();


--
-- Name: consumo consumo_insumo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consumo
    ADD CONSTRAINT consumo_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES public.insumo(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: consumo consumo_op_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consumo
    ADD CONSTRAINT consumo_op_id_fkey FOREIGN KEY (op_id) REFERENCES public.orden_produccion(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: consumo consumo_partida_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consumo
    ADD CONSTRAINT consumo_partida_id_fkey FOREIGN KEY (partida_id) REFERENCES public.partida_insumo(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: control_calidad control_calidad_lote_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.control_calidad
    ADD CONSTRAINT control_calidad_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES public.lote_produccion(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: despacho despacho_lote_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.despacho
    ADD CONSTRAINT despacho_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES public.lote_produccion(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: lote_produccion lote_produccion_op_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lote_produccion
    ADD CONSTRAINT lote_produccion_op_id_fkey FOREIGN KEY (op_id) REFERENCES public.orden_produccion(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: lote_produccion lote_produccion_producto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lote_produccion
    ADD CONSTRAINT lote_produccion_producto_id_fkey FOREIGN KEY (producto_id) REFERENCES public.producto(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: op_item op_item_insumo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.op_item
    ADD CONSTRAINT op_item_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES public.insumo(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: op_item op_item_op_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.op_item
    ADD CONSTRAINT op_item_op_id_fkey FOREIGN KEY (op_id) REFERENCES public.orden_produccion(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: orden_produccion orden_produccion_linea_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orden_produccion
    ADD CONSTRAINT orden_produccion_linea_id_fkey FOREIGN KEY (linea_id) REFERENCES public.linea(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: orden_produccion orden_produccion_producto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orden_produccion
    ADD CONSTRAINT orden_produccion_producto_id_fkey FOREIGN KEY (producto_id) REFERENCES public.producto(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: orden_produccion orden_produccion_receta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orden_produccion
    ADD CONSTRAINT orden_produccion_receta_id_fkey FOREIGN KEY (receta_id) REFERENCES public.receta(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: pallet pallet_lote_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pallet
    ADD CONSTRAINT pallet_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES public.lote_produccion(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: partida_insumo partida_insumo_insumo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partida_insumo
    ADD CONSTRAINT partida_insumo_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES public.insumo(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: producto producto_categoria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.producto
    ADD CONSTRAINT producto_categoria_id_fkey FOREIGN KEY (categoria_id) REFERENCES public.categoria(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: producto producto_linea_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.producto
    ADD CONSTRAINT producto_linea_id_fkey FOREIGN KEY (linea_id) REFERENCES public.linea(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: receta_item receta_item_insumo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receta_item
    ADD CONSTRAINT receta_item_insumo_id_fkey FOREIGN KEY (insumo_id) REFERENCES public.insumo(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: receta_item receta_item_receta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receta_item
    ADD CONSTRAINT receta_item_receta_id_fkey FOREIGN KEY (receta_id) REFERENCES public.receta(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: receta receta_producto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receta
    ADD CONSTRAINT receta_producto_id_fkey FOREIGN KEY (producto_id) REFERENCES public.producto(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: stock_pt stock_pt_lote_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_pt
    ADD CONSTRAINT stock_pt_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES public.lote_produccion(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--


