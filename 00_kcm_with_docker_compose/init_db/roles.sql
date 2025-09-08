--
-- PostgreSQL database cluster dump
--

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE kcm_user;
ALTER ROLE kcm_user WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:KUYpdeRtK3S3u6LncuoQ/A==$n3+eCflga6LhB0jNFh+4k9ETXEHoJTswJtLAOwNyYuo=:sMKSJZ5+fWu2LD4LHwkOGVxKxs6vF/X5NOfRf9XnbbA=';




--
-- PostgreSQL database cluster dump complete
--

