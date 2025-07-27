--
-- PostgreSQL database dump
--

-- Dumped from database version 16.8 (Debian 16.8-1.pgdg120+1)
-- Dumped by pg_dump version 16.8 (Debian 16.8-1.pgdg120+1)

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: authorities; Type: TABLE; Schema: public; Owner: kcm_user
--

CREATE TABLE public.authorities (
    authority character varying(255) NOT NULL,
    username character varying(255) NOT NULL,
    created_at timestamp(6) with time zone,
    created_by character varying(200),
    updated_at timestamp(6) with time zone,
    updated_by character varying(200)
);


ALTER TABLE public.authorities OWNER TO kcm_user;

--
-- Name: connectors; Type: TABLE; Schema: public; Owner: kcm_user
--

CREATE TABLE public.connectors (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone,
    created_by character varying(200),
    updated_at timestamp(6) with time zone,
    updated_by character varying(200),
    connector_config text NOT NULL,
    connector_name character varying(255) NOT NULL,
    connector_type character varying(255),
    enabled boolean NOT NULL,
    kc_cluster_id bigint NOT NULL,
    last_update timestamp(6) with time zone NOT NULL
);


ALTER TABLE public.connectors OWNER TO kcm_user;

--
-- Name: connectors_id_seq; Type: SEQUENCE; Schema: public; Owner: kcm_user
--

CREATE SEQUENCE public.connectors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.connectors_id_seq OWNER TO kcm_user;

--
-- Name: connectors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kcm_user
--

ALTER SEQUENCE public.connectors_id_seq OWNED BY public.connectors.id;


--
-- Name: kafka_cluster; Type: TABLE; Schema: public; Owner: kcm_user
--

CREATE TABLE public.kafka_cluster (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone,
    created_by character varying(200),
    updated_at timestamp(6) with time zone,
    updated_by character varying(200),
    bootstrap_server text NOT NULL,
    cluster_name character varying(255) NOT NULL,
    other_configs text,
    sasl_jaas_config text,
    sasl_mechanism character varying(255),
    security_protocol character varying(255),
    ssl_truststore_location character varying(255),
    ssl_truststore_password character varying(255),
    use_zookeeper boolean NOT NULL,
    zookeeper_path text,
    group_id bigint NOT NULL,
    metrics_enabled boolean DEFAULT false NOT NULL
);


ALTER TABLE public.kafka_cluster OWNER TO kcm_user;

--
-- Name: kafka_cluster_id_seq; Type: SEQUENCE; Schema: public; Owner: kcm_user
--

CREATE SEQUENCE public.kafka_cluster_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kafka_cluster_id_seq OWNER TO kcm_user;

--
-- Name: kafka_cluster_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kcm_user
--

ALTER SEQUENCE public.kafka_cluster_id_seq OWNED BY public.kafka_cluster.id;


--
-- Name: kafka_message_template; Type: TABLE; Schema: public; Owner: kcm_user
--

CREATE TABLE public.kafka_message_template (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone,
    created_by character varying(200),
    updated_at timestamp(6) with time zone,
    updated_by character varying(200),
    active boolean,
    kafka_message_template_description character varying(255),
    kafka_message_template_headers jsonb,
    kafka_message_template_key jsonb,
    kafka_message_template_key_with_schema boolean,
    kafka_message_template_name character varying(255),
    kafka_message_template_payload jsonb,
    kafka_message_template_payload_with_schema boolean,
    kafka_topic_name character varying(255),
    kafka_topic_partition integer,
    shared boolean,
    kcm_cluster_id bigint NOT NULL,
    kcm_user_id character varying(200) NOT NULL
);


ALTER TABLE public.kafka_message_template OWNER TO kcm_user;

--
-- Name: kafka_message_template_id_seq; Type: SEQUENCE; Schema: public; Owner: kcm_user
--

CREATE SEQUENCE public.kafka_message_template_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kafka_message_template_id_seq OWNER TO kcm_user;

--
-- Name: kafka_message_template_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kcm_user
--

ALTER SEQUENCE public.kafka_message_template_id_seq OWNED BY public.kafka_message_template.id;


--
-- Name: kc_clusters; Type: TABLE; Schema: public; Owner: kcm_user
--

CREATE TABLE public.kc_clusters (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone,
    created_by character varying(200),
    updated_at timestamp(6) with time zone,
    updated_by character varying(200),
    activated boolean,
    basic_auth boolean,
    cluster_name character varying(255) NOT NULL,
    k8s_token text,
    k8s_uri text,
    kcm_cluster_id bigint,
    password character varying(255),
    url character varying(255) NOT NULL,
    use_k8s boolean,
    username character varying(255)
);


ALTER TABLE public.kc_clusters OWNER TO kcm_user;

--
-- Name: kc_clusters_id_seq; Type: SEQUENCE; Schema: public; Owner: kcm_user
--

CREATE SEQUENCE public.kc_clusters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kc_clusters_id_seq OWNER TO kcm_user;

--
-- Name: kc_clusters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kcm_user
--

ALTER SEQUENCE public.kc_clusters_id_seq OWNED BY public.kc_clusters.id;


--
-- Name: kc_group; Type: TABLE; Schema: public; Owner: kcm_user
--

CREATE TABLE public.kc_group (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone,
    created_by character varying(200),
    updated_at timestamp(6) with time zone,
    updated_by character varying(200),
    activated boolean NOT NULL,
    color character varying(255) NOT NULL,
    name character varying(255) NOT NULL
);


ALTER TABLE public.kc_group OWNER TO kcm_user;

--
-- Name: kc_group_id_seq; Type: SEQUENCE; Schema: public; Owner: kcm_user
--

CREATE SEQUENCE public.kc_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kc_group_id_seq OWNER TO kcm_user;

--
-- Name: kc_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kcm_user
--

ALTER SEQUENCE public.kc_group_id_seq OWNED BY public.kc_group.id;


--
-- Name: kcm_users_groups; Type: TABLE; Schema: public; Owner: kcm_user
--

CREATE TABLE public.kcm_users_groups (
    kcm_group_id bigint NOT NULL,
    username character varying(255) NOT NULL,
    created_at timestamp(6) with time zone,
    created_by character varying(200),
    updated_at timestamp(6) with time zone,
    updated_by character varying(200),
    permission character varying(255) NOT NULL,
    CONSTRAINT kcm_users_groups_permission_check CHECK (((permission)::text = ANY ((ARRAY['VIEWER'::character varying, 'EDITOR'::character varying, 'ADMIN'::character varying])::text[])))
);


ALTER TABLE public.kcm_users_groups OWNER TO kcm_user;

--
-- Name: kcm_users_kafka_clusters; Type: TABLE; Schema: public; Owner: kcm_user
--

CREATE TABLE public.kcm_users_kafka_clusters (
    kafka_cluster_id bigint NOT NULL,
    username character varying(255) NOT NULL,
    created_at timestamp(6) with time zone,
    created_by character varying(200),
    updated_at timestamp(6) with time zone,
    updated_by character varying(200),
    permission character varying(255) NOT NULL,
    CONSTRAINT kcm_users_kafka_clusters_permission_check CHECK (((permission)::text = ANY ((ARRAY['VIEWER'::character varying, 'EDITOR'::character varying, 'ADMIN'::character varying])::text[])))
);


ALTER TABLE public.kcm_users_kafka_clusters OWNER TO kcm_user;

--
-- Name: kcm_users_kafka_connect_clusters; Type: TABLE; Schema: public; Owner: kcm_user
--

CREATE TABLE public.kcm_users_kafka_connect_clusters (
    kafka_connect_cluster_id bigint NOT NULL,
    username character varying(255) NOT NULL,
    created_at timestamp(6) with time zone,
    created_by character varying(200),
    updated_at timestamp(6) with time zone,
    updated_by character varying(200),
    permission character varying(255) NOT NULL,
    CONSTRAINT kcm_users_kafka_connect_clusters_permission_check CHECK (((permission)::text = ANY ((ARRAY['VIEWER'::character varying, 'EDITOR'::character varying, 'ADMIN'::character varying])::text[])))
);


ALTER TABLE public.kcm_users_kafka_connect_clusters OWNER TO kcm_user;

--
-- Name: metrics_bucket; Type: TABLE; Schema: public; Owner: kcm_user
--

CREATE TABLE public.metrics_bucket (
    kcm_cluster_id bigint NOT NULL,
    component_type character varying(50) NOT NULL,
    client_id character varying(255) NOT NULL,
    group_id character varying(255),
    topic character varying(255) NOT NULL,
    partition integer NOT NULL,
    status character varying(50) NOT NULL,
    minute_bucket timestamp with time zone NOT NULL,
    message_count bigint NOT NULL,
    service_name character varying(255),
    created_at timestamp without time zone DEFAULT now()
)
PARTITION BY RANGE (minute_bucket);


ALTER TABLE public.metrics_bucket OWNER TO kcm_user;

--
-- Name: sr_clusters; Type: TABLE; Schema: public; Owner: kcm_user
--

CREATE TABLE public.sr_clusters (
    id bigint NOT NULL,
    created_at timestamp(6) with time zone,
    created_by character varying(200),
    updated_at timestamp(6) with time zone,
    updated_by character varying(200),
    activated boolean,
    sr_cluster_name character varying(255) NOT NULL,
    default_registry boolean,
    k8s_token text,
    k8s_uri text,
    kcm_cluster_id bigint,
    url character varying(255) NOT NULL,
    use_k8s boolean
);


ALTER TABLE public.sr_clusters OWNER TO kcm_user;

--
-- Name: sr_clusters_id_seq; Type: SEQUENCE; Schema: public; Owner: kcm_user
--

CREATE SEQUENCE public.sr_clusters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sr_clusters_id_seq OWNER TO kcm_user;

--
-- Name: sr_clusters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kcm_user
--

ALTER SEQUENCE public.sr_clusters_id_seq OWNED BY public.sr_clusters.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: kcm_user
--

CREATE TABLE public.users (
    username character varying(200) NOT NULL,
    created_at timestamp(6) with time zone,
    created_by character varying(200),
    updated_at timestamp(6) with time zone,
    updated_by character varying(200),
    account_non_expired boolean,
    account_non_locked boolean,
    credentials_non_expired boolean,
    email character varying(200),
    enabled boolean,
    password character varying(200) NOT NULL,
    title character varying(200)
);


ALTER TABLE public.users OWNER TO kcm_user;

--
-- Name: connectors id; Type: DEFAULT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.connectors ALTER COLUMN id SET DEFAULT nextval('public.connectors_id_seq'::regclass);


--
-- Name: kafka_cluster id; Type: DEFAULT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kafka_cluster ALTER COLUMN id SET DEFAULT nextval('public.kafka_cluster_id_seq'::regclass);


--
-- Name: kafka_message_template id; Type: DEFAULT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kafka_message_template ALTER COLUMN id SET DEFAULT nextval('public.kafka_message_template_id_seq'::regclass);


--
-- Name: kc_clusters id; Type: DEFAULT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kc_clusters ALTER COLUMN id SET DEFAULT nextval('public.kc_clusters_id_seq'::regclass);


--
-- Name: kc_group id; Type: DEFAULT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kc_group ALTER COLUMN id SET DEFAULT nextval('public.kc_group_id_seq'::regclass);


--
-- Name: sr_clusters id; Type: DEFAULT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.sr_clusters ALTER COLUMN id SET DEFAULT nextval('public.sr_clusters_id_seq'::regclass);


--
-- Name: authorities authorities_pkey; Type: CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.authorities
    ADD CONSTRAINT authorities_pkey PRIMARY KEY (authority, username);


--
-- Name: connectors connectors_pkey; Type: CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.connectors
    ADD CONSTRAINT connectors_pkey PRIMARY KEY (id);


--
-- Name: kafka_cluster kafka_cluster_pkey; Type: CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kafka_cluster
    ADD CONSTRAINT kafka_cluster_pkey PRIMARY KEY (id);


--
-- Name: kafka_message_template kafka_message_template_pkey; Type: CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kafka_message_template
    ADD CONSTRAINT kafka_message_template_pkey PRIMARY KEY (id);


--
-- Name: kc_clusters kc_clusters_pkey; Type: CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kc_clusters
    ADD CONSTRAINT kc_clusters_pkey PRIMARY KEY (id);


--
-- Name: kc_group kc_group_pkey; Type: CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kc_group
    ADD CONSTRAINT kc_group_pkey PRIMARY KEY (id);


--
-- Name: kcm_users_groups kcm_users_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kcm_users_groups
    ADD CONSTRAINT kcm_users_groups_pkey PRIMARY KEY (kcm_group_id, username);


--
-- Name: kcm_users_kafka_clusters kcm_users_kafka_clusters_pkey; Type: CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kcm_users_kafka_clusters
    ADD CONSTRAINT kcm_users_kafka_clusters_pkey PRIMARY KEY (kafka_cluster_id, username);


--
-- Name: kcm_users_kafka_connect_clusters kcm_users_kafka_connect_clusters_pkey; Type: CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kcm_users_kafka_connect_clusters
    ADD CONSTRAINT kcm_users_kafka_connect_clusters_pkey PRIMARY KEY (kafka_connect_cluster_id, username);


--
-- Name: sr_clusters sr_clusters_pkey; Type: CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.sr_clusters
    ADD CONSTRAINT sr_clusters_pkey PRIMARY KEY (id);


--
-- Name: sr_clusters uk65i2t5nay1v05hyym4yu8im2y; Type: CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.sr_clusters
    ADD CONSTRAINT uk65i2t5nay1v05hyym4yu8im2y UNIQUE (kcm_cluster_id, sr_cluster_name);


--
-- Name: kafka_message_template ukj6k56cmfk1we8owg71owxw08j; Type: CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kafka_message_template
    ADD CONSTRAINT ukj6k56cmfk1we8owg71owxw08j UNIQUE (kcm_cluster_id, kafka_message_template_name);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (username);


--
-- Name: kcm_users_kafka_connect_clusters fk3lnfmxcrwnydoqgjh9grw4uvg; Type: FK CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kcm_users_kafka_connect_clusters
    ADD CONSTRAINT fk3lnfmxcrwnydoqgjh9grw4uvg FOREIGN KEY (kafka_connect_cluster_id) REFERENCES public.kc_clusters(id);


--
-- Name: authorities fkhjuy9y4fd8v5m3klig05ktofg; Type: FK CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.authorities
    ADD CONSTRAINT fkhjuy9y4fd8v5m3klig05ktofg FOREIGN KEY (username) REFERENCES public.users(username);


--
-- Name: kcm_users_kafka_clusters fkjmvuhryad9lbe9sqpcl4r3311; Type: FK CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kcm_users_kafka_clusters
    ADD CONSTRAINT fkjmvuhryad9lbe9sqpcl4r3311 FOREIGN KEY (username) REFERENCES public.users(username);


--
-- Name: kafka_cluster fkohuc3hiqukbxga008jxh92qp9; Type: FK CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kafka_cluster
    ADD CONSTRAINT fkohuc3hiqukbxga008jxh92qp9 FOREIGN KEY (group_id) REFERENCES public.kc_group(id);


--
-- Name: kafka_message_template fkp8emrc5o3sn2tb4142d89gksc; Type: FK CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kafka_message_template
    ADD CONSTRAINT fkp8emrc5o3sn2tb4142d89gksc FOREIGN KEY (kcm_cluster_id) REFERENCES public.kafka_cluster(id);


--
-- Name: kcm_users_groups fkpl2sigtfg9k977rkgwf65cxj0; Type: FK CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kcm_users_groups
    ADD CONSTRAINT fkpl2sigtfg9k977rkgwf65cxj0 FOREIGN KEY (username) REFERENCES public.users(username);


--
-- Name: kcm_users_kafka_clusters fkprqh535nrfo7hpgu8349q5djf; Type: FK CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kcm_users_kafka_clusters
    ADD CONSTRAINT fkprqh535nrfo7hpgu8349q5djf FOREIGN KEY (kafka_cluster_id) REFERENCES public.kafka_cluster(id);


--
-- Name: kcm_users_groups fkqckad43yne1qw8rdlqatqcfmf; Type: FK CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kcm_users_groups
    ADD CONSTRAINT fkqckad43yne1qw8rdlqatqcfmf FOREIGN KEY (kcm_group_id) REFERENCES public.kc_group(id);


--
-- Name: kafka_message_template fkqj2nb8mdt598gup64w6u64okh; Type: FK CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kafka_message_template
    ADD CONSTRAINT fkqj2nb8mdt598gup64w6u64okh FOREIGN KEY (kcm_user_id) REFERENCES public.users(username);


--
-- Name: kcm_users_kafka_connect_clusters fkt4bfpwrkaw4y2ofbyw4rl7oe1; Type: FK CONSTRAINT; Schema: public; Owner: kcm_user
--

ALTER TABLE ONLY public.kcm_users_kafka_connect_clusters
    ADD CONSTRAINT fkt4bfpwrkaw4y2ofbyw4rl7oe1 FOREIGN KEY (username) REFERENCES public.users(username);


--
-- PostgreSQL database dump complete
--

